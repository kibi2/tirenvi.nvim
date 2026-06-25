---@alias WidthCommand
---| "width"
---| "fit"
---| "wrap"

---@alias WidthOperation
---| "set"
---| "add"
---| "sub"
---| "auto"
---| "info"
---| "none"

---@class WidthOp
---@field args string
---@field command WidthCommand
---@field operation WidthOperation
---@field number integer
---@field irow integer
---@field icol integer
local WidthOp   = {}
WidthOp.__index = WidthOp

local Cell      = require("tirenvi.core.cell")
local log       = require("tirenvi.util.log")

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

local map       = {
    ["="] = "set",
    ["+"] = "add",
    ["-"] = "sub",
    ["?"] = "info",
}

---@param opts {[string]:any}
---@return integer
---@return integer
local function get_selection(opts)
    local row_start = opts.line1
    local row_end   = opts.line2
    local is_block  = (vim.fn.visualmode() == "\22")
    local col_start, col_end
    if opts.range > 0 then
        if is_block then
            col_start = vim.fn.virtcol("'<")
            col_end   = vim.fn.virtcol("'>")
        else
            col_start = 1
            col_end   = math.huge
        end
    else
        local col = vim.fn.virtcol(".")
        col_start = col
        col_end   = col
    end
    return math.min(row_start, row_end), math.min(col_start, col_end)
end

---@param str string
---@return integer
local function get_number(str)
    if not str or str == "" then
        return 1
    end
    local num = tonumber(str)
    if not num or num <= 0 then
        error(string.format("%s is not positive number", str))
    end
    return num
end

---@param opts {[string]:any}
---@return WidthOperation
---@return integer
local function get_operation(opts)
    local sub = table.concat(opts.command.sub, "%")
    local regex = string.format("^%s%%s*([%s])(.*)", opts.command_name, sub)
    local op, value = opts.args:match(regex)
    if not op then
        error(string.format("%s need operator %s", opts.command_name, sub))
    end
    if op == "=" and #value == 0 then
        return "auto", 0
    end
    return map[op], get_number(value)
end

---@param opts {[string]:any}
---@return WidthOp|nil
local function try_new(opts)
    local command_name = opts.command_name
    ---@cast command_name WidthCommand
    local irow, icol = get_selection(opts)
    local self = setmetatable({
        args = opts.args,
        command = command_name,
        operation = "none",
        number = 0,
        irow = irow,
        icol = icol,
    }, WidthOp)
    if not opts.command.has_op then
        if opts.args ~= command_name then
            return nil
        end
        return self
    end
    local operation, number = get_operation(opts)
    self.operation = operation
    self.number = number
    return self
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param opts {[string]:any}
---@return WidthOp|nil
function WidthOp.new(opts)
    local ok, self = pcall(try_new, opts)
    if not ok or not self then
        return nil
    end
    return self
end

function WidthOp:to_cmd()
    return string.format(":<C-u>Tir %s<CR>", self.args)
end

---@param self WidthOp
function WidthOp:to_string()
    return string.format("WidthOp %s %s (%d, %d) [%s] %s",
        self.command, self.operation or "nil",
        self.irow, self.icol, self.number or "nil", self:to_cmd())
end

---@param self WidthOp
---@param current integer
---@return integer|nil
function WidthOp:apply(current)
    local operation = self.operation
    local count = self.number
    if operation == "set" then
        return math.max(count, Cell.MIN_WIDTH)
    elseif operation == "add" then
        return current + count
    elseif operation == "sub" then
        return math.max(current - count, Cell.MIN_WIDTH)
    elseif operation == "auto" then
        return nil
    else
        return current
    end
end

return WidthOp
