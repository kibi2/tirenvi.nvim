local Parser = require("tirenvi.parser.parser") -- Parser

local buf_state = require("tirenvi.io.buf_state") -- IO

local Document = require("tirenvi.core.document") -- Core

local errors = require("tirenvi.util.errors") -- Util
local log = require("tirenvi.util.log")

-- =============================================================================
local M = {}

---@class Vim_system
---@field code integer
---@field signal? integer
---@field stdout? string
---@field stderr? string

-- =============================================================================
--#region Private

--- Convert flat lines to NDJSON lines
---@param parser Parser
---@param fllines string[]
---@param cursor_buf CursorBuf
---@return string[] NDJSON lines
local function flat_to_jslines(parser, fllines, cursor_buf)
	local options = vim.deepcopy(parser.options) or {}
	if parser.executable == "tir-embedded" then
		options[#options + 1] = "--cursor-line=" .. cursor_buf.row_cur
	end
	local js_string = Parser.run(parser, "parse", options, fllines)
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
				error(
					errors.new_domain_error(
						errors.invalid_json_error(jsline, ndjson)
					)
				)
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
	log.assert(
		ok,
		("tirenvi: internal JSON encode failure\n%s\nerror: %s"):format(
			vim.inspect(ndjson),
			line
		)
	)
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
	local fl_string = Parser.run(parser, "unparse", parser.options, jslines)
	local fllines = vim.split(fl_string, "\n")
	--log.debug(util.to_hex(table.concat(fllines, "\n")):sub(1, 80) .. " ")
	return fllines
end

---@param ndjsons Ndjson[]
local function expand_grid_prefix(ndjsons)
	local prefix
	local is_first = true
	for _, ndjson in ipairs(ndjsons) do
		if ndjson.kind == "grid" then
			if is_first then
				prefix = ndjson.prefix
				is_first = false
			end
			ndjson.prefix = prefix
		else
			prefix = nil
			is_first = true
		end
	end
end

---@param ndjsons Ndjson[]
local function collapse_grid_prefix(ndjsons)
	local is_first = true
	for _, ndjson in ipairs(ndjsons) do
		if ndjson.kind == "grid" then
			if is_first then
				is_first = false
			else
				ndjson.prefix = nil
			end
		else
			is_first = true
		end
	end
end

--#endregion
-- =============================================================================
-- Public API

---@param ctx Context
---@param jslines string[]
---@return Document
function M.from_jslines(ctx, jslines)
	local ndjsons = jslines_to_ndjsons(jslines)
	return Document.new_tirdoc(ndjsons, buf_state.is_allow_plain(ctx.bufnr))
end

---@param parser Parser
---@param r_result ReadResult
---@return Document
function M.parse(parser, r_result)
	local jslines = flat_to_jslines(parser, r_result.lines, r_result.cursor_buf)
	local ndjsons = jslines_to_ndjsons(jslines)
	expand_grid_prefix(ndjsons)
	local allow_plain = parser.allow_plain or false
	local tirdoc = Document.new_tirdoc(ndjsons, allow_plain)
	return tirdoc
end

---@param tirdoc Document
---@return string[]
function M.to_jslines(tirdoc)
	local ndjsons = Document.serialize_to_flat(tirdoc)
	return ndjsons_to_lines(ndjsons)
end

--- Convert display lines back to TSV format
---@param parser Parser
---@param tirdoc Document
---@return string[]
function M.unparse(parser, tirdoc)
	local ndjsons = Document.serialize_to_flat(tirdoc)
	collapse_grid_prefix(ndjsons)
	local jslines = ndjsons_to_lines(ndjsons)
	log.debug(
		"[%d]='%s'...[%d]='%s'",
		1,
		tostring(jslines[1]),
		#jslines,
		tostring(jslines[#jslines])
	)
	return jslines_to_flat(jslines, parser)
end

return M
