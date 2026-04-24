-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local Parser = require("tirenvi.core.parser")
local buffer = require("tirenvi.state.buffer")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

---@class Context
---@field bufnr number
---@field filetype string
---@field parser Parser

-- private helpers

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param bufnr number|nil
---@return table
function M.from_buf(bufnr)
    bufnr = (bufnr ~= nil and bufnr ~= 0) and bufnr or vim.api.nvim_get_current_buf()
    local filetype = buffer.get(bufnr, buffer.IKEY.FILETYPE)
    local parser = Parser.resolve_parser(filetype)
    return {
        bufnr = bufnr,
        filetype = filetype,
        parser = parser,
    }
end

---@parma self Context
---@return boolean
function M:is_allow_plain()
    return self.parser and self.parser.allow_plain or false
end

return M
