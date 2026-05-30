-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------
local Document = require("tirenvi.core.document")
local Attrs = require("tirenvi.core.attrs")
local Blocks = require("tirenvi.core.blocks")
local Bufline = require("tirenvi.core.bufline")
local dirty_range = require("tirenvi.core.dirty_range")
local Request = require("tirenvi.app.request")
local ReadResult = require("tirenvi.app.read_result")
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
---@param r_result ReadResult
---@return Document
local function fllines_to_tirdoc(ctx, r_result)
    local tirdoc = flat_parser.parse(ctx, r_result)
    log.watch("ATTR", Document.debug_attrs(tirdoc, "[1]DOC ATTR:"))
    Document.apply_attrs_by_id(tirdoc, r_result.attrs)
    log.watch("ATTR", Document.debug_attrs(tirdoc, "[4]CACHED:"))
    return tirdoc
end

---@param ctx Context
---@param r_result ReadResult
---@param range3 Range3|nil
---@return Document
local function buf_to_bdoc_text_driven(ctx, r_result, range3)
    r_result.attrs = Attrs.adjust(r_result.attrs or {}, range3)
    if range3 then log.watch("ATTR", Attrs.debug_attrs(r_result.attrs, "[0]UPDATE CHACHED:")) end
    local bufdoc = buf_parser.parse_text_driven(ctx, r_result, range3)
    local first = ReadResult.lua_range(r_result)
    Document.set_attr_range(bufdoc, first)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[1]DOC ATTR:"))
    return bufdoc
end

---@param ctx Context
---@param r_result ReadResult
---@return Document
local function buflines_to_tirdoc_text_driven(ctx, r_result)
    local bufdoc = buf_to_bdoc_text_driven(ctx, r_result)
    Document.apply_cached_attr(bufdoc, r_result.attrs)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[4]CACHED:"))
    return Document.from_bufdoc(bufdoc)
end

---@param ctx Context
---@param r_result ReadResult
---@param no_normalize boolean -- If true, skip nomalizing.
-- Prevents line count changes that would break put(); used for repair.
---@return Document
local function buflines_to_tirdoc_attrs_driven(ctx, r_result, no_normalize)
    log.watch("ATTR", Attrs.debug_attrs(r_result.attrs, "CHACHED ATTRS:"))
    local bufdoc = buf_parser.parse_attr_driven(ctx, r_result)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[1]DOC ATTR:"))
    Document.insert_empty_lines(bufdoc)
    local doc = Document.from_bufdoc(bufdoc, no_normalize)
    log.watch("ATTR", Document.debug_attrs(doc, "[7]INSERT EMPTY:"))
    return doc
end

---@param ctx Context
---@param r_result ReadResult
---@param bufdoc Document
---@param no_undo boolean|nil
local function bufdoc_to_buflines(ctx, r_result, bufdoc, no_undo)
    local first = ReadResult.lua_range(r_result)
    Document.set_attr_range(bufdoc, first)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[9]DOC ATTR:"))
    local attrs = Document.replace_attrs(bufdoc, r_result.range, r_result.attrs)
    log.watch("ATTR", Attrs.debug_attrs(attrs, "[9]CHACHED:"))
    attr_store.write(ctx, attrs)
    local buf_lines = buf_parser.unparse(bufdoc)
    if not util.same_str_array(buf_lines, r_result.lines) then
        local req_w = Request.new_writer(r_result.range, buf_lines, no_undo or false)
        req_w.attrs = attrs
        writer.write(ctx, req_w)
    end
end

---@param ctx Context
---@param doc Document
---@param no_undo boolean|nil
local function doc_to_flat(ctx, r_result, doc, no_undo)
    local fllines = flat_parser.unparse(ctx, doc)
    local req_w = Request.new_writer(r_result.range, fllines, no_undo or false)
    req_w.attrs = vim.deepcopy(r_result.attrs)
    Attrs.remove_range(req_w.attrs)
    log.watch("ATTR", Attrs.debug_attrs(req_w.attrs, "[9]CHACHED:"))
    attr_store.write(ctx, req_w.attrs, true)
    writer.write(ctx, req_w)
end

---@param ctx Context
---@param irow integer
local function get_range(ctx, irow)
    local line_provider = LinProvider.new(ctx.bufnr)
    local top = Bufline.get_block_top_nrow(ctx, line_provider, irow)
    local bottom = Bufline.get_block_bottom_nrow(ctx, line_provider, irow)
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
---@param r_result ReadResult
---@param range3 Range3
---@return Attr[]
local function reconcile_attrs(ctx, r_result, range3)
    local bufdoc = buf_to_bdoc_text_driven(ctx, r_result, range3)
    Document.inherit_neighbor_attr(bufdoc, r_result.attrs, range3)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[2]NEIGHBOR:"))
    Document.infer_consistent_attr(bufdoc)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[3]CONSISTENT:"))
    Document.apply_cached_attr(bufdoc, r_result.attrs)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[4]CACHED:"))
    Document.set_auto_attr(bufdoc)
    local attrs = Document.replace_attrs(bufdoc, r_result.range, r_result.attrs)
    log.watch("ATTR", Attrs.debug_attrs(attrs, "[6]RESULT:"))
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
    local r_result = reader.read(ctx, Range.WHOLE)
    local tirdoc
    if ReadResult.is_flat(r_result) or not Bufline.has_pipe(r_result.lines) then
        util.ensure_no_reserved_marks(r_result.lines)
        tirdoc = fllines_to_tirdoc(ctx, r_result)
    else
        tirdoc = buflines_to_tirdoc_text_driven(ctx, r_result)
    end
    Document.set_auto_attr(tirdoc)
    local bufdoc = Document.to_bufdoc(tirdoc)
    bufdoc_to_buflines(ctx, r_result, bufdoc, no_undo)
end

---@param ctx Context
---@param no_undo boolean|nil
function M.to_flat(ctx, no_undo)
    local r_result = reader.read(ctx, Range.WHOLE)
    if ReadResult.is_flat(r_result) then
        return
    end
    local doc = buflines_to_tirdoc_text_driven(ctx, r_result)
    doc_to_flat(ctx, r_result, doc, no_undo)
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
    local r_result = reader.read(ctx, sel.row)
    if ReadResult.is_flat(r_result) then
        return
    end
    local doc = buflines_to_tirdoc_text_driven(ctx, r_result)
    Blocks.change_width(doc.blocks, sel.col, width_op)
    local bufdoc = Document.to_bufdoc(doc)
    bufdoc_to_buflines(ctx, r_result, bufdoc)
end

---@param ctx Context
---@param no_normalize boolean|nil
---@param no_undo boolean|nil
function M.cmd_format(ctx, no_normalize, no_undo)
    no_normalize = no_normalize or false
    local r_result = reader.read(ctx, Range.WHOLE)
    if ReadResult.is_flat(r_result) then
        return
    end
    local doc = buflines_to_tirdoc_attrs_driven(ctx, r_result, no_normalize)
    local bufdoc = Document.to_bufdoc(doc)
    bufdoc_to_buflines(ctx, r_result, bufdoc, no_undo)
end

---@param ctx Context
---@param range3 Range3
function M.on_lines(ctx, range3)
    local r_result = reader.read(ctx, Range3.get_new_range(range3))
    if ReadResult.is_flat(r_result) then
        return
    end
    local attrs = reconcile_attrs(ctx, r_result, range3)
    reconcile_dirty_ranges(ctx.bufnr, attrs, range3)
    repair(ctx, range3)
end

---@param ctx Context
function M.insert_leave(ctx)
    repair(ctx)
end

return M
