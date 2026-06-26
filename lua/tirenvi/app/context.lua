-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local Parser = require("tirenvi.parser.parser")
local buffer = require("tirenvi.io.buffer")
local log    = require("tirenvi.util.log")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M      = {}

local api    = vim.api

---@class Context
---@field bufnr number
---@field winid number
---@field filetype string
---@field parser Parser

-- private helpers

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param bufnr number|nil
---@return table
function M.from_buf(bufnr)
    bufnr = bufnr or api.nvim_get_current_buf()
    local winid = api.nvim_get_current_win()
    local filetype = buffer.get(bufnr, buffer.IKEY.FILETYPE)
    local parser = Parser.resolve_parser(filetype)
    return {
        bufnr = bufnr,
        winid = winid,
        filetype = filetype,
        parser = parser,
    }
end

---@parma self Context
---@return boolean
function M:is_allow_plain()
    return self.parser and (self.parser.allow_plain or false) or false
end

return M
