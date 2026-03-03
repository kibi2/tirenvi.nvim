local log = require("tirenvi.util.log")
local errors = require("tirenvi.util.errors")
local util = require("tirenvi.util.util")
local buffer = require("tirenvi.state.buffer")

local M = {}

local fn = vim.fn
local bo = vim.bo
--- ensure the buffer has a parser and the parser is executable. for example, it may be a tir-vim buffer.
---@param bufnr number
---@return boolean
local function ensure_has_parser(bufnr)
	if bo[bufnr].buftype ~= "" then
		return false
	end
	local parser = util.get_parser(bufnr)
	assert(parser ~= nil, "If no parser exists, an error is raised inside get_parser_name.")
	return true
end

--- has pipe markers. for example, it may be a tir-vim buffer.
---@param bufnr number
---@return boolean
local function has_pipe(bufnr)
	log.debug("check has_pipe: %d", bufnr)
	local fl_lines = buffer.get_lines(bufnr, 0, -1, false)
	for _, fl_line in ipairs(fl_lines) do
		if util.has_pipe(fl_line) then
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
function M.is_undo_mode(bufnr)
	if buffer.get(bufnr, buffer.IKEY.INSERT_MODE) then
		return false
	end
	local ut = fn.undotree()
	if buffer.get(bufnr, buffer.IKEY.UNDO_TREE_LASET) == ut.seq_last then
		return true
	end
	buffer.set(bufnr, buffer.IKEY.UNDO_TREE_LASET, ut.seq_last)
	return false
end

--- set unsupported buffer. for example, ther is no parser for the file, or the parser fails to parse it.
---@param bufnr number
function M.set_invalid(bufnr)
	log.debug("set unsupported buffer: %d", bufnr)
	buffer.set(bufnr, buffer.IKEY.BUFFER_INVALID, true)
end

local checks = {
	unsupported = function(bufnr)
		return bo[bufnr].buftype == ""
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

	already_invalid = function(bufnr)
		return not buffer.get(bufnr, buffer.IKEY.BUFFER_INVALID)
	end,
}

--- check if the buffer is supported and valid according to the options. for example, it may be a tir-vim buffer.
---@param bufnr number
---@param opts Check_options
---@return boolean
function M.should_skip(bufnr, opts)
	for name, enabled in pairs(opts) do
		if enabled then
			local ok = checks[name](bufnr)
			if not ok then
				log.debug("===+===+=== skip: %s", name)
				return true
			end
		end
	end
	return false
end

return M
