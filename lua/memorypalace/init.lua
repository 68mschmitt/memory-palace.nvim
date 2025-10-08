local M = {}

function M.setup(opts)
  require("memorypalace.config").setup(opts)
  require("memorypalace.commands").register()
end

function M.new_note()
  local cfg = require("memorypalace.config").get()
  return require("memorypalace.note.create").create_blank_note(cfg.inbox_dir)
end

return M