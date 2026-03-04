----- dependencies
local CONST = require("tirenvi.constants")
local config = require("tirenvi.config")
local buf_state = require("tirenvi.buf_state")
local tir_vim = require("tirenvi.tir_vim")
local helper = require("tirenvi.helper")
local vimHelper = require("tirenvi.vimHelper")
local validity = require("tirenvi.validity")
local log = require("tirenvi.log")

-- module
---@class tirenvi
local M = {}

-- constants / defaults
M.motion = require("tirenvi.motion")

-- private helpers

---@param func fun(lines: string[], opts: table) :string[]
---@param bufnr number
---@param opts {[string]: any}
---@return string[] | nil
local function run(func, bufnr, opts)
	local undolevels
	if not vim.b[bufnr][CONST.BUF_KEY.INITIALIZED] then
		undolevels = vim.bo[bufnr].undolevels
		vim.bo[bufnr].undolevels = -1
	end

	---@type string[]
	local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	log.debug("===[api call]before=== [1] %s, [%d] %s", buf_lines[1], #buf_lines, buf_lines[#buf_lines])
	local new_lines = func(buf_lines, opts)
	if new_lines ~= nil then
		log.debug("===[api call]after=== [1] %s, [%d] %s", new_lines[1], #new_lines, new_lines[#new_lines])
		vimHelper.set_lines(bufnr, 0, -1, false, new_lines)
	end
	if not vim.b[bufnr][CONST.BUF_KEY.INITIALIZED] then
		vim.b[bufnr][CONST.BUF_KEY.INITIALIZED] = true
		vim.bo[bufnr].undolevels = undolevels
	end
	return new_lines
end

local function on_lines(_, bufnr, tick, first, last, new_last, bytecount)
	validity.repair_invalid_tir_vim(bufnr, first, last, new_last, true)
end

---@param bufnr number Buffer number.
---@param old_path string
---@param new_path string
---@return nil
local function to_flat(bufnr, old_path, new_path)
	if not buf_state.is_tir_vim(bufnr) then
		return
	end
	local parser = vimHelper.get_parser_name(bufnr, new_path, old_path)
	local opts = {
		parser = parser,
		file_path = old_path,
	}
	run(tir_vim.to_flat, bufnr, opts)
end

---@param bufnr number Buffer number.
---@param new_path string|nil
---@param old_path string|nil
---@return nil
local function from_flat(bufnr, new_path, old_path)
	local parser = vimHelper.get_parser_name(bufnr, new_path, old_path)
	local opts = {
		parser = parser,
	}
	run(tir_vim.from_flat, bufnr, opts)
end

-- public API

---@return string[]
function M.get_tirenvi_patterns()
	local tirenvi_patterns = {}
	for ext, _ in pairs(config.parser_map) do
		table.insert(tirenvi_patterns, "*." .. ext)
	end
	return tirenvi_patterns
end

--- Set up tirenvi plugin (load autocmds and commands)
function M.setup(opts)
	config.setup(opts)
	require("tirenvi.autocmd").setup()
	require("tirenvi.commands").setup()
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
	local file_path = vimHelper.get_file_path(bufnr)
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
	---@type string[]
	local vim_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local new_lines = tir_vim.recalculate_padding(vim_lines, true)
	if table.concat(vim_lines, "\n") ~= table.concat(new_lines, "\n") then
		log.debug({ new_lines[1], new_lines[2] })
		vimHelper.set_lines(bufnr, 0, -1, false, new_lines)
	end
end

---@param bufnr number Buffer number.
---@return nil
function M.attach_on_lines(bufnr)
	if vim.b[bufnr][CONST.BUF_KEY.ATTACH_COUNT] ~= nil then
		if vim.b[bufnr][CONST.BUF_KEY.ATTACH_COUNT] > 0 then
			return
		end
	end
	log.debug("===+===+=== attach onlines")
	vim.api.nvim_buf_attach(bufnr, false, {
		on_lines = on_lines,
		on_detach = function()
			log.debug("===+===+=== detach onlines")
			vim.b[bufnr][CONST.BUF_KEY.ATTACH_COUNT] = 0
		end,
	})
	vim.b[bufnr][CONST.BUF_KEY.ATTACH_COUNT] = 1
end

---@param bufnr number
function M.insert_char_in_newline(bufnr)
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1]
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	local ref_line = nil
	if row > 1 then
		ref_line = vim.api.nvim_buf_get_lines(bufnr, row - 2, row - 1, false)[1]
	elseif row < line_count then
		ref_line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
	else
		return
	end
	if vimHelper.first_char(ref_line) ~= config.marks.pipe then
		return
	end
	local current_line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
	if #current_line ~= 0 then
		return
	end
	local ch = vim.v.char
	vim.v.char = config.marks.pipe .. ch
end

---@param bufnr number
---@return string
function M.keymap_lf(bufnr)
	local col = vim.fn.col(".")
	local line = vim.fn.getline(".")
	if not helper.has_pipe(line) then
		return vim.api.nvim_replace_termcodes("<CR>", true, true, true)
	end
	if col == 1 or col > #line then
		return vim.api.nvim_replace_termcodes("<CR>", true, true, true)
	end
	return config.marks.lf
end

---@param bufnr number
---@return string
function M.keymap_tab(bufnr)
	local line = vim.fn.getline(".")
	if not helper.has_pipe(line) then
		return vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
	end
	if vim.bo.expandtab then
		return vim.api.nvim_replace_termcodes("<Tab>", true, true, true)
	end
	return config.marks.tab
end

return M
