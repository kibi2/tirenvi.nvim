-- dependencies
local CONST = require("tirenvi.constants")
local guard = require("tirenvi.guard")
local config = require("tirenvi.config")
local api = require("tirenvi")
local buf_state = require("tirenvi.buf_state")
local vimHelper = require("tirenvi.vimHelper")
local log = require("tirenvi.log")
local validity = require("tirenvi.validity")

-- module
local M = {}

-- constants / defaults
local GROUP_NAME = "tirenvi"

----------------------------------------------------------------------
-- Event handlers (private)
----------------------------------------------------------------------

---@param bufnr number
local function attach_on_lines(bufnr)
	local check_items = {
		unsupported = true,
		has_parser = true,
		already_invalid = true,
	}
	if buf_state.is_not_executable(bufnr, check_items) then
		return
	end
	api.attach_on_lines(bufnr)
end

---@param args table
local function on_buf_read_post(args)
	api.import_flat(args.buf, false)
	attach_on_lines(args.buf)
end

---@param args table
local function on_buf_write_pre(args)
	local old_path = vimHelper.get_file_path(args.buf)
	local new_path = vimHelper.to_file_path(args.file)
	api.export_flat(args.buf, new_path, old_path)
end

---@param args table
local function on_buf_write_post(args)
	local old_path = vimHelper.get_file_path(args.buf)
	local new_path = vimHelper.to_file_path(args.file)
	api.restore_tir_vim(args.buf, new_path, old_path)
end

local function on_buf_file_post(args, old_path)
	local new_path = vimHelper.to_file_path(args.file)
	api.export_flat(args.buf, new_path, old_path)
	api.enable(args.buf)
	attach_on_lines(args.buf)
end

---@param args table
local function on_insert_char_pre(args)
	api.insert_char_in_newline(args.buf)
end

---@param args table
local function on_cursor_hold(args)
	attach_on_lines(args.buf)
end

---@param args table
local function on_vim_leave(args) end

----------------------------------------------------------------------
-- Autocmd registration (private)
----------------------------------------------------------------------

local function register_autocmds()
	local augroup = vim.api.nvim_create_augroup(GROUP_NAME, { clear = true })
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		-- Process only items for which a parser has been specified
		pattern = api.get_tirenvi_patterns(),
		callback = guard.guarded(function(args)
			local check_items = {
				unsupported = true,
				has_parser = true,
			}
			if buf_state.is_not_executable(args.buf, check_items) then
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

	vim.api.nvim_create_autocmd("BufWritePre", {
		group = augroup,
		callback = guard.guarded(function(args)
			local check_items = {
				unsupported = true,
				is_tir_vim = true,
			}
			if buf_state.is_not_executable(args.buf, check_items) then
				return
			end
			log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
			local old_path = vimHelper.get_file_path(args.buf)
			vim.b[args.buf][CONST.BUF_KEY.OLD_PATH] = old_path
			on_buf_write_pre(args)
		end),
	})

	vim.api.nvim_create_autocmd("BufWritePost", {
		group = augroup,
		callback = guard.guarded(function(args)
			local old_path = vim.b[args.buf][CONST.BUF_KEY.OLD_PATH]
			if not old_path then
				log.debug("===+===+===+===+=== %s %s skip", args.event, args.buf)
				return
			end
			log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
			vim.b[args.buf][CONST.BUF_KEY.OLD_PATH] = nil
			on_buf_write_post(args)
		end),
	})

	vim.api.nvim_create_autocmd("BufFilePre", {
		group = augroup,
		callback = guard.guarded(function(args)
			local check_items = {
				unsupported = true,
				already_invalid = true,
			}
			if buf_state.is_not_executable(args.buf, check_items) then
				return
			end
			log.debug("===+===+===+===+=== BufFilePre %s ===+===+===+===+===", args.buf)
			local old_path = vimHelper.get_file_path(args.buf)
			vim.b[args.buf][CONST.BUF_KEY.OLD_PATH] = old_path
			log.debug(vim.b[args.buf][CONST.BUF_KEY.OLD_PATH])
		end),
	})

	vim.api.nvim_create_autocmd("BufFilePost", {
		group = augroup,
		callback = guard.guarded(function(args)
			local old_path = vim.b[args.buf][CONST.BUF_KEY.OLD_PATH]
			if not old_path then
				return
			end
			log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
			vim.b[args.buf][CONST.BUF_KEY.OLD_PATH] = nil
			on_buf_file_post(args, old_path)
		end),
	})

	vim.api.nvim_create_autocmd("CursorHold", {
		group = augroup,
		pattern = api.get_tirenvi_patterns(),
		callback = guard.guarded(function(args)
			log.debug()
			local check_items = {
				unsupported = true,
				already_invalid = true,
				has_parser = true,
			}
			if buf_state.is_not_executable(args.buf, check_items) then
				return
			end
			-- log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
			on_cursor_hold(args)
		end),
	})

	vim.api.nvim_create_autocmd("InsertEnter", {
		group = augroup,
		pattern = api.get_tirenvi_patterns(),
		callback = function(args)
			log.debug()
			local check_items = {
				unsupported = true,
				already_invalid = true,
				has_parser = true,
			}
			if buf_state.is_not_executable(args.buf, check_items) then
				return
			end
			log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
			assert(not vim.b[args.buf][CONST.BUF_KEY.INSERT_MODE])
			vim.b[args.buf][CONST.BUF_KEY.INSERT_MODE] = true
		end,
	})

	vim.api.nvim_create_autocmd("InsertLeave", {
		group = augroup,
		pattern = api.get_tirenvi_patterns(),
		callback = function(args)
			local check_items = {
				unsupported = true,
				already_invalid = true,
				has_parser = true,
			}
			if buf_state.is_not_executable(args.buf, check_items) then
				return
			end
			log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
			-- InsertLeave may be triggered without a preceding InsertEnter
			-- due to the behavior of other plugins (e.g., Telescope).
			-- Do not assert INSERT_MODE here.
			-- assert(vim.b[args.buf][CONST.BUF_KEY.INSERT_MODE])
			vim.b[args.buf][CONST.BUF_KEY.INSERT_MODE] = false
			if vim.b[args.buf][CONST.BUF_KEY.PENDING_REPAIR_ROWS] then
				validity.repair_invalid_tir_vim(args.buf, 0, -1, -1, true)
				vim.b[args.buf][CONST.BUF_KEY.PENDING_REPAIR_ROWS] = nil
			end
		end,
	})

	vim.api.nvim_create_autocmd("InsertCharPre", {
		group = augroup,
		pattern = api.get_tirenvi_patterns(),
		callback = function(args)
			local check_items = {
				unsupported = true,
				already_invalid = true,
				is_tir_vim = true,
			}
			if buf_state.is_not_executable(args.buf, check_items) then
				return
			end
			log.debug("===+===+===+===+=== %s %s ===+===+===+===+===", args.event, args.buf)
			on_insert_char_pre(args)
		end,
	})

	vim.api.nvim_create_autocmd("VimLeave", {
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
