----- dependencies
local Context = require("tirenvi.app.context")
local pipeline = require("tirenvi.app.pipeline")
local config = require("tirenvi.config")
local buffer = require("tirenvi.io.buffer")
local reader = require("tirenvi.io.reader")
local buf_state = require("tirenvi.io.buf_state")
local attr_store = require("tirenvi.io.attr_store")
local Bufline = require("tirenvi.core.bufline")
local Parser = require("tirenvi.parser.parser")
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

---@param ctx Context
local function embedded(ctx)
	if ctx.parser then
		return
	end
	ctx.parser = Parser.resolve_parser("*")
	buffer.set(ctx.bufnr, buffer.IKEY.PARSER, ctx.parser)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

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
function M.read_post(ctx)
	pipeline.read_post(ctx)
end

--- Convert current buffer (or specified buffer) from display format back to file format (tsv)
---@param ctx Context
---@return nil
function M.write_pre(ctx)
	pipeline.write_pre(ctx)
end

--- Convert current buffer (or specified buffer) from plain format to view format
---@param ctx Context
---@return nil
function M.write_post(ctx)
	pipeline.write_post(ctx)
end

---@param ctx Context
function M.toggle(ctx)
	local is_flat = buf_state.is_flat(ctx.bufnr)
	embedded(ctx)
	if is_flat == nil or is_flat then
		pipeline.from_flat(ctx)
	elseif buf_state.has_grid(ctx) then
		pipeline.to_flat(ctx)
	end
end

---@param ctx Context
function M.redraw(ctx)
	pipeline.cmd_repair(ctx)
end

---@param ctx Context	
---@param width_op WidthOp
function M.width(ctx, width_op)
	pipeline.cmd_width(ctx, width_op)
	set_repeat(util.get_termcodes(width_op:to_cmd()))
end

---@param ctx Context	
---@param width_op WidthOp
function M.fit(ctx, width_op)
	pipeline.cmd_fit(ctx, width_op)
	set_repeat(util.get_termcodes(width_op:to_cmd()))
end

---@param ctx Context	
---@param width_op WidthOp
function M.wrap(ctx, width_op)
	pipeline.cmd_wrap(ctx, width_op)
end

---@param ctx Context
function M.insert_char_in_newline(ctx)
	local cursor = reader.cursor(ctx)
	local row_cur = cursor.row_cur
	local line_new = buffer.get_line(ctx.bufnr, row_cur)
	if line_new ~= "" then
		return
	end
	local line_prev, line_next = buffer.get_lines_around(ctx.bufnr, Range.from_lua(row_cur, row_cur))
	local line_ref = line_prev
	if not Context.is_allow_plain(ctx) then
		line_ref = line_ref or line_next
	end
	local pipe = Bufline.get_pipe_char(line_ref)
	if not pipe then
		return
	end
	vim.v.char = pipe .. vim.v.char
end

---@return string
function M.keymap_lf()
	local col = fn.col(".")
	local line = fn.getline(".")
	if not Bufline.get_pipe_char(line) then
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
	if not Bufline.get_pipe_char(line) then
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
	pipeline.on_lines(ctx, range3)
	pipeline.check_and_repair(ctx, range3)
end

---@param ctx Context
---@param range3 Range3|nil
function M.on_insert_leave(ctx, range3)
	pipeline.check_and_repair(ctx, range3)
end

local function apply_wrap(winid, should_wrap)
	if vim.wo[winid].wrap ~= should_wrap then
		vim.wo[winid].wrap = should_wrap
	end
end

---@param ctx Context
function M.auto_wrap(ctx)
	if not config.ui.manage_wrap then
		return
	end
	if not ctx.parser.allow_plain then
		apply_wrap(ctx.winid, false)
		return
	end
	-- Fast path for CursorMoved.
	-- We only need the current line of the current window.
	local line = vim.api.nvim_get_current_line()
	local line_width = fn.strdisplaywidth(line)
	local win_span = buffer.get_win_span(ctx.winid)
	local is_over = win_span < line_width
	local is_plain = not Bufline.has_pipe({ line })
	if is_over then
		apply_wrap(ctx.winid, is_plain)
	end
end

---@param ctx Context
function M.on_filetype(ctx)
	local old_filetype = buffer.get(ctx.bufnr, buffer.IKEY.FILETYPE)
	local new_filetype = bo[ctx.bufnr].filetype
	-- log.debug("filetype %s -> %s", tostring(old_filetype), tostring(new_filetype))
	if old_filetype and old_filetype == new_filetype then
		return
	end
	if old_filetype then
		pipeline.to_flat(ctx)
	end
	buffer.set(ctx.bufnr, buffer.IKEY.FILETYPE, new_filetype)
	buf_state.set_buffer_flat(ctx.bufnr, true)
	attr_store.write(ctx, nil)
	local parser = Parser.resolve_parser(new_filetype)
	buffer.set(ctx.bufnr, buffer.IKEY.PARSER, parser)
end

---@param ctx Context
---@param filename string
function M.debug_read_tir(ctx, filename)
	pipeline.debug_read_tir(ctx, filename)
end

---@param ctx Context
---@param filename string
function M.debug_write_tir(ctx, filename)
	pipeline.debug_write_tir(ctx, filename)
end

return M
