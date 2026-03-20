----- dependencies
local config = require("tirenvi.config")
local buf_state = require("tirenvi.state.buf_state")
local util = require("tirenvi.util.util")
local validator = require("tirenvi.core.validator")
local log = require("tirenvi.util.log")
local buffer = require("tirenvi.state.buffer")
local flat_parser = require("tirenvi.core.flat_parser")
local vim_parser = require("tirenvi.core.vim_parser")

-- module
---@class tirenvi
local M = {}

local api = vim.api
local fn = vim.fn
local bo = vim.bo
-- constants / defaults
M.motion = require("tirenvi.editor.motion")

-- private helpers

---@param bufnr number Buffer number.
---@param old_path string
---@param new_path string
---@return nil
local function to_flat(bufnr, old_path, new_path)
	if not buf_state.is_tir_vim(bufnr) then
		return
	end
	local parser = util.get_parser(bufnr, new_path, old_path)
	local vi_lines = buffer.get_lines(bufnr, 0, -1, false)
	local blocks = vim_parser.parse(vi_lines)
	log.debug(blocks)
	local new_lines = flat_parser.unparse(blocks, parser)
	buffer.set_lines(bufnr, 0, -1, new_lines)
end

---@param bufnr number Buffer number.
---@param new_path string|nil
---@param old_path string|nil
---@return nil
local function from_flat(bufnr, new_path, old_path)
	local fl_lines = buffer.get_lines(bufnr, 0, -1, false)
	util.assert_no_reserved_marks(fl_lines)
	local parser = util.get_parser(bufnr, new_path, old_path)
	local blocks = flat_parser.parse(fl_lines, parser)
	local vi_lines = vim_parser.unparse(blocks)
	buffer.set_lines(bufnr, 0, -1, vi_lines)
end

local function safe_link_multi(name, targets)
	for _, t in ipairs(targets) do
		local ok = pcall(vim.api.nvim_get_hl, 0, { name = t })
		if ok then
			vim.api.nvim_set_hl(0, name, { link = t })
			return
		end
	end
end

vim.api.nvim_set_hl(0, "TirenviPadding", { fg = "bg", bg = "bg", })
safe_link_multi("TirenviPipe", { "@punctuation.special.markdown", "Delimiter", "Special", })
safe_link_multi("TirenviSpecialChar", { "NonText", })
local title = vim.api.nvim_get_hl(0, { name = "Title" })
vim.api.nvim_set_hl(0, "TirenviHeader", {
	fg = title.fg,
	bg = title.bg,
	bold = title.bold,
	underline = true,
	sp = title.fg,
})

-- public API

--- Set up tirenvi plugin (load autocmds and commands)
---@param opts {[string]:any}
function M.setup(opts)
	config.setup(opts)
	require("tirenvi.editor.autocmd").setup()
	require("tirenvi.editor.commands").setup()
end

--- Convert current buffer (or specified buffer) from plain format to tir-vim format
---@param bufnr number Buffer number.
---@return nil
function M.import_flat(bufnr)
	pcall(vim.cmd, "undojoin")
	from_flat(bufnr)
end

---@param bufnr number Buffer number.
---@return nil
function M.enable(bufnr)
	from_flat(bufnr)
end

--- Convert current buffer (or specified buffer) from display format back to file format (tsv)
---@param bufnr number Buffer number.
---@param new_path string
---@return nil
function M.export_flat(bufnr, new_path, old_path)
	log.debug("old_path: %s, new_path: %s", old_path, new_path)
	to_flat(bufnr, old_path, new_path)
	log.debug("export_flat done")
end

---@param bufnr number Buffer number.
---@return nil
function M.disable(bufnr)
	local file_path = buffer.get_file_path(bufnr)
	to_flat(bufnr, file_path, file_path)
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
---@param new_path string
---@param old_path string
---@return nil
function M.restore_tir_vim(bufnr, new_path, old_path)
	pcall(vim.cmd, "undojoin")
	from_flat(bufnr, new_path, old_path)
end

---@param bufnr number Buffer number.
---@return nil
function M.redraw(bufnr)
	local vi_lines = buffer.get_lines(bufnr, 0, -1, false)
	local blocks = vim_parser.parse(vi_lines)
	local new_lines = vim_parser.unparse(blocks)
	if table.concat(vi_lines, "\n") ~= table.concat(new_lines, "\n") then
		log.debug({ new_lines[1], new_lines[2] })
		buffer.set_lines(bufnr, 0, -1, new_lines)
	end
end

---@param bufnr number
function M.insert_char_in_newline(bufnr)
	local row = api.nvim_win_get_cursor(0)[1]
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
	if not util.has_pipe(line) then
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
	if not util.has_pipe(line) then
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
	validator.repair(bufnr, first, last, new_last)
end

---@param bufnr number
function M.on_insert_leave(bufnr)
	validator.repair(bufnr)
end

return M
