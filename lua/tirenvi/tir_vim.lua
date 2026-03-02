--- Utility functions for TIR VIM format
--
-- This module is intended to be used inside Vim/Neovim.
-- It may access the global `vim` object directly.
-- This module is not intended to be used outside Vim/Neovim.
--
-- @module tir_vim

----- dependencies
local config = require("tirenvi.config")
local log = require("tirenvi.log")
local helper = require("tirenvi.helper")
local vimHelper = require("tirenvi.vimHelper")
local ndjsons = require("tir.ndjsons")
local parser = require("tirenvi.parser")
-- module
local M = {}

-- constants / defaults

-- private helpers

---@param blocks Blocks
---@return string[]
local function from_blocks(blocks)
	local pipe = config.marks.pipe
	local tir_vim = {}
	for _, block in ipairs(blocks) do
		for _, ndjson in ipairs(block) do
			local kind = ndjson.kind
			if kind == ndjsons.FILE_ATTR then
			elseif kind == ndjson.BLOCK_START then
			elseif kind == ndjsons.PLAIN then
				table.insert(tir_vim, ndjson.line or "")
			elseif kind == ndjsons.GRID then
				local row_items = ndjson.row or {}
				local row = table.concat(row_items, pipe)
				row = pipe .. row .. pipe
				table.insert(tir_vim, row)
			end
		end
	end
	return tir_vim
end

---@param text string
---@return integer
local function display_width(text)
	return vim.fn.strdisplaywidth(text)
end

---@param block Block_grid
---@return integer[]
local function compute_widths(block)
	local widths = {}
	for _, row in ipairs(block) do
		local col_widths = M.get_column_widths(row.row)
		for col, width in ipairs(col_widths) do
			widths[col] = math.max(widths[col] or 0, width)
		end
	end
	return widths
end

---@param cell string
---@param target_width number
---@return string
local function pad_cell(cell, target_width)
	local width = display_width(cell)
	local diff = target_width - width
	if diff <= 0 then
		return cell
	end
	return cell .. string.rep(config.marks.padding, diff)
end

---@param record Record_grid
---@param new_count integer
---@return nil
local function increase_cols(record, new_count)
	local row = record.row
	for _ = #row + 1, new_count do
		table.insert(row, "")
	end
end

---@param record Record_grid
---@param new_count integer
---@return nil
local function reduce_cols(record, new_count)
	local row = record.row
	row[new_count] = table.concat(row, " ", new_count)
	for i = #row, new_count + 1, -1 do
		row[i] = nil
	end
end

---@param record Record_grid
---@param widths integer[]
---@return nil
local function resize_columns(record, widths)
	local old_count = #record.row
	if old_count > #widths then
		reduce_cols(record, #widths)
	elseif old_count < #widths then
		increase_cols(record, #widths)
	end
end

---@param record Record_grid
---@param widths integer[]
---@return nil
local function pad_cells(record, widths)
	for iCol, cell in ipairs(record.row) do
		record.row[iCol] = pad_cell(cell, widths[iCol])
	end
end

---@param block Block_grid
---@param widths integer[] | nil
---@return nil
local function normalize_grid(block, widths)
	if widths == nil then
		widths = compute_widths(block)
	end
	log.debug(widths)
	for _, record in ipairs(block) do
		if record.kind == "grid" then
			resize_columns(record, widths)
			pad_cells(record, widths)
		end
	end
end

---@param blocks Blocks
---@param widths integer[]|nil
---@return nil
local function pad_to_blocks(blocks, widths)
	for _, block in ipairs(blocks) do
		if ndjsons.get_block_kind(block) == ndjsons.GRID then
			normalize_grid(block, widths)
		end
	end
end

---@param vi_lines string[]
---@param noplain boolean
---@param widths integer[]|nil
---@return Record
local function tir_vim_to_ndjson(vi_lines, noplain, widths)
	if #vi_lines == 0 then
		return {}
	end
	local records = {}
	for _, vi_line in ipairs(vi_lines) do
		local is_plain = not helper.has_pipe(vi_line)
		if is_plain and widths == nil and not noplain then
			table.insert(records, { kind = ndjsons.PLAIN, line = vi_line })
		else
			table.insert(records, M.parse_grid_line(vi_line))
		end
	end
	return records
end

local function has_pipe(vi_lines)
	for _, fl_line in ipairs(vi_lines) do
		if helper.has_pipe(fl_line) then
			return true
		end
	end
	return false
end

-- public API

---@param vi_line string
---@return Record
function M.parse_grid_line(vi_line)
	local pipe = config.marks.pipe
	local padding = config.marks.padding

	if not vi_line or vi_line == "" then
		return { kind = ndjsons.GRID, row = { "" } }
	end

	-- 1. Remove the leading and trailing pipe characters
	local escaped_pipe = vim.pesc(pipe)
	vi_line = vi_line:gsub("^" .. escaped_pipe, "")
	vi_line = vi_line:gsub(escaped_pipe .. "$", "")

	-- 2. Remove padding
	local escaped_padding = vim.pesc(padding)
	vi_line = vi_line:gsub(escaped_padding, "")

	-- 3. String replacement (val -> key)
	local replace = helper.get_replace_pair()
	for key, val in pairs(replace) do
		local escaped_val = vim.pesc(val)
		vi_line = vi_line:gsub(escaped_val, key)
	end

	-- 4. Split
	local cells = vim.split(vi_line, pipe, { plain = true })

	-- 5. Assemble
	return {
		kind = ndjsons.GRID,
		row = cells,
	}
end

---@param row string[]
---@return integer[]
function M.get_column_widths(row)
	local widths = {}
	for _, cell in ipairs(row) do
		local width = display_width(cell)
		table.insert(widths, width)
	end
	return widths
end

---@param fl_lines string[]
---@param opts {parser: Parser}
---@return string[]
function M.from_flat(fl_lines, opts)
	vimHelper.init_marks(fl_lines)
	local js_records = parser.parse(fl_lines, opts.parser)
	local js_blocks = ndjsons.to_blocks(js_records)
	local replace = helper.get_replace_pair()
	ndjsons.replace(js_blocks, replace)
	pad_to_blocks(js_blocks)
	return from_blocks(js_blocks)
end

--- Convert display lines back to TSV format
---@param vi_lines string[]
---@param opts { parser:Parser, file_path:string}
---@return string[] | nil
function M.to_flat(vi_lines, opts)
	if not has_pipe(vi_lines) then
		return nil
	end
	local js_records = tir_vim_to_ndjson(vi_lines, true)
	return parser.unparse(js_records, opts.parser, opts.file_path)
end

--- Recalculate padding for a buffer
---@param vi_lines string[]
---@param noplain boolean
---@param widths integer[] | nil
---@return string[]
function M.recalculate_padding(vi_lines, noplain, widths)
	local js_records = tir_vim_to_ndjson(vi_lines, noplain, widths)
	local blocks = ndjsons.to_blocks(js_records)
	local replace = helper.get_replace_pair()
	ndjsons.replace(blocks, replace)
	pad_to_blocks(blocks, widths)
	return from_blocks(blocks)
end

return M
