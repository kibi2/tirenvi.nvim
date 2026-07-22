local buf_state = require("tirenvi.io.buf_state")

local log = require("tirenvi.util.log") -- Util

-- =============================================================================

local M = {}

-- =============================================================================
-- Public API

---@param bufnr number
---@return Attr[]
function M.read(bufnr)
	return buf_state.get(bufnr, buf_state.IKEY.ATTRS) or {}
end

---@param ctx Context
---@param attrs Attr[]|nil
function M.write(ctx, attrs)
	buf_state.set(ctx.bufnr, buf_state.IKEY.ATTRS, attrs)
end

return M
