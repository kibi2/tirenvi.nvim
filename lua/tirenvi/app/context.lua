local api                  = vim.api                      -- Neovim

local buffer               = require("tirenvi.io.buffer") -- io
local buffer_line_provider = require("tirenvi.io.buffer_line_provider")

local log                  = require("tirenvi.util.log") -- util

-- =============================================================================

---@class Context
---@field bufnr number
---@field winid number
---@field parser Parser|nil
---@field line_provider LineProvider
local M                    = {}

-- =============================================================================
-- Public API

---@param bufnr number|nil
---@return Context
function M.from_buf(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    local winid = api.nvim_get_current_win()
    local parser = buffer.get(bufnr, buffer.IKEY.PARSER)
    ---@type Context
    return
    {
        bufnr = bufnr,
        winid = winid,
        parser = parser,
        line_provider = buffer_line_provider.new(bufnr)
    }
end

---@parma self Context
---@return boolean
function M:is_allow_plain()
    return self.parser and (self.parser.allow_plain or false) or false
end

return M
