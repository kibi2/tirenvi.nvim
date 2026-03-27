local config = require("tirenvi.config")
local flat_parser = require("tirenvi.core.flat_parser")
local version = require("tirenvi.version")
local log = require("tirenvi.util.log")

local health = vim.health or require("health")

local M = {}

local function report(item)
	if item.status == "ok" then
		health.ok(item.message)
	elseif item.status == "warn" then
		health.warn(item.message)
	else
		health.error(item.message)
	end
end

local function check_command(exe, required_version)
	local results = flat_parser.check_command(exe, required_version)
	for _, item in ipairs(results) do
		report(item)
	end
end

---@param target integer[]
---@param source integer[]
---@return boolean
local function version_gt(target, source)
	for i = 1, 3 do
		if target[i] > source[i] then
			return true
		elseif target[i] < source[i] then
			return false
		end
	end
	return false
end

function M.check()
	health.start("tirenvi")
	health.info("version: " .. version.VERSION)
	if not config.parser_map or vim.tbl_isempty(config.parser_map) then
		health.warn("No parsers configured.")
		return
	end
	local command_requirements = {}
	for _, parser in pairs(config.parser_map) do
		local exe = parser.executable
		local req = parser.required_version
		if exe then
			if not command_requirements[exe] then
				command_requirements[exe] = req
			elseif req and version_gt(req, command_requirements[exe]) then
				command_requirements[exe] = req
			end
		end
	end
	table.sort(command_requirements, function(prev, next)
		return prev.key < next.key
	end)
	for exe, required_version in pairs(command_requirements) do
		check_command(exe, required_version)
	end
end

return M
