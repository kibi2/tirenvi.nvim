local config = require("tirenvi.config")
local notify = require("tirenvi.util.notify")
local Range = require("tirenvi.util.range")

local M = {}

local api = vim.api
local bo = vim.bo
local fn = vim.fn

local levels = vim.log.levels

local level_names = {}
local PREFIX = "TIR"
local uv = vim.loop
local queue = {}
local scheduled = false
local log_bufnr = nil

for name, value in pairs(levels) do
	level_names[value] = name
end

local last_tick = 0
local last_mem = 0
local last_time = uv.now()
local monitoring = false

---@return integer
local function get_tick()
	local bufnr = api.nvim_get_current_buf()
	return api.nvim_buf_get_changedtick(bufnr)
end

---@return integer
local function get_mem_mb()
	return collectgarbage("count") / 1024
end

---@return string
local function get_monitor()
	if not config.log.monitor then
		return ""
	end
	local current_mem = get_mem_mb()
	local delta_mem = current_mem - last_mem
	return string.format("[%d:%d(+%d)MB]", get_tick(), current_mem, delta_mem)
end

local function monitor()
	if monitoring then
		return
	end
	monitoring = true

	local mem = get_mem_mb()
	local tick = get_tick()
	local now = uv.now()

	if now - last_time < 1000 then
		if tick - last_tick > 100 then
			M.error("changedtick runaway detected")
		end
	end

	if mem > 2000 then
		M.error("memory runaway: " .. mem .. "MB")
	end

	last_tick = tick
	last_mem = mem
	last_time = now

	monitoring = false
end

---@param value any
---@return any
local function normalize_for_log(value)
	local v_type = type(value)
	if v_type ~= "table" then
		return value
	end
	local mt = getmetatable(value)
	if mt and mt.__tostring then
		return tostring(value)
	end
	local result = {}
	for key, val in pairs(value) do
		result[key] = normalize_for_log(val)
	end
	return result
end

---@param value any
---@return string
local function stringify(value)
	local v_type = type(value)

	if v_type == "table" then
		local normalized = normalize_for_log(value)
		if config.log.single_line then
			return string.format(
				"<table> %s",
				vim.inspect(normalized, {
					newline = " ",
					indent = "",
					depth = 4,
				})
			)
		else
			return string.format("<table>\n%s", vim.inspect(value))
		end
	elseif v_type == "string" then
		return string.format("<string> %s", value)
	else
		return string.format("<%s> %s", v_type, tostring(value))
	end
end

---@return string
local function get_timestamp()
	if not config.log.use_timestamp then
		return ""
	end
	local now = uv.hrtime()
	if not last_time then
		last_time = now
		---@type string
		return os.date("[%H:%M:%S]")
	end
	local delta_ms = (now - last_time) / 1e6
	last_time = now
	return string.format("[+%.0fms]", delta_ms)
end

local function get_bufnr_by_name(name)
	for _, bufnr in ipairs(api.nvim_list_bufs()) do
		if api.nvim_buf_get_name(bufnr) == name then
			return bufnr
		end
	end
	return nil
end

---@return number
local function ensure_log_buf()
	if log_bufnr and api.nvim_buf_is_valid(log_bufnr) then
		return log_bufnr
	end
	log_bufnr = get_bufnr_by_name(config.log.buffer_name)
	if log_bufnr then
		return log_bufnr
	end
	---@type number
	log_bufnr = api.nvim_create_buf(false, true)
	api.nvim_buf_set_name(log_bufnr, config.log.buffer_name)

	bo[log_bufnr].buftype = "nofile"
	bo[log_bufnr].bufhidden = "hide"
	bo[log_bufnr].swapfile = false

	return log_bufnr
end

local function flush_buffer(buf_string)
	local bufnr = ensure_log_buf()
	api.nvim_buf_set_lines(bufnr, -1, -1, false, vim.split(buf_string, "\n"))
	local line_count = api.nvim_buf_line_count(bufnr)
	local win = fn.bufwinid(bufnr)
	if win ~= -1 then
		api.nvim_win_set_cursor(win, { line_count, 0 })
		api.nvim_win_call(win, function()
			-- vim.cmd("normal! 3kzz")
		end)
	end
end

local initialized = false
local function flush_file(buf_string)
	local file = config.log.file_name or "/tmp/tirenvi.log"
	if not initialized then
		local fds = io.open(file, "w")
		if fds then
			fds:close()
		else
			error("tirenvi: failed to open log file: " .. file)
		end
		initialized = true
	end
	local fds = io.open(file, "a")
	if fds then
		fds:write(buf_string .. "\n")
		fds:close()
	end
