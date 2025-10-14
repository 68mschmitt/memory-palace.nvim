local M = {}

function M.register()
    vim.api.nvim_create_user_command("NewNote", function()
        local cfg = require("memorypalace.config").get()
        require("memorypalace.note.create").create_blank_note(cfg.inbox_dir)
    end, { desc = "Create blank note in inbox" })

    vim.api.nvim_create_user_command("SortNote", function()
        require("memorypalace.note.sort").sort_current_note()
    end, { desc = "Sort/move current note with required rename" })

    vim.api.nvim_create_user_command("CreateNote", function()
        require("memorypalace.note.create_at").create_note_at()
    end, { desc = "Create note in chosen location with optional label" })
end

return M

