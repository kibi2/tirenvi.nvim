----- dependencies
local Context = require("tirenvi.app.context")
local pipeline = require("tirenvi.app.pipeline")
local config = require("tirenvi.config")
local buffer = require("tirenvi.io.buffer")
local buf_state = require("tirenvi.io.buf_state")
local attr_store = require("tirenvi.io.attr_store")
local Bufline = require("tirenvi.core.bufline")
local Range = require("tirenvi.util.range")
local Range3 = require("tirenvi.util.range3")
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
---@return nil
function M.toggle(ctx)
	local is_flat = buf_state.is_flat(ctx.bufnr)
	if is_flat == nil or is_flat then
		pipeline.from_flat(ctx)
	elseif buf_state.has_grid(ctx) then
		pipeline.to_flat(ctx)
	end
end

---@param ctx Context
function M.repair(ctx)
	pipeline.cmd_repair(ctx)
end

---@param ctx Context	
---@param sel Rect
---@param width_op WidthOp
function M.width(ctx, sel, width_op)
	pipeline.cmd_width(ctx, sel, width_op)
	local command = util.get_termcodes(width_op:to_cmd())
	set_repeat(command)
end

---@param ctx Context
function M.insert_char_in_newline(ctx)
	local winid = api.nvim_get_current_win()
	local irow = buffer.get_cursor(winid)
	local line_new = buffer.get_line(ctx.bufnr, irow)
	if line_new ~= "" then
		return
	end
	local line_prev, line_next = buffer.get_lines_around(ctx.bufnr, Range.from_lua(irow, irow))
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
	log.watch("UNDO", "===+=== ENTRY on_lines[#%d]%s", ctx.bufnr, Range3.short(range3))
	pipeline.on_lines(ctx, range3)
end

---@param ctx Context
function M.on_insert_leave(ctx)
	log.watch("UNDO", "===+=== ENTRY insert_leave[#%d]", ctx.bufnr)
	pipeline.insert_leave(ctx)
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
	attr_store.write(ctx.bufnr, nil, true)
	ctx = Context.from_buf(ctx.bufnr)
	if not ctx.parser then
		buffer.set(ctx.bufnr, buffer.IKEY.FILETYPE, nil)
	end
end

return M
