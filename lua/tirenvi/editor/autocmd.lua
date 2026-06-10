-- dependencies
local Context = require("tirenvi.app.context")
local Bufline = require("tirenvi.core.bufline")
local reader = require("tirenvi.io.reader")
local buffer = require("tirenvi.io.buffer")
local init = require("tirenvi.init")
local buf_state = require("tirenvi.io.buf_state")
local ui = require("tirenvi.ui")
local guard = require("tirenvi.util.guard")
local Range3 = require("tirenvi.util.range3")
local log = require("tirenvi.util.log")
local debug = require("tirenvi.editor.debug")

-- module
local M = {}

-- constants / defaults

local GROUP_NAME = "tirenvi"

local api = vim.api

----------------------------------------------------------------------
-- Event handlers (private)
----------------------------------------------------------------------

local function get_context(bufnr)
	return Context.from_buf(bufnr)
end

---@param bufnr number
local function recover_flat(bufnr, range3)
	local r_result = reader.read(get_context(bufnr), Range3.get_new_range(range3))
	if #r_result.lines ~= buffer.line_count(bufnr) then
		return
	end
	buf_state.set_buffer_flat(bufnr, not Bufline.has_pipe(r_result.lines))
end

---@param _ string
---@param bufnr number
---@param tick integer
---@param range3 Range3
---@param bytecount integer
local function on_lines(_, bufnr, tick, range3, bytecount)
	buffer.clear_cache()
	recover_flat(bufnr, range3)
	if buf_state.should_skip(bufnr) then return end
	local ctx = get_context(bufnr)
	debug.ui_entry(bufnr, Range3.short(range3))
	init.on_lines(ctx, range3)
	debug.ui_exit(bufnr, Range3.short(range3))
end

---@param bufnr number
local function attach_on_lines(bufnr)
	if buffer.get(bufnr, buffer.IKEY.ATTACHED) then
		return
	end
	log.debug("===+=== attach on_lines")
	api.nvim_buf_attach(bufnr, false, {
		-- NOTE:
		-- When returning `true` from this callback, the attachment is detached only for
		-- this handler. In this case, `on_detach` is NOT called automatically, so any
		-- state (e.g. ATTACHED flag) must be updated manually here.
		on_lines = function(_, bufnr, tick, first, last, new_last, bytecount)
			if buffer.get(bufnr, buffer.IKEY.FILETYPE) == nil then
				log.debug("===+=== auto detach (no filetype)")
				buffer.set(bufnr, buffer.IKEY.ATTACHED, false)
				return true -- detach
			end
			if buffer.get(bufnr, buffer.IKEY.PATCH_DEPTH) > 0 then
				return
			end
			on_lines(_, bufnr, tick, Range3.new(first + 1, last, new_last), bytecount)
		end,
		on_detach = function()
			log.debug("===+=== detach on_lines")
			buffer.set(bufnr, buffer.IKEY.ATTACHED, false)
		end,
	})
	buffer.set(bufnr, buffer.IKEY.ATTACHED, true)
end

---@param ctx Context
local function on_insert_leave(ctx)
	init.on_insert_leave(ctx)
end

---@param ctx Context
local function on_buf_read_post(ctx)
	init.read_post(ctx)
end

---@param ctx Context
local function on_buf_write_pre(ctx)
	init.write_pre(ctx)
end

---@param ctx Context
local function on_buf_write_post(ctx)
	init.write_post(ctx)
end

---@param ctx Context
local function on_insert_char_pre(ctx)
	init.insert_char_in_newline(ctx)
end

---@param args table
local function on_cursor_hold(args)
	attach_on_lines(args.buf)
end

---@param ctx Context
local function on_filetype(ctx)
	init.on_filetype(ctx)
end

---@param args table
local function on_vim_leave(args) end

----------------------------------------------------------------------
-- Autocmd registration (private)
----------------------------------------------------------------------

---@param augroup integer
---@param bufnr number
local function clear_buffer_local_autocmds(augroup, bufnr)
	api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
end

