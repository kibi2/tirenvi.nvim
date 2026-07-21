local api = vim.api -- Neovim

local config = require("tirenvi.config") -- Root

local Attrs = require("tirenvi.core.attrs") -- Core

local namespaces = require("tirenvi.io.namespaces") -- IO
local buf_state = require("tirenvi.io.buf_state")

local Range = require("tirenvi.util.range") -- Util
local log = require("tirenvi.util.log")

-- =============================================================================

local M = {}

-- =============================================================================
--#region Private

---@param bufnr number
---@param range Range
---@param id integer|nil
---@param text string
local function show_marks(bufnr, range, id, text)
	local start0, end0 = Range.to_vim(range)
	local opts = {
		id = id,
		end_row = end0 - 1,
		end_col = 1000,
		right_gravity = false,
		end_right_gravity = true,
		strict = false,
		invalidate = false,
		--
		hl_group = config.ui.highlight.line,
		hl_eol = false,
		sign_text = ".",
		sign_hl_group = config.ui.highlight.sign,
	}
	if vim.log.levels.DEBUG >= config.log.level then
		opts.virt_text = { { text, "Comment" } }
		opts.virt_text_pos = "eol"
		if id then
			opts.sign_text = tostring(id):sub(-2)
		end
	end
	api.nvim_buf_set_extmark(bufnr, namespaces.DIRTY, start0, 0, opts)
end

---@param bufnr number
---@param ranges Range[]
local function set_dirty_ranges(bufnr, ranges)
	buf_state.set(bufnr, buf_state.IKEY.DIRTY, ranges)
	log.watch("INVD", ranges)
	for irange, range in ipairs(ranges) do
		show_marks(bufnr, range, irange, "dirty")
	end
end

---@param bufnr number
local function set_dirty_attrs(bufnr)
	local invalid_attrs = M.get_invalid_attrs(bufnr)
	for _, attr in ipairs(invalid_attrs) do
		local irow = attr.range.first
		local range = Range.from_lua(irow, irow)
		show_marks(bufnr, range, nil, "boundary")
	end
end

--#endregion
-- =============================================================================
-- Public API

---@param bufnr number
---@param ranges Range[]
function M.set_ranges(bufnr, ranges)
	api.nvim_buf_clear_namespace(bufnr, namespaces.DIRTY, 0, -1)
	set_dirty_ranges(bufnr, ranges)
	set_dirty_attrs(bufnr)
end

---@param bufnr number
---@return Range[]
function M.get_ranges(bufnr)
	return buf_state.get(bufnr, buf_state.IKEY.DIRTY) or {}
end

---@param bufnr number
---@return Attr[]
function M.get_invalid_attrs(bufnr)
	local attrs = buf_state.get(bufnr, buf_state.IKEY.ATTRS) or {}
	return Attrs.get_invalid_attrs(attrs)
end

return M
