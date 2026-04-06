local buffer = require("tirenvi.state.buffer")
local LinProvider = require("tirenvi.state.buffer_line_provider")
local tir_vim = require("tirenvi.core.tir_vim")
local util = require("tirenvi.util.util")

local M = {}

---@return string
local function get_pipe()
	local irow = vim.api.nvim_win_get_cursor(0)[1]
	local bufnr = vim.api.nvim_get_current_buf()
	local line = buffer.get_line(bufnr, irow - 1)
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
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1], cursor[2]
	local top
	local parser = util.get_parser(bufnr)
	if not parser or not parser.allow_plain then
		top = 1
	else
		local line_provider = LinProvider.new(0)
		top = tir_vim.get_block_top_nrow(line_provider, row)
	end
	vim.api.nvim_win_set_cursor(0, { top, col })
end

function M.block_bottom()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1], cursor[2]
	local bottom
	local parser = util.get_parser(bufnr)
	if not parser or not parser.allow_plain then
		bottom = buffer.line_count(bufnr)
	else
		local line_provider = LinProvider.new(0)
		bottom = tir_vim.get_block_bottom_nrow(line_provider, row)
	end
	vim.api.nvim_win_set_cursor(0, { bottom, col })
end

return M
