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
		return
	end
	if allow_plain then
		promote_empty_lines_gfm(records, r_result, range3)
	else
		promote_empty_lines_csv(records, r_result)
	end
end

---@param ctx Context
---@param r_result ReadResult
---@param opts any
---@return Document
function M.parse(ctx, r_result, opts)
	local records = Record.from_buflines(r_result.lines)
	local allow_plain = Context.is_allow_plain(ctx)
	promote_empty_lines(records, r_result, allow_plain, opts.range3)
	local bufdoc = Document.new_bufdoc(records, allow_plain, opts.attrs, opts.first)
	return bufdoc
end

---@param bufdoc Document
---@return string[]
function M.unparse(bufdoc)
	Document.prefix_to_records(bufdoc)
	local records = Document.serialize_to_buf(bufdoc)
	return Record.to_buflines(records)
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
