local dirty_range = require("tirenvi.parser.dirty_range") -- Parser
local buf_parser = require("tirenvi.parser.buf_parser")

local LineProvider = require("tirenvi.io.buffer_line_provider") -- IO
local attr_store = require("tirenvi.io.attr_store")
local reader = require("tirenvi.io.reader")
local dirty = require("tirenvi.io.dirty")

local Document = require("tirenvi.core.document") -- Core
local Attrs = require("tirenvi.core.attrs")

local Range3 = require("tirenvi.util.range3") -- Util
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@param r_result ReadResult
---@param bufdoc  Document
---@param range3 Range3
---@return Attr[]
local function reconcile_attrs(r_result, bufdoc, range3)
	Document.inherit_neighbor_attr(bufdoc, r_result.attrs, range3)
	log.watch("ATTR", Document.debug_attrs(bufdoc, "[2]NEIGHBOR:"))
	Document.infer_consistent_attr(bufdoc)
	log.watch("ATTR", Document.debug_attrs(bufdoc, "[3]CONSISTENT:"))
	Document.apply_attrs(bufdoc, r_result.attrs)
	log.watch("ATTR", Document.debug_attrs(bufdoc, "[4]CACHED:"))
	Document.set_max_attr(bufdoc)
	local attrs = Document.replace_attrs(bufdoc, r_result.range, r_result.attrs)
	log.watch("ATTR", Attrs.debug_attrs(attrs, "[6]RESULT:"))
	return attrs
end

---@param bufnr number
---@param attrs Attr[]
---@param range3 Range3
local function reconcile_dirty_ranges(bufnr, attrs, range3)
	local prev_ranges = dirty.get_ranges(bufnr)
	local line_provider = LineProvider.new(bufnr)
	local inv_ranges =
		dirty_range.reconcile(line_provider, prev_ranges, attrs, range3)
	log.watch("INVD", inv_ranges)
	dirty.set_ranges(bufnr, inv_ranges)
end

---@param ctx Context
---@param range3 Range3
---@param r_result ReadResult
local function update_attrs(ctx, range3, r_result)
	r_result.attrs = Attrs.adjust(r_result.attrs, range3)
	log.watch("ATTR", Attrs.debug_attrs(r_result.attrs, "[0]UPDATE CHACHED:"))
	local opts = { range3 = range3, first = r_result.range.first }
	local bufdoc = buf_parser.parse(ctx, r_result, opts)
	log.watch("ATTR", Document.debug_attrs(bufdoc, "[1]DOC ATTR:"))
	local attrs = reconcile_attrs(r_result, bufdoc, range3)
	reconcile_dirty_ranges(ctx.bufnr, attrs, range3)
	attr_store.write(ctx, attrs)
end

--#endregion
-- =============================================================================
-- Public API

---@param ctx Context
---@param range3 Range3
function M.on_lines(ctx, range3)
	local r_result =
		reader.read(ctx, Range3.get_new_range(range3), { cursor = false })
	update_attrs(ctx, range3, r_result)
end

return M
