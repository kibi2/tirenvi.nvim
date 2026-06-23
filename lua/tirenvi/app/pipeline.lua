-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------
local config = require("tirenvi.config")
local Document = require("tirenvi.core.document")
local Attrs = require("tirenvi.core.attrs")
local Attr = require("tirenvi.core.attr")
local Bufline = require("tirenvi.core.bufline")
local dirty_range = require("tirenvi.core.dirty_range")
local Request = require("tirenvi.app.request")
local width_layout = require("tirenvi.width.layout")
local flat_parser = require("tirenvi.parser.flat_parser")
local buf_parser = require("tirenvi.parser.buf_parser")
local LinProvider = require("tirenvi.io.buffer_line_provider")
local buffer = require("tirenvi.io.buffer")
local buf_state = require("tirenvi.io.buf_state")
local writer = require("tirenvi.io.writer")
local attr_store = require("tirenvi.io.attr_store")
local reader = require("tirenvi.io.reader")
local dirty = require("tirenvi.io.dirty")
local util = require("tirenvi.util.util")
local Range = require("tirenvi.util.range")
local Range3 = require("tirenvi.util.range3")
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
local function fltlines_to_tirdoc(ctx, r_result)
    local tirdoc = flat_parser.parse(ctx, r_result)
    log.watch("ATTR", Document.debug_attrs(tirdoc, "[1]DOC ATTR:"))
    Document.apply_attrs(tirdoc, r_result.attrs)
    log.watch("ATTR", Document.debug_attrs(tirdoc, "[4]CACHED:"))
    return tirdoc
end

---@param ctx Context
---@param r_result ReadResult
---@return Document
local function buflines_to_bufdoc_text_driven(ctx, r_result)
    local opts = { first = r_result.range.first }
    local bufdoc = buf_parser.parse(ctx, r_result, opts)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[1]DOC ATTR:"))
    Document.apply_attrs(bufdoc, r_result.attrs)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[4]CACHED:"))
    return bufdoc
end

---@param ctx Context
---@param r_result ReadResult
-- Prevents line count changes that would break put(); used for repair.
---@return Document
local function buflines_to_bufdoc_attrs_driven(ctx, r_result)
    log.watch("ATTR", Attrs.debug_attrs(r_result.attrs, "CHACHED ATTRS:"))
    local opts = { attrs = r_result.attrs }
    local bufdoc = buf_parser.parse(ctx, r_result, opts)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[1]DOC ATTR:"))
    Document.insert_empty_lines(bufdoc)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[7]INSERT EMPTY:"))
    return bufdoc
end

---@param tirdoc Document
local function apply_width_mode(tirdoc)
    width_layout.compute(tirdoc)
end

---@param ctx Context
---@param r_result ReadResult
---@param doc Document
---@param no_undo boolean|nil
---@param no_normalize boolean|nil
local function doc_to_buflines(ctx, r_result, doc, no_undo, no_normalize)
    local tirdoc = doc
    if not doc._tir then
        tirdoc = Document.from_bufdoc(doc, no_normalize)
    end
    apply_width_mode(tirdoc)
    local bufdoc = Document.to_bufdoc(tirdoc)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[9]DOC ATTR:"))
    local attrs = Document.replace_attrs(bufdoc, r_result.range, r_result.attrs)
    log.watch("ATTR", Attrs.debug_attrs(attrs, "[9]CHACHED:"))
    buf_state.set_buffer_flat(ctx.bufnr, false)
    attr_store.write(ctx.bufnr, attrs)
    local buf_lines = buf_parser.unparse(bufdoc)
    if not util.same_str_array(buf_lines, r_result.lines) then
        local req_w = Request.new_writer(r_result, buf_lines, no_undo)
        writer.write(ctx, req_w)
    end
end

---@param ctx Context
---@param tirdoc Document
---@param is_write_pre boolean|nil
local function tirdoc_to_flat(ctx, r_result, tirdoc, is_write_pre)
    local fltlines = flat_parser.unparse(ctx, tirdoc)
    local req_w = Request.new_writer(r_result, fltlines, is_write_pre)
    local attrs = vim.deepcopy(r_result.attrs)
    if not is_write_pre then
        Attrs.remove_range(attrs)
        log.watch("ATTR", Attrs.debug_attrs(attrs, "[9]CHACHED:"))
        buf_state.set_buffer_flat(ctx.bufnr, true)
        attr_store.write(ctx.bufnr, attrs)
    end
    writer.write(ctx, req_w)
end

