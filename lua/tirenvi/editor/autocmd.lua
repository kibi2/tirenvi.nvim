local api = vim.api                      -- Neovim

local config = require("tirenvi.config") -- Root
local ui = require("tirenvi.ui")

local Debug = require("tirenvi.editor.debug")     -- Editor

local app = require("tirenvi.app")                -- App

local tir_buf = require("tirenvi.parser.tir_buf") -- Parser

local buf_lines = require("tirenvi.io.buf_lines") -- IO
local buf_state = require("tirenvi.io.buf_state")
local Context = require("tirenvi.io.context")

local guard = require("tirenvi.util.guard") -- Util
local Range3 = require("tirenvi.util.range3")
local Range = require("tirenvi.util.range")
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

local GROUP_NAME = "tirenvi"

---@param bufnr number
---@return Context
local function get_context(bufnr)
	return Context.from_buf(bufnr)
end

---@param bufnr number
local function recover_flat(bufnr, range3)
	-- local r_result = reader.read(get_context(bufnr), Range3.get_new_range(range3))
	local first, last = Range.to_lua(Range3.get_new_range(range3))
	local lines = buf_lines.get_lines(bufnr, first, last)
	if #lines ~= buf_lines.line_count(bufnr) then
		return
	end
	buf_state.set_buffer_tirbuf(bufnr, tir_buf.has_pipe(lines))
end

---@param _ string
---@param bufnr number
---@param tick integer
---@param range3 Range3
---@param bytecount integer
local function on_lines(_, bufnr, tick, range3, bytecount)
	buf_lines.clear_cache()
	recover_flat(bufnr, range3)
	if buf_state.should_skip(bufnr) then return end
	local ctx = get_context(bufnr)
	Debug.ui_entry(bufnr, Range3.short(range3))
	app.on_lines(ctx, range3)
	app.check_and_repair(ctx, range3)
	Debug.ui_exit(bufnr, Range3.short(range3))
end

---@param bufnr number
local function attach_on_lines(bufnr)
	if buf_state.get(bufnr, buf_state.IKEY.ATTACHED) then
		return
	end
	log.debug("===+=== attach on_lines")
	api.nvim_buf_attach(bufnr, false, {
		-- NOTE:
		-- When returning `true` from this callback, the attachment is detached only for
		-- this handler. In this case, `on_detach` is NOT called automatically, so any
		-- state (e.g. ATTACHED flag) must be updated manually here.
		on_lines = function(_, bufnr, tick, first, last, new_last, bytecount)
			if buf_state.get(bufnr, buf_state.IKEY.PARSER) == nil then
				log.debug("===+=== auto detach (no filetype)")
				buf_state.set(bufnr, buf_state.IKEY.ATTACHED, false)
				return true -- detach
			end
			if buf_state.get(bufnr, buf_state.IKEY.PATCH_DEPTH) > 0 then
				return
			end
			on_lines(_, bufnr, tick, Range3.new(first + 1, last, new_last), bytecount)
		end,
		on_detach = function()
			log.debug("===+=== detach on_lines")
			buf_state.set(bufnr, buf_state.IKEY.ATTACHED, false)
		end,
	})
	buf_state.set(bufnr, buf_state.IKEY.ATTACHED, true)
end

---@param ctx Context
local function on_insert_leave(ctx)
	app.check_and_repair(ctx)
end

---@param ctx Context
local function on_buf_read_post(ctx)
	buf_state.clear_buf_local(ctx.bufnr)
	app.read_post(ctx)
end

---@param ctx Context
local function on_buf_write_pre(ctx)
	app.write_pre(ctx)
end

---@param ctx Context
local function on_buf_write_post(ctx)
	app.write_post(ctx)
end

---@param ctx Context
local function on_insert_char_pre(ctx)
	app.insert_char_in_newline(ctx)
end

---@param args table
local function on_cursor_hold(args)
	attach_on_lines(args.buf)
end

---@param args table
local function on_cursor_moved(args)
	local ctx = Context.from_buf(args.buf)
	if vim.log.levels.DEBUG >= config.log.level then
		Debug.show_attr_marks(ctx)
	end
	app.auto_wrap(ctx)
end

---@param ctx Context
local function on_filetype(ctx)
	app.on_filetype(ctx)
