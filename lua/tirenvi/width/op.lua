---@class WidthOp
---@field opts {kind:string, mode:string|nil}
---@field args string
---@field command string
---@field operation string
---@field number number[]
---@field irow integer
---@field icol integer
local WidthOp        = {}
WidthOp.__index      = WidthOp

local Cell           = require("tirenvi.core.cell")
local WidthModeState = require("tirenvi.width.state")
local log            = require("tirenvi.util.log")

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

local map            = {
    ["="] = "set",
    ["+"] = "add",
    ["-"] = "sub",
    wrap = "toggle",
}

---@param str string
---@return integer|nil
local function get_number(str)
    if not str or str == "" then
        return nil
    end
    local num = tonumber(str)
    if not num then
        error(string.format("%s is not number", str))
    end
    return num
end

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

---@param opts {[string]:any}
---@return WidthOp|nil
local function try_new(opts, command)
    local op, value = opts.args:match("^" .. command .. "%s*([=%+%-])(.*)")
    op = op or "="
    local irow, icol = get_selection(opts)
    return setmetatable({
        args = opts.args,
        command = command,
        operation = map[op],
        number = { get_number(value) },
        irow = irow,
        icol = icol,
    }, WidthOp)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param opts {[string]:any}
---@param command string
---@return WidthOp|nil
function WidthOp.new(opts, command)
    local ok, self = pcall(try_new, opts, command)
    if not ok then
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
        self.irow, self.icol, self.number[1] or "nil", self:to_cmd())
end

---@param self WidthOp
---@param current integer
---@return integer
function WidthOp:apply(current)
    log.probe(self)
    local operation = self.operation
    local count = math.max(self.number[1] or 1, 1)
    if operation == "set" then
        if not self.number[1] or count <= 1 then
            return 0
        else
            return math.max(count, Cell.MIN_WIDTH)
        end
    elseif operation == "add" then
        return current + count
    elseif operation == "sub" then
        return math.max(current - count, Cell.MIN_WIDTH)
    else
        return current
    end
end

---@param self WidthOp
---@return WidthModeState
function WidthOp:get_state()
    return WidthModeState.new(self.opts.mode, self.opts.kind, self.number)
end

return WidthOp
