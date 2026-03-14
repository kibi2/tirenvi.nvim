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

--- run external parser command
---@param executable string Parser command
---@param subcmd string Subcommand ("parse" or "unparse")
---@param options string[] Command options
---@param lines string[] Input lines
---@return string stdout
local function run_parser(executable, subcmd, options, lines)
	local command = { executable, subcmd }
	vim.list_extend(command, options)
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
---@return string | nil
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

---@param fl_lines string[]
---@param parser Parser
---@return Blocks
function M.parse(fl_lines, parser)
	local js_lines = flat_to_js_lines(fl_lines, parser)
	local ndjsons = js_lines_to_ndjsons(js_lines)
	local blocks = Blocks.new_from_flat(ndjsons)
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

return M
