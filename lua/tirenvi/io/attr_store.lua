local buffer = require("tirenvi.io.buffer") -- IO

local log = require("tirenvi.util.log")     -- Util

-- =============================================================================

local M = {}

-- =============================================================================
-- Public API

---@param bufnr number
---@return Attr[]
function M.read(bufnr)
    return buffer.get(bufnr, buffer.IKEY.ATTRS) or {}
end

---@param ctx Context
---@param attrs Attr[]|nil
function M.write(ctx, attrs)
    buffer.set(ctx.bufnr, buffer.IKEY.ATTRS, attrs)
end

return M
