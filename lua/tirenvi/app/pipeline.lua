-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------
local Document = require("tirenvi.core.document")
local Attrs = require("tirenvi.core.attrs")
local Blocks = require("tirenvi.core.blocks")
local tir_buf = require("tirenvi.core.tir_buf")
local dirty_range = require("tirenvi.core.dirty_range")
local Request = require("tirenvi.app.request")
local flat_parser = require("tirenvi.parser.flat_parser")
local buf_parser = require("tirenvi.parser.buf_parser")
local LinProvider = require("tirenvi.io.buffer_line_provider")
local buf_state = require("tirenvi.io.buf_state")
local writer = require("tirenvi.io.writer")
local attr_store = require("tirenvi.io.attr_store")
local reader = require("tirenvi.io.reader")
local dirty = require("tirenvi.io.dirty")
local Range = require("tirenvi.util.range")
local Range3 = require("tirenvi.util.range3")
local errors = require("tirenvi.util.errors")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

local api = vim.api

-- private helpers

---@param ctx Context
---@param req_r Request
---@return Document
local function flat_to_doc(ctx, req_r)
    local doc = flat_parser.parse(ctx, req_r)
    log.watch("ATTR", Document.debug_attrs(doc, "1DOC ATTR:"))
    Document.apply_attrs_by_id(doc, req_r.attrs)
    log.watch("ATTR", Document.debug_attrs(doc, "4CACHED:"))
    return doc
end

---@param ctx Context
---@param req_r Request
---@param range3 Range3|nil
---@return Document
local function buf_to_bdoc_text_driven(ctx, req_r, range3)
    reader.read(ctx, req_r)
    log.watch("ATTR", Attrs.debug_attrs(req_r.attrs, "CHACHED ATTRS:"))
    req_r.attrs = Attrs.adjust(req_r.attrs or {}, range3)
    if range3 then log.watch("ATTR", Attrs.debug_attrs(req_r.attrs, "0UPDATE CHACHED:")) end
    local buf_doc = buf_parser.parse_text_driven(ctx, req_r, range3)
    log.watch("ATTR", Document.debug_attrs(buf_doc, "1DOC ATTR:"))
    return buf_doc
end

---@param ctx Context
---@param req_r Request
---@return Document|nil
local function buf_to_bdoc_attr_driven(ctx, req_r)
    reader.read(ctx, req_r)
    if not Attrs.has_range(req_r.attrs) then
        return nil
    end
    log.watch("ATTR", Attrs.debug_attrs(req_r.attrs, "CHACHED ATTRS:"))
    local buf_doc = buf_parser.parse_attr_driven(ctx, req_r)
    log.watch("ATTR", Document.debug_attrs(buf_doc, "1DOC ATTR:"))
    return buf_doc
end

---@param ctx Context
---@param req_r Request
---@return Document
local function buf_to_doc_text_driven(ctx, req_r)
    local buf_doc = buf_to_bdoc_text_driven(ctx, req_r)
    Document.apply_cached_attr(buf_doc, req_r.attrs)
    log.watch("ATTR", Document.debug_attrs(buf_doc, "4CACHED:"))
    return Document.from_buf_doc(buf_doc)
end

---@param ctx Context
---@param req_r Request
---@param no_normalize boolean -- If true, skip nomalizing.
-- Prevents line count changes that would break put(); used for repair.
---@return Document|nil
local function buf_to_doc_attrs_driven(ctx, req_r, no_normalize)
    local buf_doc = buf_to_bdoc_attr_driven(ctx, req_r)
    if not buf_doc or not Blocks.has_grid(buf_doc.blocks) then
        return nil
    end
    Document.insert_empty_lines(buf_doc)
    local doc = Document.from_buf_doc(buf_doc, no_normalize)
    log.watch("ATTR", Document.debug_attrs(doc, "7INSERT EMPTY:"))
    return doc
end

