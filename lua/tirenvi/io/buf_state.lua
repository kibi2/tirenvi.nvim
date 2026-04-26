local config = require("tirenvi.config")
local log = require("tirenvi.util.log")
local buffer = require("tirenvi.io.buffer")

local M = {}

local api = vim.api
local fn = vim.fn
local bo = vim.bo

---@class Check_options
---@field supported? boolean
---@field has_parser? boolean
---@field no_vscode? boolean

local DEFAULT_OPTS = {
	supported = true,
	has_parser = true,
	no_vscode = true,
}

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
		return bo[bufnr].modifiable
	end,

	has_parser = function(bufnr)
		return buffer.get(bufnr, buffer.IKEY.FILETYPE) ~= nil
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
---@param user_opts Check_options|nil
---@return boolean
function M.should_skip(bufnr, user_opts)
	if config.log.buffer_name == api.nvim_buf_get_name(bufnr) then
		return true
	end
	local opts = vim.tbl_deep_extend("force", DEFAULT_OPTS, user_opts or {})
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
