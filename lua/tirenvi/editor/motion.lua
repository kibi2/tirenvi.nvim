local config = require("tirenvi.config")
local buf_state = require("tirenvi.state.buf_state")

local M = {}

local function build_motion(op)
	return function()
		if not buf_state.is_tir_vim(0) then
			return op
		end

		local delim = config.marks.pipe
		local count = vim.v.count

		if count > 0 then
			return count .. op .. delim
		end

		return op .. delim
	end
end

M.f = build_motion("f")
M.F = build_motion("F")
M.t = build_motion("t")
M.T = build_motion("T")

return M
