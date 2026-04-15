-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

----- dependencies
local Range = require("tirenvi.util.range")
local log   = require("tirenvi.util.log")

local M     = {}

local api   = vim.api
local fn    = vim.fn
local bo    = vim.bo
local b     = vim.b

local cache = { bufnr = -1, start = -1, lines = {}, }
local STEP  = 25

-- Buffer-local flags.
M.IKEY      = {
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

	-- grid columns widths [iblock][icol]
	WIDTHS = "widths",
}

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

local function fix_cursor_utf8()
	local winid = api.nvim_get_current_win()
	local row, col = unpack(api.nvim_win_get_cursor(winid))
	local line = M.get_line(0, row - 1)
	local char_index = vim.str_utfindex(line, col)
	local boundary = vim.str_byteindex(line, char_index)
	if boundary ~= col then
		api.nvim_win_set_cursor(0, { row, boundary })
	end
end

---@param bufnr number
---@param i_start integer
---@param i_end integer
---@param lines string[]
---@param no_undo boolean|nil
local function set_lines(bufnr, i_start, i_end, lines, no_undo)
	M.clear_cache()
	local undolevels = bo[bufnr].undolevels
	if no_undo then
		local undotree = fn.undotree(bufnr)
		if undotree.seq_last == 0 then
			bo[bufnr].undolevels = -1
		end
	end
	i_start = math.max(i_start, 0)
	M.set_undo_tree_last(bufnr)
	api.nvim_buf_set_lines(bufnr, i_start, i_end, false, lines)
	fix_cursor_utf8()
	bo[bufnr].undolevels = undolevels
end

