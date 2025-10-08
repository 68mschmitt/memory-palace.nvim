local M = {}

local default_config = {
  inbox_dir = "~/notes/inbox",
  file_ext = ".md",
  timestamp_fmt = "%Y-%m-%d_%H-%M-%S",
  open_after_create = true,
  notify = true,
}

local config = {}

function M.setup(opts)
  config = vim.tbl_deep_extend("force", default_config, opts or {})
  config.inbox_dir = vim.fn.expand(config.inbox_dir)
end

function M.get()
  return config
end

return M