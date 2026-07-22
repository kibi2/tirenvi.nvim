local api = vim.api -- Neovim

local LineProvider = require("tirenvi.io.buf_line_provider") -- IO

local log = require("tirenvi.util.log") -- util

-- =============================================================================

---@class Context
---@field bufnr number
---@field winid number
---@field line_provider LineProvider
local M = {}

-- =============================================================================
-- Public API

---@param bufnr number|nil
---@return Context
function M.from_buf(bufnr)
	local bufnr = bufnr or api.nvim_get_current_buf()
	---@type Context
	return {
		bufnr = bufnr,
		winid = api.nvim_get_current_win(),
		line_provider = LineProvider.new(bufnr),
	}
end

return M
