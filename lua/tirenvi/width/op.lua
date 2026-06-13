---@class WidthOp
---@field opts {kind:string, mode:string|nil, repeatable:boolean|nil}
---@field args string
---@field count integer|nil
---@field width integer|nil
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
---@return WidthOp
local function try_new(opts)
    local self = setmetatable({}, WidthOp)
    self.args = opts.args
    local token, count_str = opts.args:match("^width%s*([=%+%-])(.*)")
    if token then
        self.count = get_int(count_str)
        self.width = nil
    else
        token = opts.fargs[2]
        self.count = get_int(opts.fargs[3])
        self.width = get_int(opts.fargs[4])
    end
    self.opts = map[token]
    return self
end

---@param opts {[string]:any}
---@return WidthOp
function WidthOp.new(opts)
    local ok, self = pcall(try_new, opts)
    if not ok then
        return {}
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
    return string.format("WidthOp %s[%s,%s] %s", self.opts.kind, self.count or "nil", self.width or "nil", self:to_cmd())
end

---@param current integer
---@return integer
function WidthOp:apply(current)
    local kind = self.opts.kind
    local count = self.count or 1
    if kind == "set" then
        if not self.count or count <= 1 then
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

function WidthOp:get_state()
    local state = { mode = self.opts.mode }
    if self.opts.kind == "fit" then
        state.pages = self.count
        state.width = self.width
    end
    return state
end

return WidthOp
