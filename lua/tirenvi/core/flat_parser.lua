--- Utility for converting between flat format lines and NDJSON lines using external parsers.
---
--- Purpose:
---   - parse: Convert flat lines to NDJSON via parser command.
---   - unparse: Convert NDJSON to flat lines via parser command.
---
--- Notes:
---   - Errors from parser commands throw domain-specific errors (handled by guard.lua).
---   - Logging at debug level is only active in development mode.

----- dependencies
local log = require("tirenvi.util.log")
local util = require("tirenvi.util.util")
local errors = require("tirenvi.util.errors")
local Blocks = require("tirenvi.core.blocks")

local fn = vim.fn

-- module
local M = {}

-- constants / defaults

---@class Vim_system
---@field code integer
---@field signal? integer
---@field stdout? string
---@field stderr? string

-- private helpers

---@param command string[]
---@param input string[]
---@return Vim_system
local function vim_system(command, input)
	log.debug("=== === === [exec] %s === === ===", table.concat(command, " "))
	local result = vim.system(command, { stdin = input }):wait()
	if result.stdout and #result.stdout > 0 then
		log.debug(util.to_hex(result.stdout):sub(1, 80) .. " ")
	end
	return result
end

---@param exe string
---@param required_version integer[]|nil
---@return string|nil
local function ensure_command(exe, required_version)
	local results = M.check_command(exe, required_version)
	for _, item in ipairs(results) do
		if item.status == "error" then
			return item.message
		elseif item.status == "warn" then
			-- vim.notify(item.message, vim.log.levels.WARN)
		end
	end
	return nil
end

---@param parser table
local function ensure_parser(parser)
	if parser._checked then
		if not parser._ok then
			error(errors.new_domain_error(parser._message))
		end
		return
	end
	parser._message = ensure_command(parser.executable, parser.required_version)
	parser._checked = true
	parser._ok = parser._message == nil
	if parser._message then
		error(errors.new_domain_error(parser._message))
	end
end

--- run external parser command
---@param executable string Parser command
---@param subcmd string Subcommand ("parse" or "unparse")
---@param options string[] Command options
---@param lines string[] Input lines
---@return string stdout
local function run_parser(executable, subcmd, options, lines)
	local command = { executable, subcmd }
	if options then
		vim.list_extend(command, options)
	end
	local result = vim_system(command, lines)
	if result.code ~= 0 then
		error(errors.new_domain_error(errors.vim_system_error(result, command)))
	end
	return result.stdout
end

--- Convert flat lines to NDJSON lines
---@param fl_lines string[]
---@param parser Parser
---@return string[] NDJSON lines
local function flat_to_js_lines(fl_lines, parser)
	ensure_parser(parser)
	local js_string = run_parser(parser.executable, "parse", parser.options, fl_lines)
	return vim.split(js_string, "\n", { plain = true })
end

---@param js_lines  string[]
---@return Ndjson[]
local function js_lines_to_ndjsons(js_lines)
	local ndjsons = {}
	for _, js_line in ipairs(js_lines) do
		if js_line ~= nil and js_line ~= "" then
			local ok, ndjson = pcall(vim.json.decode, js_line)
			if not ok then
				error(errors.new_domain_error(errors.invalid_json_error(js_line, ndjson)))
			end
			ndjsons[#ndjsons + 1] = ndjson
		end
	end
	return ndjsons
end

---@param ndjson Ndjson
---@return string|nil
local function ndjson_to_line(ndjson)
	if ndjson == nil then
		return nil
	end
	local ok, line = pcall(vim.json.encode, ndjson)
	assert(ok, ("tirenvi: internal JSON encode failure\n%s\nerror: %s"):format(vim.inspect(ndjson), line))
	return line
end

---@param ndjsons Ndjson[]
---@return string[]
local function ndjsons_to_lines(ndjsons)
	local lines = {}
	for _, record in ipairs(ndjsons) do
		local line = ndjson_to_line(record)
		if line ~= nil then
			lines[#lines + 1] = line
		end
	end
	return lines
end

--- Convert NDJSON lines to flat lines
---@param js_lines string[]
---@param parser Parser
---@return string[] flat lines
local function js_lines_to_flat(js_lines, parser)
	local fl_string = run_parser(parser.executable, "unparse", parser.options, js_lines)
	local fl_lines = vim.split(fl_string, "\n")
	log.debug(util.to_hex(table.concat(fl_lines, "\n")):sub(1, 80) .. " ")
	return fl_lines
end

---@param str string
---@return integer[]|nil
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

-- public API

---@param fl_lines string[]
---@param parser Parser
---@return Blocks
function M.parse(fl_lines, parser)
	local js_lines = flat_to_js_lines(fl_lines, parser)
	local ndjsons = js_lines_to_ndjsons(js_lines)
	local blocks = Blocks.new_from_flat(ndjsons)
	if not parser.allow_plain then
		Blocks.merge_blocks(blocks)
	end
	return blocks
end

--- Convert display lines back to TSV format
---@param blocks Blocks
---@param parser Parser
---@return string[]
function M.unparse(blocks, parser)
	local ndjsons = Blocks.serialize_to_flat(blocks)
	local js_lines = ndjsons_to_lines(ndjsons)
	log.debug({ #js_lines, js_lines[1], js_lines[#js_lines] })
	return js_lines_to_flat(js_lines, parser)
end

---@class HealthItem
---@field status "ok"|"warn"|"error"
---@field message string

---@param exe string
---@param required_version integer[]|nil
---@return HealthItem[]
function M.check_command(exe, required_version)
	local results = {}
	-- existence
	if fn.executable(exe) ~= 1 then
		table.insert(results, {
			status = "error",
			message = exe .. " not found in PATH",
		})
		return results
	end
	table.insert(results, {
		status = "ok",
		message = exe .. " found",
	})
	-- version (optional)
	if not required_version then
		return results
	end
	local output = fn.system({ exe, "--version" })
	if vim.v.shell_error ~= 0 then
		table.insert(results, {
			status = "warn",
			message = "Failed to get " .. exe .. " version",
		})
		return results
	end
	local installed = parse_version(output)
	if not installed then
		table.insert(results, {
			status = "warn",
			message = "Could not parse version string: " .. output,
		})
		return results
	end
	if version_lt(installed, required_version) then
		table.insert(results, {
			status = "error",
			message = string.format(
				"%s >= %d.%d.%d required, but %d.%d.%d found",
				exe,
				required_version[1],
				required_version[2],
				required_version[3],
				installed[1],
				installed[2],
				installed[3]
			),
		})
	else
		table.insert(results, {
			status = "ok",
			message = string.format(
				"%s version %d.%d.%d OK",
				exe,
				installed[1],
				installed[2],
				installed[3]
			),
		})
	end
	return results
end

return M
