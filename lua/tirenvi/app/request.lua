-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local Range = require("tirenvi.util.range")
local Range3 = require("tirenvi.util.range3")
local log = require("tirenvi.util.log")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

---@class Request
---@field range Range
---@field lines? string[]
---@field attrs? Attr[]
---@field no_undo? boolean
---@field is_buf? boolean

-- private helpers

local function set_buf(ctx, req)
    local allow_plain = ctx.parser.allow_plain or false
    if allow_plain then
        --local lines = buffer.get_lines(ctx.bufnr, 0, -1)
        --req.is_buf = tir_buf.has_pipe(lines)
    end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param range Range
---@return Request
function M.new_reader(range)
    local self = {
        range = range,
    }
    return self
end

---@param range Range
---@param lines string[]
---@param no_undo boolean|nil
---@return Request
function M.new_writer(range, lines, no_undo)
    return {
        range = range,
        lines = lines,
        no_undo = no_undo or false,
    }
end

---@param self Request
---@return integer -- 1-based
---@return integer -- 1-based
function M:lua_range()
    return Range.to_lua(self.range)
end

---@param self Request
---@return Range3
function M:get_range3()
    local first, last = M.lua_range(self)
    return Range3.new(first, last, first + #self.lines - 1)
end

---@param self Request
---@return boolean
function M:is_no_undo()
    return self.no_undo == true
end

---@param self Request
---@return boolean
function M:is_buf()
    return self.is_buf == true
end

return M
