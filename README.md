# ack.nvim

**A modern Lua port of ack.vim, compatible with lazy.nvim**

This plugin provides a front-end for search tools like [ack](https://beyondgrep.com/) and [ag (the_silver_searcher)](https://github.com/ggreer/the_silver_searcher), allowing you to run searches from Neovim and display results in a quickfix window.

## Credits

This is a Lua port of the original [ack.vim](https://github.com/mileszs/ack.vim) plugin.
Parts of this code are inspired by [rg.nvim](https://github.com/doums/rg.nvim) by doums, particularly the async execution patterns and configuration structure.

## Features

- **Modern Lua implementation** - Fully rewritten in Lua for better performance and maintainability
- **Auto-detection** - Automatically detects and uses `ag`, `ack`, or `ack-grep` (in that order of preference)
- **Lazy.nvim compatible** - Works seamlessly with the lazy.nvim plugin manager
- **Async search** - Non-blocking search operations using Neovim's job control
- **Quickfix integration** - Results displayed in quickfix with customizable mappings
- **Backwards compatible** - Maintains the same commands as the original ack.vim

## Requirements

- Neovim >= 0.7.0
- Either [ack](https://beyondgrep.com/) or [ag (the_silver_searcher)](https://github.com/ggreer/the_silver_searcher)

### Installing Search Tools

**ag (the_silver_searcher) - Recommended**

    # macOS
    brew install the_silver_searcher
    
    # Ubuntu/Debian
    sudo apt-get install silversearcher-ag
    
    # Fedora
    sudo yum install the_silver_searcher

**ack**

    # macOS
    brew install ack
    
    # Ubuntu/Debian  
    sudo apt-get install ack-grep
    
    # Fedora
    sudo yum install ack

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "mileszs/ack.vim",
  config = function()
    require('ack').setup({
      -- Optional configuration
      ackprg = "ag --vimgrep",  -- Custom command (auto-detected by default)
      apply_qmappings = true,   -- Apply quickfix mappings
      apply_lmappings = true,   -- Apply location list mappings
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'mileszs/ack.vim',
  config = function()
    require('ack').setup()
  end
}
```


## Usage

### Commands

- `:Ack [pattern] [directory]` - Search asynchronously 
- `:AckSync [pattern] [directory]` - Search synchronously
- `:AckAdd [pattern] [directory]` - Add results to existing quickfix
- `:LAck [pattern] [directory]` - Search to location list
- `:AckFromSearch [directory]` - Search using current search register
- `:AckFile [pattern]` - Search for filenames matching pattern
- `:AckHelp [pattern]` - Search in Vim help files

If no pattern is provided, the word under cursor is used.

### Configuration

```lua
require('ack').setup({
  -- Command to use (auto-detected by default)
  -- Examples: "ack --column", "ag --vimgrep", "ack-grep --column"
  ackprg = nil,
  
  -- Apply default quickfix window mappings
  apply_qmappings = true,
  
  -- Apply default location list mappings
  apply_lmappings = true,
  
  -- Command to open quickfix window
  qhandler = "copen",
  
  -- Command to open location list window  
  lhandler = "lopen",
  
  -- Optional quickfix format function
  qf_format = nil,
  
  -- Use dispatch.vim for async if available
  use_dispatch = false,
  
  -- Show search notifications (default: false)
  -- When true, shows "Ack Searching..." and "Found N matches"
  -- Note: "No matches found" is always shown for user feedback
  show_notifications = false,
  
  -- Window picker configuration
  window_picker = {
    -- Enable window picker (default: true)
    enable = true,
    
    -- Characters to use for window labels
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    
    -- Highlight group for window labels
    highlight = "StatusLine:AckWindowPicker,StatusLineNC:AckWindowPicker",
    
    -- Exclude windows with these buffer options
    exclude = {
      filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" },
      buftype = { "nofile", "terminal", "help" }
    }
  }
})
```

### Search Tips

- Use quotes for multi-word searches: `:Ack "function foo"`
- Escape special characters: `:Ack '\#define'`
- Specify file types with ag: `:Ack --js "console.log"`
- Search in specific directory: `:Ack pattern /path/to/search`

### Keyboard Shortcuts

In the quickfix window, you can use:

    o         to open with window picker (shows letter labels when multiple windows exist)
    <CR>      to open with window picker (same as 'o')
    <mouse>   double-click to open with window picker
    s         to open in first available split immediately
    go        to preview file (open but maintain focus on ack.vim results)
    t         to open in new tab
    T         to open in new tab silently
    h         to open in horizontal split
    H         to open in horizontal split silently
    v         to open in vertical split
    gv        to open in vertical split silently
    q         to close the quickfix window

### Window Picker

By default, when you press `o` or `<CR>` in the quickfix window with multiple windows open, ack.nvim will show letter labels (A, B, C, etc.) in the status line of each available window. Press the corresponding letter to open the file in that window. If only one window is available, it opens there directly without showing the picker.

The `s` key provides a quick alternative to open the file in the first available split without showing the picker interface.

## License

This plugin maintains the original license of ack.vim.
Portions of the async handling and configuration structure are inspired by [rg.nvim](https://github.com/doums/rg.nvim) which is licensed under the Mozilla Public License 2.0.
The window picker implementation is inspired by [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua) which is licensed under the MIT License.

## Acknowledgments

- Original ack.vim plugin by Miles Z. Sterrett (mileszs)
- Async patterns and configuration structure inspired by [rg.nvim](https://github.com/doums/rg.nvim) by doums
- Window picker implementation inspired by [nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua)'s window picker
- The original Vim plugin was derived from Antoine Imbert's blog post [Ack and Vim Integration](http://blog.ant0ine.com/typepad/2007/03/ack-and-vim-integration.html)
- Lua port created with the assistance of Claude Opus 4 AI
