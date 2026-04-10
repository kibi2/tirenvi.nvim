local config = require("tirenvi.config")
local log = require("tirenvi.util.log")
local errors = require("tirenvi.util.errors")
local config = require("tirenvi.config")
local buffer = require("tirenvi.state.buffer")
local tir_vim = require("tirenvi.core.tir_vim")

local M = {}

local api = vim.api
local fn = vim.fn
local bo = vim.bo
--- ensure the buffer has a parser and the parser is executable. for example, it may be a tir-vim buffer.
---@param bufnr number
---@return boolean
local function ensure_has_parser(bufnr)
	if not bo[bufnr].modifiable then
		log.debug("buftype:%s", bo[bufnr].buftype)
		return false
	end

	local filetype = buffer.get(bufnr, buffer.IKEY.FILETYPE)
	if not filetype then
		return false
	end

	local parser = config.parser_map[filetype]
	if not parser then
		return false
	end

	-- For passive checks (autocmd gating), missing executables should only
	-- skip processing rather than raise user-facing notifications.
	return fn.executable(parser.executable) == 1
end

--- has pipe markers. for example, it may be a tir-vim buffer.
---@param bufnr number
---@return boolean
local function has_pipe(bufnr)
	for iline = 0, buffer.line_count(bufnr) do
		local fl_line = buffer.get_line(bufnr, iline)
		if tir_vim.get_pipe_char(fl_line) then
			return true
		end
	end
	return false
end

--- the buffer is tir-vim mode.
---@param bufnr number
---@return boolean
function M.is_tir_vim(bufnr)
	return has_pipe(bufnr)
end

---@param bufnr number
---@return boolean
function M.is_insert_mode(bufnr)
	local mode = buffer.get(bufnr, buffer.IKEY.INSERT_MODE) == true
	if mode then
		log.debug("===-===-===-=== insert mode[%d] ===-===-===-===", bufnr)
	end
	return mode
end

---@param bufnr number
---@return boolean
function M.is_undo_mode(bufnr)
	local pre = buffer.get(bufnr, buffer.IKEY.UNDO_TREE_LAST)
	local next = fn.undotree(bufnr).seq_last
	if pre == next then
		log.debug("===-===-===-=== und/redo mode[%d] (%d, %d) ===-===-===-===", bufnr, pre, next)
		return true
	end
	return false
end

local checks = {
	supported = function(bufnr)
		-- return bo[bufnr].buftype == ""
		return bo[bufnr].modifiable
	end,

	ensure_tir_vim = function(bufnr)
		if not M.is_tir_vim(bufnr) then
			error(errors.ENSURE_TIRVIM_MODE)
		end
		return true
	end,

	is_tir_vim = function(bufnr)
		return M.is_tir_vim(bufnr)
	end,

	has_parser = function(bufnr)
		return ensure_has_parser(bufnr)
	end,

	no_vscode = function()
		return not M.is_vscode()
	end,
}

---@return boolean
function M.is_vscode()
	return vim.g.vscode ~= nil
end

--- check if the buffer is supported and valid according to the options. for example, it may be a tir-vim buffer.
---@param bufnr number
---@param opts Check_options
---@return boolean
function M.should_skip(bufnr, opts)
	if config.log.buffer_name == api.nvim_buf_get_name(bufnr) then
		return true
	end
	for name, enabled in pairs(opts) do
		if enabled then
			local ok = checks[name](bufnr)
			if not ok then
				log.debug("===+===+=== skip:(%d) %s", bufnr, name)
				return true
			end
		end
	end
	return false
end

return M