---@param augroup integer
---@param bufnr number
local function register_buffer_local_autocmds(augroup, bufnr)
	attach_on_lines(bufnr)

	api.nvim_create_autocmd("BufWritePre", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, { has_grid = true, }) then return end
			debug.ui_entry(args.buf, args.event)
			local ctx = get_context(args.buf)
			on_buf_write_pre(ctx)
			debug.ui_exit(args.buf, args.event)
		end),
	})

	api.nvim_create_autocmd("BufWritePost", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, { is_tirbuf = false, }) then
				return
			end
			debug.ui_entry(args.buf, args.event)
			local ctx = get_context(args.buf)
			on_buf_write_post(ctx)
			debug.ui_exit(args.buf, args.event)
		end),
	})

	api.nvim_create_autocmd("CursorHold", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, { is_tirbuf = false, }) then
				return
			end
			on_cursor_hold(args)
		end),
	})

	api.nvim_create_autocmd("InsertEnter", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			debug.ui_entry(args.buf, args.event)
			log.assert(not buffer.get(args.buf, buffer.IKEY.INSERT_MODE),
				"InsertEnter triggered while already in insert mode")
			buffer.set(args.buf, buffer.IKEY.INSERT_MODE, true)
			debug.ui_exit(args.buf, args.event)
		end),
	})

	api.nvim_create_autocmd("InsertLeave", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			debug.ui_entry(args.buf, args.event)
			local ctx = get_context(args.buf)
			-- InsertLeave may be triggered without a preceding InsertEnter
			-- due to the behavior of other plugins (e.g., Telescope).
			-- Do not assert insert_mode here.
			buffer.set(args.buf, buffer.IKEY.INSERT_MODE, false)
			on_insert_leave(ctx)
			debug.ui_exit(args.buf, args.event)
		end),
	})

	api.nvim_create_autocmd("InsertCharPre", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			debug.ui_entry(args.buf, args.event)
			local ctx = get_context(args.buf)
			on_insert_char_pre(ctx)
			debug.ui_exit(args.buf, args.event)
		end),
	})

	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, { is_tirbuf = false, }) then
				return
			end
			ui.special_apply()
		end),
	})
end

local function register_autocmds()
	local augroup = api.nvim_create_augroup(GROUP_NAME, { clear = true })

	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		callback = guard.guarded(function(args)
			local bufnr = args.buf
			if buf_state.should_skip(bufnr, {
					has_parser = false,
					is_tirbuf = false,
				}) then
				return
			end
			debug.ui_entry(args.buf, args.event)
			local ctx = get_context(bufnr)
			on_filetype(ctx)
			clear_buffer_local_autocmds(augroup, bufnr)
			if buf_state.should_skip(args.buf, { is_tirbuf = false, }) then
				return
			end
			register_buffer_local_autocmds(augroup, bufnr)
			debug.ui_exit(args.buf, args.event)
		end),
	})

	api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, { is_tirbuf = false, }) then
				return
			end
			debug.ui_entry(args.buf, args.event)
			local ctx = get_context(args.buf)
			on_buf_read_post(ctx)
			debug.ui_exit(args.buf, args.event)
		end),
	})

	vim.api.nvim_create_autocmd("WinClosed", {
		group = augroup,
		callback = guard.guarded(function(args)
			local winid = tonumber(args.match)
			pcall(ui.special_clear, winid)
		end),
	})

	api.nvim_create_autocmd("VimLeave", {
		group = augroup,
		callback = guard.guarded(function(args)
			debug.ui_entry(args.buf, args.event)
			on_vim_leave(args)
			debug.ui_exit(args.buf, args.event)
		end),
	})

	if vim.g.tirenvi_test_mode == 1 then
		local ok, luacov = pcall(require, "luacov")
		if ok then
			vim.api.nvim_create_autocmd("VimLeavePre", {
				callback = function(args)
					debug.ui_entry(args.buf, args.event)
					luacov.save_stats()
					debug.ui_exit(args.buf, args.event)
				end,
			})
		end
	end
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

function M.setup()
	register_autocmds()
end

return M
