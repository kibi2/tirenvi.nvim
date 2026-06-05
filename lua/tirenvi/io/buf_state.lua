local Context = require("tirenvi.app.context")
local config = require("tirenvi.config")
local Range3 = require("tirenvi.util.range3")
local Attrs = require("tirenvi.core.attrs")
local buffer = require("tirenvi.io.buffer")
local log = require("tirenvi.util.log")

local M = {}

local api = vim.api
local fn = vim.fn
local bo = vim.bo

---@class Check_options
---@field supported? boolean
---@field has_parser? boolean
---@field is_tirbuf? boolean
---@field no_vscode? boolean

local DEFAULT_OPTS = {
	supported = true,
	has_parser = true,
	is_tirbuf = true,
	has_grid = false,
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

	is_tirbuf = function(bufnr)
		return M.is_flat(bufnr) ~= true
	end,

	has_grid = function(bufnr)
		local ctx = Context.from_buf(bufnr)
		local has_grid = M.has_grid(ctx)
		return has_grid == nil or has_grid == true
	end,

	no_vscode = function()
		return not M.is_vscode()
	end,
}

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

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
---@return boolean|nil
function M.is_repair(ctx, range3)
	local status = get_status(ctx, range3)
	log_watch(ctx.bufnr, status, range3)
	if status == INSERT_MODE then
		return false
	end
	if status == UNDO_REDO_MODE then
		return false, true
	end
	if status == REPAIR_OFF then
		return false
	end
	return true
end

---@param bufnr number
---@param value boolean
function M.set_buffer_flat(bufnr, value)
	buffer.set(bufnr, buffer.IKEY.FLAT, value)
end

---@param ctx Context
---@return string
local function get_count(ctx)
	if not Context.is_allow_plain(ctx) then
		return "P0G1"
	end
	local attrs = buffer.get(ctx.bufnr, buffer.IKEY.ATTRS)
	local count = Attrs.get_count(attrs)
	if not count then
		return "NIL"
	end
	return string.format("P%dG%d", count.plain, count.grid)
end

---@param bufnr number
---@return string
function M.debug_state(bufnr)
	if not log.is_debug() then
		return ""
	end
	local ctx = Context.from_buf(bufnr)
	local allow_plain = Context.is_allow_plain(ctx)
	local flat
	local is_flat = buffer.get(bufnr, buffer.IKEY.FLAT)
	if is_flat == nil then
		flat = "NIL"
	else
		flat = is_flat and ",A," or "|A|"
	end
	local count = get_count(ctx)
	if not allow_plain then
		log.assert(count == "P0G1", "grid must be enabled when plain is not allowed")
	end
	return string.format("%s/%s/%s", allow_plain and "GFM" or "CSV", flat, count)
end

---@return boolean|nil
function M.is_flat(bufnr)
	return buffer.get(bufnr, buffer.IKEY.FLAT)
end

---@param ctx Context
---@return boolean|nil
function M.has_grid(ctx)
	if not Context.is_allow_plain(ctx) then
		return true
	end
	local attrs = buffer.get(ctx.bufnr, buffer.IKEY.ATTRS)
	return Attrs.has_grid(attrs)
end

return M
