---@class WidthOp
---@field opts {kind:string, mode:string|nil, repeatable:boolean|nil, change_cell:boolean|nil}
---@field args string
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
    ["="] = { kind = "set", mode = "wrap", repeatable = true, change_cell = true },
    ["+"] = { kind = "add", mode = "wrap", repeatable = true, change_cell = true },
    ["-"] = { kind = "sub", mode = "wrap", repeatable = true, change_cell = true },
    fit = { kind = "fit", mode = "fit" },
    ["fit="] = { kind = "fit", mode = "fit" },
    ["fit+"] = { kind = "fit_add", mode = "fit", repeatable = true },
    ["fit-"] = { kind = "fit_sub", mode = "fit", repeatable = true },
    max = { kind = "max", mode = "max" },
    fix = { kind = "fix", mode = "fix" },
    auto = { kind = "auto", mode = "auto" },
    toggle = { kind = "toggle" },
    wrap = { kind = "toggle" },
    nowrap = { mode = "nowrap" },
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
local function try_new(opts, key)
    local op, value = opts.args:match("^" .. key .. "%s*([=%+%-])(.*)")
    op = op or "="
    local irow, icol = get_selection(opts)
    return setmetatable({
        args = opts.args,
        number = { get_number(value) },
        opts = map[op],
        irow = irow,
        icol = icol,
    }, WidthOp)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param opts {[string]:any}
---@param key string
---@return WidthOp|nil
function WidthOp.new(opts, key)
    local ok, self = pcall(try_new, opts, key)
    if not ok then
        return nil
    end
    return self
end

function WidthOp:to_cmd()
    if self.opts.repeatable then
        return string.format(":<C-u>Tir %s<CR>", self.args)
    else
        return nil
    end
end

---@param self WidthOp
function WidthOp:to_string()
    return string.format("WidthOp %s %s (%d, %d) [%s] %s",
        self.opts.mode, self.opts.kind or "nil",
        self.irow, self.icol, self.number[1] or "nil", self:to_cmd())
end

---@param self WidthOp
---@param current integer
---@return integer
function WidthOp:apply(current)
    local kind = self.opts.kind
    local count = math.max(self.number[1] or 1, 1)
    if kind == "set" then
        if not self.number[1] or count <= 1 then
            return 0
        else
            return math.max(count, Cell.MIN_WIDTH)
        end
    elseif kind == "add" then
        return current + count
    elseif kind == "sub" then
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
