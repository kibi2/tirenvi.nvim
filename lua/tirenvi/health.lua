local Parser = require("tirenvi.core.parser")
local config = require("tirenvi.config")
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

---@class HealthItem
---@field status "ok"|"warn"|"error"
---@field message string

---@param parser Parser
local function check_command(parser)
	local results = {}
	local _, err = Parser.check(parser)
	if err == Parser.ERR.EXECUTABLE_NOT_FOUND then
		report({
			status = "error",
			message = parser.executable .. " not found in PATH",
		})
		return
	end
	table.insert(results, {
		status = "ok",
		message = parser.executable .. " found",
	})
	if err == Parser.ERR.VERSION_COMMAND_FAILED then
		table.insert(results, {
			status = "warn",
			message = "Failed to get " .. parser.executable .. " version",
		})
	end
	if err == Parser.ERR.VERSION_PARSE_FAILED then
		table.insert(results, {
			status = "warn",
			message = "Could not parse " .. parser.executable .. " version string."
		})
	end
	if err == Parser.ERR.VERSION_TOO_OLD then
		table.insert(results, {
			status = "error",
			message = string.format(
				"%s >= %s required, but %s found",
				parser.executable,
				parser.required_version,
				parser._installed_version
			),
		})
	else
		table.insert(results, {
			status = "ok",
			message = string.format(
				"%s version %s OK",
				parser.executable,
				parser._installed_version
			),
		})
	end
	for _, item in ipairs(results) do
		report(item)
	end
end

function M.check()
	health.start("tirenvi")
	health.info("version: " .. version.VERSION)
	pcall(vim.fn["repeat#set"], "")
	if vim.fn.exists("*repeat#set") == 1 then
		vim.health.ok("vim-repeat is available")
	else
		vim.health.warn("vim-repeat not found ('.' repeat disabled)")
	end
	if not config.parser_map or vim.tbl_isempty(config.parser_map) then
		health.warn("No parsers configured.")
		return
	end
	---@type Parser[]
	local command_requirements = {}
	---@type Parser
	for _, parser in pairs(config.parser_map) do
		local exe = parser.executable
		if parser.required_version and not parser._required_version_int then
			report({
				status = "error",
				message = "Could not parse " .. exe .. " version string: " .. parser.required_version,
			})
		elseif exe then
			if not command_requirements[exe] then
				command_requirements[exe] = parser
			elseif parser._required_version_int > command_requirements[exe]._required_version_int then
				command_requirements[exe] = parser
			end
		end
	end
	table.sort(command_requirements, function(prev, next)
		return prev.executable < next.executable
	end)
	for _, parser in pairs(command_requirements) do
		check_command(parser)
	end
end

return M
