--- Utilities for handling NDJSON records and converting them into
--- plain/grid block structures.
---
--- Design:
---   - Blocks are separated so that plain and grid records never mix.
---   - Column expansion is applied only to grid blocks.

local CONST = require("tirenvi.constants")
local Record = require("tirenvi.core.record")
local Attr = require("tirenvi.core.attr")
local util = require("tirenvi.util.util")
local config = require("tirenvi.config")
local Block = require("tirenvi.core.block")
local log = require("tirenvi.util.log")

local M = {}
M.VERSION = "tir/0.1"

-- constants / defaults

-----------------------------------------------------------------------
-- Utility
-----------------------------------------------------------------------

---@return Ndjson
local function new_attr_file()
	return { kind = CONST.KIND.ATTR_FILE, version = M.VERSION }
end

-----------------------------------------------------------------------
-- Block construction
-----------------------------------------------------------------------

--- Split NDJSON records into plain/grid blocks.
---@param records Ndjson[]
---@return Blocks
local function build_blocks(records)
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

-----------------------------------------------------------------------
-- Attribute handling
-----------------------------------------------------------------------

---@alias RefAttrError
---| "conflict"
---| "grid in plain"

---@param blocks Blocks
---@param attr_prev Attr|nil
---@param attr_next Attr|nil
---@return boolean
---@return RefAttrError|nil
local function apply_reference_attr_single(blocks, attr_prev, attr_next)
	M.merge_blocks(blocks)
	if Attr.is_conflict(attr_prev, attr_next, false) then
		log.debug("===-===-===-=== conflict")
		log.debug(blocks[1].records[1])
		return false, "conflict"
	end
	if #blocks == 0 then
		return true
	end
	local attr = not attr_prev and attr_next or attr_prev
	local block = blocks[1]
	if not attr then
		return true
	elseif not Attr.is_plain(attr) then
		if block.kind == CONST.KIND.PLAIN then
			block = Block.plain.to_grid(block)
			blocks[1] = block
		end
	elseif Attr.is_plain(attr) then
		if block.kind == CONST.KIND.GRID then
			log.debug("===-===-===-=== grid in plain")
			log.debug(attr_prev)
			log.debug(attr_next)
			return false, "grid in plain"
		end
	end
	Block[block.kind].set_attr(block, attr)
	return true
end

---@param self Blocks
---@param attr_prev Attr|nil
---@param attr_next Attr|nil
local function insert_plain_block(self, attr_prev, attr_next)
	if #self > 1 then
		return
	end
	if #self == 1 and self[1].kind == CONST.KIND.PLAIN then
		return
	end
	if not Attr.is_conflict(attr_prev, attr_next, true) then
		return
	end
	self[#self + 1] = Block.plain.new()
end

---@param self Blocks
---@param attr_prev Attr|nil
---@param attr_next Attr|nil
local function attach_attr(self, attr_prev, attr_next)
	if #self == 0 then
		return
	end
	Block[self[1].kind].set_attr(self[1], attr_prev)
	Block[self[#self].kind].set_attr(self[#self], attr_next)
end

---@param blocks Blocks
---@param attr_prev Attr|nil
---@param attr_next Attr|nil
---@return boolean
local function apply_reference_attr_multi(blocks, attr_prev, attr_next)
	insert_plain_block(blocks, attr_prev, attr_next)
	attach_attr(blocks, attr_prev, attr_next)
	return true
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
function M:reset_attr()
	for _, block in ipairs(self) do
		Block.reset_attr(block)
	end
end

---@self Blocks
---@return integer[][]
function M:get_widths()
	local widths = {}
	for _, block in ipairs(self) do
		widths[#widths + 1] = Block[block.kind].get_widths(block)
	end
	return widths
end

---@self Blocks
---@param widths integer[][]
function M:set_widths(widths)
	if not widths then
		return
	end
	for iblock, block in ipairs(self) do
		Block[block.kind].set_widths(block, widths[iblock])
	end
end

---@self Blocks
---@param operator string
---@param count integer
---@param col Range
function M:change_width(operator, count, col)
	for _, block in ipairs(self) do
		Block[block.kind].change_width(block, operator, count, col)
	end
end

--- Convert NDJSON records into normalized blocks.
---@param ndjsons Ndjson[]
---@return Blocks
function M.new_from_flat(ndjsons, allow_plain)
	local self = build_blocks(ndjsons)
	if not allow_plain then
		M.merge_blocks(self)
	end
	for _, block in ipairs(self) do
		Block[block.kind].from_flat(block)
	end
	return self
end

---@self Blocks
---@return Ndjson[]
function M:serialize_to_flat()
	local ndjsons = { new_attr_file() }
	for _, block in ipairs(self) do
		local impl = Block[block.kind]
		impl.to_flat(block)
		util.extend(ndjsons, impl.serialize(block))
	end
	return ndjsons
end

--- Convert NDJSON records into normalized blocks.
---@param records Record[]
---@param no_unwrap boolean  -- If true, skip unwrapping.
-- Prevents line count changes that would break put(); used for repair.
---@return Blocks
function M.new_from_vim(records, no_unwrap)
	local self = build_blocks(records)
	for _, block in ipairs(self) do
		Block[block.kind].from_vim(block, no_unwrap)
	end

	return self
end

---@self Blocks
---@return Ndjson[]
function M:serialize_to_vim()
	local ndjsons = {}
	for _, block in ipairs(self) do
		local impl = Block[block.kind]
		impl.to_vim(block)
		util.extend(ndjsons, impl.serialize(block))
	end
	return ndjsons
end

---@self Blocks
---@param attr_prev Attr|nil
---@param attr_next Attr|nil
---@param allow_plain boolean|nil
---@return boolean
---@return RefAttrError|nil
function M:repair(attr_prev, attr_next, allow_plain)
	if allow_plain then
		return apply_reference_attr_multi(self, attr_prev, attr_next)
	else
		return apply_reference_attr_single(self, attr_prev, attr_next)
	end
end

return M
