--- Table structure validation module.
---
--- Validates pipe-delimited table integrity inside a buffer range.
---

-----------------------------------------------------------------------
-- Dependencies
-----------------------------------------------------------------------

local Context = require("tirenvi.app.context")
local Request = require("tirenvi.app.request")
local Document = require("tirenvi.core.document")
local Blocks = require("tirenvi.core.blocks")
local tir_vim = require("tirenvi.core.tir_vim")
local util = require("tirenvi.util.util")
local Range = require("tirenvi.util.range")
local Range3 = require("tirenvi.util.range3")
local buffer = require("tirenvi.io.buffer")
local writer = require("tirenvi.io.writer")
local reader = require("tirenvi.io.reader")
local buf_state = require("tirenvi.io.buf_state")
local vim_parser = require("tirenvi.parser.vim_parser")
local flat_parser = require("tirenvi.parser.flat_parser")
local invalid = require("tirenvi.io.invalid")
local ui = require("tirenvi.ui")
local log = require("tirenvi.util.log")

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

local api = vim.api
local fn = vim.fn
-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------


------ Adjust an empty line based on the previous block context.
---
--- If a new line is added below a table, it is treated as a grid row,
--- so an empty line is converted into an empty table row ("||").
---
--- If a new line is added above a table, it is treated as a plain line,
--- so no modification is applied.
---@param vi_lines string[]
---@param line_prev string|nil
local function normalize_trailing_empty_line(vi_lines, line_prev)
	if not line_prev then
		return
	end
	for iline = 1, #vi_lines do
		local pipe = tir_vim.get_pipe_char(line_prev)
		if vi_lines[iline] == "" and pipe then
			vi_lines[iline] = pipe .. pipe
		end
		line_prev = vi_lines[iline]
	end
end

---@param ctx Context
---@param range RangeLike
---@return Document
---@return Request
local function build_document(ctx, range)
	local req = Request.from_range(range)
	local vi_lines = reader.read(ctx, req)
	local prev0 = range:to_vim() - 1
	local line_prev = buffer.get_line(ctx.bufnr, prev0)
	normalize_trailing_empty_line(vi_lines, line_prev)
	return vim_parser.parse(ctx, req, true), req
end

---@param bufnr number
---@param range Range
---@return Attr|nil
---@return Attr|nil
local function resolve_reference_attrs(bufnr, range)
	local range_vim = Range.from_lua(range.first - 1, range.last)
	local line_prev, line_next = buffer.get_lines_around(bufnr, range_vim)
	local first0 = range:to_vim()
	local target = buffer.get_line(bufnr, first0)
	log.debug("[prev] %s [target] %s [next] %s", tostring(line_prev), tostring(target), tostring(line_next))
	local attr_prev = vim_parser.parse_to_attr(line_prev)
	local attr_next = vim_parser.parse_to_attr(line_next)
	log.debug({ attr_prev, attr_next })
	return attr_prev, attr_next
end

