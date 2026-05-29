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
---@param r_result ReadResult
---@param range3 Range3
local function promote_empty_lines_gfm(records, r_result, range3)
	if not Range3.is_insert(range3) then
		return records
	end
	local first = Range.to_lua(r_result.range)
	local prev_attr = Attrs.get(r_result.attrs, first - 1)
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
---@param r_result ReadResult
local function promote_empty_lines_csv(records, r_result)
	local first, last = Range.to_lua(r_result.range)
	local prev_attr = Attrs.get(r_result.attrs, first - 1)
	local next_attr = Attrs.get(r_result.attrs, last + 1)
	if not Attr.is_grid(prev_attr) and not Attr.is_grid(next_attr) then
		return records
	end
	for irec, record in ipairs(records) do
		records[irec] = Record[record.kind].to_grid(record)
	end
end

---@param records Record[]
---@param r_result ReadResult
---@param range3 Range3|nil
---@param allow_plain boolean
local function promote_empty_lines(records, r_result, allow_plain, range3)
	if not range3 then
		return records
	end
	if allow_plain then
		return promote_empty_lines_gfm(records, r_result, range3)
	else
		return promote_empty_lines_csv(records, r_result)
	end
end

---@param ctx Context
---@param r_result ReadResult
---@param range3 Range3|nil
---@return Document
function M.parse_text_driven(ctx, r_result, range3)
	local records = Record.from_buflines(r_result.lines)
	local allow_plain = Context.is_allow_plain(ctx)
	promote_empty_lines(records, r_result, allow_plain, range3)
	local bufdoc = Document.new_bufdoc(records, allow_plain)
	return bufdoc
end

---@param ctx Context
---@param r_result ReadResult
---@return Document
function M.parse_attr_driven(ctx, r_result)
	local records = Record.from_buflines(r_result.lines)
	--local attr = Attrs.slice(r_result.attrs, r_result.range) TODO
	local bufdoc = Document.new_bufdoc(records, Context.is_allow_plain(ctx), r_result.attrs)
	return bufdoc
end

---@param bufdoc Document
---@return string[]
function M.unparse(bufdoc)
	local ndjsons = Document.serialize(bufdoc)
	return Record.to_buflines(ndjsons)
end

---@param lines string[]
---@return boolean
function M.table_is_aligned(lines)
	local records = Record.from_buflines(lines)
	local bufdoc = Document.new_bufdoc(records, false)
	Document.infer_consistent_attr(bufdoc)
	return Document.has_width(bufdoc)
end

return M
