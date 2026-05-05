----- dependencies
local Context = require("tirenvi.app.context")
local Request = require("tirenvi.app.request")
local pipeline = require("tirenvi.app.pipeline")
local config = require("tirenvi.config")
local reconcile = require("tirenvi.core.reconcile")
local buffer = require("tirenvi.io.buffer")
local attr_store = require("tirenvi.io.attr_store")
local writer = require("tirenvi.io.writer")
local reader = require("tirenvi.io.reader")
local tir_vim = require("tirenvi.core.tir_vim")
local Blocks = require("tirenvi.core.blocks")
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

---@param req Request
---@param document Document
local function set_attrs(req, document)
	-- TODO: Document
	Blocks.set_attrs(document.blocks, req.attrs)
end

---@param ctx Context
---@param no_undo boolean|nil
---@return nil
local function from_flat(ctx, no_undo)
	pipeline.from_flat(ctx, no_undo)
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

---@param ctx Context
---@param line_provider LineProvider
---@param irow integer
local function get_range(ctx, line_provider, irow)
	local top = tir_vim.get_block_top_nrow(ctx, line_provider, irow)
	local bottom = tir_vim.get_block_bottom_nrow(ctx, line_provider, irow)
	return top, bottom
end

---@param ctx Context
---@param line_provider LineProvider
---@param row Range
local function expand_rect(ctx, line_provider, row)
	local top, bottom = get_range(ctx, line_provider, row.first)
	row.first = top
	local irow = bottom + 1
	while irow <= row.last do
		_, bottom = get_range(ctx, line_provider, irow)
		irow = bottom + 1
	end
	row.last = bottom
end

---@param ctx Context
---@param line_provider LineProvider
---@param sel Rect
---@param width_op WidthOp
local function cmd_width(ctx, line_provider, sel, width_op)
	expand_rect(ctx, line_provider, sel.row)
	pipeline.cmd_width(ctx, sel, width_op)
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
---@param ctx Context
---@return nil
function M.import_flat(ctx)
	from_flat(ctx, true)
end

---@param ctx Context
---@return nil
function M.enable(ctx)
	from_flat(ctx)
end

local buffer_backup

--- Convert current buffer (or specified buffer) from display format back to file format (tsv)
---@param ctx Context
---@return nil
function M.export_flat(ctx)
	local req = Request.from_vim0(0, -1)
	buffer_backup = reader.read(ctx, req)
	if not tir_vim.has_pipe(buffer_backup) then
		buffer_backup = nil
		return
	end
	pipeline.to_flat(ctx)
end

--- Convert current buffer (or specified buffer) from plain format to view format
---@param ctx Context
---@return nil
function M.restore_tir_vim(ctx)
	if not buffer_backup then
		return
	end
	local req = Request.from_lines(0, -1, buffer_backup, nil, true)
	writer.write(ctx, req)
	buffer_backup = nil
end

---@param ctx Context
---@return nil
function M.disable(ctx)
	pipeline.to_flat(ctx, true)
end

---@param ctx Context
---@return nil
function M.toggle(ctx)
	local req = Request.from_vim0(0, -1)
	local lines = reader.read(ctx, req)
	if tir_vim.has_pipe(lines) then
		M.disable(ctx)
	else
		M.enable(ctx)
	end
end

---@param ctx Context
function M.reconcile(ctx)
	pipeline.cmd_reconcile(ctx)
end

---@param ctx Context	
---@param line_provider LineProvider
---@param sel Rect
---@param width_op WidthOp
function M.width(ctx, line_provider, sel, width_op)
	cmd_width(ctx, line_provider, sel, width_op)
	local command = util.get_termcodes(width_op:to_cmd())
	set_repeat(command)
end

---@param ctx Context
function M.insert_char_in_newline(ctx)
	local winid = api.nvim_get_current_win()
	local row = api.nvim_win_get_cursor(winid)[1]
	local line_new = buffer.get_line(ctx.bufnr, row - 1)
	if line_new ~= "" then
		return
	end
	local line_prev, line_next = buffer.get_lines_around(ctx.bufnr, Range.from_lua(row - 1, row))
	local line_ref = line_prev
	if not Context.is_allow_plain(ctx) then
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

---@param ctx Context
---@param range3 Range3
function M.on_lines(ctx, range3)
	log.watch("UNDO", "===+=== ENTRY on_lines[#%d]%s", ctx.bufnr, range3:short())
	reconcile.handle(ctx, range3)
end

---@param ctx Context
function M.on_insert_leave(ctx)
	log.watch("UNDO", "===+=== ENTRY insert_leave[#%d]", ctx.bufnr)
	reconcile.handle(ctx)
end

---@param ctx Context
---@return Context
function M.on_filetype(ctx)
	local old_filetype = buffer.get(ctx.bufnr, buffer.IKEY.FILETYPE)
	local new_filetype = bo[ctx.bufnr].filetype
	-- log.debug("filetype %s -> %s", tostring(old_filetype), tostring(new_filetype))
	if old_filetype and old_filetype == new_filetype then
		return ctx
	end
	pipeline.to_flat(ctx)
	buffer.set(ctx.bufnr, buffer.IKEY.FILETYPE, new_filetype)
	attr_store.clear(ctx)
	ctx = Context.from_buf(ctx.bufnr)
	if not ctx.parser then
		buffer.set(ctx.bufnr, buffer.IKEY.FILETYPE, nil)
	end
	return ctx
end

return M
