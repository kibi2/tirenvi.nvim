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

---@param req Request
---@param document Document
local function set_attrs(req, document)
    -- TODO: Document
    --Document.set_attrs(document.blocks, req.attrs)
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

---@param ctx Context
---@param no_undo boolean|nil
---@return nil
function M.from_flat(ctx, no_undo)
    local req = Request.from_range(Range.new(0, -1))
    local fl_lines = reader.read(ctx, req)
    local parser = ctx.parser
    util.assert_no_reserved_marks(fl_lines)
    local document = flat_parser.parse(fl_lines, parser)
    set_attrs(req, document)
    req.lines   = vim_parser.unparse(document)
    req.no_undo = no_undo
    req.attrs   = document.attr.attrs
    writer.write(ctx, req)
end

return M
