--- flat.lua
--- Utility for converting between flat format lines and NDJSON lines using external parsers.
---
--- Purpose:
---   - parse: Convert flat lines to NDJSON via parser command.
---   - unparse: Convert NDJSON to flat lines via parser command.
---
--- Notes:
---   - Errors from parser commands throw domain-specific errors (handled by guard.lua).
---   - Logging at debug level is only active in development mode.
---   - Variable naming convention:
---       fl_: flat format
---       js_: NDJSON format
---       suffix indicates type (string, lines, records, blocks)

----- dependencies
local log = require("tirenvi.log")
local helper = require("tirenvi.helper")
local errors = require("tirenvi.errors")
local ndjsons = require("tir.ndjsons")

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
		log.debug(helper.to_hex(result.stdout):sub(1, 80) .. " ")
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
---@return Record[]
local function js_lines_to_records(js_lines)
	local js_records = {}
	for _, js_line in ipairs(js_lines) do
		if js_line ~= nil and js_line ~= "" then
			local js_record = vim.json.decode(js_line)
			table.insert(js_records, js_record)
		end
	end
	return js_records
end

---@param records Record[]
---@return string[]
local function js_records_to_lines(records)
	local lines = {}
	for _, record in ipairs(records) do
		if record ~= nil then
			local ok, encoded = pcall(vim.json.encode, record)
			if ok then
				table.insert(lines, encoded)
			else
				assert(false, ("tirenvi: failed to encode record\n%s\nerror: %s"):format(vim.inspect(record), encoded))
			end
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
	log.debug(helper.to_hex(table.concat(fl_lines, "\n")):sub(1, 80) .. " ")
	return fl_lines
end

-- public API

---@param fl_lines string[]
---@param parser Parser
---@return Record[]
function M.parse(fl_lines, parser)
	local js_lines = flat_to_js_lines(fl_lines, parser)
	return js_lines_to_records(js_lines)
end

--- Convert display lines back to TSV format
---@param js_records Record[]
---@param parser Parser
---@param file_path string
---@return string[]
function M.unparse(js_records, parser, file_path)
	---@type Record_file_attr
	local file_attr = { kind = ndjsons.FILE_ATTR, version = ndjsons.VERSION, file_path = file_path }
	table.insert(js_records, 1, file_attr)
	log.debug({ #js_records, js_records[1], js_records[#js_records] })
	local js_lines = js_records_to_lines(js_records)
	log.debug({ #js_lines, js_lines[1], js_lines[#js_lines] })
	return js_lines_to_flat(js_lines, parser)
end

return M
