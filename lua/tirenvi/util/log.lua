local ok, logger = pcall(require, "kibi2.logger")

local names = {
	"setup",
	"debug",
	"info",
	"warn",
	"error",
	"probe",
	"watch",
	"assert",
}

if not ok then
	local noop = function() end
	logger = {}
	for _, name in ipairs(names) do
		logger[name] = noop
	end
	logger.new = noop
	logger.is_debug = noop
end

-- =============================================================================

local M = {}
local log = logger.new() or {}

-- =============================================================================
-- Public API

for _, name in ipairs(names) do
	M[name] = function(...)
		logger[name](log, ...)
	end
end

---@return boolean
function M.is_debug()
	return logger.is_debug(log) == true
end

return M
