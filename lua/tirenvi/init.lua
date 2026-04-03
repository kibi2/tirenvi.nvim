----- dependencies
local config = require("tirenvi.config")
local buf_state = require("tirenvi.state.buf_state")
local util = require("tirenvi.util.util")
local repair = require("tirenvi.core.repair")
local log = require("tirenvi.util.log")
local buffer = require("tirenvi.state.buffer")
local flat_parser = require("tirenvi.core.flat_parser")
local vim_parser = require("tirenvi.core.vim_parser")
local tir_vim = require("tirenvi.core.tir_vim")
local Blocks = require("tirenvi.core.blocks")
local ui = require("tirenvi.ui")

-- module
local M = {}

local api = vim.api
local fn = vim.fn
local bo = vim.bo
-- constants / defaults
M.motion = require("tirenvi.editor.motion")

-- private helpers

---@param bufnr number Buffer number.
---@return nil
local function to_flat(bufnr)
	if not buf_state.is_tir_vim(bufnr) then
		return
	end
	local parser = util.get_parser(bufnr)
	local vi_lines = buffer.get_lines(bufnr, 0, -1, false)
	local blocks = vim_parser.parse(vi_lines)
	log.debug(blocks)
	local fl_lines = flat_parser.unparse(blocks, parser)
	ui.set_lines(bufnr, 0, -1, fl_lines)
end

---@param bufnr number Buffer number.
---@param no_undo boolean|nil
---@return nil
local function from_flat(bufnr, no_undo)
	local fl_lines = buffer.get_lines(bufnr, 0, -1, false)
	util.assert_no_reserved_marks(fl_lines)
	local parser = util.get_parser(bufnr)
	local blocks = flat_parser.parse(fl_lines, parser)
	local vi_lines = vim_parser.unparse(blocks)
	ui.set_lines(bufnr, 0, -1, vi_lines, true, no_undo)
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
	require("tirenvi.editor.column").setup()
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

--- Convert current buffer (or specified buffer) from display format back to file format (tsv)
---@param bufnr number Buffer number.
---@return nil
function M.export_flat(bufnr)
	to_flat(bufnr)
	log.debug("export_flat done")
end

---@param bufnr number Buffer number.
---@return nil
function M.disable(bufnr)
	to_flat(bufnr)
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

--- Convert current buffer (or specified buffer) from plain format to view format
---@param bufnr number Buffer number.
---@return nil
function M.restore_tir_vim(bufnr)
	pcall(vim.cmd, "undojoin")
	from_flat(bufnr)
end

---@param bufnr number|nil Buffer number.
---@return nil
function M.redraw(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local old_lines = buffer.get_lines(bufnr, 0, -1, false)
	local blocks = vim_parser.parse(old_lines)
	Blocks.reset_attr(blocks)
	local vi_lines = vim_parser.unparse(blocks)
	if table.concat(old_lines, "\n") ~= table.concat(vi_lines, "\n") then
		log.debug({ vi_lines[1], vi_lines[2] })
		ui.set_lines(bufnr, 0, -1, vi_lines)
	end
end

---@param bufnr number Buffer number.
---@return nil
function M.hbar(bufnr)
	vim.w.tirenvi_view_bar = not (vim.w.tirenvi_view_bar or false)
	ui.special_apply()
end

---@param bufnr number
function M.insert_char_in_newline(bufnr)
	local winid = vim.api.nvim_get_current_win()
	local row = api.nvim_win_get_cursor(winid)[1]
	local line_prev, line_next = buffer.get_lines_around(bufnr, row - 1, row)
	local ref_line = line_prev and line_prev or line_next
	local pipe = config.marks.pipe
	if not ref_line or ref_line:sub(1, #pipe) ~= pipe then
		return
	end
	if buffer.get_line(bufnr, row - 1) ~= "" then
		return
	end
	local ch = vim.v.char
	vim.v.char = config.marks.pipe .. ch
end

---@return string
function M.keymap_lf()
	local col = fn.col(".")
	local line = fn.getline(".")
	if not tir_vim.has_pipe(line) then
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
	if not tir_vim.has_pipe(line) then
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
	repair.repair(bufnr, first, last, new_last)
end

---@param bufnr number
function M.on_insert_leave(bufnr)
	repair.repair(bufnr)
end

---@param bufnr number
function M.on_filetype(bufnr)
	local old_filetype = buffer.get(bufnr, buffer.IKEY.FILETYPE)
	local new_filetype = bo[bufnr].filetype
	log.debug("filetype %s -> %s", tostring(old_filetype), tostring(new_filetype))
	if old_filetype then
		if old_filetype ~= new_filetype then
			to_flat(bufnr)
		end
	end
	buffer.set(bufnr, buffer.IKEY.FILETYPE, new_filetype)
end

return M
