-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local Parser = require("tirenvi.parser.parser")
local buffer = require("tirenvi.io.buffer")
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
    bufnr = buffer.normalize_bufnr(bufnr)
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