---@param ctx Context
---@param req_r Request
---@param buf_doc Document
---@param no_undo boolean|nil
local function doc_to_vim(ctx, req_r, buf_doc, no_undo)
    local vi_lines = buf_parser.unparse(buf_doc, req_r)
    log.watch("ATTR", Document.debug_attrs(buf_doc, "9DOC ATTR:"))
    local req_w = Request.new_writer(req_r.range, vi_lines, no_undo or false)
    req_w.attrs = Document.replace_attrs(buf_doc, req_r.range, req_r.attrs)
    log.watch("ATTR", Attrs.debug_attrs(req_w.attrs, "9CHACHED:"))
    attr_store.write(ctx, req_w.attrs)
    if not util.same_str_array(vi_lines, req_r.lines) then
        writer.write(ctx, req_w)
    end
end

---@param ctx Context
---@param doc Document
---@param no_undo boolean|nil
local function doc_to_flat(ctx, req_r, doc, no_undo)
    local fl_lines = flat_parser.unparse(ctx, doc)
    local req_w = Request.new_writer(req_r.range, fl_lines, no_undo or false)
    req_w.attrs = vim.deepcopy(req_r.attrs)
    Attrs.remove_range(req_w.attrs)
    log.watch("ATTR", Attrs.debug_attrs(req_w.attrs, "9CHACHED:"))
    attr_store.write(ctx, req_w.attrs)
    writer.write(ctx, req_w)
end

---@param ctx Context
---@param irow integer
local function get_range(ctx, irow)
    local line_provider = LinProvider.new(ctx.bufnr)
    local top = tir_buf.get_block_top_nrow(ctx, line_provider, irow)
    local bottom = tir_buf.get_block_bottom_nrow(ctx, line_provider, irow)
    return top, bottom
end

---@param ctx Context
---@param row Range
local function expand_rect(ctx, row)
    local top, bottom = get_range(ctx, row.first)
    row.first = top
    local irow = bottom + 1
    while irow <= row.last do
        _, bottom = get_range(ctx, irow)
        irow = bottom + 1
    end
    row.last = bottom
end

---@param ctx Context
---@param range3 Range3
---@return Attr[]|nil
local function reconcile_attrs(ctx, range3)
    local req_r = Request.new_reader(Range3.get_new_range(range3))
    local buf_doc = buf_to_bdoc_text_driven(ctx, req_r, range3)
    if not Attrs.has_range(req_r.attrs) then
        return nil
    end
    Document.inherit_neighbor_attr(buf_doc, req_r.attrs, range3)
    log.watch("ATTR", Document.debug_attrs(buf_doc, "2NEIGHBOR:"))
    Document.infer_consistent_attr(buf_doc)
    log.watch("ATTR", Document.debug_attrs(buf_doc, "3CONSISTENT:"))
    Document.apply_cached_attr(buf_doc, req_r.attrs)
    log.watch("ATTR", Document.debug_attrs(buf_doc, "4CACHED:"))
    Document.set_auto_attr(buf_doc)
    log.watch("ATTR", Document.debug_attrs(buf_doc, "5AUTO ATTR:"))
    local attrs = Document.replace_attrs(buf_doc, req_r.range, req_r.attrs)
    log.watch("ATTR", Attrs.debug_attrs(attrs, "6RESULT:"))
    attr_store.write(ctx, attrs)
    return attrs
end

---@param bufnr number
---@param attrs Attr[]
---@param range3 Range3
local function reconcile_dirty_ranges(bufnr, attrs, range3)
    local prev_ranges = dirty.get_ranges(bufnr)
    local line_provider = LinProvider.new(bufnr)
    local inv_ranges = dirty_range.reconcile(line_provider, prev_ranges, attrs, range3)
    dirty.set_ranges(bufnr, inv_ranges)
end

local local_range = nil
---@param ctx Context
local function apply_local_range(ctx)
    ---@cast local_range Range
    M.cmd_format(ctx, true, true)
    local_range = nil
end

