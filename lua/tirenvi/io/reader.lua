local buf_lines = require("tirenvi.io.buf_lines") -- IO
local attr_store = require("tirenvi.io.attr_store")
local ReadResult = require("tirenvi.io.read_result")

local CursorNvim = require("tirenvi.cursor.nvim") -- Cursor

local Attrs = require("tirenvi.core.attrs") -- Core

local log = require("tirenvi.util.log") -- Util

-- =============================================================================

local M = {}

-- =============================================================================
-- Public API

---@param ctx Context
---@param range Range
---@pram opts {restore_mode: "none"|"buffer"|"logical"|nil, curosr:boolean|nil}
---@return ReadResult
function M.read(ctx, range, opts)
	opts = opts or {}
	local restore_mode = opts.restore_mode
	local result = ReadResult.new_reader(range)
	result.attrs = attr_store.read(ctx.bufnr)
	local first, last = ReadResult.lua_range(result)
	result.lines = buf_lines.get_lines(ctx.bufnr, first, last)
	if opts.cursor ~= false then
		result.cursor = M.cursor(ctx)
		result.cursor.restore_mode = restore_mode or "none"
	end
	log.watch("ATTR", Attrs.debug_attrs(result.attrs, "[0]CHACHED ATTRS:"))
	return result
end

---@param ctx Context
---@return CursorBuf
function M.cursor(ctx)
	return CursorNvim.capture(ctx)
end

return M
