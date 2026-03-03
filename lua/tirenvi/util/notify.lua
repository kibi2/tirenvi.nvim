--- notify.lua
--- UI notification layer for tirenvi.
---
--- Wraps vim.notify and ensures safe scheduling.
---

-----------------------------------------------------------------------
-- Module
-----------------------------------------------------------------------

local M = {}

-----------------------------------------------------------------------
-- Private helpers
-----------------------------------------------------------------------

---@param msg string
---@param level integer
local function emit(msg, level)
	if msg == nil then
		return
	end
	-- In test mode, avoid scheduling for deterministic behavior.
	if vim.g.tirenvi_test_mode then
		if msg ~= "" then
			print(msg)
		end
	else
		vim.schedule(function()
			vim.notify(msg, level)
		end)
	end
end

-----------------------------------------------------------------------
-- Public API
-----------------------------------------------------------------------

---@param msg string
function M.error(msg)
	emit(msg, vim.log.levels.ERROR)
end

---@param msg string
function M.warn(msg)
	emit(msg, vim.log.levels.WARN)
end

---@param msg string
function M.info(msg)
	emit(msg, vim.log.levels.INFO)
end

---@param msg string
---@param level integer
function M.notify(msg, level)
	emit(msg, level)
end

return M
