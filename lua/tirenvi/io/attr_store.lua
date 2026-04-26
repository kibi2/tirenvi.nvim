local buffer = require("tirenvi.io.buffer")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults

-- private helpers

---@return Ndjson

-- Public API

---@param request Request
function M.write(request)
    if not request.attrs then
        return
    end
    buffer.set(request.context.bufnr, buffer.IKEY.ATTRS, request.attrs)
end

return M
