--- Table structure validation module.
---
--- Validates pipe-delimited table integrity inside a buffer range.
---

-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local log = require("tirenvi.util.log")
local util = require("tirenvi.util.util")
local Range = require("tirenvi.util.range")
local buffer = require("tirenvi.state.buffer")
local buf_state = require("tirenvi.state.buf_state")
local Blocks = require("tirenvi.core.blocks")
local vim_parser = require("tirenvi.core.vim_parser")
local flat_parser = require("tirenvi.core.flat_parser")
local tir_vim = require("tirenvi.core.tir_vim")
local render = require("tirenvi.render")
local ui = require("tirenvi.ui")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

local api = vim.api
local fn = vim.fn
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
local function normalize_trailing_empty_line(vi_lines, line_prev)
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
local function build_blocks(bufnr, start_row, end_row)
	local vi_lines = buffer.get_lines(bufnr, start_row, end_row)
	local line_prev = buffer.get_line(bufnr, start_row - 1)
	normalize_trailing_empty_line(vi_lines, line_prev)
	return vim_parser.parse(vi_lines, true)
end

---@param bufnr number
---@param start_row integer
---@param end_row integer
---@return Attr|nil
---@return Attr|nil
local function resolve_reference_attrs(bufnr, start_row, end_row)
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
local function reconcile_range(bufnr, start_row, end_row)
	log.debug("===-===-===-=== validation start (%d, %d) ===-===-===-===", start_row, end_row)
	local attr_prev, attr_next = resolve_reference_attrs(bufnr, start_row, end_row)
	local blocks = build_blocks(bufnr, start_row, end_row)
	log.debug(#blocks ~= 0 and blocks[1].records)
	local parser = util.get_parser(bufnr)
	local allow_plain = parser.allow_plain
	log.debug(#blocks ~= 0 and blocks[1].records[1])
	local success, reason = Blocks.reconcile(blocks, attr_prev, attr_next, allow_plain)
	log.debug(#blocks ~= 0 and blocks[1].attr)
	log.debug(#blocks ~= 0 and blocks[1].records[1])
	if not success then
		log.debug("===-===-===-=== not success: %s", reason)
		if reason == "grid in plain" then
			return flat_parser.unparse(blocks, parser)
		elseif reason == "conflict" then
			blocks = build_blocks(bufnr, 0, -1)
		else
			error("repair: unexpected error: " .. tostring(reason))
		end
	end
	return vim_parser.unparse(blocks)
end

---@param bufnr number
---@param ranges Range[]
local function apply_ranges(bufnr, ranges)
	for index = 1, #ranges do
		local first = ranges[index].first
		local last = ranges[index].last + 1
		local new_lines = reconcile_range(bufnr, first, last)
		buffer.set_lines(bufnr, first, last, new_lines)
	end
end

local function log_watch(bufnr, message)
	local pre = buffer.get(bufnr, buffer.IKEY.UNDO_TREE_LAST)
	local next = fn.undotree(bufnr).seq_last
	log.watch("UNDO", { message, pre, next })
end

---@param bufnr number
---@param range Range
local function expand_continue_lines(bufnr, range)
	local lines = buffer.get_lines(bufnr, range.first, range.last)
	---@type string|nil
	local last_line = lines[#lines]
	local last = range.last
	while tir_vim.is_continue_line(last_line) do
		last_line = buffer.get_line(bufnr, last)
		last = last + 1
	end
	range.last = last - 1
end

---@param bufnr number
---@param ext_ranges Range
local function apply_extra_range(bufnr, ext_ranges)
	if #ext_ranges ~= 0 then
		pcall(vim.cmd, "undojoin")
		apply_ranges(bufnr, ext_ranges)
	end
end

local local_range = nil
---@param bufnr number
local function apply_local_ranges(bufnr)
	buffer.set_undo_tree_last(bufnr)
	pcall(vim.cmd, "undojoin")
	apply_ranges(bufnr, { local_range })
	local_range = nil
end

---@param bufnr number
---@param new_range Range
local function schedule_new_range(bufnr, new_range)
	if local_range == nil then
		vim.schedule(function()
			apply_local_ranges(bufnr)
		end)
		local_range = new_range
	else
		log.watch(bufnr, { "muli time on_lines", local_range })
		Range.union({ local_range, new_range })
	end
end

---@param bufnr number
---@param first integer|nil
---@param _ integer|nil
---@param new_last integer|nil
local function handle_request(bufnr, first, _, new_last)
	local ext_ranges = render.get_range(bufnr)
	ui.diagnostic_clear(bufnr)
	if not first then
		log_watch(bufnr, "INSERT LEAVE")
		apply_extra_range(bufnr, ext_ranges)
		return
	end
	local new_range = Range.new(first, new_last)
	---@cast new_range Range
	expand_continue_lines(bufnr, new_range)
	if buf_state.is_insert_mode(bufnr) then
		-- Modifying the buffer in insert mode may corrupt the undo node.
		-- Therefore, in insert mode, only record the invalid changed region
		-- and repair it when leaving insert mode.
		log_watch(bufnr, "INSERT")
		ext_ranges[#ext_ranges + 1] = new_range
		ui.diagnostic_set(bufnr, Range.union(ext_ranges))
	elseif buf_state.is_undo_mode(bufnr) then
		-- Moving the cursor in insert mode may create an invalid table undo node.
		-- Therefore, when performing undo/redo, skip table validation.
		log_watch(bufnr, "UNDO/REDO")
		ext_ranges[#ext_ranges + 1] = new_range
		ui.diagnostic_set(bufnr, Range.union(ext_ranges))
	else
		log_watch(bufnr, #ext_ranges ~= 0 and "UNDO/REDO LEAVE" or "NORMAL")
		apply_extra_range(bufnr, ext_ranges)
		schedule_new_range(bufnr, new_range)
	end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param bufnr number
---@param first integer|nil
---@param last integer|nil
---@param new_last integer|nil
function M.handle(bufnr, first, last, new_last)
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
				handle_request(bufnr, first, last, new_last)
			end,
			debug.traceback
		)
		if not ok then
			error(err)
		end
	end)
end

return M
