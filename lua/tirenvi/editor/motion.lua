local config = require("tirenvi.config")
local buf_state = require("tirenvi.state.buf_state")
local LinProvider = require("tirenvi.state.buffer_line_provider")
local tir_vim = require("tirenvi.core.tir_vim")
local util = require("tirenvi.util.util")

local M = {}

---@param op string
---@return function
local function build_motion(op)
	return function()
		local bufnr = vim.api.nvim_get_current_buf()
		if not buf_state.is_tir_vim(bufnr) then
			return op
		end

		local delim = config.marks.pipe
		local count = vim.v.count

		if count > 0 then
			return count .. op .. delim
		end

		return op .. delim
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
		bottom = vim.api.nvim_buf_line_count(bufnr)
	else
		local line_provider = LinProvider.new(0)
		bottom = tir_vim.get_block_bottom_nrow(line_provider, row)
	end
	vim.api.nvim_win_set_cursor(0, { bottom, col })
end

return M
