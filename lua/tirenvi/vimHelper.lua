----- dependencies
local config = require("tirenvi.config")
local CONST = require("tirenvi.constants")
local notify = require("tirenvi.notify")
local log = require("tirenvi.log")
local helper = require("tirenvi.helper")
local errors = require("tirenvi.errors")

-- module
local M = {}

-- constants / defaults

-- private helpers

---@param fl_lines string[]
---@return {[string]: string}
local function select_character(fl_lines)
	-- 1. collect all candidates
	local available = {}
	for _, marks in pairs(config.marks) do
		local mark = M.first_char(marks)
		if mark then
			available[mark] = true
		end
	end

	-- 2. scan buffer once
	for _, fl_line in ipairs(fl_lines) do
		for _, fl_char in ipairs(M.utf8_chars(fl_line)) do
			if available[fl_char] ~= nil then
				available[fl_char] = false
			end
		end
	end

	-- 3. assign marks in order
	local selectedChars = {}

	for name, marks in pairs(config.marks) do
		local mark = M.first_char(marks)
		if mark and available[mark] then
			selectedChars[name] = mark
			available[mark] = false
		end
	end
	return selectedChars
end

---@param fl_lines string[]
---@return string[]
local function get_missing_marks(fl_lines)
	local selected_chars = select_character(fl_lines)
	local missing = {}
	for name, _ in pairs(config.marks) do
		if selected_chars[name] == nil then
			table.insert(missing, name)
		end
	end
	return missing
end

local function fix_cursor_utf8()
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local line = vim.api.nvim_get_current_line()
	local char_index = vim.str_utfindex(line, col)
	local boundary = vim.str_byteindex(line, char_index)
	if boundary ~= col then
		vim.api.nvim_win_set_cursor(0, { row, boundary })
	end
end

-- public API

---@param str string
---@return string|nil
function M.first_char(str)
	local chars = M.utf8_chars(str)
	if #chars > 0 then
		return chars[1]
	else
		return nil
	end
end

---@param str string
---@return string[]
function M.utf8_chars(str)
	local chars = {}
	local nStr = vim.fn.strchars(str)
	for iStr = 0, nStr - 1 do
		chars[#chars + 1] = vim.fn.strcharpart(str, iStr, 1)
	end
	return chars
end

---@param fl_lines string[]
---@return nil
function M.init_marks(fl_lines)
	local missing = get_missing_marks(fl_lines)
	if #missing > 0 then
		error(errors.new_domain_error(errors.err_no_usable_characters(missing)))
	end
end

function M.starts_with(str, start_string)
	return vim.startswith(str, start_string)
end

--- Check if a parser is available for the buffer's file type and if the parser's command is executable.
---@param bufnr number
---@return boolean
function M.has_parser(bufnr)
	local parser = helper.get_parser_for_file(M.get_file_path(bufnr))
	if parser == nil then
		return false
	end
	if vim.fn.executable(parser.executable) ~= 1 then
		error(errors.new_domain_error(errors.not_found_parser_error(parser)))
	end
	return true
end

---@param bufnr number
---@param new_path string|nil
---@param old_path string|nil
---@return Parser
function M.get_parser_name(bufnr, new_path, old_path)
	if new_path == nil then
		new_path = M.get_file_path(bufnr)
	end
	local file_path = new_path
	local parser = helper.get_parser_for_file(file_path)
	if not parser and old_path then
		file_path = old_path
		parser = helper.get_parser_for_file(file_path)
	end
	if parser == nil then
		local ext = helper.get_ext(file_path)
		-- error(errors.new_domain_error(errors.no_parser_error(ext)))
		error(errors.new_domain_error(""))
	end
	if vim.fn.executable(parser.executable) ~= 1 then
		error(errors.new_domain_error(errors.not_found_parser_error(parser)))
	end
	return parser
end

--- Get absolute file path of the buffer.
---@param bufnr number
---@return string
function M.get_file_path(bufnr)
	local file_name = vim.api.nvim_buf_get_name(bufnr)
	return M.to_file_path(file_name)
end

--- Convert file name to absolute file path. if the file name is empty, return it as is.
---@param file_name string
---@return string
function M.to_file_path(file_name)
	local file_path = file_name
	if file_path ~= "" then
		file_path = vim.fn.fnamemodify(file_path, ":p")
	end
	return file_path
end

function M.set_lines(bufnr, iStart, iEnd, strict, lines)
	log.debug("=== set_lines (%d, %d) %s", iStart, iEnd, table.concat(lines, "↩️"))
	if vim.b[bufnr][CONST.BUF_KEY.PATCH_DEPTH] == nil then
		vim.b[bufnr][CONST.BUF_KEY.PATCH_DEPTH] = 0
	end
	vim.b[bufnr][CONST.BUF_KEY.PATCH_DEPTH] = vim.b[bufnr][CONST.BUF_KEY.PATCH_DEPTH] + 1
	vim.api.nvim_buf_set_lines(bufnr, iStart, iEnd, strict, lines)
	vim.b[bufnr][CONST.BUF_KEY.PATCH_DEPTH] = vim.b[bufnr][CONST.BUF_KEY.PATCH_DEPTH] - 1
	assert(vim.b[bufnr][CONST.BUF_KEY.PATCH_DEPTH] == 0)
	fix_cursor_utf8()
end

function M.is_insert_mode(bufnr)
	return vim.b[bufnr][CONST.BUF_KEY.INSERT_MODE]
end

local undo_tree_last = -1
function M.is_undo_mode(bufnr)
	if M.is_insert_mode(bufnr) then
		return false
	end
	local ut = vim.fn.undotree()
	if undo_tree_last == ut.seq_last then
		return true
	end
	undo_tree_last = ut.seq_last
	return false
end

function M.with_schedule(schedule, func)
	if not schedule then
		return func
	end
	return function(...)
		local args = { ... }
		schedule(function()
			func(table.unpack(args))
		end)
	end
end

function M.is_same(old_lines, new_lines)
	local old_string = table.concat(old_lines, "\n")
	local new_string = table.concat(new_lines, "\n")
	local escaped_padding = vim.pesc(config.marks.padding)
	old_string = old_string:gsub(escaped_padding, "")
	new_string = new_string:gsub(escaped_padding, "")
	return old_string == new_string
end

return M
