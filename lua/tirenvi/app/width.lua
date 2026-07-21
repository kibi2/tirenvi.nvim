local fn = vim.fn -- Neovim

local common = require("tirenvi.app.common") -- App

local tir_buf = require("tirenvi.parser.tir_buf") -- Parser

local LinProvider = require("tirenvi.io.buffer_line_provider") -- IO
local buf_lines = require("tirenvi.io.buf_lines")
local buf_state = require("tirenvi.io.buf_state")
local attr_store = require("tirenvi.io.attr_store")
local reader = require("tirenvi.io.reader")

local CursorConvert = require("tirenvi.cursor.convert") -- Cursor

local Attrs = require("tirenvi.core.attrs") -- Core
local Attr = require("tirenvi.core.attr")
local Cell = require("tirenvi.core.cell")

local util = require("tirenvi.util.util") -- Util
local Range = require("tirenvi.util.range")
local notify = require("tirenvi.util.notify")
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@class DocToBufLinesOpts
---@field no_undo? boolean
---@field no_normalize? boolean

---@param ctx Context
---@param irow integer
local function expand_rect(ctx, irow)
	local line_provider = LinProvider.new(ctx.bufnr)
	local top = tir_buf.get_block_top_nrow(ctx, line_provider, irow)
	local bottom = tir_buf.get_block_bottom_nrow(ctx, line_provider, irow)
	return Range.from_lua(top, bottom)
end

---@param ctx Context
---@param width_op WidthOp
local function change_wrap_width(ctx, width_op)
	local row_range = expand_rect(ctx, width_op.row_cur)
	local r_result = reader.read(ctx, row_range)
	local bufdoc = common.buflines_to_bufdoc_text_driven(ctx, r_result)
	log.assert(#bufdoc.blocks == 1, "only one block")
	local attr = bufdoc.blocks[1].attr
	if Attr.is_plain(attr) then
		return
	end
	local column = Attr.get(attr, width_op.col_disp)
	column.width = width_op:apply(column.width)
	attr.fit_span = Attr.get_fit_span(attr)
	attr.wrap_mode = "wrap_width"
	common.doc_to_buflines(ctx, r_result, bufdoc)
end

---@param ctx Context
---@param width_op WidthOp
local function change_wrap_fit(ctx, width_op)
	local row_range = expand_rect(ctx, width_op.row_cur)
	local r_result = reader.read(ctx, row_range)
	local bufdoc = common.buflines_to_bufdoc_text_driven(ctx, r_result)
	log.assert(#bufdoc.blocks == 1, "only one block")
	local attr = bufdoc.blocks[1].attr
	if Attr.is_plain(attr) then
		return
	end
	attr.fit_span = width_op:apply(Attr.get_fit_span(attr))
	attr.wrap_mode = "wrap_fit"
	common.doc_to_buflines(ctx, r_result, bufdoc)
end

---@param ctx Context
---@param width_op WidthOp
local function change_wrap_auto(ctx, width_op)
	local row_range = expand_rect(ctx, width_op.row_cur)
	local r_result = reader.read(ctx, row_range)
	local bufdoc = common.buflines_to_bufdoc_text_driven(ctx, r_result)
	log.assert(#bufdoc.blocks == 1, "only one block")
	local attr = bufdoc.blocks[1].attr
	if Attr.is_plain(attr) then
		return
	end
	attr.fit_span = 0
	attr.wrap_mode = "wrap_auto"
	common.doc_to_buflines(ctx, r_result, bufdoc)
end

local MAX_HEAD = 5
---@param bufnr number
---@param attr Attr
---@param icol integer
---@return string
local function get_head(bufnr, attr, icol)
	local irow = attr.range.first
	local line = buf_lines.get_line(bufnr, irow) or ""
	local cells = tir_buf.get_cells(line)
	local head = Cell.remove_padding(cells[icol] or "")
	local head_chars = util.utf8_chars(head)
	if #head_chars > MAX_HEAD then
		head = table.concat(vim.list_slice(head_chars, 1, MAX_HEAD)) .. ".."
	end
	return head
end

local DELTA = 2
---@param attr Attr
---@param logical CursorLogical
---@return string
local function get_col_info(attr, logical)
	local widths = Attr.get_width_array(attr.columns)
	---@cast widths string[]
	widths[logical.icol] = widths[logical.icol] .. "*"
	local first = math.max(1, logical.icol - DELTA)
	local last = math.min(#widths, logical.icol + DELTA)
	local info = table.concat(widths, ",", first, last)
	if first ~= 1 then
		info = "..," .. info
	end
	if last ~= #widths then
		info = info .. ",.."
	end
	return "[" .. info .. "]"
end

---@param bufnr number
---@param attr Attr
---@param logical CursorLogical
---@return string
local function get_width_info(bufnr, attr, logical)
	local mode = Attr.get_wrap_kind(attr)
	local span = Attr.get_fit_span(attr)
	local head = get_head(bufnr, attr, logical.icol)
	local col_info = get_col_info(attr, logical)
	return string.format(
		"mode=%s span=%d col=%d/%d header=%q widths=%s",
		mode,
		span,
		logical.icol,
		#attr.columns,
		head,
		col_info
	)
end

---@param ctx Context
---@param width_op WidthOp
local function width_info(ctx, width_op)
	local attrs = buf_state.get(ctx.bufnr, buf_state.IKEY.ATTRS)
	local logical =
		CursorConvert.to_logical(attrs, width_op.row_cur, width_op.col_disp)
	local attr = attrs[logical.iblock]
	if Attr.is_plain(attr) then
		print("kind=plain")
	else
		print(get_width_info(ctx.bufnr, attr, logical))
	end
end

---@param ctx Context
---@param width_op WidthOp
local function toggle_wrap_mode(ctx, width_op)
	local attrs = attr_store.read(ctx.bufnr)
	local attr = Attrs.get(attrs, width_op.row_cur)
	Attr.toggle_wrap_mode(attr or {})
	attr_store.write(ctx, attrs)
end

local warned = false
---@param command string
local function set_repeat(command)
	local ok = pcall(function()
		fn["repeat#set"](command)
	end)
	if not ok and not warned then
		warned = true
		notify.info("tirenvi: install 'tpope/vim-repeat' to enable '.' repeat")
	end
end

--#endregion
-- =============================================================================
-- Public API

---@param ctx Context
---@param width_op WidthOp
function M.cmd_width(ctx, width_op)
	if width_op.operation == "info" then
		width_info(ctx, width_op)
	else
		change_wrap_width(ctx, width_op)
	end
	set_repeat(util.get_termcodes(width_op:to_cmd()))
end

---@param ctx Context
---@param width_op WidthOp
function M.cmd_fit(ctx, width_op)
	if width_op.operation == "auto" then
		change_wrap_auto(ctx, width_op)
	else
		change_wrap_fit(ctx, width_op)
	end
	set_repeat(util.get_termcodes(width_op:to_cmd()))
end

---@param ctx Context
---@param width_op WidthOp
function M.cmd_wrap(ctx, width_op)
	toggle_wrap_mode(ctx, width_op)
end

return M
