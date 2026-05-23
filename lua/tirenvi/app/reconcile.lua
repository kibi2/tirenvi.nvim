--- Table structure validation module.
---
--- Validates pipe-delimited table integrity inside a buffer range.
---

-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local pipeline = require("tirenvi.app.pipeline")
local Range = require("tirenvi.util.range")
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

local local_range = nil
---@param ctx Context
local function apply_local_range(ctx)
	---@cast local_range Range
	pipeline.cmd_format(ctx, true, true)
	local_range = nil
end

---@param ctx Context
local function schedule_new_range(ctx)
	local new_ranges = invalid.get_ranges(ctx.bufnr)
	if #new_ranges == 0 then
		return
	end
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

---@param ctx Context
---@param range3 Range3|nil
local function reconcile_request(ctx, range3)
	local bufnr = ctx.bufnr
	if buf_state.is_repair(ctx, range3) then
		schedule_new_range(ctx)
		invalid.clear(bufnr)
	end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param ctx Context
---@param range3 Range3|nil
function M.reconcile(ctx, range3)
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
				reconcile_request(ctx, range3)
			end,
			debug.traceback
		)
		if not ok then
			error(err)
		end
	end)
end

return M
