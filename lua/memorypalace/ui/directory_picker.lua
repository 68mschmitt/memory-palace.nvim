local M = {}

local directory = require("memorypalace.core.directory")

local function normalize_path(path)
    path = path:gsub("/+$", "")
    return path
end

local function get_relative_path(base_dir, current_path)
    base_dir = normalize_path(base_dir)
    current_path = normalize_path(current_path)

    if current_path == base_dir then
        return "/"
    end

    local relative = current_path:gsub("^" .. vim.pesc(base_dir), "")
    return relative:gsub("^/", "")
end

function M.show_directory_picker(base_dir, current_path, exclude_dirs, callback)
    current_path = current_path or base_dir
    current_path = normalize_path(current_path)
    base_dir = normalize_path(base_dir)

    local subdirs = directory.list_subdirs(current_path, exclude_dirs)
    local items = M.build_picker_items(base_dir, current_path, subdirs)

    local relative_path = get_relative_path(base_dir, current_path)
    local prompt = "Select destination [" .. relative_path .. "]"

    vim.ui.select(items, { prompt = prompt }, function(choice)
        if not choice then
            return
        end

        M.handle_picker_selection(choice, base_dir, current_path, exclude_dirs, callback)
    end)
end

function M.build_picker_items(base_dir, current_path, subdirs)
    local items = {}

    for _, subdir in ipairs(subdirs) do
        table.insert(items, subdir)
    end

    table.insert(items, "✓ Drop Here")

    table.insert(items, "+ Create New")

    if normalize_path(current_path) ~= normalize_path(base_dir) then
        table.insert(items, "← Go Back")
    end

    return items
end

function M.handle_picker_selection(choice, base_dir, current_path, exclude_dirs, callback)
    if choice == "← Go Back" then
        local parent = vim.fn.fnamemodify(current_path, ":h")
        M.show_directory_picker(base_dir, parent, exclude_dirs, callback)
    elseif choice == "✓ Drop Here" then
        callback(current_path)
    elseif choice == "+ Create New" then
        M.create_new_directory(current_path, base_dir, exclude_dirs, callback)
    else
        local next_path = current_path .. "/" .. choice
        M.show_directory_picker(base_dir, next_path, exclude_dirs, callback)
    end
end

function M.create_new_directory(parent_path, base_dir, exclude_dirs, callback)
    vim.ui.input({ prompt = "New directory name: " }, function(name)
        if not name or name == "" then
            M.show_directory_picker(base_dir, parent_path, exclude_dirs, callback)
            return
        end

        local new_path = parent_path .. "/" .. name
        directory.ensure_path_exists(new_path)

        M.show_directory_picker(base_dir, new_path, exclude_dirs, callback)
    end)
end

return M

