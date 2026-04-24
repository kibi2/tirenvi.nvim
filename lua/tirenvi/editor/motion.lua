local Parser = require("tirenvi.core.parser")
local Context = require("tirenvi.core.context")
local buffer = require("tirenvi.state.buffer")
local LinProvider = require("tirenvi.state.buffer_line_provider")
local tir_vim = require("tirenvi.core.tir_vim")
local util = require("tirenvi.util.util")

local M = {}

---@return string
local function get_pipe()
	local context = Context.from_buf()
	local irow = vim.api.nvim_win_get_cursor(0)[1]
	local line = buffer.get_line(context.bufnr, irow - 1)
	return tir_vim.get_pipe_char(line) or ""
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
	local context = Context.from_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1], cursor[2]
	local top
	if not Context.is_allow_plain(context) then
		top = 1
	else
		local line_provider = LinProvider.new()
		top = tir_vim.get_block_top_nrow(line_provider, row)
	end
	vim.api.nvim_win_set_cursor(0, { top, col })
end

function M.block_bottom()
	local context = Context.from_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1], cursor[2]
	local bottom
	if not Context.is_allow_plain(context) then
		bottom = buffer.line_count(context.bufnr)
	else
		local line_provider = LinProvider.new()
		bottom = tir_vim.get_block_bottom_nrow(line_provider, row)
	end
	vim.api.nvim_win_set_cursor(0, { bottom, col })
end

return M
