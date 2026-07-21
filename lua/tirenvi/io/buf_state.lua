local api            = vim.api -- Neovim
local fn             = vim.fn
local bo             = vim.bo
local b              = vim.b

local config         = require("tirenvi.config")      -- Root

local Attrs          = require("tirenvi.core.attrs")  -- Core

local Range3         = require("tirenvi.util.range3") -- Util
local log            = require("tirenvi.util.log")

-- =============================================================================

local M              = {}

-- Buffer-local flags.
M.IKEY               = {
	-- true when in insert mode
	INSERT_MODE = "insert_mode",

	-- Set only when the on_lines callback is attached.
	ATTACHED = "attached",

	-- Depth of patch recursion
	PATCH_DEPTH = "patch_depth",

	-- create autocmd
	AUTOCMD = "autocmd",

	-- fn.undotree().seq_last
	UNDO_TREE_LAST = "undo_tree_last",

	-- bo[bufnr].filetype
	FILETYPE = "filetype",

	-- parser
	PARSER = "parser",

	-- repair flag
	REPAIR = "repair",

	-- block attrs
	ATTRS = "attrs",

	-- dirty row #
	DIRTY = "dirty",

	-- buffer is flat or tir-buffer
	TIRBUF = "tirbuf",
}

local initial_value  = {
	[M.IKEY.INSERT_MODE] = false,
	[M.IKEY.ATTACHED] = false,
	[M.IKEY.PATCH_DEPTH] = 0,
	[M.IKEY.AUTOCMD] = false,
	[M.IKEY.UNDO_TREE_LAST] = -1,
	[M.IKEY.FILETYPE] = nil,
	[M.IKEY.PARSER] = nil,
	[M.IKEY.REPAIR] = nil,
	[M.IKEY.ATTRS] = nil,
	[M.IKEY.DIRTY] = nil,
	[M.IKEY.TIRBUF] = false,
}

-- =============================================================================
--#region Private

---@class Check_options
---@field supported? boolean
---@field has_parser? boolean
---@field is_tirbuf? boolean
---@field no_vscode? boolean

local DEFAULT_OPTS   = {
	supported = true,
	has_parser = true,
	is_tirbuf = true,
	has_grid = false,
	no_vscode = true,
}
local REPAIR_OFF     = "REPAIR_OFF"
local INSERT_LEAVE   = "INSERT_LEAVE"
local INSERT_MODE    = "INSERT_MODE"
local UNDO_REDO_MODE = "UNDO_REDO_MODE"
local NORMAL_MODE    = "NORMAL_MODE"

---@param bufnr number
---@param message string
---@param range3 Range3|nil
local function log_watch(bufnr, message, range3)
	range3 = range3 or Range3.new(0, 0, 0)
	local pre = M.get(bufnr, M.IKEY.UNDO_TREE_LAST)
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
	local mode = M.get(bufnr, M.IKEY.INSERT_MODE) == true
	if mode then
		log.debug("===-===-===-=== insert mode[%d] ===-===-===-===", bufnr)
	end
	return mode
end

---@param bufnr number
---@return boolean
local function is_undo_mode(bufnr)
	local pre = M.get(bufnr, M.IKEY.UNDO_TREE_LAST)
	local next = fn.undotree(bufnr).seq_last
	if pre == next then
		log.debug("===-===-===-=== und/redo mode[%d] (%d, %d) ===-===-===-===", bufnr, pre, next)
		return true
	end
	return false
end

---@param bufnr number
---@param range3 Range3|nil
---@return string
local function get_status(bufnr, range3)
	if M.get_repair(bufnr) == false then
		return REPAIR_OFF
	end
	if not range3 then
		return INSERT_LEAVE
	elseif is_insert_mode(bufnr) then
		-- Modifying the buffer in insert mode may corrupt the undo node.
		-- Therefore, in insert mode, only record the dirty changed region
		-- and repair it when leaving insert mode.
		return INSERT_MODE
	elseif is_undo_mode(bufnr) then
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
		return M.get(bufnr, M.IKEY.PARSER) ~= nil
	end,

	is_tirbuf = function(bufnr)
		return M.is_tirbuf(bufnr)
	end,

	has_grid = function(bufnr)
		local has_grid = M.has_grid(bufnr)
		return has_grid == nil or has_grid == true
	end,

	no_vscode = function()
		return not M.is_vscode()
	end,
}

---@param bufnr number
---@return string
local function get_count(bufnr)
	if not M.is_allow_plain(bufnr) then
		return "P0G1"
	end
	local attrs = M.get(bufnr, M.IKEY.ATTRS)
	local count = Attrs.get_count(attrs)
	if not count then
		return "NIL"
	end
	return string.format("P%dG%d", count.plain, count.grid)
end

---@param bufnr number
---@return {[string]: boolean|integer|string|integer[][]|nil}
local function get_state(bufnr)
	if not b[bufnr].tirenvi then
		b[bufnr].tirenvi = initial_value
	end
	return b[bufnr].tirenvi
end

--#endregion
-- =============================================================================
-- Public API

---@param bufnr number
---@param key string
---@return any
function M.get(bufnr, key)
	return get_state(bufnr)[key]
end

---@param bufnr number
---@param key string
---@param val boolean|integer|string|integer[][]|nil
function M.set(bufnr, key, val)
	local state = get_state(bufnr)
	state[key] = val
	b[bufnr].tirenvi = state
end

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

---@param bufnr number
---@param range3 Range3|nil
---@return boolean
function M.is_repair(bufnr, range3)
	local status = get_status(bufnr, range3)
	log_watch(bufnr, status, range3)
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
---@param value boolean
function M.set_buffer_tirbuf(bufnr, value)
	M.set(bufnr, M.IKEY.TIRBUF, value)
end

---@param bufnr number
---@return string
function M.debug_state(bufnr)
	if not log.is_debug() then
		return ""
	end
	local allow_plain = M.is_allow_plain(bufnr)
	local form = M.is_tirbuf(bufnr) and "|A|" or ",A,"
	local count = get_count(bufnr)
	if not allow_plain then
		log.assert(count == "P0G1", "grid must be enabled when plain is not allowed")
	end
	return string.format("%s/%s/%s", allow_plain and "GFM" or "CSV", form, count)
end

---@param bufnr number
---@return boolean
function M.is_tirbuf(bufnr)
	return M.get(bufnr, M.IKEY.TIRBUF)
end

---@param bufnr number
---@return boolean
function M.has_grid(bufnr)
	if not M.is_allow_plain(bufnr) then
		return true
	end
	local attrs = M.get(bufnr, M.IKEY.ATTRS)
	return Attrs.has_grid(attrs)
end

---@param bufnr number
---@return boolean
function M.is_allow_plain(bufnr)
	local parser = M.get(bufnr, M.IKEY.PARSER)
	return parser and (parser.allow_plain or false) or false
end

function M.clear_buf_local(bufnr)
	M.set(bufnr, M.IKEY.ATTRS, nil)
	M.set(bufnr, M.IKEY.DIRTY, nil)
end

---@param bufnr number
---@param value boolean
function M.set_repair(bufnr, value)
	M.set(bufnr, M.IKEY.REPAIR, value)
end

---@param bufnr number
---@return boolean
function M.get_repair(bufnr)
	local auto_repair = M.get(bufnr, M.IKEY.REPAIR)
	if auto_repair == nil then
		auto_repair = config.table.auto_reconcile
		M.set_repair(bufnr, auto_repair)
	end
	return auto_repair
end

---@param winid integer
---@return integer
function M.get_win_span(winid)
	local info = fn.getwininfo(winid)[1]
	return info.width - info.textoff
end

return M
