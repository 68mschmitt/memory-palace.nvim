# memory-palace.nvim

A minimal Neovim plugin for quick note creation and organization. Capture thoughts instantly in your inbox, then sort them into a structured hierarchy when ready.

## Features

### Quick Note Creation (`:NewNote`)
- **Single Command**: `:NewNote` creates a blank markdown file instantly
- **Unique Filenames**: Timestamped format `YYYY-MM-DD_HH-MM-SS--note.md`
- **Auto-open**: Immediately opens the new file for editing
- **Collision Handling**: Automatically handles filename conflicts

### Direct Note Creation (`:CreateNote`)
- **Create in Place**: Create notes directly in their final destination
- **Directory Drill-down**: Interactive navigation to choose location
- **Optional Labeling**: Add descriptive names or skip for timestamp-only filenames
- **Template Selection**: Choose from multiple templates with variable substitution
- **Template Variables**: Support for `{{title}}`, `{{date}}`, `{{datetime}}`, `{{timestamp}}`
- **Smart Naming**: Format becomes `{label}-{timestamp}--note.md` (or just `{timestamp}--note.md` if no label)

### Note Sorting (`:SortNote`)
- **Directory Drill-down**: Interactive navigation through your note structure
- **Optional Labeling**: Add descriptive names or skip for timestamp-only filenames
- **Timestamp Preservation**: Keeps original creation timestamp
- **Smart Renaming**: Format becomes `{label}-{timestamp}--note.md` (or just `{timestamp}--note.md` if no label)
- **True Move**: Original file is moved, not copied
- **Cross-filesystem Support**: Works across different filesystems

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "68mschmitt/memory-palace.nvim",
  cmd = { "NewNote", "CreateNote", "SortNote" },
  keys = {
    { "<leader>nn", "<cmd>NewNote<cr>", desc = "New note (inbox)" },
    { "<leader>nc", "<cmd>CreateNote<cr>", desc = "Create note at location" },
    { "<leader>ns", "<cmd>SortNote<cr>", desc = "Sort/move note" },
  },
  opts = {
    inbox_dir = "~/notes/inbox",
    base_dir = "~/notes",
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
  -- Note Creation
  inbox_dir = "~/notes/inbox",              -- Directory for new notes
  base_dir = "~/notes",                      -- Base directory for CreateNote and sorting
  file_ext = ".md",                          -- File extension
  timestamp_fmt = "%Y-%m-%d_%H-%M-%S",      -- Timestamp format
  open_after_create = true,                  -- Open file after creating
  auto_save_new_note = true,                 -- Auto-save new notes to disk (false = manual :w)
  notify = true,                             -- Show notifications
  
  -- Templates for CreateNote
  templates = {
    none = "",
    default = "# {{title}}\n\nCreated: {{date}}\n\n",
    meeting = [[# Meeting: {{title}}

Date: {{date}}

## Attendees
- 

## Agenda
1. 

## Discussion Notes


## Action Items
- [ ] 

## Next Meeting
]],
    journal = [[# Daily Journal - {{date}}

## Morning Thoughts


## What Happened Today


## Grateful For
1. 
2. 
3. 

## Tomorrow's Focus
]],
    task = [[# Task: {{title}}

Created: {{datetime}}

## Status
- [ ] Not Started

## Description


## Steps
1. 

## Notes
]],
  },
  default_template = "none",                 -- Pre-selected template in picker
  
  -- Note Sorting
  trailing_marker = "--note",                -- Filename suffix marker
  exclude_dirs = { ".git", ".obsidian" },   -- Directories to exclude from picker
  confirm_on_cross_fs = false,               -- Confirm cross-filesystem moves
  allow_non_md = true,                       -- Allow sorting non-markdown files
})
```

### Auto-Save Behavior

- **`auto_save_new_note = true`** (default): File is immediately saved to disk when created. The file exists in your filesystem before you start editing.
- **`auto_save_new_note = false`**: File is only created in a buffer. You must save with `:w` to persist it. Closing the buffer without saving leaves no empty file behind.

## Usage

### Commands

- `:NewNote` - Creates a blank markdown file in your inbox
- `:CreateNote` - Create a note directly in a chosen location with optional label and template
- `:SortNote` - Move and rename the current note with interactive directory selection

### Workflows

#### Capture-Then-Sort (Unknown destination)
1. **Capture**: Use `:NewNote` to quickly create a note in your inbox
2. **Edit**: Write your content without worrying about organization
3. **Sort**: When ready, use `:SortNote` to:
   - Navigate through your directory structure
   - Choose a destination (or create new directories)
   - Optionally provide a descriptive label (or press Enter to skip)
   - File is automatically moved and renamed

#### Create-In-Place (Known destination)
1. **Create**: Use `:CreateNote` to create a note directly:
   - Navigate through your directory structure
   - Choose a destination (or create new directories)
   - Optionally provide a descriptive label (or press Enter to skip)
   - Select a template from your configured options
   - File is created with the selected template (variables substituted)
2. **Edit**: Write your content in the final location

### Programmatic API

```lua
local memorypalace = require("memorypalace")

-- Create a new note in inbox and get the path
local path = memorypalace.new_note()

-- Create a note in chosen location (interactive)
memorypalace.create_note_at()

-- Sort the current note
memorypalace.sort_note()
```

## File Naming

### New Notes (`:NewNote`)
- `2025-10-08_09-17-33--note.md` - Inbox format
- `2025-10-08_09-17-33--note--2.md` - With collision handling

### Created Notes (`:CreateNote`)
- `miata-boost-2025-10-14_13-42-10--note.md` - With label
- `2025-10-14_13-42-10--note.md` - Without label (skipped)
- `{label}-{timestamp}--note.md` - General pattern with label
- `{timestamp}--note.md` - General pattern without label
- Created directly in final destination
- Collision handling with `--2`, `--3`, etc.

### Sorted Notes (`:SortNote`)
- `miata-boost-2025-10-08_11-07-15--note.md` - With label
- `2025-10-08_11-07-15--note.md` - Without label (skipped)
- `{label}-{timestamp}--note.md` - General pattern with label
- `{timestamp}--note.md` - General pattern without label
- Timestamp is preserved from original file
- Label precedes timestamp for readability (when provided)
- Collision handling with `--2`, `--3`, etc.

## Templates

Templates support variable substitution with the following placeholders:

- `{{title}}` - Replaced with the note label (or "Note" if no label provided)
- `{{date}}` - Today's date in `YYYY-MM-DD` format
- `{{datetime}}` - Full timestamp in `YYYY-MM-DD HH:MM:SS` format
- `{{timestamp}}` - Filename timestamp in configured format

### Example Template Configuration

```lua
templates = {
  none = "",
  default = "# {{title}}\n\nCreated: {{date}}\n\n",
  meeting = [[# Meeting: {{title}}

Date: {{date}}

## Attendees
- 

## Agenda
]],
}
```

## Directory Navigation

When sorting a note, you'll see:
- **← Go Back** - Navigate to parent directory (hidden at base)
- **✓ Drop Here** - Select current directory as destination
- **+ Create New** - Create a new subdirectory
- **[Subdirectories]** - Existing subdirectories (alphabetical)

## Philosophy

**Two workflows for different needs**

- **Capture fast, organize later**: `:NewNote` → `:SortNote`
  - Zero friction capture to inbox
  - Thoughtful organization when ready
- **Create in place**: `:CreateNote`
  - Direct creation when destination is known
  - Optional template support for structured notes
- Timestamp preservation maintains creation history
- Clean, predictable file naming for easy searching

## License

MIT
