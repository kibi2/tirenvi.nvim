-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------
local Document = require("tirenvi.core.document")
local Attrs = require("tirenvi.core.attrs")
local Bufline = require("tirenvi.core.bufline")
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
---@param r_result ReadResult
---@return Document
local function fllines_to_tirdoc(ctx, r_result)
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

---@param ctx Context
---@param r_result ReadResult
---@param doc Document
---@param no_undo boolean|nil
---@param no_normalize boolean|nil
local function doc_to_buflines(ctx, r_result, doc, no_undo, no_normalize)
    local tirdoc = doc
    if not doc._tir then
        tirdoc = Document.from_bufdoc(doc, no_normalize or false)
    end
    Document.set_auto_attr(tirdoc)
    local bufdoc = Document.to_bufdoc(tirdoc)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[9]DOC ATTR:"))
    local attrs = Document.replace_attrs(bufdoc, r_result.range, r_result.attrs)
    log.watch("ATTR", Attrs.debug_attrs(attrs, "[9]CHACHED:"))
    attr_store.write(ctx.bufnr, attrs, "formatted")
    local buf_lines = buf_parser.unparse(bufdoc)
    if not util.same_str_array(buf_lines, r_result.lines) then
        local req_w = Request.new_writer(r_result.range, buf_lines, no_undo or false)
        writer.write(ctx, req_w)
    end
end

---@param ctx Context
---@param tirdoc Document
---@param no_undo boolean|nil
local function tirdoc_to_flat(ctx, r_result, tirdoc, no_undo)
    local fllines = flat_parser.unparse(ctx, tirdoc)
    local req_w = Request.new_writer(r_result.range, fllines, no_undo or false)
    local attrs = vim.deepcopy(r_result.attrs)
    Attrs.remove_range(attrs)
    log.watch("ATTR", Attrs.debug_attrs(attrs, "[9]CHACHED:"))
    attr_store.write(ctx.bufnr, attrs, "flat")
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
---@param bufdoc  Document
---@param range3 Range3
---@return Attr[]
local function reconcile_attrs(ctx, r_result, bufdoc, range3)
    Document.inherit_neighbor_attr(bufdoc, r_result.attrs, range3)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[2]NEIGHBOR:"))
    Document.infer_consistent_attr(bufdoc)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[3]CONSISTENT:"))
    Document.apply_attrs(bufdoc, r_result.attrs)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[4]CACHED:"))
    Document.set_auto_attr(bufdoc)
    local attrs = Document.replace_attrs(bufdoc, r_result.range, r_result.attrs)
    log.watch("ATTR", Attrs.debug_attrs(attrs, "[6]RESULT:"))
    attr_store.write(ctx.bufnr, attrs, "formatted")
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
local function schedule_repair(ctx)
    if not schedule_repair_flag then
        vim.schedule(function()
            schedule_repair_flag = false
            M.cmd_repair(ctx, true, true)
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
    if not buf_state.is_repair(ctx, range3) then
        return
    end
    schedule_repair(ctx)
end

---@param bufnr number
---@param range Range|nil
---@return boolean
local function has_dirty(bufnr, range)
    local dirty_ranges = dirty.get_ranges(bufnr)
    if range then
        dirty_ranges = Range.slice(dirty_ranges, range)
    end
    return #dirty_ranges > 0
end

---@param bufnr number
---@return boolean
local function need_repair(bufnr)
    if has_dirty(bufnr) then
        return true
    end
    local attrs = dirty.get_invalid_attrs(bufnr)
    return #attrs > 0
end

---@param ctx Context
---@param range3 Range3|nil
local function check_and_repair(ctx, range3)
    local bufnr = ctx.bufnr
    if not need_repair(bufnr) then
        return
    end
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

---@param bufnr number
---@param lines string[]
---@return boolean
local function is_flat(bufnr, lines)
    local format = buf_state.get_buffer_format(bufnr)
    if not format then
        return not Bufline.has_pipe(lines)
    end
    return not buf_state.is_formatted(bufnr) -- flat or plain
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param ctx Context
---@param no_undo boolean|nil
---@return nil
function M.from_flat(ctx, no_undo)
    local r_result = reader.read(ctx, Range.WHOLE)
    if is_flat(ctx.bufnr, r_result.lines) then
        util.ensure_no_reserved_marks(r_result.lines)
        local tirdoc = fllines_to_tirdoc(ctx, r_result)
        doc_to_buflines(ctx, r_result, tirdoc, no_undo)
    else
        local bufdoc = buflines_to_bufdoc_text_driven(ctx, r_result)
        doc_to_buflines(ctx, r_result, bufdoc, no_undo)
    end
end

---@param ctx Context
---@param no_undo boolean|nil
---@return string[]
function M.to_flat(ctx, no_undo)
    local r_result = reader.read(ctx, Range.WHOLE)
    local bufdoc = buflines_to_bufdoc_text_driven(ctx, r_result)
    local tirdoc = Document.from_bufdoc(bufdoc)
    tirdoc_to_flat(ctx, r_result, tirdoc, no_undo)
    return r_result.lines
end

---@param ctx Context
---@param sel Rect
---@param width_op WidthOp
function M.cmd_width(ctx, sel, width_op)
    if has_dirty(ctx.bufnr, sel.row) then
        error(errors.new_domain_error(errors.ERR.TABLE_IS_NOT_ALIGNED))
    end
    expand_rect(ctx, sel.row)
    log.debug("row%s, col%s", Range.short(sel.row), Range.short(sel.col))
    local r_result = reader.read(ctx, sel.row)
    Attrs.change_width(r_result.attrs, sel, width_op)
    local bufdoc = buflines_to_bufdoc_text_driven(ctx, r_result)
    doc_to_buflines(ctx, r_result, bufdoc)
end

---@param ctx Context
---@param no_undo boolean|nil
---@param no_normalize boolean|nil
function M.cmd_repair(ctx, no_undo, no_normalize)
    local r_result = reader.read(ctx, Range.WHOLE)
    local bufdoc = buflines_to_bufdoc_attrs_driven(ctx, r_result)
    doc_to_buflines(ctx, r_result, bufdoc, no_undo, no_normalize)
end

---@param ctx Context
---@param range3 Range3
function M.on_lines(ctx, range3)
    local r_result = reader.read(ctx, Range3.get_new_range(range3))
    r_result.attrs = Attrs.adjust(r_result.attrs, range3)
    log.watch("ATTR", Attrs.debug_attrs(r_result.attrs, "[0]UPDATE CHACHED:"))
    local opts = { range3 = range3, first = r_result.range.first }
    local bufdoc = buf_parser.parse(ctx, r_result, opts)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[1]DOC ATTR:"))
    local attrs = reconcile_attrs(ctx, r_result, bufdoc, range3)
    reconcile_dirty_ranges(ctx.bufnr, attrs, range3)
    check_and_repair(ctx, range3)
end

---@param ctx Context
function M.insert_leave(ctx)
    check_and_repair(ctx)
end

local buffer_backup

---@param ctx Context
function M.write_pre(ctx)
    buffer_backup = M.to_flat(ctx, true)
end

---@param ctx Context
function M.write_post(ctx)
    if not buffer_backup then
        return
    end
    local req = Request.new_writer(Range.WHOLE, buffer_backup, true)
    writer.write(ctx, req)
    buffer_backup = nil
end

return M
