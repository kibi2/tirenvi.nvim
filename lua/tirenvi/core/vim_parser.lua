-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

----- dependencies
local config = require("tirenvi.config")
local CONST = require("tirenvi.constants")
local util = require("tirenvi.util.util")
local Blocks = require("tirenvi.core.blocks")
local Record = require("tirenvi.core.record")
local Attr = require("tirenvi.core.attr")
-- local log = require("tirenvi.util.log")

local M = {}

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param ndjsons Ndjson[]
---@return string[]
local function to_lines(ndjsons)
	local pipe = config.marks.pipe
	local tir_vim = {}
	for _, record in ipairs(ndjsons) do
		local kind = record.kind
		if kind == CONST.KIND.PLAIN then
			tir_vim[#tir_vim + 1] = record.line or ""
		elseif kind == CONST.KIND.GRID then
			local row_items = record.row
			local row = table.concat(row_items, pipe)
			row = pipe .. row .. pipe
			tir_vim[#tir_vim + 1] = row
		end
	end
	return tir_vim
end

---@param vi_line string
---@return Record
local function tir_vim_to_ndjson(vi_line)
	if util.has_pipe(vi_line) then
		return Record.grid.new_from_vi_line(vi_line)
	else
		return Record.plain.new_from_vi_line(vi_line)
	end
end

---@param vi_lines string[]
---@return Record[]
local function tir_vim_to_ndjsons(vi_lines)
	local records = {}
	for index = 1, #vi_lines do
		records[index] = tir_vim_to_ndjson(vi_lines[index])
	end
	return records
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param vi_lines string[]
---@return Blocks
function M.parse(vi_lines)
	local records = tir_vim_to_ndjsons(vi_lines)
	local blocks = Blocks.new_from_vim(records)
	return blocks
end

---@param blocks Blocks
---@return string[]
function M.unparse(blocks)
	local ndjsons = Blocks.serialize_to_vim(blocks)
	return to_lines(ndjsons)
end

---@param vi_line string|nil
---@return Attr|nil
function M.parse_to_attr(vi_line)
	if not vi_line then
		return nil
	end
	local record = tir_vim_to_ndjson(vi_line)
	return Attr[record.kind].new_from_record(record)
end

return M
