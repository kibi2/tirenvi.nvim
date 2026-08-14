local fn = vim.fn -- Neovim

local tir_buf = require("tirenvi.parser.tir_buf") -- Parser
local Cursor = require("tirenvi.parser.cursor")

local buf_state = require("tirenvi.io.buf_state") -- IO
local reader = require("tirenvi.io.reader")
local Context = require("tirenvi.io.context")

local Attr = require("tirenvi.core.attr") -- Core

local log = require("tirenvi.util.log") -- Util

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@return string
local function get_pipe()
	local ctx = Context.from_buf()
	local cursor_buf = reader.cursor_buf(ctx)
	return tir_buf.get_pipe_char(cursor_buf.line) or ""
end

---@param op string
---@return function
local function build_motion(op)
	return function()
		local pipe = get_pipe()
		if #pipe == 0 then
			return "<Esc>"
		end
		return op .. pipe
	end
end

---@param top boolean
---@return string
local function get_block_motion(top)
	local ctx = Context.from_buf()
	local attrs = buf_state.get(ctx.bufnr, buf_state.IKEY.ATTRS)
	if not attrs then
		return "<Esc>"
	end
	if vim.fn.mode(1) == "no" and vim.v.count1 ~= 1 then
		return "<Esc>"
	end
	local cursor_buf = reader.cursor_buf(ctx)
	local pos = Cursor.to_tir(attrs, cursor_buf)
	local count = vim.v.count1 - 1
	if cursor_buf.row_cur == Attr.boundary_row(attrs[pos.iblock], top) then
		count = count + 1
	end
	local iblock = top and math.max(pos.iblock - count, 1)
		or math.min(pos.iblock + count, #attrs)
	local next_row = Attr.boundary_row(attrs[iblock], top)
	local motion = string.format("%dG%d|", next_row, cursor_buf.col_disp)
	if vim.v.count1 ~= 1 then
		motion = "|" .. motion
	end
	return motion
end

---@param line_provider LineProvider
---@param cursor_buf CursorBuf
---@param next boolean
---@return integer|nil
---@return integer|nil
local function get_cell_row_col(line_provider, cursor_buf, next)
	local cline = cursor_buf.line or ""
	local row_cur = cursor_buf.row_cur
	local cbyte_pos = tir_buf.get_pipe_byte_positions(cline)
	if #cbyte_pos == 0 then
		return
	end
	local icol_start =
		tir_buf.get_current_col_index(cbyte_pos, cursor_buf.col_byte)
	if not icol_start then
		return
	end
	local icol_next = icol_start + vim.v.count1 * (next and 1 or -1)
	while icol_next > #cbyte_pos or icol_next <= 0 do
		if vim.fn.mode(1) == "no" then
			return
		end
		local row_next = row_cur + (next and 1 or -1)
		local line_next = line_provider.get_line(row_next) or ""
		local cbyte_next = tir_buf.get_pipe_byte_positions(line_next)
		if #cbyte_next == 0 then
			icol_next = next and #cbyte_pos or 1
			break
		end
		icol_next = icol_next + (next and -#cbyte_pos or #cbyte_next)
		row_cur = row_next
		cbyte_pos = cbyte_next
		cline = line_next
	end
	local next_byte = cbyte_pos[icol_next]
	local part = string.sub(cline, 1, next_byte - 1)
	local next_pos = fn.strdisplaywidth(part) + 1
	return row_cur, next_pos
end

---@param next boolean
---@return string
local function get_cell_motion(next)
	local ctx = Context.from_buf()
	local attrs = buf_state.get(ctx.bufnr, buf_state.IKEY.ATTRS)
	if not attrs then
		return "<Esc>"
	end
	if vim.fn.mode(1) == "no" and vim.v.count1 ~= 1 then
		return "<Esc>"
	end
	local cursor_buf = reader.cursor_buf(ctx)
	local row_cur, next_pos =
		get_cell_row_col(ctx.line_provider, cursor_buf, next)
	if not row_cur then
		return "<Esc>"
	end
	local motion = string.format("%d|%dG", next_pos, row_cur)
	if vim.v.count1 ~= 1 then
		motion = "|" .. motion
	end
	return motion
end

--#endregion
-- =============================================================================
-- Public API

M.f = build_motion("f")
M.F = build_motion("F")
M.t = build_motion("t")
M.T = build_motion("T")

function M.block_top()
	return get_block_motion(true)
end

function M.block_bottom()
	return get_block_motion(false)
end

function M.cell_next()
	return get_cell_motion(true)
end

function M.cell_prev()
	return get_cell_motion(false)
end

return M
