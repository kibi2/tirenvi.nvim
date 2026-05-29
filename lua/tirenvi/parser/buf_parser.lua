-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

----- dependencies
local CONST = require("tirenvi.constants")
local Request = require("tirenvi.app.request")
local Document = require("tirenvi.core.document")
local Record = require("tirenvi.core.record")
local Attr = require("tirenvi.core.attr")
local Attrs = require("tirenvi.core.attrs")
local Context = require("tirenvi.app.context")
local Range = require("tirenvi.util.range")
local Range3 = require("tirenvi.util.range3")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param records Record[]
---@param req ReadResult
---@param range3 Range3
local function promote_empty_lines_gfm(records, req, range3)
	if not Range3.is_insert(range3) then
		return records
	end
	local first = Range.to_lua(req.range)
	local prev_attr = Attrs.get(req.attrs, first - 1)
	if not Attr.is_grid(prev_attr) then
		return records
	end
	for _, record in ipairs(records) do
		if record.kind ~= CONST.KIND.PLAIN or record.line ~= "" then
			return records
		end
	end
	for irec, record in ipairs(records) do
		records[irec] = Record[record.kind].to_grid(record)
	end
end

---@param records Record[]
---@param req ReadResult
local function promote_empty_lines_csv(records, req)
	local first, last = Range.to_lua(req.range)
	local prev_attr = Attrs.get(req.attrs, first - 1)
	local next_attr = Attrs.get(req.attrs, last + 1)
	if not Attr.is_grid(prev_attr) and not Attr.is_grid(next_attr) then
		return records
	end
	for irec, record in ipairs(records) do
		records[irec] = Record[record.kind].to_grid(record)
	end
end

---@param records Record[]
---@param req ReadResult
---@param range3 Range3|nil
---@param allow_plain boolean
local function promote_empty_lines(records, req, allow_plain, range3)
	if not range3 then
		return records
	end
	if allow_plain then
		return promote_empty_lines_gfm(records, req, range3)
	else
		return promote_empty_lines_csv(records, req)
	end
end

---@param ctx Context
---@param req ReadResult
---@param range3 Range3|nil
---@return Document
function M.parse_text_driven(ctx, req, range3)
	local records = Record.from_tir_buf(req.lines)
	local allow_plain = Context.is_allow_plain(ctx)
	promote_empty_lines(records, req, allow_plain, range3)
	local buf_doc = Document.new_buf_doc(records, allow_plain)
	return buf_doc
end

---@param ctx Context
---@param req ReadResult
---@return Document
function M.parse_attr_driven(ctx, req)
	local records = Record.from_tir_buf(req.lines)
	--local attr = Attrs.slice(req.attrs, req.range) TODO
	local buf_doc = Document.new_buf_doc(records, Context.is_allow_plain(ctx), req.attrs)
	return buf_doc
end

---@param buf_doc Document
---@return string[]
function M.unparse(buf_doc)
	local ndjsons = Document.serialize(buf_doc)
	return Record.to_tir_buf(ndjsons)
end

---@param lines string[]
---@return boolean
function M.table_is_aligned(lines)
	local records = Record.from_tir_buf(lines)
	local buf_doc = Document.new_buf_doc(records, false)
	Document.infer_consistent_attr(buf_doc)
	return Document.has_width(buf_doc)
end

return M
