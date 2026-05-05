-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------
local Document = require("tirenvi.core.document")
local Blocks = require("tirenvi.core.blocks")
local tir_vim = require("tirenvi.core.tir_vim")
local Request = require("tirenvi.app.request")
local flat_parser = require("tirenvi.parser.flat_parser")
local vim_parser = require("tirenvi.parser.vim_parser")
local writer = require("tirenvi.io.writer")
local reader = require("tirenvi.io.reader")
local Range = require("tirenvi.util.range")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

-- private helpers

---@param ctx Context
---@param req Request
---@return Document
local function flat_to_doc(ctx, req)
    reader.read(ctx, req)
    util.ensure_no_reserved_marks(req.lines)
    return flat_parser.parse(ctx, req)
end

---@param ctx Context
---@param document Document
local function doc_to_flat(ctx, document)
    local fl_lines = flat_parser.unparse(ctx, document)
    local req = Request.from_lines(Range.WHOLE, fl_lines, document)
    writer.write(ctx, req)
end

---@param ctx Context
---@param req Request
---@return Document|nil
local function vim_to_doc(ctx, req)
    local lines = reader.read(ctx, req)
    if not tir_vim.has_pipe(lines) then
        return nil
    end
    return vim_parser.parse(ctx, req)
end

---@param ctx Context
---@param req Request
---@param document Document
---@param no_undo boolean|nil
local function doc_to_vim(ctx, req, document, no_undo)
    local vi_lines = vim_parser.unparse(document, req)
    if util.same_str_array(vi_lines, req.lines) then
        return
    end
    req = Request.from_lines(req.range, vi_lines, document, no_undo or false)
    writer.write(ctx, req)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param ctx Context
---@param no_undo boolean|nil
---@return nil
function M.from_flat(ctx, no_undo)
    local req = Request.from_range(Range.WHOLE)
    local document = flat_to_doc(ctx, req)
    doc_to_vim(ctx, req, document, no_undo)
end

---@param ctx Context
---@param is_toggle boolean|nil
function M.to_flat(ctx, is_toggle)
    is_toggle = is_toggle or false
    local req = Request.from_range(Range.WHOLE)
    local document = vim_to_doc(ctx, req)
    if document then
        log.debug(document.blocks[1].records)
        doc_to_flat(ctx, document)
    end
end

---@param ctx Context
---@param sel Rect
---@param width_op WidthOp
function M.cmd_width(ctx, sel, width_op)
    log.debug("row%s, col%s", sel.row:short(), sel.col:short())
    local req = Request.from_range(Range.from_lua(sel.row.first, sel.row.last))
    local document = vim_to_doc(ctx, req)
    if document then
        Blocks.change_width(document.blocks, sel.col, width_op)
        doc_to_vim(ctx, req, document)
    end
end

---@param ctx Context
function M.cmd_reconcile(ctx)
    local req = Request.from_range(Range.WHOLE)
    local document = vim_to_doc(ctx, req)
    if document then
        doc_to_vim(ctx, req, document)
    end
end

return M
