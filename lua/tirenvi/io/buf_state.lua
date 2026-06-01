local config = require("tirenvi.config")
local Range3 = require("tirenvi.util.range3")
local buffer = require("tirenvi.io.buffer")
local log = require("tirenvi.util.log")

local M = {}

local api = vim.api
local fn = vim.fn
local bo = vim.bo

---@class Check_options
---@field supported? boolean
---@field has_parser? boolean
---@field is_formatted? boolean
---@field no_vscode? boolean

local DEFAULT_OPTS = {
	supported = true,
	has_parser = true,
	is_formatted = true,
	no_vscode = true,
}
local REPAIR_OFF = "REPAIR_OFF"
local INSERT_LEAVE = "INSERT_LEAVE"
local INSERT_MODE = "INSERT_MODE"
local UNDO_REDO_MODE = "UNDO_REDO_MODE"
local NORMAL_MODE = "NORMAL_MODE"


---@param bufnr number
---@param message string
---@param range3 Range3|nil
local function log_watch(bufnr, message, range3)
	range3 = range3 or Range3.new(0, 0, 0)
	local pre = buffer.get(bufnr, buffer.IKEY.UNDO_TREE_LAST)
	local next = fn.undotree(bufnr).seq_last
	local status = string.format(
		"[tree:%d->%d]%s",
		pre,
		next,
		Range3.short(range3)
	)
	log.watch("UNDO", message .. status)
end

---@param bufnr number
---@return boolean
local function is_insert_mode(bufnr)
	local mode = buffer.get(bufnr, buffer.IKEY.INSERT_MODE) == true
	if mode then
		log.debug("===-===-===-=== insert mode[%d] ===-===-===-===", bufnr)
	end
	return mode
end

---@param bufnr number
---@return boolean
local function is_undo_mode(bufnr)
	local pre = buffer.get(bufnr, buffer.IKEY.UNDO_TREE_LAST)
	local next = fn.undotree(bufnr).seq_last
	if pre == next then
		log.debug("===-===-===-=== und/redo mode[%d] (%d, %d) ===-===-===-===", bufnr, pre, next)
		return true
	end
	return false
end

---@param ctx Context
---@param range3 Range3|nil
---@return string
local function get_status(ctx, range3)
	if buffer.get_repair(ctx.bufnr) == false then
		return REPAIR_OFF
	end
	if not range3 then
		return INSERT_LEAVE
	elseif is_insert_mode(ctx.bufnr) then
		-- Modifying the buffer in insert mode may corrupt the undo node.
		-- Therefore, in insert mode, only record the dirty changed region
		-- and repair it when leaving insert mode.
		return INSERT_MODE
	elseif is_undo_mode(ctx.bufnr) then
		-- Moving the cursor in insert mode may create an dirty table undo node.
		-- Therefore, when performing undo/redo, skip table validation.
		return UNDO_REDO_MODE
	else
		return NORMAL_MODE
	end
end

local checks = {
	supported = function(bufnr)
		return bo[bufnr].modifiable
	end,

	has_parser = function(bufnr)
		return buffer.get(bufnr, buffer.IKEY.FILETYPE) ~= nil
	end,

	is_formatted = function(bufnr)
		return M.is_formatted(bufnr)
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
				log.debug("===+=== skip:(%d) %s", bufnr, name)
				return true
			end
		end
	end
	return false
end

---@param ctx Context
---@param range3 Range3|nil
---@return boolean
function M.is_repair(ctx, range3)
	local status = get_status(ctx, range3)
	log_watch(ctx.bufnr, status, range3)
	if status == INSERT_MODE then
		return false
	end
	if status == UNDO_REDO_MODE then
		return false
	end
	if status == REPAIR_OFF then
		return false
	end
	return true
end

---@param bufnr number
---@param value BufferFormat
function M.set_buffer_format(bufnr, value)
	buffer.set(bufnr, buffer.IKEY.BUFFER_FORMAT, value)
end

---@param bufnr number
---@return BufferFormat|nil
function M.get_buffer_format(bufnr)
	return buffer.get(bufnr, buffer.IKEY.BUFFER_FORMAT)
end

---@return boolean
function M.is_flat(bufnr)
	return M.get_buffer_format(bufnr) == "flat"
end

---@return boolean
function M.is_formatted(bufnr)
	return M.get_buffer_format(bufnr) == "formatted"
end

return M
