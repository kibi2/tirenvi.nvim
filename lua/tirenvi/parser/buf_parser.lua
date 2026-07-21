local CONST = require("tirenvi.constants") -- Root
local config = require("tirenvi.config")

local Bufline = require("tirenvi.parser.bufline") -- Parser

local buf_state = require("tirenvi.io.buf_state") -- IO

local Document = require("tirenvi.core.document") -- Core
local Record = require("tirenvi.core.record")
local Attr = require("tirenvi.core.attr")
local Attrs = require("tirenvi.core.attrs")

local Range = require("tirenvi.util.range") -- Util
local Range3 = require("tirenvi.util.range3")
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@param bufline string
---@param pipe string
---@param embedded_key string|nil
---@return Record_grid
local function new_from_bufline(bufline, pipe, embedded_key)
	local pos = string.find(bufline, pipe, 1, true) or 1
	local prefix = string.sub(bufline, 1, pos - 1)
	if vim.trim(prefix) == embedded_key then
		bufline = string.sub(bufline, pos)
	end
	local cells = Bufline.get_cells(bufline)
	local record = Record.grid.new(cells)
	if vim.trim(prefix) == embedded_key then
		record.prefix = prefix
	end
	record._has_continuation = pipe == config.marks.pipec
	return record
end

---@param bufline string
---@param embedded_key string|nil
---@return Record
local function bufline_to_records(bufline, embedded_key)
	local pipe = Bufline.get_pipe_char(bufline)
	if pipe then
		return new_from_bufline(bufline, pipe, embedded_key)
	else
		return Record.plain.new(bufline)
	end
end

---@param buflines string[]
---@param embedded_key string|nil
---@return Record[]
local function buflines_to_records(buflines, embedded_key)
	local records = {}
	for index = 1, #buflines do
		records[index] = bufline_to_records(buflines[index], embedded_key)
	end
	return records
end

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

---@param records Record[]
---@return string[]
local function to_buflines(records)
	local pipec = config.marks.pipec
	local pipen = config.marks.pipe
	local buflines = {}
	for _, record in ipairs(records) do
		local kind = record.kind
		if kind == CONST.KIND.PLAIN then
			buflines[#buflines + 1] = record.line or ""
		elseif kind == CONST.KIND.GRID then
			local pipe = record._has_continuation and pipec or pipen
			local row_items = record.row
			local row = table.concat(row_items, pipe)
			row = pipe .. row .. pipe
			local line = (record.prefix or "") .. row
			buflines[#buflines + 1] = line
		end
	end
	return buflines
end

--#endregion
-- =============================================================================
-- Public API

---@param ctx Context
---@param r_result ReadResult
---@param opts any
---@return Document
function M.parse(ctx, r_result, opts)
	local embedded_key = Attrs.get_embedded_key(r_result.attrs)
	local records = buflines_to_records(r_result.lines, embedded_key)
	local allow_plain = buf_state.is_allow_plain(ctx.bufnr)
	promote_empty_lines(records, r_result, allow_plain, opts.range3)
	local bufdoc = Document.new_bufdoc(records, allow_plain, opts.attrs, opts.first)
	return bufdoc
end

---@param bufdoc Document
---@return string[]
function M.unparse(bufdoc)
	local records = Document.serialize_to_buf(bufdoc)
	return to_buflines(records)
end

---@param lines string[]
---@return boolean
function M.table_is_aligned(lines)
	local records = buflines_to_records(lines)
	local bufdoc = Document.new_bufdoc(records, false)
	Document.infer_consistent_attr(bufdoc)
	return Document.has_width(bufdoc)
end

return M
