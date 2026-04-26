local buffer = require("tirenvi.io.buffer")
local Blocks = require("tirenvi.core.blocks")
local util = require("tirenvi.util.util")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-- private helpers

---@return Ndjson

-- Public API

---@param bufnr number
---@param range Range
---@param lines string[]
---@param no_undo boolean|nil
function M.write(bufnr, range, lines, no_undo)
    buffer.set_lines(bufnr, range.first, range.last, lines, no_undo)
end

return M
