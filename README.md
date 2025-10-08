# memory-palace.nvim

A minimal Neovim plugin for quick note creation. One command, one keystroke, one blank markdown file in your inbox.

## Features

- **Single Command**: `:NewNote` creates a blank markdown file instantly
- **Unique Filenames**: Timestamped format `YYYY-MM-DD_HH-MM-SS--note.md`
- **Auto-open**: Immediately opens the new file for editing
- **Collision Handling**: Automatically handles filename conflicts
- **Configurable**: Customize inbox directory and behavior

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "68mschmitt/memory-palace.nvim",
  cmd = { "NewNote" },
  keys = {
    { "<leader>nn", "<cmd>NewNote<cr>", desc = "New note (inbox)" },
  },
  opts = {
      inbox_dir = "~/notes/inbox",
  },
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  '68mschmitt/memory-palace.nvim',
  config = function()
    require('memorypalace').setup({
      inbox_dir = '~/notes/inbox',
    })
  end
}
```

## Configuration

```lua
require("memorypalace").setup({
  inbox_dir = "~/notes/inbox",     -- Directory for new notes
  file_ext = ".md",                 -- File extension
  timestamp_fmt = "%Y-%m-%d_%H-%M-%S", -- Timestamp format
  open_after_create = true,         -- Open file after creating
  notify = true,                    -- Show notification after creating
})
```

## Usage

### Command

- `:NewNote` - Creates a blank markdown file in your inbox

### Programmatic API

```lua
local memorypalace = require("memorypalace")

-- Create a new note and get the path
local path = memorypalace.new_note()
```

## File Structure

The plugin creates files with the following pattern:
- `2025-10-08_09-17-33--note.md` - Standard format
- `2025-10-08_09-17-33--note--2.md` - With collision handling

## Philosophy

This plugin follows the MVP principle: **one keystroke → blank markdown file in inbox**

- No prompts
- No metadata
- No formatting
- Just a blank file ready for your thoughts

## License

MIT
