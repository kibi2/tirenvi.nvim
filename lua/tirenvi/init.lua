local log = require("tirenvi.util.log") -- Util

-- =============================================================================

local M = {}

M.motion = require("tirenvi.editor.motion")

-- =============================================================================
-- Public API

--- Set up tirenvi plugin (load autocmds and commands)
---@param opts {[string]:any}
function M.setup(opts)
	if vim.g.tirenvi_initialized then
		log.error("tirenvi does not support reload. Please restart Neovim.")
		return
	end
	vim.g.tirenvi_initialized = true
	require("tirenvi.config").setup(opts)
	require("tirenvi.ui").setup()
	require("tirenvi.editor").setup()
end

return M
