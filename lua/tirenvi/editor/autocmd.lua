-- dependencies
local guard = require("tirenvi.util.guard")
local buffer = require("tirenvi.state.buffer")
local init = require("tirenvi.init")
local buf_state = require("tirenvi.state.buf_state")
local log = require("tirenvi.util.log")
local util = require("tirenvi.util.util")
local ui = require("tirenvi.ui")

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

---@param _ string
---@param bufnr number
---@param tick integer
---@param first integer
---@param last integer
---@param new_last integer
---@param bytecount integer
local function on_lines(_, bufnr, tick, first, last, new_last, bytecount)
	buffer.clear_cache()
	if buf_state.should_skip(bufnr) then return end
	init.on_lines(bufnr, first, last, new_last)
end

---@param bufnr number
local function attach_on_lines(bufnr)
	buffer.attach_on_lines(bufnr, on_lines)
end

---@param bufnr number
local function on_insert_leave(bufnr)
	init.on_insert_leave(bufnr)
end

---@param args table
local function on_buf_read_post(args)
	init.import_flat(args.buf)
end

---@param args table
local function on_buf_write_pre(args)
	init.export_flat(args.buf)
end

---@param args table
local function on_buf_write_post(args)
	init.restore_tir_vim(args.buf)
end

---@param args table
local function on_insert_char_pre(args)
	init.insert_char_in_newline(args.buf)
end

---@param args table
local function on_cursor_hold(args)
	attach_on_lines(args.buf)
end

---@param args table
local function on_filetype(args)
	init.on_filetype(args.buf)
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
			if buf_state.should_skip(args.buf, {
					is_tir_vim = true,
				}) then
				return
			end
			debug_entry_point(args)
			on_buf_write_pre(args)
		end),
	})

	api.nvim_create_autocmd("BufWritePost", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			debug_entry_point(args)
			on_buf_write_post(args)
		end),
	})

	api.nvim_create_autocmd("CursorHold", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			on_cursor_hold(args)
		end),
	})

	api.nvim_create_autocmd("InsertEnter", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			debug_entry_point(args)
			assert(not buffer.get(args.buf, buffer.IKEY.INSERT_MODE))
			buffer.set(args.buf, buffer.IKEY.INSERT_MODE, true)
		end),
	})

	api.nvim_create_autocmd("InsertLeave", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			debug_entry_point(args)
			-- InsertLeave may be triggered without a preceding InsertEnter
			-- due to the behavior of other plugins (e.g., Telescope).
			-- Do not assert insert_mode here.
			buffer.set(args.buf, buffer.IKEY.INSERT_MODE, false)
			on_insert_leave(args.buf)
		end),
	})

	api.nvim_create_autocmd("InsertCharPre", {
		group = augroup,
		buffer = bufnr,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			debug_entry_point(args)
			on_insert_char_pre(args)
		end),
	})

	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
		group = augroup,
		buffer = bufnr,
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
			on_filetype(args)
			clear_buffer_local_autocmds(augroup, args.buf)
			local _, err = util.resolve_parser(args.buf)
			if not err then
				register_buffer_local_autocmds(augroup, args.buf)
			end
		end),
	})

	api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf) then return end
			debug_entry_point(args)
			on_buf_read_post(args)
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
