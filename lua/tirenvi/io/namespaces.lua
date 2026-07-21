local api = vim.api -- Neovim

-- =============================================================================

local M = {}

M.ATTR = api.nvim_create_namespace("tirenvi_attr")
M.DIRTY = api.nvim_create_namespace("tirenvi_dirty")

return M
