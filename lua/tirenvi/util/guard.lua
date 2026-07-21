local buf_state = require("tirenvi.io.buf_state") -- IO
local buffer = require("tirenvi.io.buffer")

local errors = require("tirenvi.util.errors") -- Util
local notify = require("tirenvi.util.notify")
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}

-- =============================================================================
-- Public API

--- Wrap a function with guarded error handling.
---@param func fun(...)
---@param opts? { on_error?: fun(err, ...) }
---@return fun(...)
function M.guarded(func, opts)
	opts = opts or {}
	buffer.clear_cache()

	return function(...)
		if buf_state.is_vscode() then
			return
		end
		local args = { ... }

		local ok, result = xpcall(func, function(err)
			if type(err) == "table" and err.tag == errors.DOMAIN_ERROR then
				return err
			end
			return debug.traceback(err, 2)
		end, ...)

		if not ok then
			if opts.on_error then
				opts.on_error(unpack(args), result)
			end

			if type(result) == "table" and result.tag == errors.DOMAIN_ERROR then
				notify.error(result.message)
			else
				notify.error(result)
			end
		end
	end
end

return M
