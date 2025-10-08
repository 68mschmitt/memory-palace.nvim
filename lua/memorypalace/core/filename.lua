local M = {}

local fs = require("memorypalace.core.fs")

function M.build(timestamp, slug, ext)
  return timestamp .. "--" .. slug .. ext
end

function M.ensure_unique(dir, filename)
  local path = dir .. "/" .. filename
  
  if not fs.file_exists(path) then
    return filename
  end
  
  local base = filename:gsub("%.md$", "")
  local counter = 2
  
  while true do
    local new_filename = string.format("%s--%d.md", base, counter)
    local new_path = dir .. "/" .. new_filename
    
    if not fs.file_exists(new_path) then
      return new_filename
    end
    
    counter = counter + 1
  end
end

return M