-- dependencies
local guard = require("tirenvi.util.guard")
local buffer = require("tirenvi.state.buffer")
local init = require("tirenvi.init")
local buf_state = require("tirenvi.state.buf_state")
local config = require("tirenvi.config")
local log = require("tirenvi.util.log")
local validator = require("tirenvi.core.validator")

-- module
local M = {}

-- constants / defaults
local GROUP_NAME = "tirenvi"

local api = vim.api

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
	local old_path = buffer.get_file_path(args.buf)
	local new_path = buffer.to_file_path(args.file)
	init.export_flat(args.buf, new_path, old_path)
end

---@param args table
local function on_buf_write_post(args)
	local old_path = buffer.get_file_path(args.buf)
	local new_path = buffer.to_file_path(args.file)
	init.restore_tir_vim(args.buf, new_path, old_path)
end

---@param bufnr number
---@param new_path string
---@param old_path string
local function on_buf_file_post(bufnr, new_path, old_path)
	local new_path = buffer.to_file_path(new_path)
	init.export_flat(bufnr, new_path, old_path)
	init.enable(bufnr)
	attach_on_lines(bufnr)
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
local function on_vim_leave(args) end

---@return string[]
local function get_tirenvi_patterns()
	local tirenvi_patterns = {}
	for ext, _ in pairs(config.parser_map) do
		table.insert(tirenvi_patterns, "*." .. ext)
	end
	return tirenvi_patterns
end

----------------------------------------------------------------------
-- Autocmd registration (private)
----------------------------------------------------------------------

local function register_autocmds()
	local augroup = api.nvim_create_augroup(GROUP_NAME, { clear = true })
	api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		-- Process only items for which a parser has been specified
		pattern = get_tirenvi_patterns(),
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, {
					unsupported = true,
					has_parser = true,
				}) then
				return
			end
			log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
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
			log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
			local old_path = buffer.get_file_path(args.buf)
			buffer.set(args.buf, buffer.IKEY.OLD_PATH, old_path)
			on_buf_write_pre(args)
		end),
	})

	api.nvim_create_autocmd("BufWritePost", {
		group = augroup,
		callback = guard.guarded(function(args)
			local old_path = buffer.get(args.buf, buffer.IKEY.OLD_PATH)
			if not old_path then
				log.debug("===+===+===+===+=== %s %s skip", args.event, args.buf)
				return
			end
			log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
			buffer.set(args.buf, buffer.IKEY.OLD_PATH, nil)
			on_buf_write_post(args)
		end),
	})

	api.nvim_create_autocmd("BufFilePre", {
		group = augroup,
		callback = guard.guarded(function(args)
			if buf_state.should_skip(args.buf, {
					unsupported = true,
					already_invalid = true,
				}) then
				return
			end
			log.debug("===+===+===+===+=== BufFilePre %s ===+===+===+===+===", args.buf)
			local old_path = buffer.get_file_path(args.buf)
			buffer.set(args.buf, buffer.IKEY.OLD_PATH, old_path)
			log.debug(buffer.get(args.buf, buffer.IKEY.OLD_PATH))
		end),
	})

	api.nvim_create_autocmd("BufFilePost", {
		group = augroup,
		callback = guard.guarded(function(args)
			local old_path = buffer.get(args.buf, buffer.IKEY.OLD_PATH)
			---@cast  old_path string | nil
			if not old_path then
				return
			end
			log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
			buffer.set(args.buf, buffer.IKEY.OLD_PATH, nil)
			on_buf_file_post(args.buf, args.file, old_path)
		end),
	})

	api.nvim_create_autocmd("CursorHold", {
		group = augroup,
		pattern = get_tirenvi_patterns(),
		callback = guard.guarded(function(args)
			log.debug()
			if buf_state.should_skip(args.buf, {
					unsupported = true,
					already_invalid = true,
					has_parser = true,
				}) then
				return
			end
			-- log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
			on_cursor_hold(args)
		end),
	})

	api.nvim_create_autocmd("InsertEnter", {
		group = augroup,
		pattern = get_tirenvi_patterns(),
		callback = function(args)
			log.debug()
			if buf_state.should_skip(args.buf, {
					unsupported = true,
					already_invalid = true,
					has_parser = true,
				}) then
				return
			end
			log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
			assert(not buffer.get(args.buf, buffer.IKEY.INSERT_MODE))
			buffer.set(args.buf, buffer.IKEY.INSERT_MODE, true)
		end,
	})

	api.nvim_create_autocmd("InsertLeave", {
		group = augroup,
		pattern = get_tirenvi_patterns(),
		callback = function(args)
			if buf_state.should_skip(args.buf, {
					unsupported = true,
					already_invalid = true,
					has_parser = true,
				}) then
				return
			end
			log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
			-- InsertLeave may be triggered without a preceding InsertEnter
			-- due to the behavior of other plugins (e.g., Telescope).
			-- Do not assert insert_mode here.
			buffer.set(args.buf, buffer.IKEY.INSERT_MODE, false)
			on_insert_leave(args.buf)
		end,
	})

	api.nvim_create_autocmd("InsertCharPre", {
		group = augroup,
		pattern = get_tirenvi_patterns(),
		callback = function(args)
			if buf_state.should_skip(args.buf, {
					unsupported = true,
					already_invalid = true,
					is_tir_vim = true,
				}) then
				return
			end
			log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
			on_insert_char_pre(args)
		end,
	})

	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
		callback = function()
			vim.fn.clearmatches()
			vim.fn.matchadd("TirenviPipe", config.marks.pipe, 20)
			vim.fn.matchadd("TirenviPadding", config.marks.padding, 10)
		end,
	})

	api.nvim_create_autocmd("VimLeave", {
		group = augroup,
		callback = guard.guarded(function(args)
			log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
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
