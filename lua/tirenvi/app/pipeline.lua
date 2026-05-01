-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------
local Document = require("tirenvi.core.document")
local Request = require("tirenvi.app.request")
local flat_parser = require("tirenvi.parser.flat_parser")
local vim_parser = require("tirenvi.parser.vim_parser")
local writer = require("tirenvi.io.writer")
local reader = require("tirenvi.io.reader")
local Range = require("tirenvi.util.range")
local util = require("tirenvi.util.util")

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

return M
