-- dependencies
local Context = require("tirenvi.app.context")
local buffer = require("tirenvi.io.buffer")
local init = require("tirenvi.init")
local buf_state = require("tirenvi.io.buf_state")
local ui = require("tirenvi.ui")
local guard = require("tirenvi.util.guard")
local Range3 = require("tirenvi.util.range3")
local log = require("tirenvi.util.log")

-- module
local M = {}

-- constants / defaults
local GROUP_NAME = "tirenvi"

local api = vim.api
local bo = vim.bo
local fn = vim.fn

----------------------------------------------------------------------
-- Event handlers (private)
----------------------------------------------------------------------

local function get_context(bufnr)
	return Context.from_buf(bufnr)
end

---@param _ string
---@param bufnr number
---@param tick integer
---@param range3 Range3
---@param bytecount integer
local function on_lines(_, bufnr, tick, range3, bytecount)
	buffer.clear_cache()
	if buf_state.should_skip(bufnr) then return end
	local ctx = get_context(bufnr)
	init.on_lines(ctx, range3)
end

---@param ctx Context
local function attach_on_lines(ctx)
	local bufnr = ctx.bufnr
	if buffer.get(bufnr, buffer.IKEY.ATTACHED) then
		return
	end
	log.debug("===+===+=== attach onlines")
	api.nvim_buf_attach(bufnr, false, {
		-- NOTE:
		-- When returning `true` from this callback, the attachment is detached only for
		-- this handler. In this case, `on_detach` is NOT called automatically, so any
		-- state (e.g. ATTACHED flag) must be updated manually here.
		on_lines = function(_, bufnr, tick, first, last, new_last, bytecount)
			if buffer.get(bufnr, buffer.IKEY.FILETYPE) == nil then
				log.debug("===+===+=== auto detach (no filetype)")
				buffer.set(bufnr, buffer.IKEY.ATTACHED, false)
				return true -- detach
			end
			if buffer.get(bufnr, buffer.IKEY.PATCH_DEPTH) > 0 then
				return
			end
			on_lines(_, bufnr, tick, Range3.new(first + 1, last, new_last), bytecount)
		end,
		on_detach = function()
			log.debug("===+===+=== detach onlines")
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
	init.import_flat(ctx)
end

---@param ctx Context
local function on_buf_write_pre(ctx)
	init.export_flat(ctx)
end

---@param ctx Context
local function on_buf_write_post(ctx)
	init.restore_tir_vim(ctx)
end

---@param ctx Context
local function on_insert_char_pre(ctx)
	init.insert_char_in_newline(ctx)
end

---@param args table
local function on_cursor_hold(args)
	attach_on_lines(args)
end

---@param ctx Context
---@return Context
local function on_filetype(ctx)
	return init.on_filetype(ctx)
end

---@param args table
local function on_vim_leave(args) end

----------------------------------------------------------------------
-- Autocmd registration (private)
----------------------------------------------------------------------

local function debug_entry_point(args)
	local filetype = bo[args.buf].filetype
	log.debug("===+===+===+===+=== %s[#%d]%s ===+===+===+===+===", args.event, args.buf, filetype)
end

---@param augroup integer
---@param ctx Context
local function clear_buffer_local_autocmds(augroup, ctx)
	api.nvim_clear_autocmds({ group = augroup, buffer = ctx.bufnr })
end

---@param augroup integer
---@param ctx Context
local function register_buffer_local_autocmds(augroup, ctx)
	attach_on_lines(ctx)

	api.nvim_create_autocmd("BufWritePre", {
		group = augroup,
		buffer = ctx.bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			debug_entry_point(args)
			local ctx = get_context(args.bufnr)
			on_buf_write_pre(ctx)
		end),
	})

	api.nvim_create_autocmd("BufWritePost", {
		group = augroup,
		buffer = ctx.bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			debug_entry_point(args)
			local ctx = get_context(args.bufnr)
			on_buf_write_post(ctx)
		end),
	})

	api.nvim_create_autocmd("CursorHold", {
		group = augroup,
		buffer = ctx.bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			on_cursor_hold(args)
		end),
	})

	api.nvim_create_autocmd("InsertEnter", {
		group = augroup,
		buffer = ctx.bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			debug_entry_point(args)
			local ctx = get_context(args.bufnr)
			assert(not buffer.get(args.buf, buffer.IKEY.INSERT_MODE))
			buffer.set(args.buf, buffer.IKEY.INSERT_MODE, true)
		end),
	})

	api.nvim_create_autocmd("InsertLeave", {
		group = augroup,
		buffer = ctx.bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			debug_entry_point(args)
			local ctx = get_context(args.bufnr)
			-- InsertLeave may be triggered without a preceding InsertEnter
			-- due to the behavior of other plugins (e.g., Telescope).
			-- Do not assert insert_mode here.
			buffer.set(args.buf, buffer.IKEY.INSERT_MODE, false)
			on_insert_leave(ctx)
		end),
	})

	api.nvim_create_autocmd("InsertCharPre", {
		group = augroup,
		buffer = ctx.bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			debug_entry_point(args)
			local ctx = get_context(args.bufnr)
			on_insert_char_pre(ctx)
		end),
	})

	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
		group = augroup,
		buffer = ctx.bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			ui.special_apply()
		end),
	})
end

local function register_autocmds()
	local augroup = api.nvim_create_augroup(GROUP_NAME, { clear = true })

	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, {
					has_parser = false,
				}) then
				return
			end
			debug_entry_point(args)
			local ctx = get_context(args.bufnr)
			ctx = on_filetype(ctx)
			clear_buffer_local_autocmds(augroup, ctx)
			if buf_state.should_skip(args.buf) then return end
			register_buffer_local_autocmds(augroup, ctx)
		end),
	})

	api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			debug_entry_point(args)
			local ctx = get_context(args.bufnr)
			on_buf_read_post(ctx)
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
			debug_entry_point(args)
			on_vim_leave(args)
		end),
	})

	if vim.g.tirenvi_test_mode == 1 then
		local ok, luacov = pcall(require, "luacov")
		if ok then
			vim.api.nvim_create_autocmd("VimLeavePre", {
				callback = function(args)
					debug_entry_point(args)
					luacov.save_stats()
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