---@param bufnr number
---@param i_start integer
---@param i_end integer integer
local function get_lines_and_cache(bufnr, i_start, i_end)
	local start = math.max(i_start, 0)
	local end_  = math.min(math.max(i_end, start + 2 * STEP), M.line_count(bufnr))
	local start = math.max(math.min(start, end_ - 2 * STEP), 0)
	local lines = api.nvim_buf_get_lines(bufnr, start, end_, false)
	cache       = { bufnr = bufnr, start = start, lines = lines, }
	log.debug("===== cache [%d,] (%d, %d), lines[1]=%s, line[%d]=%s",
		cache.bufnr, cache.start, cache.start + #cache.lines,
		tostring(cache.lines[1]), #cache.lines, tostring(cache.lines[#cache.lines]))
end

---@param bufnr number
---@param iline integer
---@return string|nil
local function get_line_from_cache(bufnr, iline)
	if cache.bufnr ~= bufnr then
		return nil
	end
	return cache.lines[iline - cache.start + 1]
end

---@param bufnr number
---@param i_start integer
---@param i_end integer
---@return string[]
local function get_lines_from_cache(bufnr, i_start, i_end)
	if cache.bufnr ~= bufnr then
		return {}
	end
	local start = i_start - cache.start + 1
	local end_ = i_end - cache.start
	if start < 1 or end_ > #cache.lines then
		return {}
	end
	return vim.list_slice(cache.lines, start, end_)
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param bufnr number
function M.set_undo_tree_last(bufnr)
	local next = fn.undotree(bufnr).seq_last
	M.set(bufnr, M.IKEY.UNDO_TREE_LAST, next)
end

---@param bufnr number
---@return {[string]: boolean|integer|string|integer[][]|nil}
function M.get_state(bufnr)
	bufnr = bufnr or api.nvim_get_current_buf()
	if not b[bufnr].tirenvi then
		b[bufnr].tirenvi = {
			attached = false,
			filetype = nil,
			insert_mode = false,
			patch_depth = 0,
			undo_tree_last = -1,
			widths = nil,
		}
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
---@param i_start integer
---@param i_end integer integer
---@param lines string[]
---@param no_undo boolean|nil
function M.set_lines(bufnr, i_start, i_end, lines, no_undo)
	local range = Range.new(i_start, i_end)
	log.debug("=== set_lines%s[1]%s [%d]%s", range:short(), tostring(lines[1]), #lines,
		tostring(lines[#lines]))
	log.debug(M.get_state(bufnr))
	M.set(bufnr, M.IKEY.PATCH_DEPTH, M.get(bufnr, M.IKEY.PATCH_DEPTH) + 1)
	local ok, err = pcall(set_lines, bufnr, i_start, i_end, lines, no_undo)
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
---@param i_start integer
---@param i_end integer
---@return string[]
function M.get_lines(bufnr, i_start, i_end)
	bufnr = bufnr == 0 and api.nvim_get_current_buf() or bufnr
	i_start = math.max(0, i_start)
	local nline = M.line_count(bufnr)
	if i_end == -1 then
		i_end = nline
	end
	i_end = math.min(nline, i_end)
	local lines = get_lines_from_cache(bufnr, i_start, i_end)
	if #lines ~= 0 then
		return lines
	end
	get_lines_and_cache(bufnr, i_start - STEP, i_end + STEP)
	return get_lines_from_cache(bufnr, i_start, i_end)
end

---@param bufnr number
---@param iline integer
---@return string|nil
function M.get_line(bufnr, iline)
	bufnr = bufnr == 0 and api.nvim_get_current_buf() or bufnr
	local line = get_line_from_cache(bufnr, iline)
	if line then
		return line
	end
	if cache.bufnr ~= bufnr then
		M.get_lines(bufnr, iline, iline + 1)
	elseif iline < cache.start then
		if iline >= 0 then
			get_lines_and_cache(bufnr, iline - 2 * STEP, iline + 1)
		end
	else
		if iline < M.line_count(bufnr) then
			get_lines_and_cache(bufnr, iline, iline + 2 * STEP)
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
---@param start integer
---@param end_ integer
---@return string|nil
---@return string|nil
function M.get_lines_around(bufnr, start, end_)
	M.get_lines(bufnr, start - 1, end_ + 1)
	return M.get_line(bufnr, start - 1), M.get_line(bufnr, end_)
end

--- Get absolute file path of the buffer.
---@param bufnr number
---@return string
function M.get_file_path(bufnr)
	local file_name = api.nvim_buf_get_name(bufnr)
	return M.to_file_path(file_name)
end

--- Convert file name to absolute file path. if the file name is empty, return it as is.
---@param file_name string
---@return string
function M.to_file_path(file_name)
	local file_path = file_name
	if file_path ~= "" then
		file_path = fn.fnamemodify(file_path, ":p")
	end
	return file_path
end

---@param bufnr number
---@param callback function
function M.attach_on_lines(bufnr, callback)
	if M.get(bufnr, M.IKEY.ATTACHED) then
		return
	end
	log.debug("===+===+=== attach onlines")
	api.nvim_buf_attach(bufnr, false, {
		-- NOTE:
		-- When returning `true` from this callback, the attachment is detached only for
		-- this handler. In this case, `on_detach` is NOT called automatically, so any
		-- state (e.g. ATTACHED flag) must be updated manually here.
		on_lines = function(_, bufnr, tick, first, last, new_last, bytecount)
			if M.get(bufnr, M.IKEY.FILETYPE) == nil then
				log.debug("===+===+=== auto detach (no filetype)")
				M.set(bufnr, M.IKEY.ATTACHED, false)
				return true -- detach
			end
			if M.get(bufnr, M.IKEY.PATCH_DEPTH) > 0 then
				return
			end
			callback(_, bufnr, tick, first, last, new_last, bytecount)
		end,
		on_detach = function()
			log.debug("===+===+=== detach onlines")
			M.set(bufnr, M.IKEY.ATTACHED, false)
		end,
	})
	M.set(bufnr, M.IKEY.ATTACHED, true)
end

---@param step integer
function M.set_step(step)
	STEP = step
end

return M
