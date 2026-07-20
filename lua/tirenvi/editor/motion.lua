local Context    = require("tirenvi.app.context")
local buffer     = require("tirenvi.io.buffer")
local reader     = require("tirenvi.io.reader")
local Attrs      = require("tirenvi.core.attrs")
local Bufline    = require("tirenvi.parser.bufline")
local CursorNvim = require("tirenvi.cursor.nvim")
local log        = require("tirenvi.util.log")

local M          = {}

---@return string
local function get_pipe()
	local ctx = Context.from_buf()
	local cursor = reader.cursor(ctx)
	return Bufline.get_pipe_char(cursor.line) or ""
end

---@param op string
---@return function
local function build_motion(op)
	return function()
		return op .. get_pipe()
	end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

M.f = build_motion("f")
M.F = build_motion("F")
M.t = build_motion("t")
M.T = build_motion("T")

function M.block_top()
	local ctx     = Context.from_buf()
	local attrs   = buffer.get(ctx.bufnr, buffer.IKEY.ATTRS)
	local cursor  = reader.cursor(ctx)
	local pos     = Attrs.to_logical(attrs, cursor.row_cur, cursor.col_disp)
	local top_row = attrs[pos.iblock].range.first
	CursorNvim.restore_disp(ctx, top_row, cursor.col_disp)
end

function M.block_bottom()
	local ctx        = Context.from_buf()
	local attrs      = buffer.get(ctx.bufnr, buffer.IKEY.ATTRS)
	local cursor     = reader.cursor(ctx)
	local pos        = Attrs.to_logical(attrs, cursor.row_cur, cursor.col_disp)
	local bottom_row = attrs[pos.iblock].range.last
	CursorNvim.restore_disp(ctx, bottom_row, cursor.col_disp)
end

return M
