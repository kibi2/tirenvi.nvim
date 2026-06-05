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
local Context = require("tirenvi.app.context")
local Parser = require("tirenvi.parser.parser")
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
---@param fllines string[]
---@param parser Parser
---@return string[] NDJSON lines
local function flat_to_jslines(fllines, parser)
	local js_string = Parser.run(parser, "parse", fllines)
	return vim.split(js_string, "\n", { plain = true })
end

---@param jslines  string[]
---@return Ndjson[]
local function jslines_to_ndjsons(jslines)
	local ndjsons = {}
	for _, jsline in ipairs(jslines) do
		if jsline ~= nil and jsline ~= "" then
			local ok, ndjson = pcall(vim.json.decode, jsline)
			if not ok then
				error(errors.new_domain_error(errors.invalid_json_error(jsline, ndjson)))
			end
			ndjsons[#ndjsons + 1] = ndjson
		end
	end
	return ndjsons
end

---@param ndjson Ndjson
---@return string|nil
local function ndjson_to_line(ndjson)
	local ok, line = pcall(vim.json.encode, ndjson)
	log.assert(ok, ("tirenvi: internal JSON encode failure\n%s\nerror: %s"):format(vim.inspect(ndjson), line))
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
---@param jslines string[]
---@param parser Parser
---@return string[] flat lines
local function jslines_to_flat(jslines, parser)
	local fl_string = Parser.run(parser, "unparse", jslines)
	local fllines = vim.split(fl_string, "\n")
	--log.debug(util.to_hex(table.concat(fllines, "\n")):sub(1, 80) .. " ")
	return fllines
end

-- public API

---@param ctx Context
---@param r_result ReadResult
---@return Document
function M.parse(ctx, r_result)
	local jslines = flat_to_jslines(r_result.lines, ctx.parser)
	local ndjsons = jslines_to_ndjsons(jslines)
	return Document.new_tirdoc(ndjsons, Context.is_allow_plain(ctx))
end

--- Convert display lines back to TSV format
---@param ctx Context
---@param tirdoc Document	
---@return string[]
function M.unparse(ctx, tirdoc)
	local ndjsons = Document.serialize_to_flat(tirdoc)
	local jslines = ndjsons_to_lines(ndjsons)
	log.debug("[%d]='%s'...[%d]='%s'", 1, tostring(jslines[1]), #jslines, tostring(jslines[#jslines]))
	return jslines_to_flat(jslines, ctx.parser)
end

return M
