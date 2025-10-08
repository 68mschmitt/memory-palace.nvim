local M = {}

function M.register()
  vim.api.nvim_create_user_command("NewNote", function()
    local cfg = require("memorypalace.config").get()
    require("memorypalace.note.create").create_blank_note(cfg.inbox_dir)
  end, { desc = "Create blank note in inbox" })
end

return M