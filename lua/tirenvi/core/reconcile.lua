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
---@param inv_range Range[]
local function log_watch(bufnr, message, range3, inv_range)
	range3 = range3 or Range3.new(0, 0, 0)
	local pre = buffer.get(bufnr, buffer.IKEY.UNDO_TREE_LAST)
	local next = fn.undotree(bufnr).seq_last
	local no_ext = inv_range and (#inv_range ~= 0 and "/ext" .. #inv_range .. Range.short(inv_range[1]) or "") or ""
	local status = string.format(
		"[tree:%d->%d]%s%s",
		pre,
		next,
		range3:short(),
		no_ext
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

local INSERT_LEAVE = "INSERT_LEAVE"
local INSERT_MODE = "INSERT_MODE"
local UNDO_REDO_MODE = "UNDO_REDO_MODE"
local UNDO_REDO_LEAVE = "UNDO_REDO_LEAVE"
local NORMAL_MODE = "NORMAL_MODE"

---@param ctx Context
---@param range3 Range3|nil
---@param inv_ranges Range[]
---@return boolean
local function is_repair(ctx, range3, inv_ranges)
	if buffer.get_repair(ctx.bufnr) == false then
		return false
	end
	local status
	if not range3 then
		status = INSERT_LEAVE
	elseif buf_state.is_insert_mode(ctx.bufnr) then
		-- Modifying the buffer in insert mode may corrupt the undo node.
		-- Therefore, in insert mode, only record the invalid changed region
		-- and repair it when leaving insert mode.
		status = INSERT_MODE
	elseif buf_state.is_undo_mode(ctx.bufnr) then
		-- Moving the cursor in insert mode may create an invalid table undo node.
		-- Therefore, when performing undo/redo, skip table validation.
		status = UNDO_REDO_MODE
	elseif #inv_ranges ~= 0 then
		status = UNDO_REDO_LEAVE
	else
		status = NORMAL_MODE
	end
	log_watch(ctx.bufnr, status, range3, inv_ranges)
	return not (status == INSERT_MODE or status == UNDO_REDO_MODE)
end

---@param bufnr number
---@param range3 Range3|nil
---@return Range|nil
local function get_new_range(bufnr, range3)
	if not range3 then
		return nil
	end
	local new_range = Range3.get_new_range(range3)
	log.watch("INVD", new_range)
	expand_continue_lines(bufnr, new_range)
	return new_range
end

---@param bufnr number
---@param inv_ranges Range[]
---@param range3 Range3|nil
local function update_ranges(bufnr, inv_ranges, range3)
	Range3.update_ranges(range3, inv_ranges)
	local new_range = get_new_range(bufnr, range3)
	inv_ranges[#inv_ranges + 1] = new_range
	inv_ranges = Range.union(inv_ranges)
end

---@param ctx Context
---@param range3 Range3|nil
local function handle_request(ctx, range3)
	local bufnr = ctx.bufnr
	local inv_ranges = invalid.get_ranges(bufnr)
	local repair = is_repair(ctx, range3, inv_ranges)
	invalid.clear(bufnr)
	update_ranges(bufnr, inv_ranges, range3)
	if #inv_ranges == 0 then
		return
	end
	if repair then
		schedule_new_range(ctx, inv_ranges)
	else
		invalid.set_ranges(bufnr, inv_ranges)
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
