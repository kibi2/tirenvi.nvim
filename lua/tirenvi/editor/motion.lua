local Context = require("tirenvi.app.context")
local buffer = require("tirenvi.io.buffer")
local LinProvider = require("tirenvi.io.buffer_line_provider")
local Attrs = require("tirenvi.core.attrs")
local Bufline = require("tirenvi.core.bufline")
local log = require("tirenvi.util.log")

local M = {}

---@return string
local function get_pipe()
	local ctx = Context.from_buf()
	local irow = buffer.get_cursor_byte_pos()
	local line = buffer.get_line(ctx.bufnr, irow)
	return Bufline.get_pipe_char(line) or ""
end

---@param op string
---@return function
local function build_motion(op)
	return function()
		return op .. get_pipe()
	end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

M.f = build_motion("f")
M.F = build_motion("F")
M.t = build_motion("t")
M.T = build_motion("T")

function M.block_top()
	local attrs                = buffer.get(nil, buffer.IKEY.ATTRS)
	local cur_row, _, char_col = buffer.get_cursor_char_pos()
	log.probe(char_col)
	local pos     = Attrs.to_logical(attrs, cur_row, char_col)
	local top_row = attrs[pos.iblock].range.first
	buffer.set_cursor_char_pos(0, top_row, char_col)
end

function M.block_bottom()
	local attrs                = buffer.get(nil, buffer.IKEY.ATTRS)
	local cur_row, _, char_col = buffer.get_cursor_char_pos()
	log.probe(char_col)
	local pos        = Attrs.to_logical(attrs, cur_row, char_col)
	local bottom_row = attrs[pos.iblock].range.last
	buffer.set_cursor_char_pos(0, bottom_row, char_col)
end

return M
