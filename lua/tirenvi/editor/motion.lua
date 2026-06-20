local Context = require("tirenvi.app.context")
local buffer = require("tirenvi.io.buffer")
local LinProvider = require("tirenvi.io.buffer_line_provider")
local Bufline = require("tirenvi.core.bufline")
local log = require("tirenvi.util.log")

local M = {}

---@return string
local function get_pipe()
	local ctx = Context.from_buf()
	local irow = buffer.get_cursor_byte_pos()
	local line = buffer.get_line(ctx.bufnr, irow)
	return Bufline.get_pipe_char(line) or ""
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
	local ctx           = Context.from_buf()
	local irow, icol    = buffer.get_cursor_byte_pos()
	local line_provider = LinProvider.new(ctx.bufnr)
	local top           = Bufline.get_block_top_nrow(ctx, line_provider, irow)
	buffer.set_cursor_byte_pos(0, top, icol)
end

function M.block_bottom()
	local ctx = Context.from_buf()
	local irow, icol = buffer.get_cursor_byte_pos()
	local line_provider = LinProvider.new(ctx.bufnr)
	local bottom = Bufline.get_block_bottom_nrow(ctx, line_provider, irow)
	buffer.set_cursor_byte_pos(0, bottom, icol)
end

return M