---@param ctx Context
---@param range Range
---@return string[]
local function apply_range(ctx, range)
	log.debug("===-===-===-=== reconcile start%s ===-===-===-===", range:short())
	local attr_prev, attr_next = resolve_reference_attrs(ctx.bufnr, range)
	local range = Range.from_vim(range.first - 1, range.last)
	local document, req = build_document(ctx, range)
	local blocks = document.blocks
	log.debug(#blocks ~= 0 and blocks[1].records)
	log.debug(#blocks ~= 0 and blocks[1].records[1])
	local success, reason = Document.reconcile(document, attr_prev, attr_next)
	log.debug(#blocks ~= 0 and blocks[1].attr)
	log.debug(#blocks ~= 0 and blocks[1].records[1])
	if not success then
		log.debug("===-===-===-=== not success: %s", reason)
		if reason == "grid in plain" then
			return flat_parser.unparse(ctx, document)
		elseif reason == "conflict" then
			document, req = build_document(ctx, Range.WHOLE)
		else
			error("repair: unexpected error: " .. tostring(reason))
		end
	end
	return vim_parser.unparse(document, req)
end

---@param ctx Context
---@param ranges Range[]
local function apply_ranges(ctx, ranges)
	for index = #ranges, 1, -1 do
		local range = Range.from_vim(ranges[index].first, ranges[index].last + 1)
		local new_lines = apply_range(ctx, range)
		local req = Request.from_lines(range, new_lines, nil, true)
		writer.write(ctx, req)
	end
end

local function log_watch(bufnr, message, range3, ext_range)
	range3 = range3 or Range3.new(0, 0, 0)
	local pre = buffer.get(bufnr, buffer.IKEY.UNDO_TREE_LAST)
	local next = fn.undotree(bufnr).seq_last
	local no_ext = ext_range and (#ext_range ~= 0 and "/ext" .. #ext_range .. ext_range[1]:short() or "") or ""
	local status = string.format(
		"[tree:%d->%d]%s%s",
		pre,
		next,
		range3:short(),
		no_ext
	)
	log.watch("UNDO", message .. status)
end

---@param bufnr number
---@param range Range
local function expand_continue_lines(bufnr, range)
	local ctx = Context.from_buf(bufnr)
	local req = Request.from_range(Range.from_vim(range.first, range.last))
	local lines = reader.read(ctx, req)
	local first = range.first - 1
	local first_line = buffer.get_line(bufnr, first)
	while tir_vim.is_continue_line(first_line) do
		first = first - 1
		first_line = buffer.get_line(bufnr, first)
	end
	range.first = first + 1
	---@type string|nil
	local last_line = lines[#lines]
	local last = range.last
	while tir_vim.is_continue_line(last_line) or last_line == "" do
		last_line = buffer.get_line(bufnr, last)
		last = last + 1
	end
	range.last = last - 1
end

---@param ctx Context
---@param ext_ranges Range
local function apply_extra_ranges(ctx, ext_ranges)
	apply_ranges(ctx, ext_ranges)
end

local local_range = nil
---@param ctx Context
local function apply_local_range(ctx)
	apply_ranges(ctx, { local_range })
	local_range = nil
end

---@param ctx Context
---@param ext_ranges Range
local function schedule_extra_ranges(ctx, ext_ranges)
	vim.schedule(function()
		apply_extra_ranges(ctx, ext_ranges)
	end)
end

---@param ctx Context
---@param new_range Range
local function schedule_new_range(ctx, new_range)
	if local_range == nil then
		vim.schedule(function()
			apply_local_range(ctx)
		end)
		local_range = new_range
	else
		log.watch("UNDO", ctx.bufnr, { "muli time on_lines", local_range })
		Range.union({ local_range, new_range })
	end
end

---@param ctx Context
---@param range3 Range3|nil
local function handle_request(ctx, range3)
	local bufnr = ctx.bufnr
	local ext_ranges = invalid.get_range(bufnr)
	ui.diagnostic_clear(bufnr)
	if not range3 then
		log_watch(bufnr, "INSERT LEAVE", nil, ext_ranges)
		schedule_extra_ranges(ctx, ext_ranges)
		return
	end
	local new_range = Range3.get_new_range(range3)
	---@cast new_range Range
	expand_continue_lines(bufnr, new_range)
	if buf_state.is_insert_mode(bufnr) then
		-- Modifying the buffer in insert mode may corrupt the undo node.
		-- Therefore, in insert mode, only record the invalid changed region
		-- and repair it when leaving insert mode.
		log_watch(bufnr, "INSERT", range3)
		ext_ranges[#ext_ranges + 1] = new_range
		ui.diagnostic_set(bufnr, Range.union(ext_ranges))
	elseif buf_state.is_undo_mode(bufnr) then
		-- Moving the cursor in insert mode may create an invalid table undo node.
		-- Therefore, when performing undo/redo, skip table validation.
		log_watch(bufnr, "UNDO/REDO", range3)
		ext_ranges[#ext_ranges + 1] = new_range
		ui.diagnostic_set(bufnr, Range.union(ext_ranges))
	elseif #ext_ranges ~= 0 then
		log_watch(bufnr, "UNDO/REDO LEAVE", range3, ext_ranges)
		schedule_extra_ranges(ctx, ext_ranges)
		schedule_new_range(ctx, new_range)
	else
		log_watch(bufnr, "NORMAL", range3, ext_ranges)
		schedule_new_range(ctx, new_range)
	end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param ctx Context
---@param range3 Range3|nil
function M.handle(ctx, range3)
	-- log.debug(debug.traceback())
	local bufnr = ctx.bufnr
	vim.schedule(function()
		if not api.nvim_buf_is_valid(bufnr) then
			return
		end
		if api.nvim_get_current_buf() ~= bufnr then
			return
		end
		local ok, err = xpcall(
			function()
				handle_request(ctx, range3)
			end,
			debug.traceback
		)
		if not ok then
			error(err)
		end
	end)
end

return M
