-- dependencies
local Context = require("tirenvi.app.context")
local buf_state = require("tirenvi.io.buf_state")
local log = require("tirenvi.util.log")

-- module
local M = {}

-- constants / defaults

local bo = vim.bo

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

local function debug_trace(bufnr, title, name)
    if not log.is_debug() then
        return
    end
    local ctx = Context.from_buf()
    local filetype = bo[ctx.bufnr].filetype
    local state = buf_state.debug_state(ctx.bufnr)
    log.debug("===+=== %s ===+=== %s[#%d] %s : %s ===", title, name or "", bufnr, filetype, state)
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

function M.ui_entry(bufnr, name)
    debug_trace(bufnr, "ENTRY", name)
end

function M.ui_exit(bufnr, name)
    debug_trace(bufnr, "EXIT!", name)
end

return M
