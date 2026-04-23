--- Table structure validation module.
---
--- Validates pipe-delimited table integrity inside a buffer range.
---

-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local Parser = require("tirenvi.core.parser")
local util = require("tirenvi.util.util")
local Range = require("tirenvi.util.range")
local buffer = require("tirenvi.state.buffer")
local buf_state = require("tirenvi.state.buf_state")
local Blocks = require("tirenvi.core.blocks")
local vim_parser = require("tirenvi.core.vim_parser")
local flat_parser = require("tirenvi.core.flat_parser")
local tir_vim = require("tirenvi.core.tir_vim")
local invalid = require("tirenvi.extmark.invalid")
local ui = require("tirenvi.ui")
local log = require("tirenvi.util.log")

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
	for iline = 1, #vi_lines do
		local pipe = tir_vim.get_pipe_char(line_prev)
		if vi_lines[iline] == "" and pipe then
			vi_lines[iline] = pipe .. pipe
		end
		line_prev = vi_lines[iline]
	end
end

---@param context Context
---@param start_row integer
---@param end_row integer
---@return Document
local function build_blocks(context, start_row, end_row)
	local allow_plain = context.parser.allow_plain
	local vi_lines = buffer.get_lines(context.bufnr, start_row, end_row)
	local line_prev = buffer.get_line(context.bufnr, start_row - 1)
	normalize_trailing_empty_line(vi_lines, line_prev)
	return vim_parser.parse(vi_lines, allow_plain, true)
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

---@param context Context
---@param start_row integer
---@param end_row integer
---@return string[]
local function apply_range(context, start_row, end_row)
	log.debug("===-===-===-=== reconcile start[%d, %d] ===-===-===-===", start_row + 1, end_row)
	local attr_prev, attr_next = resolve_reference_attrs(context.bufnr, start_row, end_row)
	local document = build_blocks(context, start_row, end_row)
	local blocks = document.blocks
	log.debug(#blocks ~= 0 and blocks[1].records)
	local allow_plain = context.parser.allow_plain
	log.debug(#blocks ~= 0 and blocks[1].records[1])
	local success, reason = Blocks.reconcile(blocks, attr_prev, attr_next, allow_plain)
	log.debug(#blocks ~= 0 and blocks[1].attr)
	log.debug(#blocks ~= 0 and blocks[1].records[1])
	if not success then
		log.debug("===-===-===-=== not success: %s", reason)
		if reason == "grid in plain" then
			return flat_parser.unparse(document, context.parser)
		elseif reason == "conflict" then
			document = build_blocks(context, 0, -1)
		else
			error("repair: unexpected error: " .. tostring(reason))
		end
	end
	return vim_parser.unparse(document)
end

---@param context Context
---@param ranges Range[]
local function apply_ranges(context, ranges)
	for index = 1, #ranges do
		local first = ranges[index].first
		local last = ranges[index].last + 1
		local new_lines = apply_range(context, first, last)
		buffer.set_lines(context.bufnr, first, last, new_lines, true)
	end
end

local function log_watch(bufnr, message, first, last, new_last, ext_range)
	local pre = buffer.get(bufnr, buffer.IKEY.UNDO_TREE_LAST)
	local next = fn.undotree(bufnr).seq_last
	local delta = (new_last or 0) - (last or 0)
	local add = delta > 0 and "+" .. tostring(delta) or ""
	local remove = delta < 0 and "-" .. tostring(-delta) or ""
	local update = (new_last or 0) - (first or 0) > 0 and "u" .. tostring(new_last - first) or ""
	local no_ext = ext_range and (#ext_range ~= 0 and "/ext" .. #ext_range or "") or ""
	local status = string.format(
		"[tree:%d->%d]%s%s%s%s",
		pre,
		next,
		add,
		remove,
		update,
		no_ext
	)
	log.watch("UNDO", message .. status)
end

---@param bufnr number
---@param range Range
local function expand_continue_lines(bufnr, range)
	local lines = buffer.get_lines(bufnr, range.first, range.last)
	local first = range.first - 1
	local first_line = buffer.get_line(bufnr, first)
	while tir_vim.is_continue_line(first_line) do
		first = first - 1
		first_line = buffer.get_line(bufnr, first)
	end
	range.first = first + 1
	---@type string|nil
	local last_line = lines[#lines]
	local last = range.last
	while tir_vim.is_continue_line(last_line) or last_line == "" do
		last_line = buffer.get_line(bufnr, last)
		last = last + 1
	end
	range.last = last - 1
end

---@param context Context
---@param ext_ranges Range
local function apply_extra_ranges(context, ext_ranges)
	apply_ranges(context, ext_ranges)
end

local local_range = nil
---@param context Context
local function apply_local_range(context)
	apply_ranges(context, { local_range })
	local_range = nil
end

---@param context Context
---@param ext_ranges Range
local function schedule_extra_ranges(context, ext_ranges)
	vim.schedule(function()
		apply_extra_ranges(context, ext_ranges)
	end)
end

---@param context Context
---@param new_range Range
local function schedule_new_range(context, new_range)
	if local_range == nil then
		vim.schedule(function()
			apply_local_range(context)
		end)
		local_range = new_range
	else
		log.watch(context.bufnr, { "muli time on_lines", local_range })
		Range.union({ local_range, new_range })
	end
end

---@param context Context
---@param first integer|nil
---@param last integer|nil
---@param new_last integer|nil
local function handle_request(context, first, last, new_last)
	local bufnr = context.bufnr
	local ext_ranges = invalid.get_range(bufnr)
	ui.diagnostic_clear(bufnr)
	if not first then
		log_watch(bufnr, "INSERT LEAVE[" .. tostring(#ext_ranges) .. "]")
		schedule_extra_ranges(context, ext_ranges)
		return
	end
	local new_range = Range.new(first, new_last)
	---@cast new_range Range
	expand_continue_lines(bufnr, new_range)
	if buf_state.is_insert_mode(bufnr) then
		-- Modifying the buffer in insert mode may corrupt the undo node.
		-- Therefore, in insert mode, only record the invalid changed region
		-- and repair it when leaving insert mode.
		log_watch(bufnr, "INSERT", first, last, new_last)
		ext_ranges[#ext_ranges + 1] = new_range
		ui.diagnostic_set(bufnr, Range.union(ext_ranges))
	elseif buf_state.is_undo_mode(bufnr) then
		-- Moving the cursor in insert mode may create an invalid table undo node.
		-- Therefore, when performing undo/redo, skip table validation.
		log_watch(bufnr, "UNDO/REDO", first, last, new_last)
		ext_ranges[#ext_ranges + 1] = new_range
		ui.diagnostic_set(bufnr, Range.union(ext_ranges))
	elseif #ext_ranges ~= 0 then
		log_watch(bufnr, "UNDO/REDO LEAVE", first, last, new_last, ext_ranges)
		schedule_extra_ranges(context, ext_ranges)
		schedule_new_range(context, new_range)
	else
		log_watch(bufnr, "NORMAL", first, last, new_last, ext_ranges)
		schedule_new_range(context, new_range)
	end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param context Context
---@param first integer|nil
---@param last integer|nil
---@param new_last integer|nil
function M.handle(context, first, last, new_last)
	-- log.debug(debug.traceback())
	local bufnr = context.bufnr
	vim.schedule(function()
		if not api.nvim_buf_is_valid(bufnr) then
			return
		end
		if api.nvim_get_current_buf() ~= bufnr then
			return
		end
		local ok, err = xpcall(
			function()
				handle_request(context, first, last, new_last)
			end,
			debug.traceback
		)
		if not ok then
			error(err)
		end
	end)
end

return M
