-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------
----- dependencies
local config        = require("tirenvi.config")
local CursorNvim    = require("tirenvi.cursor.nvim")
local Range         = require("tirenvi.util.range")
local util          = require("tirenvi.util.util")
local log           = require("tirenvi.util.log")

local M             = {}

local api           = vim.api
local fn            = vim.fn
local bo            = vim.bo
local b             = vim.b
local cache         = { bufnr = -1, start = -1, lines = {}, }
local STEP          = 25

-- Buffer-local flags.
M.IKEY              = {
	-- true when in insert mode
	INSERT_MODE = "insert_mode",

	-- Set only when the on_lines callback is attached.
	ATTACHED = "attached",

	-- Depth of patch recursion
	PATCH_DEPTH = "patch_depth",

	-- fn.undotree().seq_last
	UNDO_TREE_LAST = "undo_tree_last",

	-- bo[bufnr].filetype
	FILETYPE = "filetype",

	-- repair flag
	REPAIR = "repair",

	-- block attrs
	ATTRS = "attrs",

	-- dirty row #
	DIRTY = "dirty",

	-- buffer is flat or tir-buffer
	FLAT = "flat",
}

local initial_value = {
	[M.IKEY.INSERT_MODE] = false,
	[M.IKEY.ATTACHED] = false,
	[M.IKEY.PATCH_DEPTH] = 0,
	[M.IKEY.UNDO_TREE_LAST] = -1,
	[M.IKEY.FILETYPE] = nil,
	[M.IKEY.REPAIR] = nil,
	[M.IKEY.ATTRS] = nil,
	[M.IKEY.DIRTY] = nil,
	[M.IKEY.FLAT] = nil,
}

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param ctx Context
---@param cursor CursorBuf
local function reset_cursor_logical(ctx, cursor)
	-- CursorNvim.move(ctx, cursor.row_cur, cursor.col_byte)
end

---@param ctx Context
---@param cursor CursorBuf|nil
local function set_cursor_pos(ctx, cursor)
	if not cursor then
		CursorNvim.reset(ctx)
	elseif cursor.restore_mode == "buffer" then
		CursorNvim.restore_byte(ctx, cursor.row_cur, cursor.col_byte)
	elseif cursor.restore_mode == "logical" then
		reset_cursor_logical(ctx, cursor)
	else
		CursorNvim.reset(ctx)
	end
end

---@param bufnr number
local function set_undo_tree_last(bufnr)
	local next = fn.undotree(bufnr).seq_last
	M.set(bufnr, M.IKEY.UNDO_TREE_LAST, next)
end

---@param ctx Context
---@param range Range
---@param lines string[]
---@param no_undo boolean
---@param cursor CursorBuf|nil
local function set_lines(ctx, range, lines, no_undo, cursor)
	M.clear_cache()
	local bufnr = ctx.bufnr
	local undolevels = bo[bufnr].undolevels
	if no_undo then
		local undotree = fn.undotree(bufnr)
		if undotree.seq_last == 0 then
			bo[bufnr].undolevels = -1
		else
			pcall(vim.cmd, "undojoin")
		end
	end
	local start0, end0 = Range.to_vim(range)
	start0 = math.max(start0, 0)
	api.nvim_buf_set_lines(bufnr, start0, end0, false, lines)
	set_undo_tree_last(bufnr)
	set_cursor_pos(ctx, cursor)
	bo[bufnr].undolevels = undolevels
end

