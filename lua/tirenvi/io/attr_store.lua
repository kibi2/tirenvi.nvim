local buf_lines = require("tirenvi.io.buf_lines") -- IO

local log = require("tirenvi.util.log")           -- Util

-- =============================================================================

local M = {}

-- =============================================================================
-- Public API

---@param bufnr number
---@return Attr[]
function M.read(bufnr)
    return buf_lines.get(bufnr, buf_lines.IKEY.ATTRS) or {}
end

---@param ctx Context
---@param attrs Attr[]|nil
function M.write(ctx, attrs)
    buf_lines.set(ctx.bufnr, buf_lines.IKEY.ATTRS, attrs)
end

return M
