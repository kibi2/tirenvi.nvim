----- dependencies
local Context = require("tirenvi.app.context")
local Request = require("tirenvi.app.request")
local Document = require("tirenvi.core.document")
local Parser = require("tirenvi.parser.parser")
local flat_parser = require("tirenvi.parser.flat_parser")
local vim_parser = require("tirenvi.parser.vim_parser")
local config = require("tirenvi.config")
local reconcile = require("tirenvi.core.reconcile")
local buf_state = require("tirenvi.io.buf_state")
local buffer = require("tirenvi.io.buffer")
local attr_store = require("tirenvi.io.attr_store")
local writer = require("tirenvi.io.writer")
local reader = require("tirenvi.io.reader")
local tir_vim = require("tirenvi.core.tir_vim")
local Blocks = require("tirenvi.core.blocks")
local ui = require("tirenvi.ui")
local Range = require("tirenvi.util.range")
local util = require("tirenvi.util.util")
local notify = require("tirenvi.util.notify")
local log = require("tirenvi.util.log")

-- module
local M = {}

local api = vim.api
local fn = vim.fn
local bo = vim.bo
-- constants / defaults
M.motion = require("tirenvi.editor.motion")

-- private helpers

---@param bufnr number
---@param document Document
local function store_widths(bufnr, document)
	buffer.set(bufnr, buffer.IKEY.WIDTHS, Blocks.get_widths(document.blocks))
end

---@param request Request
---@param document Document
local function set_attrs(request, document)
	Blocks.set_attrs(document.blocks, request.attrs)
end

---@param context Context
---@param is_toggle boolean|nil
---@return nil
local function to_flat(context, is_toggle)
	is_toggle = is_toggle or false
	local request = Request.from_range(context, Range.new(0, -1))
	local vi_lines = reader.read(request)
	if not tir_vim.has_pipe(vi_lines) then
		return
	end
	local document = vim_parser.parse(vi_lines, Context.is_allow_plain(context))
	log.debug(document.blocks[1].records)
	local fl_lines = flat_parser.unparse(document, context.parser)
	local request = Request.from_lines(context, Range.new(0, -1), fl_lines)
	request.attrs = Document.get_attrs(document)
	writer.write(request)
end

---@param context Context
---@param no_undo boolean|nil
---@return nil
local function from_flat(context, no_undo)
	local request = Request.from_range(context, Range.new(0, -1))
	local fl_lines = reader.read(request)
	local parser = context.parser
	util.assert_no_reserved_marks(fl_lines)
	local document = flat_parser.parse(fl_lines, parser)
	set_attrs(request, document)
	local vi_lines = vim_parser.unparse(document)
	local request = Request.from_lines(context, Range.new(0, -1), vi_lines, no_undo)
	writer.write(request)
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

---@param context Context
---@param row Range
---@return Document|nil
local function get_blocks(context, row)
	local request = Request.from_range(context, Range.new(row.first - 1, row.last))
	local lines = reader.read(request)
	if not tir_vim.has_pipe(lines) then
		return nil
	end
	return vim_parser.parse(lines, Context.is_allow_plain(context))
end

---@param context Context
---@param line_provider LineProvider
---@param irow integer
local function get_range(context, line_provider, irow)
	local top = tir_vim.get_block_top_nrow(context, line_provider, irow)
	local bottom = tir_vim.get_block_bottom_nrow(context, line_provider, irow)
	return top, bottom
end

---@param line_provider LineProvider
---@param row Range
local function expand_rect(context, line_provider, row)
	local top, bottom = get_range(context, line_provider, row.first)
	row.first = top
	local irow = bottom + 1
	while irow <= row.last do
		_, bottom = get_range(context, line_provider, irow)
		irow = bottom + 1
	end
	row.last = bottom
end

---@param context Context
---@param operator string
---@param count integer
---@param rect Rect
---@return boolean
local function change_table_width(context, operator, count, rect)
	log.debug("row%s, col%s", rect.row:short(), rect.col:short())
	local document = get_blocks(context, rect.row)
	if not document then
		return false
	end
	Blocks.change_width(document.blocks, operator, count, rect.col)
	local vi_lines = vim_parser.unparse(document)
	local request = Request.from_lines(context, Range.new(rect.row.first - 1, rect.row.last), vi_lines)
	writer.write(request)
	return true
end

---@param context Context
---@param line_provider LineProvider
---@param rect Rect
---@param operator string
local function change_width(context, line_provider, rect, operator, count)
	expand_rect(context, line_provider, rect.row)
	change_table_width(context, operator, count, rect)
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
---@param context Context
---@return nil
function M.import_flat(context)
	from_flat(context, true)
