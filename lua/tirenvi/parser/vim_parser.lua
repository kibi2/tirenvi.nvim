-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

----- dependencies
local Document = require("tirenvi.core.document")
local Record = require("tirenvi.core.record")
local Attr = require("tirenvi.core.attr")
local Context = require("tirenvi.app.context")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param document Document
---@param req Request|nil
local function build_attr_pre(document, req)
	if req then
		Document.apply_attrs_in(document, req and req.attrs or nil)
	end
	Document.rebuild_attrs(document)
	Document.apply_attr(document)
	Document.debug_attr("UNPARSE", document)
end

---@param document Document
---@param req Request
local function build_attr_post(document, req)
	Document.set_attr_range(document, req.start0 + 1)
	Document.apply_attrs_in(document, req.attrs)
	Document.rebuild_attrs(document)
	Document.apply_attr(document)
	Document.debug_attr("PARSE", document)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param req Request
---@param no_normalize boolean|nil  -- If true, skip nomalizing.
-- Prevents line count changes that would break put(); used for repair.
---@return Document
function M.parse(ctx, req, no_normalize)
	local records = Record.from_tir_vim(req.lines)
	local vim_doc = Document.new_vim_doc(records, Context.is_allow_plain(ctx))
	build_attr_post(vim_doc, req)
	Document.from_vim_doc(vim_doc, no_normalize or false)
	return vim_doc
end

---@param document Document
---@param req Request
---@return string[]
function M.unparse(document, req)
	build_attr_pre(document, req)
	local vim_doc = Document.to_vim_doc(document)
	if req then
		Document.set_attr_range(vim_doc, req.start0 + 1)
	end
	local ndjsons = Document.serialize(vim_doc)
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
