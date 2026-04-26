local buffer = require("tirenvi.io.buffer")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-- private helpers

-- Public API

---@param ctx Context
---@param req Request
function M.write(ctx, req)
    buffer.set_lines(ctx.bufnr, req.range, req.lines, req.no_undo)
end

return M