---@param ctx Context
---@param irow integer
local function expand_rect(ctx, irow)
    local line_provider = LinProvider.new(ctx.bufnr)
    local top = Bufline.get_block_top_nrow(ctx, line_provider, irow)
    local bottom = Bufline.get_block_bottom_nrow(ctx, line_provider, irow)
    return Range.from_lua(top, bottom)
end

---@param r_result ReadResult
---@param bufdoc  Document
---@param range3 Range3
---@return Attr[]
local function reconcile_attrs(r_result, bufdoc, range3)
    Document.inherit_neighbor_attr(bufdoc, r_result.attrs, range3)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[2]NEIGHBOR:"))
    Document.infer_consistent_attr(bufdoc)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[3]CONSISTENT:"))
    Document.apply_attrs(bufdoc, r_result.attrs)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[4]CACHED:"))
    Document.set_max_attr(bufdoc)
    local attrs = Document.replace_attrs(bufdoc, r_result.range, r_result.attrs)
    log.watch("ATTR", Attrs.debug_attrs(attrs, "[6]RESULT:"))
    return attrs
end

---@param bufnr number
---@param attrs Attr[]
---@param range3 Range3
local function reconcile_dirty_ranges(bufnr, attrs, range3)
    local prev_ranges = dirty.get_ranges(bufnr)
    local line_provider = LinProvider.new(bufnr)
    local inv_ranges = dirty_range.reconcile(line_provider, prev_ranges, attrs, range3)
    log.watch("INVD", inv_ranges)
    dirty.set_ranges(bufnr, inv_ranges)
end

local schedule_repair_flag = false
---@param ctx Context
---@param range3 Range3|nil
local function schedule_repair(ctx, range3)
    if not schedule_repair_flag then
        vim.schedule(function()
            schedule_repair_flag = false
            local no_normalize = range3 and Range3.get_delta(range3) == 0 or false
            M.cmd_repair(ctx, true, no_normalize)
        end)
        schedule_repair_flag = true
    else
        local dirty_ranges = dirty.get_ranges(ctx.bufnr)
        log.watch("UNDO", ctx.bufnr, { "multi time on_lines", dirty_ranges })
    end
end

---@param ctx Context
---@param range3 Range3|nil
local function repair_request(ctx, range3)
    if buf_state.is_repair(ctx, range3) then
        schedule_repair(ctx, range3)
    end
end

---@param ctx Context
---@return boolean
local function need_repair(ctx)
    if buf_state.is_flat(ctx.bufnr) then
        return false
    end
    if buf_state.has_grid(ctx) == false then
        return false
    end
    -- repair must remove redundant padding,
    -- so it does not check whether dirty exists.
    return true
end

---@param ctx Context
---@param range3 Range3
---@param r_result ReadResult
local function update_attrs(ctx, range3, r_result)
    r_result.attrs = Attrs.adjust(r_result.attrs, range3)
    log.watch("ATTR", Attrs.debug_attrs(r_result.attrs, "[0]UPDATE CHACHED:"))
    local opts = { range3 = range3, first = r_result.range.first }
    local bufdoc = buf_parser.parse(ctx, r_result, opts)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[1]DOC ATTR:"))
    local attrs = reconcile_attrs(r_result, bufdoc, range3)
    reconcile_dirty_ranges(ctx.bufnr, attrs, range3)
    attr_store.write(ctx.bufnr, attrs)
end

---@param width_op WidthOp
local function change_attrs_width(attrs, width_op)
    return Attrs.change_width(attrs, width_op)
end

