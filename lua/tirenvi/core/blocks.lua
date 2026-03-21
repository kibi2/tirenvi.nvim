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

local ESCAPE_MAP = {
	["\n"] = config.marks.lf,
	["\t"] = config.marks.tab,
}

local UNESCAPE_MAP = {
	[config.marks.lf] = "\n",
	[config.marks.tab] = "\t",
}

-----------------------------------------------------------------------
-- Utility
-----------------------------------------------------------------------

---@return Ndjson
local function new_attr_file()
	return { kind = CONST.KIND.ATTR_FILE, version = M.VERSION }
end

---@self Blocks
---@param replace {[string]: string}
local function apply_replacements(self, replace)
	for _, block in ipairs(self) do
		Block[block.kind].apply_replacements(block, replace)
	end
end

---@self Blocks
local function remove_padding(self)
	for _, block in ipairs(self) do
		Block[block.kind].remove_padding(block)
	end
end

-----------------------------------------------------------------------
-- Block construction
-----------------------------------------------------------------------

--- Split NDJSON records into plain/grid blocks.
---@param records Ndjson[]
---@return Blocks
local function build_blocks(records)
	local blocks = {}
	---@type Block
	local block = Block.new()
	local function flush_block()
		if #(block.records) ~= 0 then
			table.insert(blocks, block)
		end
		block = Block.new()
	end
	for _, record in ipairs(records) do
		local kind = record.kind
		if kind == CONST.KIND.ATTR_FILE then
			flush_block()
		elseif kind == CONST.KIND.ATTR_PLAIN then
		elseif kind == CONST.KIND.ATTR_GRID then
			flush_block()
			---@cast record Attr_grid
			Block.set_kind(block, CONST.KIND.GRID)
			Block.grid.set_attr_if_empty(block, record)
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
	return blocks
end

---@param self Blocks
local function merge_blocks(self)
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

-----------------------------------------------------------------------
-- Attribute handling
-----------------------------------------------------------------------

---@alias RefAttrError
---| "conflict"
---| "grid in plain"

---@param blocks Blocks
---@param attr_prev Attr
---@param attr_next Attr
---@return boolean
---@return RefAttrError | nil
local function apply_reference_attr_single(blocks, attr_prev, attr_next)
	merge_blocks(blocks)
	if Attr.is_conflict(attr_prev, attr_next) then
		return false, "conflict"
	end
	if #blocks == 0 then
		return true
	end
	local attr = Attr.is_empty(attr_prev) and attr_next or attr_prev
	local block = blocks[1]
	if attr.kind == CONST.KIND.ATTR_GRID then
		if block.kind == CONST.KIND.PLAIN then
			block = Block.plain.to_grid(block)
			blocks[1] = block
		end
	elseif attr.kind == CONST.KIND.ATTR_PLAIN then
		if block.kind == CONST.KIND.GRID then
			return false, "grid in plain"
		end
	elseif Attr.is_empty(attr) then
		return true
	end
	Block[block.kind].set_attr_if_empty(block, attr)
	return true
end

---@param self Blocks
---@param block Block
---@param attr Attr
---@param is_first boolean
local function insert_plain_block(self, block, attr, is_first)
	if attr.kind ~= CONST.KIND.ATTR_GRID then
		return
	end
	if block.kind ~= CONST.KIND.GRID then
		return
	end
	if #attr.columns == #block.records then
		return
	end
	local block = Block.new()
	Block.set_kind(block, CONST.KIND.PLAIN)
	Block.add(block, Record.plain.new_from_vi_line(""))
	if is_first then
		table.insert(self, 1, block)
	else
		self[#self + 1] = block
	end
end

---@param blocks Blocks
---@param attr_prev Attr
---@param attr_next Attr
local function apply_reference_attr_multi(blocks, attr_prev, attr_next)
	insert_plain_block(blocks, blocks[1], attr_prev, true)
	insert_plain_block(blocks, blocks[#blocks], attr_next, false)
end

---@param map {[string]: string}
---@return {[string]: string}
local function prepare_replace_map(map)
	local out = {}
	for key, value in pairs(map) do
		out[vim.pesc(key)] = value
	end
	return out
end
-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

--- Convert NDJSON records into normalized blocks.
---@param ndjsons Ndjson[]
---@return Blocks
function M.new_from_flat(ndjsons)
	local self = build_blocks(ndjsons)
	local map = prepare_replace_map(ESCAPE_MAP)
	apply_replacements(self, map)
	return self
end

--- Convert NDJSON records into normalized blocks.
---@param records Record[]
---@return Blocks
function M.new_from_vim(records)
	local self = build_blocks(records)
	remove_padding(self)
	return self
end

---@self Blocks
---@return Ndjson[]
function M:serialize_to_flat()
	local map = prepare_replace_map(UNESCAPE_MAP)
	apply_replacements(self, map)
	local ndjsons = { new_attr_file() }
	for _, block in ipairs(self) do
		local impl = Block[block.kind]
		impl.normalize(block)
		util.extend(ndjsons, impl.serialize(block))
	end
	return ndjsons
end

---@self Blocks
---@return Ndjson[]
function M:serialize_to_vim()
	local ndjsons = {}
	for _, block in ipairs(self) do
		local impl = Block[block.kind]
		impl.normalize(block)
		impl.to_vim(block)
		util.extend(ndjsons, impl.serialize(block))
	end
	return ndjsons
end

---@self Blocks
---@param attr_prev Attr
---@param attr_next Attr
---@param allow_plain boolean | nil
---@return boolean
---@return RefAttrError | nil
function M:repair(attr_prev, attr_next, allow_plain)
	if allow_plain then
		apply_reference_attr_multi(self, attr_prev, attr_next)
		return true
	else
		return apply_reference_attr_single(self, attr_prev, attr_next)
	end
end

return M
