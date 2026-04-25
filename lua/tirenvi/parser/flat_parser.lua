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
local Document = require("tirenvi.core.document")
local Parser = require("tirenvi.parser.parser")
local util = require("tirenvi.util.util")
local errors = require("tirenvi.util.errors")
local log = require("tirenvi.util.log")

-- module
local M = {}

-- constants / defaults

---@class Vim_system
---@field code integer
---@field signal? integer
---@field stdout? string
---@field stderr? string

-- private helpers

--- Convert flat lines to NDJSON lines
---@param fl_lines string[]
---@param parser Parser
---@return string[] NDJSON lines
local function flat_to_js_lines(fl_lines, parser)
	local js_string = Parser.run(parser, "parse", fl_lines)
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
	local fl_string = Parser.run(parser, "unparse", js_lines)
	local fl_lines = vim.split(fl_string, "\n")
	log.debug(util.to_hex(table.concat(fl_lines, "\n")):sub(1, 80) .. " ")
	return fl_lines
end

-- public API

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
