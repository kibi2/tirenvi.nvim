local fn = vim.fn                                 --Neovim

local config = require("tirenvi.config")          -- Root

local Bufline = require("tirenvi.parser.bufline") -- Parser

local buffer = require("tirenvi.io.buffer")       -- IO

local log = require("tirenvi.util.log")           -- Util

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

local function apply_wrap(winid, should_wrap)
    if vim.wo[winid].wrap ~= should_wrap then
        vim.wo[winid].wrap = should_wrap
    end
end

--#endregion
-- =============================================================================
-- Public API

---@param ctx Context
function M.auto_wrap(ctx)
    if not config.ui.manage_wrap then
        return
    end
    if not ctx.parser.allow_plain then
        apply_wrap(ctx.winid, false)
        return
    end
    -- Fast path for CursorMoved.
    -- We only need the current line of the current window.
    local line = vim.api.nvim_get_current_line()
    local line_width = fn.strdisplaywidth(line)
    local win_span = buffer.get_win_span(ctx.winid)
    local is_over = win_span < line_width
    local is_plain = not Bufline.has_pipe({ line })
    if is_over then
        apply_wrap(ctx.winid, is_plain)
    end
end

return M
