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

---@param request Request
---@param document Document
local function set_attrs(request, document)
    -- TODO: Document
    --Document.set_attrs(document.blocks, request.attrs)
end

function M.document_to_vim(ctx, req, document)
    local vi_lines = vim_parser.unparse(document)
    Document.set_attr_range(req.range.first, document)
    req.lines = vi_lines
    req.attrs = document.attr.block_attrs
    --writer.write(ctx, req)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param context Context
---@param no_undo boolean|nil
---@return nil
function M.from_flat(context, no_undo)
    local request = Request.from_range(context, Range.new(0, -1))
    local fl_lines = reader.read(request)
    local parser = context.parser
    util.assert_no_reserved_marks(fl_lines)
    local document = flat_parser.parse(fl_lines, parser)
    set_attrs(request, document)
    request.lines   = vim_parser.unparse(document)
    request.no_undo = no_undo
    request.attrs   = document.attr.attrs
    writer.write(request)
end

return M