---@param bufnr number
---@param first integer -- 1-based
---@param last integer -- 1-based
local function get_lines_and_cache(bufnr, first, last)
	local start  = math.max(first - 1, 0)
	local end0   = util.trim(last, start + 2 * STEP, M.line_count(bufnr))
	local start0 = util.trim(start, 0, end0 - 2 * STEP)
	local lines  = api.nvim_buf_get_lines(bufnr, start0, end0, false)
	cache        = { bufnr = bufnr, start = start0, lines = lines, }
	log.debug("=== cache[#%d] lines[%d]='%s'...[%d]='%s'", cache.bufnr,
		cache.start + 1, tostring(cache.lines[1]),
		cache.start + #cache.lines, tostring(cache.lines[#cache.lines]))
end

---@param bufnr number
---@param iline integer -- 1-based
---@return string|nil
local function get_line_from_cache(bufnr, iline)
	if cache.bufnr ~= bufnr then
		return nil
	end
	return cache.lines[iline - cache.start]
end

---@param bufnr number
---@param first integer -- 1-based
---@param last integer -- 1-based
---@return string[]
local function get_lines_from_cache(bufnr, first, last)
	if cache.bufnr ~= bufnr then
		return {}
	end
	local istart = first - cache.start
	local ilast = last - cache.start
	if istart < 1 or ilast > #cache.lines then
		return {}
	end
	return vim.list_slice(cache.lines, istart, ilast)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param bufnr number
---@return {[string]: boolean|integer|string|integer[][]|nil}
function M.get_state(bufnr)
	if not b[bufnr].tirenvi then
		b[bufnr].tirenvi = initial_value
	end
	return b[bufnr].tirenvi
end

---@param bufnr number
---@param key string
---@return any
function M.get(bufnr, key)
	return M.get_state(bufnr)[key]
end

---@param bufnr number
---@param key string
---@param val boolean|integer|string|integer[][]|nil
function M.set(bufnr, key, val)
	local state = M.get_state(bufnr)
	state[key] = val
	b[bufnr].tirenvi = state
end

---@param ctx Context
---@param range Range
---@param lines string[]
---@param no_undo boolean|nil
---@param cursor CursorBuf|nil
function M.set_lines(ctx, range, lines, no_undo, cursor)
	local bufnr = ctx.bufnr
	M.set(bufnr, M.IKEY.PATCH_DEPTH, M.get(bufnr, M.IKEY.PATCH_DEPTH) + 1)
	local before = fn.undotree(bufnr).seq_last
	local ok, err = pcall(set_lines, ctx, range, lines, no_undo, cursor)
	local after = fn.undotree(bufnr).seq_last
	local first, last = Range.to_lua(range)
	log.watch("UNDO", "%s[%d->%d]set_lines lines[%d]='%s'...[%d]='%s'", tostring(no_undo),
		before, after, first, tostring(lines[1]), last, tostring(lines[#lines]))
	M.set(bufnr, M.IKEY.PATCH_DEPTH, M.get(bufnr, M.IKEY.PATCH_DEPTH) - 1)
	log.assert(M.get(bufnr, M.IKEY.PATCH_DEPTH) == 0, "PATCH_DEPTH should be 0 after set_lines")
	if not ok then
		error(err)
	end
end

function M.clear_buf_local(bufnr)
	M.set(bufnr, M.IKEY.ATTRS, nil)
	M.set(bufnr, M.IKEY.DIRTY, nil)
end

function M.clear_cache()
	cache = { bufnr = -1, start = -1, lines = {}, }
end

---@param bufnr number
---@param first integer -- 1-based
---@param last integer -- 1-based
---@return string[]
function M.get_lines(bufnr, first, last)
	first = math.max(1, first)
	local nline = M.line_count(bufnr)
	if last == -1 then
		last = nline
	end
	last = math.min(nline, last)
	local lines = get_lines_from_cache(bufnr, first, last)
	if #lines ~= 0 then
		return lines
	end
	get_lines_and_cache(bufnr, first - STEP, last + STEP)
	return get_lines_from_cache(bufnr, first, last)
end

---@param bufnr number
---@param iline integer -- 1-based
---@return string|nil
function M.get_line(bufnr, iline)
	local line = get_line_from_cache(bufnr, iline)
	if line then
		return line
	end
	if cache.bufnr ~= bufnr then
		M.get_lines(bufnr, iline, iline)
	elseif iline - 1 < cache.start then
		if iline >= 1 then
			get_lines_and_cache(bufnr, iline - 2 * STEP, iline)
		end
	else
		if iline <= M.line_count(bufnr) then
			get_lines_and_cache(bufnr, iline, iline + 2 * STEP - 1)
		end
	end
	return get_line_from_cache(bufnr, iline)
end

---@param bufnr number
---@return integer
function M.line_count(bufnr)
	return api.nvim_buf_line_count(bufnr)
end

---@param bufnr number
---@param range Range
---@return string|nil
---@return string|nil
function M.get_lines_around(bufnr, range)
	M.get_lines(bufnr, range.first - 1, range.last + 1)
	return M.get_line(bufnr, range.first - 1), M.get_line(bufnr, range.last + 1)
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

---@param step integer
function M.set_step(step)
	STEP = step
end

---@param winid integer
---@return integer
function M.get_win_span(winid)
	local info = fn.getwininfo(winid)[1]
	return info.width - info.textoff
end

return M
