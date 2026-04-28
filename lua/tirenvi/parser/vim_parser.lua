-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

----- dependencies
local config = require("tirenvi.config")
local CONST = require("tirenvi.constants")
local Document = require("tirenvi.core.document")
local Blocks = require("tirenvi.core.blocks")
local Record = require("tirenvi.core.record")
local Attr = require("tirenvi.core.attr")
local tir_vim = require("tirenvi.core.tir_vim")
local Context = require("tirenvi.app.context")
local log = require("tirenvi.util.log")

local M = {}

-- constants / defaults
local pipen = config.marks.pipe
local pipec = config.marks.pipec
-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param ndjsons Ndjson[]
---@return string[]
local function to_lines(ndjsons)
	local tir_vim = {}
	for _, record in ipairs(ndjsons) do
		local kind = record.kind
		if kind == CONST.KIND.PLAIN then
			tir_vim[#tir_vim + 1] = record.line or ""
		elseif kind == CONST.KIND.GRID then
			local pipe = record._has_continuation and pipec or pipen
			local row_items = record.row
			local row = table.concat(row_items, pipe)
			row = pipe .. row .. pipe
			tir_vim[#tir_vim + 1] = row
		end
	end
	return tir_vim
end

---@param vi_line string
---@return Record
local function tir_vim_to_ndjson(vi_line)
	local pipe = tir_vim.get_pipe_char(vi_line)
	if pipe then
		return Record.grid.new_from_vi_line(vi_line, pipe == pipec)
	else
		return Record.plain.new_from_vi_line(vi_line)
	end
end

---@param vi_lines string[]
---@return Record[]
local function tir_vim_to_ndjsons(vi_lines)
	local records = {}
	for index = 1, #vi_lines do
		records[index] = tir_vim_to_ndjson(vi_lines[index])
	end
	return records
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param req Request
---@param no_normalize boolean|nil  -- If true, skip nomalizing.
-- Prevents line count changes that would break put(); used for repair.
---@return Document
function M.parse(ctx, req, no_normalize)
	no_normalize = no_normalize or false
	local allow_plain = Context.is_allow_plain(ctx)
	local records = tir_vim_to_ndjsons(req.lines)
	log.probe(req.attrs)
	return Document.new_from_vim(records, req.attrs, allow_plain, no_normalize)
end

---@param req Request
---@param document Document
---@return string[]
function M.unparse(req, document)
	Document.to_vim(document)
	local ndjsons = Document.serialize(document)
	Document.rebuild_attr_range(document, req.range.first)
	log.probe(Document.collect_attrs(document))
	return to_lines(ndjsons)
end

---@param vi_line string|nil
---@return Attr|nil
function M.parse_to_attr(vi_line)
	if not vi_line then
		return nil
	end
	local record = tir_vim_to_ndjson(vi_line)
	return Attr[record.kind].new_from_record(record.row)
end

return M
