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
---@field cur_row integer
---@field disp_col integer
local WidthOp   = {}
WidthOp.__index = WidthOp

local Cell      = require("tirenvi.core.cell")
local Range     = require("tirenvi.util.range")
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
---@return Rect
local function get_selection(opts)
    local row_range = Range.from_lua_normal(opts.line1, opts.line2)
    local is_block  = (vim.fn.visualmode() == "\22")
    local disp_col_start, disp_col_end
    if opts.range > 0 then
        if is_block then
            disp_col_start = vim.fn.virtcol("'<")
            disp_col_end   = vim.fn.virtcol("'>")
        else
            disp_col_start = 1
            disp_col_end   = math.huge
        end
    else
        local col      = vim.fn.virtcol(".")
        disp_col_start = col
        disp_col_end   = col
    end
    local col_range = Range.from_lua_normal(disp_col_start, disp_col_end)
    return {
        row = row_range,
        col = col_range
    }
end

---@param str string
---@return integer
local function get_number(str)
    if not str or str == "" then
        return 1
    end
    local num = tonumber(str)
    if not num or num < 0 then
        error(string.format("%s is not positive number", str))
    end
    return math.max(1, num)
end

---@param opts {[string]:any}
---@return WidthOperation|nil
---@return integer|nil
local function get_operation(opts)
    local sub = table.concat(opts.command.sub, "%")
    local regex = string.format("^%s%%s*([%s])(.*)", opts.command_name, sub)
    local op, value = opts.args:match(regex)
    if not op then
        error(string.format("%s need operator %s", opts.command_name, sub))
    end
    if op == "?" and #value ~= 0 then
        return nil, nil
    end
    local num = get_number(value)
    if op == "=" and num <= 1 then
        return "auto", 0
    end
    return map[op], num
end

---@param opts {[string]:any}
---@return WidthOp|nil
local function try_new(opts)
    local command_name = opts.command_name
    ---@cast command_name WidthCommand
    local rect = get_selection(opts)
    local cur_row = rect.row.first
    local disp_col = rect.col.first
    local self = setmetatable({
        args = opts.args,
        command = command_name,
        operation = "none",
        number = 0,
        cur_row = cur_row,
        disp_col = disp_col,
    }, WidthOp)
    if not opts.command.has_op then
        if opts.args ~= command_name then
            return nil
        end
        return self
    end
    local operation, number = get_operation(opts)
    if not operation or not number then
        return nil
    end
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
        self.cur_row, self.disp_col, self.number or "nil", self:to_cmd())
end

---@param self WidthOp
---@param current integer
---@return integer
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
        return 0
    else
        return current
    end
end

return WidthOp
