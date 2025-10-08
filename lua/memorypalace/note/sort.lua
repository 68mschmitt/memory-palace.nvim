local M = {}

local config = require("memorypalace.config")
local timestamp = require("memorypalace.core.timestamp")
local filename = require("memorypalace.core.filename")
local move = require("memorypalace.core.move")
local notify = require("memorypalace.ui.notify")
local directory_picker = require("memorypalace.ui.directory_picker")
local input = require("memorypalace.ui.input")

function M.validate_current_buffer()
    local current_file = vim.api.nvim_buf_get_name(0)

    if current_file == "" then
        return false, "Current buffer has no file"
    end

    local cfg = config.get()
    if not cfg.allow_non_md and not current_file:match("%.md$") then
        return false, "Current file is not a markdown file"
    end

    if vim.fn.filereadable(current_file) == 0 then
        return false, "Current file does not exist on disk"
    end

    return true, current_file
end

function M.execute_sort_workflow(current_path, dest_dir, label)
    local cfg = config.get()

    local extracted_timestamp = timestamp.preserve_or_fallback_timestamp(
        current_path,
        current_path,
        cfg.timestamp_fmt
    )

    local new_filename = filename.build_sorted_filename(
        label,
        extracted_timestamp,
        cfg.file_ext,
        cfg.trailing_marker
    )

    local unique_filename = filename.ensure_unique(dest_dir, new_filename)

    local dest_path = dest_dir .. "/" .. unique_filename

    if vim.bo.modified then
        vim.cmd("write")
    end

    local success, err = move.move_file(current_path, dest_path)

    if not success then
        notify.warn("Failed to move file: " .. tostring(err))
        return false
    end

    vim.cmd.edit(dest_path)

    return true, dest_path
end

function M.handle_sort_completion(old_path, new_path)
    local cfg = config.get()

    if cfg.notify then
        local base_dir = cfg.base_dir
        local relative = new_path:gsub("^" .. vim.pesc(base_dir) .. "/", "")
        notify.info("Sorted → " .. relative)
    end
end

function M.sort_current_note()
    local valid, current_file = M.validate_current_buffer()

    if not valid then
        notify.warn(current_file)
        return
    end

    local cfg = config.get()

    directory_picker.show_directory_picker(
        cfg.base_dir,
        cfg.base_dir,
        cfg.exclude_dirs,
        function(dest_dir)
            input.prompt_for_label(function(label)
                local success, new_path = M.execute_sort_workflow(current_file, dest_dir, label)

                if success then
                    M.handle_sort_completion(current_file, new_path)
                end
            end)
        end
    )
end

return M

