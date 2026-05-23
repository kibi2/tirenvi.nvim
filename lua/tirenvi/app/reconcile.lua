--- Table structure validation module.
---
--- Validates pipe-delimited table integrity inside a buffer range.
---

-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local pipeline = require("tirenvi.app.pipeline")
local Context = require("tirenvi.app.context")
local Request = require("tirenvi.app.request")
local tir_vim = require("tirenvi.core.tir_vim")
local Range = require("tirenvi.util.range")
local Range3 = require("tirenvi.util.range3")
local buffer = require("tirenvi.io.buffer")
local reader = require("tirenvi.io.reader")
local buf_state = require("tirenvi.io.buf_state")
local invalid = require("tirenvi.io.invalid")
local util = require("tirenvi.util.util")
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

---@param bufnr number
---@param range Range
local function expand_continue_lines(bufnr, range)
	local ctx = Context.from_buf(bufnr)
	local req = Request.from_range(range)
	local lines = reader.read(ctx, req)
	local prev = range.first - 1
	local prev_line = buffer.get_line(bufnr, prev)
	while tir_vim.is_continue_line(prev_line) do
		prev = prev - 1
		prev_line = buffer.get_line(bufnr, prev)
	end
	range.first = prev + 1
	---@type string|nil
	local last_line = lines[#lines]
	local last = range.last
	while tir_vim.is_continue_line(last_line) or last_line == "" do
		last = last + 1
		last_line = buffer.get_line(bufnr, last)
	end
	range.last = last
end

---@param bufnr number
---@param message string
---@param range3 Range3|nil
local function log_watch(bufnr, message, range3)
	range3 = range3 or Range3.new(0, 0, 0)
	local pre = buffer.get(bufnr, buffer.IKEY.UNDO_TREE_LAST)
	local next = fn.undotree(bufnr).seq_last
	local status = string.format(
		"[tree:%d->%d]%s",
		pre,
		next,
		Range3.short(range3)
	)
	log.watch("UNDO", message .. status)
end

local local_range = nil
---@param ctx Context
local function apply_local_range(ctx)
	---@cast local_range Range
	pipeline.cmd_format(ctx, true, true)
	local_range = nil
end

---@param ctx Context
---@param new_ranges Range[]
local function schedule_new_range(ctx, new_ranges)
	if local_range == nil then
		local_range = Range.join(new_ranges)
		vim.schedule(function()
			apply_local_range(ctx)
		end)
	else
		log.watch("UNDO", ctx.bufnr, { "multi time on_lines", local_range })
		new_ranges[#new_ranges + 1] = local_range
		local_range = Range.join(new_ranges)
	end
end

local REPAIR_OFF = "REPAIR_OFF"
local INSERT_LEAVE = "INSERT_LEAVE"
local INSERT_MODE = "INSERT_MODE"
local UNDO_REDO_MODE = "UNDO_REDO_MODE"
local NORMAL_MODE = "NORMAL_MODE"

---@param ctx Context
---@param range3 Range3|nil
---@return string
local function get_status(ctx, range3)
	if buffer.get_repair(ctx.bufnr) == false then
		return REPAIR_OFF
	end
	local status
	if not range3 then
		return INSERT_LEAVE
	elseif buf_state.is_insert_mode(ctx.bufnr) then
		-- Modifying the buffer in insert mode may corrupt the undo node.
		-- Therefore, in insert mode, only record the invalid changed region
		-- and repair it when leaving insert mode.
		return INSERT_MODE
	elseif buf_state.is_undo_mode(ctx.bufnr) then
		-- Moving the cursor in insert mode may create an invalid table undo node.
		-- Therefore, when performing undo/redo, skip table validation.
		return UNDO_REDO_MODE
	else
		return NORMAL_MODE
	end
end

---@param bufnr number
---@param range3 Range3
---@return Range
local function get_new_range(bufnr, range3)
	local new_range = Range3.get_new_range(range3)
	log.watch("INVD", new_range)
	expand_continue_lines(bufnr, new_range)
	return new_range
end

---@param bufnr number
---@param prev_ranges Range[]
---@param range3 Range3|nil
---@return Range[]
local function update_ranges(bufnr, prev_ranges, range3)
	if not range3 then
		return prev_ranges
	end
	local ranges1, _, ranges3 = Range.split(prev_ranges, Range.from_lua(range3.first, range3.last))
	Range.shift(ranges3, Range3.get_delta(range3))
	local range2 = get_new_range(bufnr, range3)
	local new_ranges = ranges1
	new_ranges[#new_ranges + 1] = range2
	util.extend(new_ranges, ranges3)
	return Range.union(new_ranges)
end

---@param bufnr number
---@param new_ranges Range[]
---@return Range[]
local function check_invalid(bufnr, new_ranges)
	local inv_ranges = {}
	return inv_ranges
end

---@param ctx Context
---@param range3 Range3|nil
local function handle_request(ctx, range3)
	local bufnr = ctx.bufnr
	local prev_ranges = invalid.get_ranges(bufnr)
	invalid.clear(bufnr)
	local new_ranges = update_ranges(bufnr, prev_ranges, range3)
	if #new_ranges == 0 then
		return
	end
	local status = get_status(ctx, range3)
	log_watch(ctx.bufnr, status, range3)
	if status == INSERT_MODE or status == UNDO_REDO_MODE or status == REPAIR_OFF then
		invalid.set_ranges(bufnr, new_ranges)
	else
		schedule_new_range(ctx, new_ranges)
	end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param ctx Context
---@param range3 Range3|nil
function M.handle(ctx, range3)
	local bufnr = ctx.bufnr
	vim.schedule(function()
		if not api.nvim_buf_is_valid(bufnr) then
			return
		end
		if api.nvim_get_current_buf() ~= bufnr then
			return
		end
		local ok, err = xpcall(
			function()
				handle_request(ctx, range3)
			end,
			debug.traceback
		)
		if not ok then
			error(err)
		end
	end)
end

return M
