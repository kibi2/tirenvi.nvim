-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

----- dependencies
local config = require("tirenvi.config")
local CONST = require("tirenvi.constants")
local Document = require("tirenvi.core.document")
local Blocks = require("tirenvi.core.blocks")
local Record = require("tirenvi.core.record")
local Attr = require("tirenvi.core.attr")
local tir_vim = require("tirenvi.core.tir_vim")
local Context = require("tirenvi.app.context")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults
local pipec = config.marks.pipec
-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param req Request
---@param no_normalize boolean|nil  -- If true, skip nomalizing.
-- Prevents line count changes that would break put(); used for repair.
---@return Document
function M.parse(ctx, req, no_normalize)
	local records = Record.from_tir_vim(req.lines)
	log.probe(req.attrs)
	local vim_doc = Document.new_vim_doc(records, req.attrs, Context.is_allow_plain(ctx))
	log.watch("ATTR", "PARSE")
	Document.rebuild_attrs(vim_doc, req.range.first)
	Document.set_attrs_in(vim_doc, req.attrs)
	--Document.apply_attrs(vim_doc)
	return Document.from_vim_doc(vim_doc, no_normalize or false)
end

---@param req Request
---@param document Document
---@return string[]
function M.unparse(req, document)
	local vim_doc = Document.to_vim_doc(document)
	log.watch("ATTR", "UNPARSE")
	Document.rebuild_attrs(vim_doc, req.range.first)
	Document.set_attrs_in(vim_doc, req.attrs)
	--Document.apply_attrs(vim_doc)
	local ndjsons = Document.serialize(vim_doc)
	log.probe(Document.collect_attrs(document))
	return Record.to_tir_vim(ndjsons)
end

---@param vi_line string|nil
---@return Attr|nil
function M.parse_to_attr(vi_line)
	if not vi_line then
		return nil
	end
	local record = Record.from_vi_line(vi_line)
	return Attr[record.kind].new_from_record(record.row)
end

return M
