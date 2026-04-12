--- Table structure validation module.
---
--- Validates pipe-delimited table integrity inside a buffer range.
---

-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local log = require("tirenvi.util.log")
local util = require("tirenvi.util.util")
local buffer = require("tirenvi.state.buffer")
local buf_state = require("tirenvi.state.buf_state")
local Blocks = require("tirenvi.core.blocks")
local vim_parser = require("tirenvi.core.vim_parser")
local flat_parser = require("tirenvi.core.flat_parser")
local tir_vim = require("tirenvi.core.tir_vim")
local ui = require("tirenvi.ui")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

local api = vim.api
-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------


------ Adjust an empty line based on the previous block context.
---
--- If a new line is added below a table, it is treated as a grid row,
--- so an empty line is converted into an empty table row ("||").
---
--- If a new line is added above a table, it is treated as a plain line,
--- so no modification is applied.
---@param vi_lines string[]
---@param line_prev string|nil
local function fix_empty_line_after_table(vi_lines, line_prev)
	if not line_prev then
		return
	end
	if #vi_lines == 0 then
		return
	end
	if vi_lines[1] ~= "" then
		return
	end
	local pipe = tir_vim.get_pipe_char(line_prev)
	if not pipe then
		return
	end
	vi_lines[1] = pipe .. pipe
end

---@param bufnr number
---@param start_row integer
---@param end_row integer
---@return Blocks
local function get_blocks(bufnr, start_row, end_row)
	local vi_lines = buffer.get_lines(bufnr, start_row, end_row)
	local line_prev = buffer.get_line(bufnr, start_row - 1)
	fix_empty_line_after_table(vi_lines, line_prev)
	return vim_parser.parse(vi_lines, true)
end

---@param bufnr number
---@param start_row integer
---@param end_row integer
---@return Attr|nil
---@return Attr|nil
local function get_reference_attrs(bufnr, start_row, end_row)
	local line_prev, line_next = buffer.get_lines_around(bufnr, start_row, end_row)
	local target = buffer.get_line(bufnr, start_row)
	log.debug("[prev] %s [target] %s [next] %s", tostring(line_prev), tostring(target), tostring(line_next))
	local attr_prev = vim_parser.parse_to_attr(line_prev)
	local attr_next = vim_parser.parse_to_attr(line_next)
	log.debug({ attr_prev, attr_next })
	return attr_prev, attr_next
end

---@param bufnr number
---@param start_row integer
---@param end_row integer
---@return string[]
local function get_repaired_lines(bufnr, start_row, end_row)
	log.debug("===-===-===-=== validation start (%d, %d) ===-===-===-===", start_row, end_row)
	local attr_prev, attr_next = get_reference_attrs(bufnr, start_row, end_row)
	local blocks = get_blocks(bufnr, start_row, end_row)
	log.debug(#blocks ~= 0 and blocks[1].records)
	local parser = util.get_parser(bufnr)
	local allow_plain = parser.allow_plain
	log.debug(#blocks ~= 0 and blocks[1].records[1])
	local success, reason = Blocks.repair(blocks, attr_prev, attr_next, allow_plain)
	log.debug(#blocks ~= 0 and blocks[1].attr)
	log.debug(#blocks ~= 0 and blocks[1].records[1])
	if not success then
		log.debug("===-===-===-=== not success: %s", reason)
		if reason == "grid in plain" then
			return flat_parser.unparse(blocks, parser)
		elseif reason == "conflict" then
			blocks = get_blocks(bufnr, 0, -1)
		else
			error("repair: unexpected error: " .. tostring(reason))
		end
	end
	return vim_parser.unparse(blocks)
end

---@param bufnr number
---@param ranges Range[]
local function repair_ranges(bufnr, ranges)
	for index = 1, #ranges do
		local first = ranges[index].first
		local last = ranges[index].last + 1
		local new_lines = get_repaired_lines(bufnr, first, last)
		ui.set_lines(bufnr, first, last, new_lines)
	end
end

---@param bufnr number
---@param first integer|nil
---@param last integer|nil
---@param new_last integer|nil
local function repair(bufnr, first, last, new_last)
	local ranges = ui.diagnostic_get(bufnr, first, new_last)
	ui.diagnostic_clear(bufnr)
	-- Modifying the buffer in insert mode may corrupt the undo node.
	-- Therefore, in insert mode, only record the invalid changed region
	-- and repair it when leaving insert mode.
	if buf_state.is_insert_mode(bufnr) then
		ui.diagnostic_set(bufnr, ranges)
		return
	end
	-- Moving the cursor in insert mode may create an invalid table undo node.
	-- Therefore, when performing undo/redo, skip table validation.
	if buf_state.is_undo_mode(bufnr) then
		ui.diagnostic_set(bufnr, ranges)
		return
	end
	buffer.set_undo_tree_last(bufnr)
	pcall(vim.cmd, "undojoin")
	repair_ranges(bufnr, ranges)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param bufnr number
---@param first integer|nil
---@param last integer|nil
---@param new_last integer|nil
function M.repair(bufnr, first, last, new_last)
	-- log.debug(debug.traceback())
	vim.schedule(function()
		if not api.nvim_buf_is_valid(bufnr) then
			return
		end
		if api.nvim_get_current_buf() ~= bufnr then
			return
		end
		local ok, err = xpcall(
			function()
				repair(bufnr, first, last, new_last)
			end,
			debug.traceback
		)
		if not ok then
			error(err)
		end
	end)
end

return M