---@param ctx Context
---@param width_op WidthOp
local function change_width(ctx, width_op)
    local row_range = expand_rect(ctx, width_op.irow)
    local r_result = reader.read(ctx, row_range)
    local bufdoc = buflines_to_bufdoc_text_driven(ctx, r_result)
    log.assert(#bufdoc.blocks == 1, "only one block")
    local attr = bufdoc.blocks[1].attr
    if Attr.is_plain(attr) then return end
    local column = Attr.get(attr, width_op.icol)
    column.width = width_op:apply(column.width)
    attr.width_mode = "wrap_width"
    doc_to_buflines(ctx, r_result, bufdoc)
end

---@param ctx Context
---@param width_op WidthOp
local function change_fit(ctx, width_op)
    log.debug("row%d, col%d", width_op.irow, width_op.icol)
    local row_range = expand_rect(ctx, width_op.irow)
    local r_result = reader.read(ctx, row_range)
    if change_attrs_width(r_result.attrs, width_op) then
        local bufdoc = buflines_to_bufdoc_text_driven(ctx, r_result)
        log.watch("ATTR", Document.debug_attrs(bufdoc, "[88]MODE"))
        doc_to_buflines(ctx, r_result, bufdoc)
        log.watch("ATTR", Document.debug_attrs(bufdoc, "[88]MODE"))
    end
end

---@param ctx Context
---@param width_op WidthOp
local function change_wrap(ctx, width_op)
    log.debug("row%d, col%d", width_op.irow, width_op.icol)
    local row_range = expand_rect(ctx, width_op.irow)
    local r_result = reader.read(ctx, row_range)
    if change_attrs_width(r_result.attrs, width_op) then
        local bufdoc = buflines_to_bufdoc_text_driven(ctx, r_result)
        log.watch("ATTR", Document.debug_attrs(bufdoc, "[88]MODE"))
        doc_to_buflines(ctx, r_result, bufdoc)
        log.watch("ATTR", Document.debug_attrs(bufdoc, "[88]MODE"))
    end
end

---@param ctx Context
---@param width_op WidthOp
local function change_mode(ctx, width_op)
    local attrs = attr_store.read(ctx.bufnr)
    local attr = Attrs.get(attrs, width_op.irow)
    Attr.change_width_mode(attr or {})
    attr_store.write(ctx.bufnr, attrs)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param ctx Context
---@return nil
function M.read_post(ctx)
    local r_result = reader.read(ctx, Range.WHOLE)
    if not Bufline.has_pipe(r_result.lines) then
        util.ensure_no_reserved_marks(r_result.lines)
        local tirdoc = fltlines_to_tirdoc(ctx, r_result)
        doc_to_buflines(ctx, r_result, tirdoc, true)
    else
        local bufdoc = buflines_to_bufdoc_text_driven(ctx, r_result)
        doc_to_buflines(ctx, r_result, bufdoc, true)
    end
end

local backup_buffer
---@param ctx Context
function M.write_pre(ctx)
    backup_buffer = M.to_flat(ctx, true)
end

---@param ctx Context
function M.write_post(ctx)
    if backup_buffer then
        local r_result = reader.read(ctx, Range.WHOLE)
        local req = Request.new_writer(r_result, backup_buffer, true)
        writer.write(ctx, req)
        backup_buffer = nil
    end
end

---@param ctx Context
---@return nil
function M.from_flat(ctx)
    local r_result = reader.read(ctx, Range.WHOLE)
    util.ensure_no_reserved_marks(r_result.lines)
    local tirdoc = fltlines_to_tirdoc(ctx, r_result)
    doc_to_buflines(ctx, r_result, tirdoc)
end

---@param ctx Context
---@param is_write_pre boolean|nil
---@return string[]
function M.to_flat(ctx, is_write_pre)
    local r_result = reader.read(ctx, Range.WHOLE)
    local bufdoc = buflines_to_bufdoc_text_driven(ctx, r_result)
    local tirdoc = Document.from_bufdoc(bufdoc)
    tirdoc_to_flat(ctx, r_result, tirdoc, is_write_pre)
    return r_result.lines
end

---@param ctx Context
---@param width_op WidthOp
function M.cmd_width(ctx, width_op)
    change_width(ctx, width_op)
end

---@param ctx Context
---@param width_op WidthOp
function M.cmd_fit(ctx, width_op)
    --log.probe(width_op)
    --change_mode(ctx, width_op)
    --change_fit(ctx, width_op)
end

---@param ctx Context
---@param width_op WidthOp
function M.cmd_wrap(ctx, width_op)
    change_mode(ctx, width_op)
    M.cmd_repair(ctx)
end

---@param ctx Context
---@param no_undo boolean|nil
---@param no_normalize boolean|nil
function M.cmd_repair(ctx, no_undo, no_normalize)
    if not need_repair(ctx) then
        return
    end
    log.debug("===+=== START ===+=== %s[#%d] ===", "REPAIR", ctx.bufnr)
    local r_result = reader.read(ctx, Range.WHOLE)
    log.watch("ATTR", Attrs.debug_attrs(r_result.attrs, "[88]MODE:"))
    local bufdoc = buflines_to_bufdoc_attrs_driven(ctx, r_result)
    doc_to_buflines(ctx, r_result, bufdoc, no_undo, no_normalize)
end

---@param ctx Context
---@param range3 Range3
function M.on_lines(ctx, range3)
    local r_result = reader.read(ctx, Range3.get_new_range(range3))
    update_attrs(ctx, range3, r_result)
end

---@param ctx Context
---@param range3 Range3|nil
function M.check_and_repair(ctx, range3)
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

return M