end

---@param context Context
---@return nil
function M.enable(context)
	from_flat(context)
end

local buffer_backup

--- Convert current buffer (or specified buffer) from display format back to file format (tsv)
---@param context Context
---@return nil
function M.export_flat(context)
	local request = Request.from_range(context, Range.new(0, -1))
	buffer_backup = reader.read(request)
	if not tir_vim.has_pipe(buffer_backup) then
		buffer_backup = nil
		return
	end
	to_flat(context)
end

--- Convert current buffer (or specified buffer) from plain format to view format
---@param context Context
---@return nil
function M.restore_tir_vim(context)
	if not buffer_backup then
		return
	end
	local request = Request.from_lines(context, Range.new(0, -1), buffer_backup, true)
	writer.write(request)
	buffer_backup = nil
end

---@param context Context
---@return nil
function M.disable(context)
	to_flat(context, true)
end

---@param context Context
---@return nil
function M.toggle(context)
	local request = Request.from_range(context, Range.new(0, -1))
	local lines = reader.read(request)
	if tir_vim.has_pipe(lines) then
		M.disable(context)
	else
		M.enable(context)
	end
end

---@param context Context
---@return nil
function M.reconcile(context)
	local bufnr = context.bufnr
	local request = Request.from_range(context, Range.new(0, -1))
	local old_lines = reader.read(request)
	local document = vim_parser.parse(old_lines, Context.is_allow_plain(context))
	local vi_lines = vim_parser.unparse(document)
	if table.concat(old_lines, "\n") ~= table.concat(vi_lines, "\n") then
		log.debug({ vi_lines[1], vi_lines[2] })
		local request = Request.from_lines(context, Range.new(0, -1), vi_lines)
		writer.write(request)
	end
end

---@param context Context	
---@param line_provider LineProvider
---@param rect Rect
---@param operator string Operator: "", "=", "+", "-"
---@param count integer Count for the operator (default: 0)
---@return nil
function M.width(context, line_provider, rect, operator, count)
	change_width(context, line_provider, rect, operator, count)
	local command = util.get_termcodes(":<C-u>Tir width " .. operator .. count .. "<CR>")
	set_repeat(command)
end

---@param context Context
function M.insert_char_in_newline(context)
	local winid = api.nvim_get_current_win()
	local row = api.nvim_win_get_cursor(winid)[1]
	local line_new = buffer.get_line(context.bufnr, row - 1)
	if line_new ~= "" then
		return
	end
	local line_prev, line_next = buffer.get_lines_around(context.bufnr, row - 1, row)
	local line_ref = line_prev
	if not Context.is_allow_plain(context) then
		line_ref = line_ref or line_next
	end
	local pipe = tir_vim.get_pipe_char(line_ref)
	if not pipe then
		return
	end
	vim.v.char = pipe .. vim.v.char
end

---@return string
function M.keymap_lf()
	local col = fn.col(".")
	local line = fn.getline(".")
	if not tir_vim.get_pipe_char(line) then
		return util.get_termcodes("<CR>")
	end
	if col == 1 or col > #line then
		return util.get_termcodes("<CR>")
	end
	return config.marks.lf
end

---@return string
function M.keymap_tab()
	local line = fn.getline(".")
	if not tir_vim.get_pipe_char(line) then
		return util.get_termcodes("<Tab>")
	end
	if bo.expandtab then
		return util.get_termcodes("<Tab>")
	end
	return config.marks.tab
end

---@param context Context
---@param range3 Range3
function M.on_lines(context, range3)
	log.watch("UNDO", "===+=== ENTRY on_lines[#%d]%s", context.bufnr, range3)
	reconcile.handle(context, range3)
end

---@param context Context
function M.on_insert_leave(context)
	log.watch("UNDO", "===+=== ENTRY insert_leave[#%d]", context.bufnr)
	reconcile.handle(context)
end

---@param context Context
---@return Context
function M.on_filetype(context)
	local old_filetype = buffer.get(context.bufnr, buffer.IKEY.FILETYPE)
	local new_filetype = bo[context.bufnr].filetype
	-- log.debug("filetype %s -> %s", tostring(old_filetype), tostring(new_filetype))
	if old_filetype and old_filetype == new_filetype then
		return context
	end
	to_flat(context)
	buffer.set(context.bufnr, buffer.IKEY.FILETYPE, new_filetype)
	attr_store.clear(context)
	context = Context.from_buf(context.bufnr)
	if not context.parser then
		buffer.set(context.bufnr, buffer.IKEY.FILETYPE, nil)
	end
	return context
end

return M
