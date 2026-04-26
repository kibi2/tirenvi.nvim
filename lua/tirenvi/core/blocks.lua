--- Utilities for handling NDJSON records and converting them into
--- plain/grid block structures.
---
--- Design:
---   - Blocks are separated so that plain and grid records never mix.
---   - Column expansion is applied only to grid blocks.

local CONST = require("tirenvi.constants")
local Attr = require("tirenvi.core.attr")
local Block = require("tirenvi.core.block")
local Record = require("tirenvi.core.record")
local util = require("tirenvi.util.util")
local Range = require("tirenvi.util.range")
local errors = require("tirenvi.util.errors")
local notify = require("tirenvi.util.notify")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-----------------------------------------------------------------------
-- Utility
-----------------------------------------------------------------------

---@param self Blocks
---@param method string
---@param ... unknown
---@return boolean
local function apply(self, method, ...)
	local result = true
	for _, block in ipairs(self) do
		local common = Block[method]
		if common then
			result = common(block, ...) and result
		end

		local handler = Block[block.kind]
		local specific = handler[method]
		if specific then
			result = specific(block, ...) and result
		end
	end
	return result
end

-----------------------------------------------------------------------
-- Block construction
-----------------------------------------------------------------------

--- Split NDJSON records into plain/grid blocks.
---@param records Ndjson[]
---@return Blocks
local function build_blocks_from_records(records)
	local self = {}
	---@type Block
	local block = Block.new()
	local function flush_block()
		if #(block.records) ~= 0 then
			table.insert(self, block)
		end
		block = Block.new()
	end
	for _, record in ipairs(records) do
		local kind = record.kind
		if kind == CONST.KIND.ATTR_FILE then
			flush_block()
		elseif record.kind == "plain" or record.kind == "grid" then
			if block.kind ~= kind then
				flush_block()
			end
			Block.set_kind(block, record.kind)
			Block.add(block, record)
		else
			log.error(record)
		end
	end
	flush_block()
	return self
end

--- Split NDJSON records into plain/grid blocks.
---@param records Ndjson[]
---@param attrs Attr[]
---@return Blocks
local function build_blocks_from_attrs(records, attrs)
	local self = {}
	for iattr, attr in ipairs(attrs) do
		local block = Block.new()
		Block.set_kind(block, Attr.is_plain(attr) and CONST.KIND.PLAIN or CONST.KIND.GRID)
		local has_continuation = false
		for irow = attr.range.first, attr.range.last do
			local record = records[irow]
			if not record then
				log.error(string.format("Record not found for row %d", irow))
				break
			end
			if record.kind == CONST.KIND.ATTR_FILE then
			elseif record.kind == CONST.KIND.PLAIN or record.kind == CONST.KIND.GRID then
				record = Record[record.kind].change_kind(record, block.kind)
				if record.kind == "grid" then
					Record.apply_column_count(record, #attr.columns)
					if record._has_continuation == nil then
						record._has_continuation = has_continuation
					end
				end
				Block.add(block, record)
				has_continuation = record._has_continuation
			end
		end
		block.attr = vim.deepcopy(attr)
		self[iattr] = block
	end
	return self
end

--- Split NDJSON records into plain/grid blocks.
---@param records Ndjson[]
---@param attrs Attr[]|nil
---@return Blocks
local function build_blocks(records, attrs)
	if attrs then
		return build_blocks_from_attrs(records, attrs)
	else
		return build_blocks_from_records(records)
	end
end

-----------------------------------------------------------------------
-- Attribute handling
-----------------------------------------------------------------------

---@alias RefAttrError
---| "conflict"
---| "grid in plain"

---@param self Blocks
---@param first integer
local function rebuild_attr_range(self, first)
	for _, block in ipairs(self) do
		local attr = block.attr or Attr.new()
		block.attr = attr
		local last = first + #block.records - 1
		attr.range = Range.from_lua(first, last)
		first      = last + 1
	end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param self Blocks
function M.merge_blocks(self)
	if #self <= 1 then
		return
	end
	for index, block in ipairs(self) do
		local new_block = Block[block.kind].to_grid(block)
		self[index] = new_block
	end
	local first = self[1]
	local records = first.records
	for index = 2, #self do
		util.extend(records, self[index].records)
	end
	for i = #self, 2, -1 do
		self[i] = nil
	end
end

---@self Blocks
---@return Attr[]
function M:collect_attrs()
	local attrs = {}
	for _, block in ipairs(self) do
		assert(block.attr, "block.attr is nil")
		attrs[#attrs + 1] = block.attr
	end
	return attrs
end

---@self Blocks
---@param sel Range
---@param width_op WidthOp
function M:change_width(sel, width_op)
	apply(self, "change_width", sel, width_op)
end

--- Convert NDJSON records into normalized blocks.
---@param ndjsons Ndjson[]
---@param attrs Attr[]|nil
---@param allow_plain boolean
---@return Blocks
function M.new_from_records(ndjsons, allow_plain, attrs)
	local self = build_blocks(ndjsons, attrs)
	if not allow_plain and M.has_grid(self) then
		M.merge_blocks(self)
	end
	return self
end

--- Convert NDJSON records into normalized blocks.
---@param self Blocks
function M.from_flat(self)
	apply(self, "from_flat")
end

---@self Blocks
function M:to_flat()
	apply(self, "to_flat")
end

--- Convert NDJSON records into normalized blocks.
---@param self Blocks
---@param no_normalize boolean  -- If true, skip nomalizing.
-- Prevents line count changes that would break put(); used for repair.
function M.from_vim(self, no_normalize)
	apply(self, "from_vim", no_normalize)
end

---@self Blocks
function M:to_vim()
	apply(self, "to_vim")
end

---@self Blocks
function M:infer_consistent_attr()
	apply(self, "infer_consistent_attr")
end

---@self Blocks
function M:set_auto_attr()
	apply(self, "set_auto_attr")
end

---@self Blocks
---@param first integer
function M:set_attr_range(first)
	rebuild_attr_range(self, first)
end

---@param self Blocks
---@return Ndjson[]
function M.serialize(self)
	local ndjsons = {}
	for _, block in ipairs(self) do
		util.extend(ndjsons, Block[block.kind].serialize(block))
	end
	return ndjsons
end

---@self Blocks
---@param attrs Attr[]
function M:apply_cached_attr(attrs)
	apply(self, "apply_cached_attr", attrs)
end

---@param self Blocks
---@return boolean
function M.has_grid(self)
	for _, block in ipairs(self) do
		if block.kind == CONST.KIND.GRID then
			return true
		end
	end
	return false
end

---@param self Blocks
function M:insert_empty_lines()
	local prev_kind = self[#self].kind
	for iblock = #self - 1, 1, -1 do
		local block = self[iblock]
		if block.kind == CONST.KIND.GRID and block.kind == prev_kind then
			notify.warn(errors.table_merge_warning(block.attr.range.last))
			table.insert(self, iblock + 1, Block.plain.new())
		end
		prev_kind = block.kind
	end
end

---@param self Document
---@return boolean
function M:has_width()
	return apply(self, "has_width")
end

return M
