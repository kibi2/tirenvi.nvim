local api                  = vim.api                                    -- Neovim

local buffer_line_provider = require("tirenvi.io.buffer_line_provider") -- IO

local log                  = require("tirenvi.util.log")                -- util

-- =============================================================================

---@class Context
---@field bufnr number
---@field winid number
---@field line_provider LineProvider
local M                    = {}

-- =============================================================================
-- Public API

---@param bufnr number|nil
---@return Context
function M.from_buf(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    local winid = api.nvim_get_current_win()
    ---@type Context
    return
    {
        bufnr = bufnr,
        winid = winid,
        line_provider = buffer_line_provider.new(bufnr)
    }
end

return M
