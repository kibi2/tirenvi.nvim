local tir_buf = require("tirenvi.parser.tir_buf") -- Parser
local Cursor = require("tirenvi.parser.cursor")

local buf_state = require("tirenvi.io.buf_state") -- IO
local reader = require("tirenvi.io.reader")
local Context = require("tirenvi.io.context")
local CursorNvim = require("tirenvi.io.cursor_nvim")

local log = require("tirenvi.util.log") -- Util

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@return string
local function get_pipe()
	local ctx = Context.from_buf()
	local cursor_buf = reader.cursor_buf(ctx)
	return tir_buf.get_pipe_char(cursor_buf.line) or ""
end

---@param op string
---@return function
local function build_motion(op)
	return function()
		return op .. get_pipe()
	end
end

--#endregion
-- =============================================================================
-- Public API

M.f = build_motion("f")
M.F = build_motion("F")
M.t = build_motion("t")
M.T = build_motion("T")

function M.block_top()
	local ctx = Context.from_buf()
	local attrs = buf_state.get(ctx.bufnr, buf_state.IKEY.ATTRS)
	local cursor_buf = reader.cursor_buf(ctx)
	local pos = Cursor.to_tir(attrs, cursor_buf.row_cur, cursor_buf.col_disp)
	local top_row = attrs[pos.iblock].range.first
	CursorNvim.restore_disp(ctx, top_row, cursor_buf.col_disp)
end

function M.block_bottom()
	local ctx = Context.from_buf()
	local attrs = buf_state.get(ctx.bufnr, buf_state.IKEY.ATTRS)
	local cursor_buf = reader.cursor_buf(ctx)
	local pos = Cursor.to_tir(attrs, cursor_buf.row_cur, cursor_buf.col_disp)
	local bottom_row = attrs[pos.iblock].range.last
	CursorNvim.restore_disp(ctx, bottom_row, cursor_buf.col_disp)
end

return M
