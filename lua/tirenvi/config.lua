--- Configuration management for tirenvi.

local levels = vim.log.levels

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

-----------------------------------------------------------------------
-- Defaults
-----------------------------------------------------------------------

local defaults = {
	---@type Marks
	marks = {
		pipe = "│", -- │┆┊┇┃┋▏▕
		padding = "⠀", --    ·∙⸱␣␠⠀░
		trim = "⋯", -- ⇢⋯⋮︙›↠▶¬…
		lf = "↲", -- ⤶⏎↵↲⤷␤¶—↩️
		tab = "⇥", -- »⇥→⇨▹▸▻►⇤␉》
	},
	---@type {[string]: Parser}
	parser_map = {
		csv = { executable = "tir-csv", required_version = "0.1.4" },
		tsv = { executable = "tir-csv", options = { "--delimiter", "\t" }, required_version = "0.1.4" },
		markdown = { executable = "tir-gfm-lite", allow_plain = true, required_version = "0.1.3" },
		pukiwiki = { executable = "tir-pukiwiki", allow_plain = true, required_version = "0.1.0" },
	},
	log = {
		level = levels.WARN,
		single_line = true,
		output = "notify", -- "notify" | "buffer" | "print"
		buffer_name = "tirenvi://log",
		use_timestamp = false,
		monitor = true,
		probe = false,
	},
}

-----------------------------------------------------------------------
-- Initialize with defaults
-----------------------------------------------------------------------

---@param opts {[string]:any}
local function apply(opts)
	for key, value in pairs(opts) do
		M[key] = value
	end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param opts {[string]:any}
function M.setup(opts)
	local merged = vim.tbl_deep_extend("force", {}, M, opts or {})
	apply(merged)
end

apply(vim.deepcopy(defaults))

return M
