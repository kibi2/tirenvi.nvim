local config = require("tirenvi.config")
local buf_state = require("tirenvi.state.buf_state")
local tir_vim = require("tirenvi.core.tir_vim")

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

function M.g()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1], cursor[2]
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local top = tir_vim.get_block_top_nrow(lines, row)
	vim.api.nvim_win_set_cursor(0, { top, col })
end

function M.G()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1], cursor[2]
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local bottom = tir_vim.get_block_bottom_nrow(lines, row)
	vim.api.nvim_win_set_cursor(0, { bottom, col })
end

return M
