local api = vim.api                               -- Neovim

local fn = vim.fn                                 --Neovim

local config = require("tirenvi.config")          -- Root

local tir_buf = require("tirenvi.parser.tir_buf") -- Parser

local buf_lines = require("tirenvi.io.buf_lines") -- IO
local buf_state = require("tirenvi.io.buf_state")

local log = require("tirenvi.util.log") -- Util

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
    if not buf_state.is_allow_plain(ctx.bufnr) then
        apply_wrap(ctx.winid, false)
        return
    end
    -- Fast path for CursorMoved.
    -- We only need the current line of the current window.
    local line = api.nvim_get_current_line()
    local line_width = fn.strdisplaywidth(line)
    local win_span = buf_state.get_win_span(ctx.winid)
    local is_over = win_span < line_width
    local is_plain = not tir_buf.has_pipe({ line })
    if is_over then
        apply_wrap(ctx.winid, is_plain)
    end
end

return M