end

local function flush()
	scheduled = false
	if #queue == 0 then
		return
	end
	local buf_string = table.concat(queue, "\n")
	buf_string = buf_string:gsub("\r", "")
	if config.log.output == "buffer" then
		flush_buffer(buf_string)
	elseif config.log.output == "file" then
		flush_file(buf_string)
	end
	queue = {}
end

---@param msg string
local function write_buffer(msg)
	table.insert(queue, msg)
	if not scheduled then
		scheduled = true
		vim.schedule(flush)
	end
end

local unpack = table.unpack or unpack -- Lua 5.1/5.2 compatibility
local category_hl_map = {}
local category_match_id = {}

local function apply_log_highlight(bufnr)
	local winid = vim.fn.bufwinid(bufnr)
	if winid == -1 then return end
	vim.api.nvim_win_call(winid, function()
		vim.fn.clearmatches()
		for cat, hl in pairs(category_hl_map) do
			vim.fn.matchadd(hl, "\\[" .. cat .. "\\]")
		end
	end)
end

local function pick_color(cat)
	local colors = {
		"#ff6b6b", "#4ecdc4", "#ffe66d",
		"#c7f464", "#c792ea", "#f78c6c",
	}
	local idx = (vim.fn.str2nr(vim.fn.sha256(cat):sub(1, 8), 16) % #colors) + 1
	return colors[idx]
end

local function ensure_category_highlight(category)
	if category_hl_map[category] then
		return category_hl_map[category]
	end

	local hl = "TirLog_" .. category
	local color = pick_color(category)

	vim.api.nvim_set_hl(0, hl, { fg = color, bold = true })

	category_hl_map[category] = hl
	return hl
end

local function ensure_match(bufnr, category, hl)
	if category_match_id[category] then
		return
	end

	vim.api.nvim_buf_call(bufnr, function()
		local pattern = "\\[" .. category .. "\\]"
		local id = vim.fn.matchadd(hl, pattern)
		category_match_id[category] = id
	end)
end

---@param force boolean
---@param level integer
---@param opts? table
---@param fmt any
---@param ... unknown
local function emit(force, level, opts, fmt, ...)
	monitor()
	if not force and level < config.log.level then
		return
	end
	if opts == nil or fmt == nil then
		return
	end
	local category = opts and opts.category
	if category then
		local bufnr = ensure_log_buf()
		local hl = ensure_category_highlight(category)
		ensure_match(bufnr, category, hl)
	end
	local info = debug.getinfo(3, "Sl")
	local file = info and (info.short_src:match("([^/\\]+)$")) or "?"
	local line = info and info.currentline or 0
	local args = { ... }
	local msg
	local ok, result = pcall(function()
		return string.format(fmt, unpack(args))
	end)
	if ok then
		msg = result
	else
		local args = { fmt, ... }
		local parts = vim.tbl_map(stringify, args)
		msg = table.concat(parts, " ")
	end
	local ts = get_timestamp()
	local mon = get_monitor()
	local name = level_names[level]
	if force then
		name = "🟧PRB"
	elseif category then
		name = category
	end
	local final = string.format("[%s]%s%s[%s][%s %d] %s", PREFIX, ts, mon, name, file, line, msg)
	if config.log.output == "buffer" then
		write_buffer(final)
	elseif config.log.output == "file" then
		write_buffer(final)
	elseif config.log.output == "print" then
		print(final)
	else
		notify.notify(final, level)
	end
end

---@param ... unknown
function M.debug(...)
	emit(false, levels.DEBUG, {}, ...)
end

---@param ... unknown
function M.info(...)
	emit(false, levels.INFO, {}, ...)
end

---@param ... unknown
function M.warn(...)
	emit(false, levels.WARN, {}, ...)
end

---@param ... unknown
function M.error(...)
	emit(false, levels.ERROR, {}, ...)
end

---@param ... unknown
function M.probe(...)
	if not config.log.probe then
		return
	end
	emit(true, levels.ERROR, {}, ...)
end

---@param category string
---@param ... unknown
function M.watch(category, ...)
	if levels.DEBUG < config.log.level then
		return
	end
	emit(false, levels.DEBUG, { category = category }, ...)
end

local aug = vim.api.nvim_create_augroup("TirenviLogHL", { clear = true })
vim.api.nvim_create_autocmd("WinEnter", {
	group = aug,
	callback = function(args)
		if args.buf == log_bufnr then
			apply_log_highlight(args.buf)
		end
	end,
})

return M