---@param ctx Context
local function schedule_new_range(ctx)
    local new_ranges = dirty.get_ranges(ctx.bufnr)
    if #new_ranges == 0 then
        return
    end
    if local_range == nil then
        local_range = Range.bounding(new_ranges)
        vim.schedule(function()
            apply_local_range(ctx)
        end)
    else
        log.watch("UNDO", ctx.bufnr, { "multi time on_lines", local_range })
        new_ranges[#new_ranges + 1] = local_range
        local_range = Range.bounding(new_ranges)
    end
end

---@param ctx Context
---@param range3 Range3|nil
local function repair_request(ctx, range3)
    if not buf_state.is_repair(ctx, range3) then
        return
    end
    schedule_new_range(ctx)
end

---@param ctx Context
---@param range3 Range3|nil
local function repair(ctx, range3)
    local bufnr = ctx.bufnr
    vim.schedule(function()
        if not api.nvim_buf_is_valid(bufnr) then
            return
        end
        if api.nvim_get_current_buf() ~= bufnr then
            return
        end
        local ok, err = xpcall(
            function()
                repair_request(ctx, range3)
            end,
            debug.traceback
        )
        if not ok then
            error(err)
        end
    end)
end

---@param ctx Context
---@param range Range
---@return boolean
local function has_dirty(ctx, range)
    local dirty_ranges = dirty.get_ranges(ctx.bufnr)
    local ranges = Range.slice(dirty_ranges, range)
    return #ranges > 0
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param ctx Context
---@param no_undo boolean|nil
---@return nil
function M.from_flat(ctx, no_undo)
    local req_r = Request.new_reader(Range.WHOLE)
    reader.read(ctx, req_r)
    log.watch("ATTR", Attrs.debug_attrs(req_r.attrs, "CHACHED ATTRS:"))
    if util.ensure_no_reserved_marks(req_r.lines) then
        local flat_doc = flat_to_doc(ctx, req_r)
        Document.set_auto_attr(flat_doc)
        log.watch("ATTR", Document.debug_attrs(flat_doc, "5AUTO ATTR:"))
        local buf_doc = Document.to_vim(flat_doc)
        doc_to_vim(ctx, req_r, buf_doc, no_undo)
    else
        local buf_doc = buf_to_doc_text_driven(ctx, req_r)
        local attrs = Blocks.collect_attrs(buf_doc.blocks)
        attr_store.write(ctx, attrs)
    end
end

---@param ctx Context
---@param no_undo boolean|nil
function M.to_flat(ctx, no_undo)
    local req_r = Request.new_reader(Range.WHOLE)
    local doc = buf_to_doc_text_driven(ctx, req_r)
    if doc and Blocks.has_grid(doc.blocks) then
        doc_to_flat(ctx, req_r, doc, no_undo)
    end
end

---@param ctx Context
---@param sel Rect
---@param width_op WidthOp
function M.cmd_width(ctx, sel, width_op)
    expand_rect(ctx, sel.row)
    log.debug("row%s, col%s", Range.short(sel.row), Range.short(sel.col))
    if has_dirty(ctx, sel.row) then
        error(errors.new_domain_error(errors.ERR.TABLE_IS_NOT_ALIGNED))
    end
    local req_r = Request.new_reader(sel.row)
    local doc = buf_to_doc_text_driven(ctx, req_r)
    if doc and Blocks.has_grid(doc.blocks) then
        Blocks.change_width(doc.blocks, sel.col, width_op)
        local buf_doc = Document.to_vim(doc)
        doc_to_vim(ctx, req_r, buf_doc)
    end
end

---@param ctx Context
---@param no_normalize boolean|nil
---@param no_undo boolean|nil
function M.cmd_format(ctx, no_normalize, no_undo)
    no_normalize = no_normalize or false
    local req_r = Request.new_reader(Range.WHOLE)
    local doc = buf_to_doc_attrs_driven(ctx, req_r, no_normalize)
    if not doc or not Blocks.has_grid(doc.blocks) then
        return
    end
    local buf_doc = Document.to_vim(doc)
    doc_to_vim(ctx, req_r, buf_doc, no_undo)
end

---@param ctx Context
---@param range3 Range3
function M.on_lines(ctx, range3)
    local attrs = reconcile_attrs(ctx, range3)
    if not attrs then
        return
    end
    reconcile_dirty_ranges(ctx.bufnr, attrs, range3)
    repair(ctx, range3)
end

---@param ctx Context
function M.insert_leave(ctx)
    repair(ctx)
end

return M
