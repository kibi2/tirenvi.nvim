local Request = require("tirenvi.app.request")            -- App

local width_layout = require("tirenvi.width.layout")      -- Width

local flat_parser = require("tirenvi.parser.flat_parser") -- Parser
local buf_parser = require("tirenvi.parser.buf_parser")

local buf_state = require("tirenvi.io.buf_state") -- IO
local writer = require("tirenvi.io.writer")
local attr_store = require("tirenvi.io.attr_store")
local reader = require("tirenvi.io.reader")

local Document = require("tirenvi.core.document") -- Core
local Attrs = require("tirenvi.core.attrs")

local util = require("tirenvi.util.util") -- Util
local Range = require("tirenvi.util.range")
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@param ctx Context
---@param tirdoc Document
local function apply_wrap_mode(ctx, tirdoc)
    width_layout.compute(ctx.winid, tirdoc)
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
        buf_state.set_buffer_tirbuf(ctx.bufnr, false)
        attr_store.write(ctx, attrs)
    end
    writer.write(ctx, req_w)
end

--#endregion
-- =============================================================================
-- Public API

---@param ctx Context
---@param r_result ReadResult
---@return Document
function M.buflines_to_bufdoc_text_driven(ctx, r_result)
    local opts = { first = r_result.range.first }
    local bufdoc = buf_parser.parse(ctx, r_result, opts)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[1]DOC ATTR:"))
    Document.apply_attrs(bufdoc, r_result.attrs)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[4]CACHED:"))
    return bufdoc
end

---@param ctx Context
---@param r_result ReadResult
---@param doc Document
---@param opts DocToBufLinesOpts|nil
function M.doc_to_buflines(ctx, r_result, doc, opts)
    local no_undo = opts and opts.no_undo or false
    local no_normalize = opts and opts.no_normalize or false
    local tirdoc = doc
    if not doc._tir then
        tirdoc = Document.from_bufdoc(doc, no_normalize)
    end
    apply_wrap_mode(ctx, tirdoc)
    local bufdoc = Document.to_bufdoc(tirdoc)
    log.watch("ATTR", Document.debug_attrs(bufdoc, "[9]DOC ATTR:"))
    local attrs = Document.replace_attrs(bufdoc, r_result.range, r_result.attrs)
    log.watch("ATTR", Attrs.debug_attrs(attrs, "[9]CHACHED:"))
    buf_state.set_buffer_tirbuf(ctx.bufnr, Attrs.has_grid(attrs))
    attr_store.write(ctx, attrs)
    local buf_lines = buf_parser.unparse(bufdoc)
    if not util.same_str_array(buf_lines, r_result.lines or "") then
        local req_w = Request.new_writer(r_result, buf_lines, no_undo)
        writer.write(ctx, req_w)
    end
end

---@param ctx Context
---@param is_write_pre boolean|nil
---@return ReadResult
function M.to_flat(ctx, is_write_pre)
    local r_result = reader.read(ctx, Range.WHOLE)
    local bufdoc = M.buflines_to_bufdoc_text_driven(ctx, r_result)
    local tirdoc = Document.from_bufdoc(bufdoc)
    tirdoc_to_flat(ctx, r_result, tirdoc, is_write_pre)
    return r_result
end

return M