end

---@param args table
local function on_vim_leave(args) end

---@param bufnr number
local function clear_buffer_local_autocmds(bufnr)
	buf_state.set(bufnr, buf_state.IKEY.AUTOCMD, false)
	local augroup = api.nvim_create_augroup(GROUP_NAME, { clear = false })
	api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
end

---@param bufnr number
local function register_buffer_local_autocmds(bufnr)
	if buf_state.get(bufnr, buf_state.IKEY.AUTOCMD) then
		return
	end
	buf_state.set(bufnr, buf_state.IKEY.AUTOCMD, true)
	local augroup = api.nvim_create_augroup(GROUP_NAME, { clear = false })
	attach_on_lines(bufnr)

	api.nvim_create_autocmd("BufWritePre", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, { has_grid = true, }) then return end
			Debug.ui_entry(args.buf, args.event)
			local ctx = get_context(args.buf)
			on_buf_write_pre(ctx)
			Debug.ui_exit(args.buf, args.event)
		end),
	})

	api.nvim_create_autocmd("BufWritePost", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, { is_tirbuf = false, }) then
				return
			end
			Debug.ui_entry(args.buf, args.event)
			local ctx = get_context(args.buf)
			on_buf_write_post(ctx)
			Debug.ui_exit(args.buf, args.event)
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

	api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then
				return
			end
			on_cursor_moved(args)
		end),
	})

	api.nvim_create_autocmd("InsertEnter", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			Debug.ui_entry(args.buf, args.event)
			log.assert(not buf_state.get(args.buf, buf_state.IKEY.INSERT_MODE),
				"InsertEnter triggered while already in insert mode")
			buf_state.set(args.buf, buf_state.IKEY.INSERT_MODE, true)
			Debug.ui_exit(args.buf, args.event)
		end),
	})

	api.nvim_create_autocmd("InsertLeave", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			Debug.ui_entry(args.buf, args.event)
			local ctx = get_context(args.buf)
			-- InsertLeave may be triggered without a preceding InsertEnter
			-- due to the behavior of other plugins (e.g., Telescope).
			-- Do not assert insert_mode here.
			buf_state.set(args.buf, buf_state.IKEY.INSERT_MODE, false)
			on_insert_leave(ctx)
			Debug.ui_exit(args.buf, args.event)
		end),
	})

	api.nvim_create_autocmd("InsertCharPre", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			Debug.ui_entry(args.buf, args.event)
			local ctx = get_context(args.buf)
			on_insert_char_pre(ctx)
			Debug.ui_exit(args.buf, args.event)
		end),
	})

	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, { is_tirbuf = false, }) then
				return
			end
			local ctx = Context.from_buf(bufnr)
			ui.special_apply(ctx.winid)
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
			Debug.ui_entry(args.buf, args.event)
			local ctx = get_context(bufnr)
			on_filetype(ctx)
			clear_buffer_local_autocmds(bufnr)
			if buf_state.should_skip(args.buf, { is_tirbuf = false, }) then
				return
			end
			register_buffer_local_autocmds(bufnr)
			Debug.ui_exit(args.buf, args.event)
		end),
	})

	api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, { is_tirbuf = false, }) then
				return
			end
			Debug.ui_entry(args.buf, args.event)
			local ctx = get_context(args.buf)
			on_buf_read_post(ctx)
			Debug.ui_exit(args.buf, args.event)
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
			Debug.ui_entry(args.buf, args.event)
			on_vim_leave(args)
			Debug.ui_exit(args.buf, args.event)
		end),
	})

	if vim.g.tirenvi_test_mode == 1 then
		local ok, luacov = pcall(require, "luacov")
		if ok then
			vim.api.nvim_create_autocmd("VimLeavePre", {
				group = augroup,
				callback = function(args)
					Debug.ui_entry(args.buf, args.event)
					luacov.save_stats()
					Debug.ui_exit(args.buf, args.event)
				end,
			})
		end
	end
end

--#endregion
-- =============================================================================
-- Public API

function M.setup()
	register_autocmds()
end

function M.clear_buf_autocmds(bufnr)
	clear_buffer_local_autocmds(bufnr)
end

function M.register_buf_autocmd(bufnr)
	register_buffer_local_autocmds(bufnr)
end

return M
