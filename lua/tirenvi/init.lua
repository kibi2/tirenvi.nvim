----- dependencies
local config = require("tirenvi.config")
local buf_state = require("tirenvi.state.buf_state")
local util = require("tirenvi.util.util")
local reconcile = require("tirenvi.core.reconcile")
local log = require("tirenvi.util.log")
local buffer = require("tirenvi.state.buffer")
local flat_parser = require("tirenvi.core.flat_parser")
local vim_parser = require("tirenvi.core.vim_parser")
local tir_vim = require("tirenvi.core.tir_vim")
local Blocks = require("tirenvi.core.blocks")
local ui = require("tirenvi.ui")
local notify = require("tirenvi.util.notify")

-- module
local M = {}

local api = vim.api
local fn = vim.fn
local bo = vim.bo
-- constants / defaults
M.motion = require("tirenvi.editor.motion")

-- private helpers

---@param bufnr number
---@param blocks Blocks
local function store_widths(bufnr, blocks)
	buffer.set(bufnr, buffer.IKEY.WIDTHS, Blocks.get_widths(blocks))
end

---@param bufnr number
---@param blocks Blocks
local function restore_widths(bufnr, blocks)
	local widths = buffer.get(bufnr, buffer.IKEY.WIDTHS)
	Blocks.set_widths(blocks, widths)
	buffer.set(bufnr, buffer.IKEY.WIDTHS, nil)
end

---@param bufnr number Buffer number.
---@param is_toggle boolean|nil
---@return nil
local function to_flat(bufnr, is_toggle)
	is_toggle = is_toggle or false
	if not buf_state.is_tir_vim(bufnr) then
		return
	end
	local parser = util.get_parser(bufnr)
	local vi_lines = buffer.get_lines(bufnr, 0, -1)
	local blocks = vim_parser.parse(vi_lines)
	if is_toggle then
		store_widths(bufnr, blocks)
	end
	log.debug(blocks[1].records)
	local fl_lines = flat_parser.unparse(blocks, parser)
	ui.set_lines(bufnr, 0, -1, fl_lines)
end

---@param bufnr number Buffer number.
---@param no_undo boolean|nil
---@return nil
local function from_flat(bufnr, no_undo)
	local fl_lines = buffer.get_lines(bufnr, 0, -1)
	local parser = util.get_parser(bufnr)
	util.assert_no_reserved_marks(fl_lines)
	local blocks = flat_parser.parse(fl_lines, parser)
	restore_widths(bufnr, blocks)
	local vi_lines = vim_parser.unparse(blocks)
	ui.set_lines(bufnr, 0, -1, vi_lines, no_undo)
end

---@return integer|nil
---@return integer|nil
local function get_current_col()
	local irow, ibyte0 = unpack(api.nvim_win_get_cursor(0))
	local ibyte = ibyte0 + 1
	local cline = buffer.get_line(0, irow - 1) or ""
	local pipe_pos = tir_vim.get_pipe_byte_position(cline)
	if #pipe_pos == 0 then
		return nil, nil
	end
	return irow, tir_vim.get_current_col_index(pipe_pos, ibyte)
end

---@param row Range
---@return number
---@return Blocks
local function get_blocks(row)
	local bufnr = api.nvim_get_current_buf()
	local lines = buffer.get_lines(bufnr, row.first - 1, row.last)
	return bufnr, vim_parser.parse(lines)
end

---@param line_provider LineProvider
---@param irow integer
local function get_range(line_provider, irow)
	local top = tir_vim.get_block_top_nrow(line_provider, irow)
	local bottom = tir_vim.get_block_bottom_nrow(line_provider, irow)
	return top, bottom
end

---@param line_provider LineProvider
---@param row Range
local function expand_rect(line_provider, row)
	local top, bottom = get_range(line_provider, row.first)
	row.first = top
	local irow = bottom + 1
	while irow <= row.last do
		_, bottom = get_range(line_provider, irow)
		irow = bottom + 1
	end
	row.last = bottom
end

---@param operator string
---@param count integer
---@param rect Rect
local function change_table_width(operator, count, rect)
	log.debug("row%s, col%s", rect.row:short(), rect.col:short())
	local bufnr, blocks = get_blocks(rect.row)
	Blocks.change_width(blocks, operator, count, rect.col)
	local vi_lines = vim_parser.unparse(blocks)
	ui.set_lines(bufnr, rect.row.first - 1, rect.row.last, vi_lines)
end

---@param line_provider LineProvider
---@param rect Rect
---@param operator string
local function change_width(line_provider, rect, operator, count)
	expand_rect(line_provider, rect.row)
	change_table_width(operator, count, rect)
end

local warned = false

---@param command string
local function set_repeat(command)
	local ok = pcall(function()
		fn["repeat#set"](command)
	end)
	if not ok and not warned then
		warned = true
		notify.info(
			"tirenvi: install 'tpope/vim-repeat' to enable '.' repeat"
		)
	end
end

-- public API

