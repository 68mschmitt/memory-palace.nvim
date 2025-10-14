local M = {}

local time = require("memorypalace.core.time")
local filename = require("memorypalace.core.filename")
local fs = require("memorypalace.core.fs")
local notify = require("memorypalace.ui.notify")
local config = require("memorypalace.config")
local directory_picker = require("memorypalace.ui.directory_picker")
local input = require("memorypalace.ui.input")
local template_module = require("memorypalace.core.template")

function M.create_note_at()
    local cfg = config.get()

    directory_picker.show_directory_picker(
        cfg.base_dir,
        cfg.base_dir,
        cfg.exclude_dirs,
        function(dest_dir)
            input.prompt_for_label(function(label)
                input.prompt_for_template(
                    cfg.templates,
                    cfg.default_template,
                    function(template_key)
                        local timestamp = time.now_stamp()
                        local new_filename = filename.build_sorted_filename(
                            label,
                            timestamp,
                            cfg.file_ext,
                            cfg.trailing_marker
                        )
                        local unique_filename = filename.ensure_unique(dest_dir, new_filename)
                        local full_path = dest_dir .. "/" .. unique_filename

                        local raw_template = cfg.templates[template_key] or ""
                        local variables = template_module.get_template_variables(label, timestamp)
                        local template_content = template_module.substitute_variables(raw_template, variables)

                        if cfg.auto_save_new_note then
                            fs.ensure_dir(dest_dir)
                            local success = fs.write_file(full_path, template_content)

                            if not success then
                                notify.warn("Failed to create note: " .. full_path)
                                return nil
                            end
                        end

                        if cfg.open_after_create then
                            vim.cmd.edit(full_path)

                            if not cfg.auto_save_new_note and template_content ~= "" then
                                local lines = vim.split(template_content, "\n")
                                vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
                            end
                        end

                        if cfg.notify then
                            local relative = full_path:gsub("^" .. vim.pesc(cfg.base_dir) .. "/", "")
                            notify.info("Created → " .. relative)
                        end

                        return full_path
                    end
                )
            end)
        end
    )
end

return M
