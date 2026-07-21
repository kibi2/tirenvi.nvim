-- =============================================================================

local M = {}

-- =============================================================================
-- Public API

function M.setup()
    require("tirenvi.editor.autocmd").setup()
    require("tirenvi.editor.commands").setup()
    require("tirenvi.editor.textobj").setup()
end

return M
