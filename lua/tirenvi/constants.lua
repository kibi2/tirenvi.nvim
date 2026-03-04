local config = require("tirenvi.config")

local M = {}

-- ng line
M.NG_LINE_MARK = "TIRVIM-NG" .. config.marks.pipe

-- Buffer-local flags.
local PREFIX = "tirenvi_"
M.BUF_KEY = {
	-- Set only when バッファが最初に表示された
	INITIALIZED = PREFIX .. "initialized",

	-- Set only when the on_lines callback is attached.
	ATTACH_COUNT = PREFIX .. "attached",

	-- Has a value only between Buf[Write|File]Pre and Buf[Write|File]Post.
	OLD_PATH = PREFIX .. "old_path",

	-- Intended to store a list of invalid line numbers.
	-- Currently set to {1} when invalid lines exist, otherwise nil.
	INVALID_LINES = PREFIX .. "invalid_lines",

	-- true when in insert mode
	INSERT_MODE = PREFIX .. "insert_mode",

	-- Rows that became invalid in insert mode
	PENDING_REPAIR_ROWS = PREFIX .. "pending_repair_rows",

	-- Depth of patch
	PATCH_DEPTH = PREFIX .. "patch_depth",
}

return M
