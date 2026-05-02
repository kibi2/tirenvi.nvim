-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------
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
---@param document Document
---@param no_undo boolean|nil
local function document_to_vim(ctx, req, document, no_undo)
    local vi_lines = vim_parser.unparse(req, document)
    local req = Request.from_lines(req.range, vi_lines, document.attr.attrs_out, no_undo or false)
    writer.write(ctx, req)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param ctx Context
---@param no_undo boolean|nil
---@return nil
function M.from_flat(ctx, no_undo)
    local req = Request.from_range(Range.new(0, -1))
    reader.read(ctx, req)
    util.ensure_no_reserved_marks(req.lines)
    local document = flat_parser.parse(ctx, req)
    document_to_vim(ctx, req, document, no_undo)
end

---@param ctx Context
---@param is_toggle boolean|nil
---@return nil
function M.to_flat(ctx, is_toggle)
    is_toggle = is_toggle or false
    local req = Request.from_range(Range.new(0, -1))
    local vi_lines = reader.read(ctx, req)
    if not tir_vim.has_pipe(vi_lines) then
        return
    end
    local document = vim_parser.parse(ctx, req)
    log.debug(document.blocks[1].records)
    local fl_lines = flat_parser.unparse(ctx, document)
    local req = Request.from_lines(Range.new(0, -1), fl_lines, document.attr.attrs_out)
    writer.write(ctx, req)
end

return M
