local M = {}

local function get_state_file_path()
    local config = require("memorypalace.config").get()
    return config.recent_state_file or (vim.fn.stdpath("state") .. "/memory-palace-mru.json")
end

function M.load_recent()
    local state_file = get_state_file_path()

    if vim.fn.filereadable(state_file) == 0 then
        return { recent = {} }
    end

    local file = io.open(state_file, "r")
    if not file then
        return { recent = {} }
    end

    local content = file:read("*a")
    file:close()

    local success, data = pcall(vim.json.decode, content)
    if not success or type(data) ~= "table" then
        return { recent = {} }
    end

    return data
end

function M.save_recent(data)
    local state_file = get_state_file_path()
    local state_dir = vim.fn.fnamemodify(state_file, ":h")

    if vim.fn.isdirectory(state_dir) == 0 then
        vim.fn.mkdir(state_dir, "p")
    end

    local json = vim.json.encode(data)

    local file = io.open(state_file, "w")
    if not file then
        return false
    end

    file:write(json)
    file:close()
    return true
end

function M.add_recent_entry(dir, template, label)
    local config = require("memorypalace.config").get()

    if not config.enable_recent_dirs then
        return
    end

    local data = M.load_recent()
    local recent = data.recent or {}

    local existing_idx = nil
    for i, entry in ipairs(recent) do
        if entry.dir == dir then
            existing_idx = i
            break
        end
    end

    if existing_idx then
        table.remove(recent, existing_idx)
    end

    table.insert(recent, 1, {
        dir = dir,
        template = template,
        label = label,
        timestamp = os.time(),
    })

    while #recent > config.max_recent_dirs do
        table.remove(recent)
    end

    data.recent = recent
    M.save_recent(data)
end

function M.get_recent_list()
    local config = require("memorypalace.config").get()

    if not config.enable_recent_dirs then
        return {}
    end

    local data = M.load_recent()
    local recent = data.recent or {}

    local valid_entries = {}
    for _, entry in ipairs(recent) do
        local expanded_dir = vim.fn.expand(entry.dir)
        if vim.fn.isdirectory(expanded_dir) == 1 then
            entry.dir = expanded_dir
            table.insert(valid_entries, entry)
        end
    end

    return valid_entries
end

function M.format_time_ago(timestamp)
    local now = os.time()
    local diff = now - timestamp

    if diff < 60 then
        return "just now"
    elseif diff < 3600 then
        local mins = math.floor(diff / 60)
        return mins == 1 and "1 min ago" or string.format("%d mins ago", mins)
    elseif diff < 86400 then
        local hours = math.floor(diff / 3600)
        return hours == 1 and "1 hour ago" or string.format("%d hours ago", hours)
    elseif diff < 172800 then
        return "yesterday"
    else
        local days = math.floor(diff / 86400)
        return string.format("%d days ago", days)
    end
end

function M.format_recent_display(entry, base_dir)
    local relative = entry.dir:gsub("^" .. vim.pesc(base_dir) .. "/", "")
    local time_ago = M.format_time_ago(entry.timestamp)
    return string.format("%s [%s] (%s)", relative, entry.template or "none", time_ago)
end

return M
