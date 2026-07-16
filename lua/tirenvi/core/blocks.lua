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
---@param ndjsons Ndjson[]
---@return Blocks
local function build_blocks_text_driven(ndjsons)
	local self = {}
	---@type Block
	local block = Block.new()
	local function flush_block()
		if #(block.records) ~= 0 then
			table.insert(self, block)
		end
		block = Block.new()
	end
	for _, ndjson in ipairs(ndjsons) do
		local kind = ndjson.kind
		if kind == CONST.KIND.ATTR_FILE then
			flush_block()
		elseif ndjson.kind == "plain" or ndjson.kind == "grid" then
			if block.kind ~= kind then
				flush_block()
			end
			Block.set_kind(block, ndjson.kind)
			Block.add(block, ndjson)
		else
			log.error(ndjson)
		end
	end
	flush_block()
	return self
end

--- Split NDJSON records into plain/grid blocks.
---@param ndjsons Ndjson[]
---@param attrs Attr[]
---@return Blocks
local function build_blocks_attr_driven(ndjsons, attrs)
	local self = {}
	for iattr, attr in ipairs(attrs) do
		local block = Block.new()
		Block.set_kind(block, Attr.is_plain(attr) and CONST.KIND.PLAIN or CONST.KIND.GRID)
		local has_continuation = false
		for irow = attr.range.first, attr.range.last do
			local record = ndjsons[irow]
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

-----------------------------------------------------------------------
-- Attribute handling
-----------------------------------------------------------------------

---@alias RefAttrError
---| "conflict"
---| "grid in plain"

---@param bufblocks Blocks
---@param first integer
local function rebuild_attr_range(bufblocks, first)
	for _, block in ipairs(bufblocks) do
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

---@self Blocks
---@return Attr[]
function M:collect_attrs()
	local attrs = {}
	for _, block in ipairs(self) do
		log.assert(block.attr, "block.attr is nil")
		attrs[#attrs + 1] = block.attr
	end
	return attrs
end

--- Convert NDJSON records into normalized blocks.
---@param ndjsons Ndjson[]
---@param attrs Attr[]|nil
---@return Blocks
function M.new_from_records(ndjsons, attrs)
	if attrs then
		return build_blocks_attr_driven(ndjsons, attrs)
	else
		return build_blocks_text_driven(ndjsons)
	end
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
function M.from_buf(self, no_normalize)
	apply(self, "from_buf", no_normalize)
end

---@self Blocks
function M:to_bufdoc()
	apply(self, "to_bufdoc")
end

---@self Blocks
function M:infer_consistent_attr()
	apply(self, "infer_consistent_attr")
end

---@self Blocks
function M:set_max_attr()
	apply(self, "set_max_attr")
end

---@parama bufblocks Blocks
---@param first integer|nil
function M.set_attr_range(bufblocks, first)
	if not first then
		return
	end
	rebuild_attr_range(bufblocks, first)
end

---@param self Blocks
function M.prefix_to_records(self)
	apply(self, "prefix_to_records")
end

---@param self Blocks
function M.prefix_to_attrs(self)
	apply(self, "prefix_to_attrs")
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
function M:apply_attrs_by_range(attrs)
	apply(self, "apply_attrs_by_range", attrs)
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
