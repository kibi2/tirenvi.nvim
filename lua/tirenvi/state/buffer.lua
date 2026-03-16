-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

----- dependencies
local log = require("tirenvi.util.log")

local M = {}

local api = vim.api
local fn = vim.fn
local bo = vim.bo
local b = vim.b

-- Buffer-local flags.
M.IKEY = {
	-- Buffer currently contains invalid TIR structure.
	BUFFER_INVALID = "buffer_invalid",

	-- Buffer contains edits that require repair after leaving insert mode.
	REPAIR_PENDING = "repair_pending",

	-- true when in insert mode
	INSERT_MODE = "insert_mode",

	-- Has a value only between Buf[Write|File]Pre and Buf[Write|File]Post.
	OLD_PATH = "old_path",

	-- Set only when the on_lines callback is attached.
	ATTACHED = "attached",

	-- Depth of patch recursion
	PATCH_DEPTH = "patch_depth",

	-- vim.fn.undotree().seq_last
	UNDO_TREE_LASET = "undo_tree_laset",

	INTERNAL = "internal",
}

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param bufnr number
---@return {[string]: boolean | integer | string | nil}
local function get_state(bufnr)
	bufnr = bufnr or 0
	if not b[bufnr].tirenvi then
		b[bufnr].tirenvi = {
			buffer_invalid = false,
			repair_pending = false,
			insert_mode = false,
			old_path = nil,
			attached = false,
			patch_depth = 0,
			undo_tree_last = -1,
			internal = false,
		}
	end
	return b[bufnr].tirenvi
end

local function fix_cursor_utf8()
	local row, col = unpack(api.nvim_win_get_cursor(0))
	local line = api.nvim_get_current_line()
	local char_index = vim.str_utfindex(line, col)
	local boundary = vim.str_byteindex(line, char_index)
	if boundary ~= col then
		api.nvim_win_set_cursor(0, { row, boundary })
	end
end

local function set_lines(bufnr, i_start, i_end, strict, lines)
	local undotree = fn.undotree()
	local undolevels
	if undotree.seq_last == 0 then
		undolevels = bo[bufnr].undolevels
		bo[bufnr].undolevels = -1
	end
	api.nvim_buf_set_lines(bufnr, i_start, i_end, strict, lines)
	fix_cursor_utf8()
	if undotree.seq_last == 0 then
		bo[bufnr].undolevels = undolevels
	end
	log.debug(get_state(bufnr))
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param bufnr number
---@param key string
---@return boolean | integer | string | nil
function M.get(bufnr, key)
	return get_state(bufnr)[key]
end

---@param bufnr number
---@param key string
---@param val boolean | integer | string | nil
function M.set(bufnr, key, val)
	local state = get_state(bufnr)
	state[key] = val
	b[bufnr].tirenvi = state
end

---@param bufnr number
---@param i_start integer
---@param i_end integer integer
---@param lines string[] | nil
---@param strict boolean | nil
function M.set_lines(bufnr, i_start, i_end, lines, strict)
	if lines == nil then
		return
	end
	bufnr = bufnr or 0
	strict = strict == true
	log.debug("=== set_lines(%d, %d)[1]%s [%d]%s", i_start, i_end, lines[1], #lines, lines[#lines])
	log.debug(get_state(bufnr))
	M.set(bufnr, M.IKEY.PATCH_DEPTH, M.get(bufnr, M.IKEY.PATCH_DEPTH) + 1)
	local ok, err = pcall(set_lines, bufnr, i_start, i_end, strict, lines)
	M.set(bufnr, M.IKEY.PATCH_DEPTH, M.get(bufnr, M.IKEY.PATCH_DEPTH) - 1)
	assert(M.get(bufnr, M.IKEY.PATCH_DEPTH) == 0)
	if not ok then
		error(err)
	end
end

---@param bufnr number
---@param i_start integer
---@param i_end integer integer
---@param strict boolean | nil
---@return string[]
function M.get_lines(bufnr, i_start, i_end, strict)
	strict = strict or false
	return api.nvim_buf_get_lines(bufnr, i_start, i_end, strict)
end

---@param bufnr number
---@param index integer
---@return string | nil
function M.get_line(bufnr, index)
	local lines = M.get_lines(bufnr, index, index + 1)
	return lines[1]
end

---@param bufnr number
---@param start integer
---@param end_ integer
---@return string | nil
---@return string | nil
function M.get_lines_around(bufnr, start, end_)
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
		on_lines = function(_, bufnr, tick, first, last, new_last, bytecount)
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

return M
