--- Table structure validation module.
---
--- Validates pipe-delimited table integrity inside a buffer range.
---

-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local config = require("tirenvi.config")
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

vim.fn.sign_define("TirenviSign", { text = "◆", texthl = "ErrorMsg" })
vim.api.nvim_set_hl(0, "TirenviDebugLine", { bg = "#888840" })
local NS_INVALID = vim.api.nvim_create_namespace("tirenvi_invalid")

---@param bufnr number
---@param first integer
---@param last integer
---@param id integer
local function set_range_extmark(bufnr, first, last, id)
	local opts = {
		id = id,
		strict = false,
		right_gravity = false,
		end_right_gravity = true,
		end_row = last,
		end_col = 0,
		invalidate = false,
	}
	if vim.log.levels.DEBUG >= config.log.level then
		opts.hl_group = "TirenviDebugLine"
		opts.hl_eol = false
		opts.virt_text = { { tostring(id), "ErrorMsg" } }
		opts.virt_text_pos = "eol_right_align" -- eol
		opts.sign_text = tostring(id):sub(-2)
		opts.sign_hl_group = "ErrorMsg"
	end
	vim.api.nvim_buf_set_extmark(bufnr, NS_INVALID, first, 0, opts)
end

---@class Range
---@field first integer
---@field last integer

---@param bufnr number
---@return Range[]
local function get_range_extmarks(bufnr)
	local extmarks = vim.api.nvim_buf_get_extmarks(
		bufnr,
		NS_INVALID,
		{ 0, 0 },
		{ -1, -1 },
		{ details = true }
	)
	local ranges = {}
	for index = 1, #extmarks do
		ranges[index] = { first = extmarks[index][2], last = extmarks[index][4].end_row }
	end
	return ranges
end

---@param bufnr number
---@param first integer | nil
---@param last integer | nil
---@return Range[]
local function get_ranges(bufnr, first, last)
	local ranges = get_range_extmarks(bufnr)
	if first then
		---@cast last integer
		ranges[#ranges + 1] = { first = first, last = last }
	end
	return ranges
end

---@param bufnr number
---@param ranges Range[]
local function set_range_extmarks(bufnr, ranges)
	local id = 1
	for index = 1, #ranges do
		set_range_extmark(bufnr, ranges[index].first, ranges[index].last, id)
		id = id + 1
	end
end

---@param bufnr number
---@param first integer
---@param last integer
local function set_range_extmark(bufnr, first, last)
	local bufnr = 0 -- 例としてカレントバッファ
	local ns = vim.api.nvim_create_namespace("tirenvi")
	vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
	vim.api.nvim_set_hl(0, "TirenviDebugLine", { bg = "#888840" })
	vim.fn.sign_define("TirenviSign", { text = "◆", texthl = "ErrorMsg" })
	vim.api.nvim_buf_set_extmark(bufnr, ns, 1, 8, {
		strict = false,
		right_gravity = false,
		end_right_gravity = true,
		end_row = 2,
		end_col = 8,
		hl_group = "TirenviDebugLine",
		hl_eol = false,
		-- 	line_hl_group = "TirenviDebugLine",
		virt_text = { { "●●●", "ErrorMsg" } },
		virt_text_pos = "eol_right_align", -- eol
		sign_text = "◆◆",
		sign_hl_group = "ErrorMsg",
		invalidate = false,
	})
	local extmarks = vim.api.nvim_buf_get_extmarks(
		bufnr,
		ns,
		{ 0, 0 },
		{ -1, -1 },
		{ details = true }
	)
end

---@param bufnr number
---@param ranges Range[]
local function repair_rages(bufnr, ranges)
	for index = 1, #ranges do
		local new_lines = get_repaired_lines(bufnr, ranges[index].first, ranges[index].last)
		buffer.set_lines(bufnr, ranges[index].first, ranges[index].last, new_lines)
	end
end

---@param bufnr number
---@param first integer | nil
---@param last integer | nil
---@param new_last integer | nil
local function repair(bufnr, first, last, new_last)
	local ranges = get_ranges(bufnr, first, new_last)
	vim.api.nvim_buf_clear_namespace(0, NS_INVALID, 0, -1)
	-- Moving the cursor in insert mode may create an invalid table undo node.
	-- Therefore, when performing undo/redo, skip table validation.
	if buf_state.is_insert_mode(bufnr) then
		log.debug("===-===-===-=== insert mode (%d, %d) ===-===-===-===", first, new_last)
		set_range_extmarks(bufnr, ranges)
		return
	end
	if buf_state.is_undo_mode(bufnr) then
		log.debug("===-===-===-=== undo/redo mode (%d, %d) ===-===-===-===", first, new_last)
		set_range_extmarks(bufnr, ranges)
		return
	end
	-- Modifying the buffer in insert mode may corrupt the undo node.
	-- Therefore, in insert mode, only record the invalid changed region
	-- and repair it when leaving insert mode.
	pcall(vim.cmd, "undojoin")
	repair_rages(bufnr, ranges)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param bufnr number
---@param first integer | nil
---@param last integer | nil
---@param new_last integer | nil
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
