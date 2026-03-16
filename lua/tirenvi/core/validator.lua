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

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

local api = vim.api
-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param bufnr number
---@param start_row integer
---@param end_row integer
---@return Blocks
local function get_blocks(bufnr, start_row, end_row)
	local vi_lines = buffer.get_lines(bufnr, start_row, end_row)
	return vim_parser.parse(vi_lines)
end

---@param bufnr number
---@param start_row integer
---@param end_row integer
---@return Attr
---@return Attr
local function get_reference_attrs(bufnr, start_row, end_row)
	local line_prev, line_next = buffer.get_lines_around(bufnr, start_row, end_row)
	log.debug("[prev] %s [next] %s", tostring(line_prev), tostring(line_next))
	local attr_prev = vim_parser.parse_to_attr(line_prev)
	local attr_next = vim_parser.parse_to_attr(line_next)
	return attr_prev, attr_next
end

---@param bufnr number
---@param start_row integer
---@param end_row integer
---@return string[]
local function get_repaired_lines(bufnr, start_row, end_row)
	log.debug("===-===-===-=== validation start (%d, %d) ===-===-===-===", start_row, end_row)
	local blocks = get_blocks(bufnr, start_row, end_row)
	local attr_prev, attr_next = get_reference_attrs(bufnr, start_row, end_row)
	local parser = util.get_parser(bufnr)
	local allow_plain = parser.allow_plain
	local success, reason = Blocks.repair(blocks, attr_prev, attr_next, allow_plain)
	if not success then
		if reason == "grid in plain" then
			return flat_parser.unparse(blocks, parser)
		elseif reason == "conflict" then
			blocks = get_blocks(bufnr, 0, -1)
		else
			error("validator: unexpected error: " .. tostring(reason))
		end
	end
	return vim_parser.unparse(blocks)
end

local function on_insert_mode(bufnr, first, last, new_last)
	log.debug("===-===-===-=== validation insert mode (%d, %d) ===-===-===-===", first, new_last)
	buffer.set(bufnr, buffer.IKEY.REPAIR_PENDING, true)
end

---@param bufnr number
---@param first integer
---@param last integer
---@param new_last integer
local function repair(bufnr, first, last, new_last)
	-- Moving the cursor in insert mode may create an invalid table undo node.
	-- Therefore, when performing undo/redo, skip table validation.
	if buf_state.is_insert_mode(bufnr) then
		log.probe("===-===-===-=== insert mode (%d, %d) ===-===-===-===", first, new_last)
		on_insert_mode(bufnr, first, last, new_last)
		return
	end
	if buf_state.is_undo_mode(bufnr) then
		log.probe("===-===-===-=== undo/redo mode (%d, %d) ===-===-===-===", first, new_last)
		return
	end
	local new_lines = get_repaired_lines(bufnr, first, new_last)
	-- Modifying the buffer in insert mode may corrupt the undo node.
	-- Therefore, in insert mode, only record the invalid changed region
	-- and repair it when leaving insert mode.
	pcall(vim.cmd, "undojoin")
	buffer.set_lines(bufnr, first, new_last, new_lines)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param bufnr number
---@param first integer
---@param new_last integer
function M.repair(bufnr, first, last, new_last)
	vim.schedule(function()
		if not api.nvim_buf_is_valid(bufnr) then
			return
		end
		if api.nvim_get_current_buf() ~= bufnr then
			return
		end
		if buffer.get(bufnr, buffer.IKEY.INTERNAL) then
			-- log.debug("===-===-===-=== validation skip (%d, %d) ===-===-===-===", i_start, i_end)
			return
		end
		buffer.set(bufnr, buffer.IKEY.INTERNAL, true)

		local ok, err = xpcall(
			function()
				repair(bufnr, first, last, new_last)
			end,
			debug.traceback
		)

		buffer.set(bufnr, buffer.IKEY.INTERNAL, false)

		if not ok then
			error(err)
		end
	end)
end

return M
