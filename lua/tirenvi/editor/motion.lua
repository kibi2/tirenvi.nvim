local Context = require("tirenvi.app.context")
local Attrs = require("tirenvi.core.attrs")
local buffer = require("tirenvi.io.buffer")
local LinProvider = require("tirenvi.io.buffer_line_provider")
local tir_buf = require("tirenvi.core.tir_buf")

local M = {}

---@return string
local function get_pipe()
	local ctx = Context.from_buf()
	local irow = buffer.get_cursor()
	local line = buffer.get_line(ctx.bufnr, irow)
	return tir_buf.get_pipe_char(line) or ""
end

---@param op string
---@return function
local function build_motion(op)
	return function()
		local count = vim.v.count
		local prefix = (count > 0) and tostring(count) or ""
		return prefix .. op .. get_pipe()
	end
end

M.f = build_motion("f")
M.F = build_motion("F")
M.t = build_motion("t")
M.T = build_motion("T")

function M.block_top()
	local ctx           = Context.from_buf()
	local irow, icol    = buffer.get_cursor()
	local line_provider = LinProvider.new(ctx.bufnr)
	local top           = tir_buf.get_block_top_nrow(ctx, line_provider, irow)
	buffer.set_cursor(0, top, icol)
end

function M.block_bottom()
	local ctx = Context.from_buf()
	local irow, icol = buffer.get_cursor()
	local line_provider = LinProvider.new(ctx.bufnr)
	local bottom = tir_buf.get_block_bottom_nrow(ctx, line_provider, irow)
	buffer.set_cursor(0, bottom, icol)
end

return M