--- Set up tirenvi plugin (load autocmds and commands)
---@param opts {[string]:any}
function M.setup(opts)
	if vim.g.tirenvi_initialized then
		log.error("tirenvi does not support reload. Please restart Neovim.")
		return
	end
	vim.g.tirenvi_initialized = true
	config.setup(opts)
	require("tirenvi.editor.autocmd").setup()
	require("tirenvi.editor.commands").setup()
	require("tirenvi.editor.textobj").setup()
	require("tirenvi.ui").setup()
end

--- Convert current buffer (or specified buffer) from plain format to tir-vim format
---@param bufnr number Buffer number.
---@return nil
function M.import_flat(bufnr)
	from_flat(bufnr, true)
end

---@param bufnr number Buffer number.
---@return nil
function M.enable(bufnr)
	from_flat(bufnr)
end

local buffer_backup

--- Convert current buffer (or specified buffer) from display format back to file format (tsv)
---@param bufnr number Buffer number.
---@return nil
function M.export_flat(bufnr)
	buffer_backup = buffer.get_lines(bufnr, 0, -1)
	to_flat(bufnr)
end

--- Convert current buffer (or specified buffer) from plain format to view format
---@param bufnr number Buffer number.
---@return nil
function M.restore_tir_vim(bufnr)
	if not buffer_backup then
		return
	end
	pcall(vim.cmd, "undojoin")
	buffer.set_lines(bufnr, 0, -1, buffer_backup)
	buffer_backup = nil
end

---@param bufnr number Buffer number.
---@return nil
function M.disable(bufnr)
	to_flat(bufnr, true)
end

---@param bufnr number Buffer number.
---@return nil
function M.toggle(bufnr)
	if buf_state.is_tir_vim(bufnr) then
		M.disable(bufnr)
	else
		M.enable(bufnr)
	end
end

---@param bufnr number|nil Buffer number.
---@return nil
function M.redraw(bufnr)
	bufnr = bufnr or api.nvim_get_current_buf()
	local old_lines = buffer.get_lines(bufnr, 0, -1)
	local blocks = vim_parser.parse(old_lines)
	local vi_lines = vim_parser.unparse(blocks)
	if table.concat(old_lines, "\n") ~= table.concat(vi_lines, "\n") then
		log.debug({ vi_lines[1], vi_lines[2] })
		ui.set_lines(bufnr, 0, -1, vi_lines)
	end
end

---@param bufnr number Buffer number.
---@return nil
function M.hbar(bufnr)
	vim.w.tirenvi_view_nobar = not (vim.w.tirenvi_view_nobar or false)
	ui.special_apply()
end

---@param line_provider LineProvider
---@param rect Rect
---@param operator string Operator: "", "=", "+", "-"
---@param count integer Count for the operator (default: 0)
---@return nil
function M.width(line_provider, rect, operator, count)
	change_width(line_provider, rect, operator, count)
	local command = api.nvim_replace_termcodes(
		":<C-u>Tir width " .. operator .. count .. "<CR>",
		true, false, true
	)
	set_repeat(command)
end

---@param bufnr number
function M.insert_char_in_newline(bufnr)
	local winid = api.nvim_get_current_win()
	local row = api.nvim_win_get_cursor(winid)[1]
	local line_prev, line_next = buffer.get_lines_around(bufnr, row - 1, row)
	local line_ref = line_prev and line_prev or line_next
	if not line_ref or not tir_vim.start_with_pipe(line_ref) then
		return
	end
	local line_new = buffer.get_line(bufnr, row - 1)
	if line_new ~= "" then
		return
	end
	local ch = vim.v.char
	local pipe = fn.strcharpart(line_ref, 0, 1)
	vim.v.char = pipe .. ch
end

---@return string
function M.keymap_lf()
	local col = fn.col(".")
	local line = fn.getline(".")
	if not tir_vim.get_pipe_char(line) then
		return api.nvim_replace_termcodes("<CR>", true, true, true)
	end
	if col == 1 or col > #line then
		return api.nvim_replace_termcodes("<CR>", true, true, true)
	end
	return config.marks.lf
end

---@return string
function M.keymap_tab()
	local line = fn.getline(".")
	if not tir_vim.get_pipe_char(line) then
		return api.nvim_replace_termcodes("<Tab>", true, true, true)
	end
	if bo.expandtab then
		return api.nvim_replace_termcodes("<Tab>", true, true, true)
	end
	return config.marks.tab
end

---@param bufnr number
---@param first integer
---@param last integer
---@param new_last integer
function M.on_lines(bufnr, first, last, new_last)
	reconcile.handle(bufnr, first, last, new_last)
end

---@param bufnr number
function M.on_insert_leave(bufnr)
	reconcile.handle(bufnr)
end

---@param bufnr number
function M.on_filetype(bufnr)
	local old_filetype = buffer.get(bufnr, buffer.IKEY.FILETYPE)
	local new_filetype = bo[bufnr].filetype
	-- log.debug("filetype %s -> %s", tostring(old_filetype), tostring(new_filetype))
	if old_filetype and old_filetype ~= new_filetype then
		to_flat(bufnr)
	end
	buffer.set(bufnr, buffer.IKEY.FILETYPE, new_filetype)
end

return M
