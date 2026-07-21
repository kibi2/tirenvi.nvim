local tir_buf       = require("tirenvi.parser.tir_buf") -- Parser

local buffer        = require("tirenvi.io.buffer")      -- IO
local reader        = require("tirenvi.io.reader")
local Context       = require("tirenvi.io.context")

local CursorNvim    = require("tirenvi.cursor.nvim") -- Cursor
local CursorConvert = require("tirenvi.cursor.convert")

local log           = require("tirenvi.util.log") -- Util

-- =============================================================================

local M             = {}

-- =============================================================================
--#region Private

---@return string
local function get_pipe()
	local ctx = Context.from_buf()
	local cursor = reader.cursor(ctx)
	return tir_buf.get_pipe_char(cursor.line) or ""
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
	local ctx     = Context.from_buf()
	local attrs   = buffer.get(ctx.bufnr, buffer.IKEY.ATTRS)
	local cursor  = reader.cursor(ctx)
	local pos     = CursorConvert.to_logical(attrs, cursor.row_cur, cursor.col_disp)
	local top_row = attrs[pos.iblock].range.first
	CursorNvim.restore_disp(ctx, top_row, cursor.col_disp)
end

function M.block_bottom()
	local ctx        = Context.from_buf()
	local attrs      = buffer.get(ctx.bufnr, buffer.IKEY.ATTRS)
	local cursor     = reader.cursor(ctx)
	local pos        = CursorConvert.to_logical(attrs, cursor.row_cur, cursor.col_disp)
	local bottom_row = attrs[pos.iblock].range.last
	CursorNvim.restore_disp(ctx, bottom_row, cursor.col_disp)
end

return M
