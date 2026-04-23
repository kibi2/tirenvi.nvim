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
local Document = require("tirenvi.core.document")
local Blocks = require("tirenvi.core.blocks")
local config = require("tirenvi.config")

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

---@param parser Parser
---@return string|nil
local function ensure_command(parser)
	if not parser.required_version or not parser._iversion then
		return "Could not parse " .. parser.executable .. " version string: " .. parser.required_version
	end
	local results = M.check_command(parser)
	for _, item in ipairs(results) do
		if item.status == "error" then
			return item.message
		elseif item.status == "warn" then
			-- notify.warn(item.message)
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
	parser._message = ensure_command(parser)
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

-- public API

---@class HealthItem
---@field status "ok"|"warn"|"error"
---@field message string

---@param parser Parser
---@return HealthItem[]
function M.check_command(parser)
	local results = {}
	-- existence
	if fn.executable(parser.executable) ~= 1 then
		table.insert(results, {
			status = "error",
			message = parser.executable .. " not found in PATH",
		})
		return results
	end
	table.insert(results, {
		status = "ok",
		message = parser.executable .. " found",
	})
	-- version (optional)
	local installed_version = fn.system({ parser.executable, "--version" })
	installed_version = vim.trim(installed_version)
	if vim.v.shell_error ~= 0 then
		table.insert(results, {
			status = "warn",
			message = "Failed to get " .. parser.executable .. " version",
		})
		return results
	end
	local installed = config.version_to_integer(installed_version)
	if not installed then
		table.insert(results, {
			status = "warn",
			message = "Could not parse " .. parser.executable .. " version string."
		})
		return results
	end
	if installed < parser._iversion then
		table.insert(results, {
			status = "error",
			message = string.format(
				"%s >= %s required, but %s found",
				parser.executable,
				parser.required_version,
				installed_version
			),
		})
	else
		table.insert(results, {
			status = "ok",
			message = string.format(
				"%s version %s OK",
				parser.executable,
				installed_version
			),
		})
	end
	return results
end

---@param fl_lines string[]
---@param parser Parser
---@return Document
function M.parse(fl_lines, parser)
	local js_lines = flat_to_js_lines(fl_lines, parser)
	local ndjsons = js_lines_to_ndjsons(js_lines)
	local document = Document.new_from_flat(ndjsons, parser.allow_plain)
	return document
end

--- Convert display lines back to TSV format
---@param document Document	
---@param parser Parser
---@return string[]
function M.unparse(document, parser)
	local ndjsons = Document.serialize_to_flat(document)
	local js_lines = ndjsons_to_lines(ndjsons)
	log.debug({ #js_lines, js_lines[1], js_lines[#js_lines] })
	return js_lines_to_flat(js_lines, parser)
end

return M
