local api = vim.api -- Neovim

local config = require("tirenvi.config") -- Root

local buf_parser = require("tirenvi.parser.buf_parser") -- Parser
local tir_buf = require("tirenvi.parser.tir_buf")

local Context = require("tirenvi.io.context") -- IO
local buf_state = require("tirenvi.io.buf_state")
local buf_lines = require("tirenvi.io.buf_lines")
local CursorNvim = require("tirenvi.io.cursor_nvim")

local Attrs = require("tirenvi.core.attrs") -- Core

local Range = require("tirenvi.util.range") -- Util
local errors = require("tirenvi.util.errors")
local notify = require("tirenvi.util.notify")
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@param ctx Context
---@param lines string[]
---@param is_around boolean
---@return Range|nil
local function get_col_range(ctx, lines, is_around)
	local count = vim.v.count1
	local cursor_buf = CursorNvim.capture(ctx)
	local attrs = buf_state.get(ctx.bufnr, buf_state.IKEY.ATTRS)
	local attr = Attrs.get(attrs, cursor_buf.row_cur)
	assert(attr ~= nil)
	local cline = buf_lines.get_line(ctx.bufnr, cursor_buf.row_cur) or ""
	local byte_pos = tir_buf.get_pipe_byte_positions(cline)
	if #byte_pos == 0 then
		return nil
	end
	local icol_start =
		tir_buf.get_current_col_index(byte_pos, cursor_buf.col_byte)
	if not icol_start or icol_start == 0 then
		return nil
	end
	icol_start = math.min(icol_start, #byte_pos - 1)
	local tline = lines[1]
	local bline = lines[#lines]
	local tbyte_pos = tir_buf.get_pipe_byte_positions(tline)
	local bbyte_pos = tir_buf.get_pipe_byte_positions(bline)
	local icol_end = icol_start + count
	icol_end = math.min(icol_end, #bbyte_pos)
	local pipe = tir_buf.get_pipe_char(tline)
	return Range.from_lua(
		tbyte_pos[icol_start] + (is_around and 0 or #pipe),
		bbyte_pos[icol_end] - 1
	)
end

---@param is_around boolean
local function setup_visual_block(row_range, is_around)
	local ctx = Context.from_buf()
	local lines =
		buf_lines.get_lines(ctx.bufnr, row_range.first, row_range.last)
	local col_range = get_col_range(ctx, lines, is_around)
	if not col_range then
		return
	end
	if not buf_parser.table_is_aligned(lines) then
		notify.error(errors.ERR.TABLE_IS_NOT_ALIGNED)
		return
	end
	CursorNvim.move_byte(ctx, row_range.first, col_range.first)
	api.nvim_feedkeys(vim.keycode("<C-v>"), "n", false)
	vim.cmd("normal! o")
	CursorNvim.move_byte(ctx, row_range.last, col_range.last)
end

---@return Range|nil
local function get_block_rows()
	local ctx = Context.from_buf()
	local attrs = buf_state.get(ctx.bufnr, buf_state.IKEY.ATTRS)
	if not attrs then
		return
	end
	local cursor_buf = CursorNvim.capture(ctx)
	local attr = Attrs.get(attrs, cursor_buf.row_cur)
	if not attr then
		return nil
	end
	return attr.range
end

---@return Range|nil
local function get_cell_rows()
	local ctx = Context.from_buf()
	local cursor_buf = CursorNvim.capture(ctx)
	return tir_buf.get_continue_range(
		ctx.line_provider,
		Range.from_lua(cursor_buf.row_cur, cursor_buf.row_cur)
	)
end

local function setup_vl(is_around)
	local row_range = get_block_rows()
	if row_range then
		setup_visual_block(row_range, is_around)
	end
end

local function setup_vil()
	setup_vl(false)
end

local function setup_val()
	setup_vl(true)
end

local function setup_vc(is_around)
	local row_range = get_cell_rows()
	if row_range then
		setup_visual_block(row_range, is_around)
	end
end

local function setup_vic()
	setup_vc(false)
end

local function setup_vac()
	setup_vc(true)
end

--#endregion
-- =============================================================================
-- Public API

function M.setup()
	vim.keymap.set({ "x" }, "i" .. config.textobj.column, setup_vil, {
		desc = "Inner column",
	})
	vim.keymap.set({ "x" }, "a" .. config.textobj.column, setup_val, {
		desc = "Around column",
	})
	vim.keymap.set({ "x" }, "i" .. config.textobj.cell, setup_vic, {
		desc = "Inner cell",
	})
	vim.keymap.set({ "x" }, "a" .. config.textobj.cell, setup_vac, {
		desc = "Around cell",
	})
end

return M
