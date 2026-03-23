-- dependencies
local guard = require("tirenvi.util.guard")
local buffer = require("tirenvi.state.buffer")
local init = require("tirenvi.init")
local buf_state = require("tirenvi.state.buf_state")
local config = require("tirenvi.config")
local log = require("tirenvi.util.log")
local ui = require("tirenvi.ui")

-- module
local M = {}

-- constants / defaults
local GROUP_NAME = "tirenvi"

local api = vim.api
local bo = vim.bo

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
	init.on_lines(bufnr, first, last, new_last)
end

---@param bufnr number
local function attach_on_lines(bufnr)
	local check_items = {
		unsupported = true,
		has_parser = true,
		already_invalid = true,
	}
	if buf_state.should_skip(bufnr, check_items) then
		return
	end
	buffer.attach_on_lines(bufnr, on_lines)
end

---@param bufnr number
local function on_insert_leave(bufnr)
	init.on_insert_leave(bufnr)
end

---@param args table
local function on_buf_read_post(args)
	init.import_flat(args.buf)
	attach_on_lines(args.buf)
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
	log.debug("===+===+===+===+=== %s(%d)%s ===+===+===+===+===", args.event, args.buf, filetype)
end

local function register_autocmds()
	local augroup = api.nvim_create_augroup(GROUP_NAME, { clear = true })
	api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		-- Process only items for which a parser has been specified
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, {
					unsupported = true,
					has_parser = true,
				}) then
				return
			end
			debug_entry_point(args)
			on_buf_read_post(args)
		end, {
			on_error = function(args)
				buf_state.set_invalid(args.buf)
			end,
		}),
	})

	api.nvim_create_autocmd("BufWritePre", {
		group = augroup,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, {
					unsupported = true,
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
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, {
					unsupported = true,
				}) then
				return
			end
			debug_entry_point(args)
			on_buf_write_post(args)
		end),
	})

	api.nvim_create_autocmd("CursorHold", {
		group = augroup,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, {
					unsupported = true,
					already_invalid = true,
					has_parser = true,
				}) then
				return
			end
			-- debug_entry_point(args)
			on_cursor_hold(args)
		end),
	})

	api.nvim_create_autocmd("InsertEnter", {
		group = augroup,
		callback = guard.guarded(function(args)
			debug_entry_point(args)
			if buf_state.should_skip(args.buf, {
					unsupported = true,
					already_invalid = true,
					has_parser = true,
				}) then
				return
			end
			debug_entry_point(args)
			assert(not buffer.get(args.buf, buffer.IKEY.INSERT_MODE))
			buffer.set(args.buf, buffer.IKEY.INSERT_MODE, true)
		end),
	})

	api.nvim_create_autocmd("InsertLeave", {
		group = augroup,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, {
					unsupported = true,
					already_invalid = true,
					has_parser = true,
				}) then
				return
			end
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
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, {
					unsupported = true,
					already_invalid = true,
					is_tir_vim = true,
				}) then
				return
			end
			debug_entry_point(args)
			on_insert_char_pre(args)
		end),
	})

	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, {
					unsupported = true,
					already_invalid = true,
					is_tir_vim = true,
				}) then
				return
			end
			ui.special_clear()
			ui.special_apply()
		end),
	})

	vim.api.nvim_create_autocmd("WinClosed", {
		callback = guard.guarded(function(args)
			local winid = tonumber(args.match)
			pcall(ui.clear_matches, winid)
		end),
	})

	vim.api.nvim_create_autocmd("FileType", {
		callback = guard.guarded(function(args)
			debug_entry_point(args)
			on_filetype(args)
		end),
	})

	api.nvim_create_autocmd("VimLeave", {
		group = augroup,
		callback = guard.guarded(function(args)
			debug_entry_point(args)
			on_vim_leave(args)
		end),
	})
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------

function M.setup()
	register_autocmds()
end

return M
