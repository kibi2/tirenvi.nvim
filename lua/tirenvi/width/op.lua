---@class WidthOp
---@field opts {kind:string, mode:string|nil, repeatable:boolean|nil}
---@field args string
---@field count integer
---@field width integer
local WidthOp   = {}
WidthOp.__index = WidthOp

local Cell      = require("tirenvi.core.cell")
local log       = require("tirenvi.util.log")

-- constants / defaults

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

local map       = {
    ["="] = { kind = "set", mode = "fix", repeatable = true },
    ["+"] = { kind = "add", mode = "fix", repeatable = true },
    ["-"] = { kind = "sub", mode = "fix", repeatable = true },
    fit = { kind = "fit", mode = "fit" },
    max = { kind = "max", mode = "max" },
    fix = { kind = "fix", mode = "fix" },
    auto = { kind = "auto", mode = "auto" },
    toggle = { kind = "toggle" }
}

---@param str string
---@return integer|nil
local function get_int(str)
    local num
    if str and str ~= "" then
        num = tonumber(str)
        if not num then
            return nil
        end
    end
    return math.max(num or 0, 1)
end

---@param opts {[string]:any}
---@return WidthOp
function WidthOp.new(opts)
    local self = setmetatable({}, WidthOp)
    self.args = opts.args
    local token, count_str = opts.args:match("^width%s*([=%+%-])(.*)")
    local width, count
    if not token then
        token = opts.fargs[2]
        count = get_int(opts.fargs[3])
        width = get_int(opts.fargs[4])
    else
        count = get_int(count_str)
        width = 0
    end
    if not count or not width then
        return self
    end
    self.opts = map[token]
    self.count = count
    self.width = width
    if self.opts.kind == "set" and self.count <= 1 then
        self.count = 0
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

function WidthOp:to_string()
    return string.format("WidthOp %s:%d %s", self.opts.kind, self.count, self:to_cmd())
end

---@param current integer
---@return integer
function WidthOp:apply(current)
    local kind = self.opts.kind
    if kind == "set" and self.count == 0 then
        return 0
    elseif kind == "set" then
        return math.max(self.count, Cell.MIN_WIDTH)
    elseif kind == "add" then
        return current + self.count
    elseif kind == "sub" then
        return math.max(current - self.count, Cell.MIN_WIDTH)
    else
        return current
    end
end

function WidthOp:get_state()
    local state = { mode = self.opts.mode }
    if self.opts.kind == "fit" then
        state.pages = self.count
        state.width = self.width
    end
    return state
end

return WidthOp
