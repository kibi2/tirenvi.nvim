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

---@param parser Parser
local function check_command(parser)
	local results = flat_parser.check_command(parser)
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
	local command_requirements = {}
	for _, parser in pairs(config.parser_map) do
		local exe = parser.executable
		if not parser._iversion then
			report({
				status = "error",
				message = "Could not parse " .. exe .. " version string: " .. parser.required_version,
			})
		elseif exe then
			if not command_requirements[exe] then
				command_requirements[exe] = parser
			elseif parser._iversion > command_requirements[exe]._iversion then
				command_requirements[exe] = parser
			end
		end
	end
	table.sort(command_requirements, function(prev, next)
		return prev.key < next.key
	end)
	for _, parser in pairs(command_requirements) do
		check_command(parser)
	end
end

return M
