-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

----- dependencies
local config        = require("tirenvi.config")
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

	-- auto_reconcile flag
	AUTO_RECONCILE = "auto_reconcile",

	-- block attrs
	ATTRS = "attrs",
}

local initial_value = {
	[M.IKEY.INSERT_MODE] = false,
	[M.IKEY.ATTACHED] = false,
	[M.IKEY.PATCH_DEPTH] = 0,
	[M.IKEY.UNDO_TREE_LAST] = -1,
	[M.IKEY.FILETYPE] = nil,
	[M.IKEY.AUTO_RECONCILE] = nil,
	[M.IKEY.ATTRS] = nil,
}

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

local function fix_cursor_utf8()
	local winid = api.nvim_get_current_win()
	local irow, icol = M.get_cursor(winid)
	local line = M.get_line(0, irow)
	local char_index0 = vim.str_utfindex(line, icol - 1)
	local boundary = vim.str_byteindex(line, char_index0) + 1
	if boundary ~= icol then
		M.set_cursor(0, irow, boundary)
	end
end

---@param bufnr number
local function set_undo_tree_last(bufnr)
	local next = fn.undotree(bufnr).seq_last
	M.set(bufnr, M.IKEY.UNDO_TREE_LAST, next)
end

---@param bufnr number
---@param range RangeLike
---@param lines string[]
---@param no_undo boolean|nil
local function set_lines(bufnr, range, lines, no_undo)
	M.clear_cache()
	local undolevels = bo[bufnr].undolevels
	if no_undo then
		local undotree = fn.undotree(bufnr)
		if undotree.seq_last == 0 then
			bo[bufnr].undolevels = -1
		else
			pcall(vim.cmd, "undojoin")
		end
	end
	local start0, end0 = range:to_vim()
	start0 = math.max(start0, 0)
	if not no_undo or M.get_auto_reconcile(bufnr) then
		api.nvim_buf_set_lines(bufnr, start0, end0, false, lines)
	end
	set_undo_tree_last(bufnr)
	fix_cursor_utf8()
	bo[bufnr].undolevels = undolevels
end

---@param bufnr number
---@param first integer -- 1-based
---@param last integer -- 1-based
local function get_lines_and_cache(bufnr, first, last)
	local start  = math.max(first - 1, 0)
	local end0   = math.min(math.max(last, start + 2 * STEP), M.line_count(bufnr))
	local start0 = math.max(math.min(start, end0 - 2 * STEP), 0)
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
	bufnr = bufnr or api.nvim_get_current_buf()
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
	bufnr = bufnr or api.nvim_get_current_buf()
	local state = M.get_state(bufnr)
	state[key] = val
	b[bufnr].tirenvi = state
end

---@param bufnr number
---@param range RangeLike
---@param lines string[]
---@param no_undo boolean|nil
function M.set_lines(bufnr, range, lines, no_undo)
	log.debug(M.get_state(bufnr))
	M.set(bufnr, M.IKEY.PATCH_DEPTH, M.get(bufnr, M.IKEY.PATCH_DEPTH) + 1)
	local before = fn.undotree(bufnr).seq_last
	local ok, err = pcall(set_lines, bufnr, range, lines, no_undo)
	local after = fn.undotree(bufnr).seq_last
	local first, last = range:to_lua()
	log.watch("UNDO", "=== [%d->%d]set_lines lines[%d]='%s'...[%d]='%s'", before, after,
		first, tostring(lines[1]), last, tostring(lines[#lines]))
	M.set(bufnr, M.IKEY.PATCH_DEPTH, M.get(bufnr, M.IKEY.PATCH_DEPTH) - 1)
	assert(M.get(bufnr, M.IKEY.PATCH_DEPTH) == 0)
	if not ok then
		error(err)
	end
end

function M.clear_cache()
	cache = { bufnr = -1, start = -1, lines = {}, }
end

---@param bufnr number
---@param first integer -- 1-based
---@param last integer -- 1-based
---@return string[]
function M.get_lines(bufnr, first, last)
	bufnr = bufnr == 0 and api.nvim_get_current_buf() or bufnr
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
	log.probe(iline - 1)
	bufnr = bufnr == 0 and api.nvim_get_current_buf() or bufnr
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
function M.set_auto_reconcile(bufnr, value)
	M.set(bufnr, M.IKEY.AUTO_RECONCILE, value)
end

---@param bufnr number
---@return boolean
function M.get_auto_reconcile(bufnr)
	local auto_reconcile = M.get(bufnr, M.IKEY.AUTO_RECONCILE)
	if auto_reconcile == nil then
		auto_reconcile = config.table.auto_reconcile
		M.set_auto_reconcile(bufnr, auto_reconcile)
	end
	return auto_reconcile
end

---@param step integer
function M.set_step(step)
	STEP = step
end

---@param winid integer|nil
---@return integer
---@return integer
function M.get_cursor(winid)
	winid = (winid == nil or winid == 0) and api.nvim_get_current_win() or winid
	local irow, icol0 = unpack(api.nvim_win_get_cursor(winid))
	return irow, icol0 + 1
end

---@param winid integer|nil
---@param irow integer
---@param icol integer
function M.set_cursor(winid, irow, icol)
	winid = (winid == nil or winid == 0) and api.nvim_get_current_win() or winid
	vim.api.nvim_win_set_cursor(winid, { irow, icol - 1 })
end

return M
