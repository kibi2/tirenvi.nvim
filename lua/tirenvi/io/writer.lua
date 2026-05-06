local buffer = require("tirenvi.io.buffer")
local attr_store = require("tirenvi.io.attr_store")
local Request = require("tirenvi.app.request")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-- private helpers

-- Public API

---@param ctx Context
---@param req Request
function M.write(ctx, req)
    local first, last = Request.vim_range(req)
    log.probe({ first, last })
    buffer.set_lines(ctx.bufnr, req.range, req.lines, req.no_undo)
    attr_store.write(ctx, req)
end

return M
