local config = require("tirenvi.config")
local version = require("tirenvi.version")

local health = vim.health or require("health")

local M = {}

local fn = vim.fn
local REQUIRED_VERSION_FMT = "%d.%d.%d"

---@param str string
---@return integer[] | nil
local function parse_version(str)
	local major, minor, patch = str:match("(%d+)%.(%d+)%.(%d+)")
	if not major then
		return nil
	end
	return { tonumber(major), tonumber(minor), tonumber(patch) }
end

---@param install integer[]
---@param require integer[]
---@return boolean
local function version_lt(install, require)
	for i = 1, 3 do
		if install[i] < require[i] then
			return true
		elseif install[i] > require[i] then
			return false
		end
	end
	return false
end

---@param exe string
---@param required_version {[string]:string}
local function check_command(exe, required_version)
	if fn.executable(exe) ~= 1 then
		health.error(exe .. " not found in PATH.", {
			"Install it and ensure it is in your PATH.",
			"Check with: which " .. exe,
		})
		return
	end

	health.ok(exe .. " found")

	if not required_version then
		return
	end

	local output = fn.system({ exe, "--version" })

	if vim.v.shell_error ~= 0 then
		health.warn("Failed to get " .. exe .. " version.")
		return
	end

	local installed = parse_version(output)

	if not installed then
		health.warn("Could not parse " .. exe .. " version string: " .. output)
		return
	end

	if version_lt(installed, required_version) then
		health.error(
			string.format(
				"%s >= " .. REQUIRED_VERSION_FMT .. " required, but %d.%d.%d found.",
				exe,
				required_version[1],
				required_version[2],
				required_version[3],
				installed[1],
				installed[2],
				installed[3]
			)
		)
	else
		health.ok(string.format("%s version %d.%d.%d OK", exe, installed[1], installed[2], installed[3]))
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
	for exe, required_version in pairs(command_requirements) do
		check_command(exe, required_version)
	end
end

return M
