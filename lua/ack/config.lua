-- Configuration module for ack.nvim
-- Parts of this code are inspired by rg.nvim (https://github.com/doums/rg.nvim)

local M = {}

-- Detect which searcher is available
local function detect_searcher()
  if vim.fn.executable('rg') == 1 then
    return "rg --vimgrep"
  elseif vim.fn.executable('ag') == 1 then
    return "ag --vimgrep"
  elseif vim.fn.executable('ack') == 1 then
    return "ack --column"
  elseif vim.fn.executable('ack-grep') == 1 then
    return "ack-grep --column"
  else
    return nil
  end
end

-- Default config
local _config = {
  -- Location of the ack utility (auto-detects rg, ag, ack, or ack-grep)
  ackprg = nil,
  
  -- Apply quickfix mappings
  apply_qmappings = true,
  
  -- Apply location list mappings  
  apply_lmappings = true,
  
  -- Quickfix handler
  qhandler = "copen",
  
  -- Location list handler
  lhandler = "lopen",
  
  -- Optional function to be used to format the items in the
  -- quickfix window (:h 'quickfixtextfunc')
  qf_format = nil,
  
  -- Use dispatch.vim for async search (if available)
  use_dispatch = false,
  
  -- Show search notifications (e.g., "Ack Searching...", "Found N matches")
  show_notifications = false,
  
  -- Window picker configuration
  window_picker = {
    -- Enable window picker for opening files
    enable = true,
    
    -- Characters to use for window labels
    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
    
    -- Highlight group for window labels
    highlight = "StatusLine:AckWindowPicker,StatusLineNC:AckWindowPicker",
    
    -- Exclude windows with these buffer options
    exclude = {
      filetype = { "notify", "packer", "diff", "fugitive", "fugitiveblame", "NvimTree", "neo-tree" },
      buftype = { "terminal", "help", "prompt" }
    }
  }
}

function M.init(config)
  _config = vim.tbl_deep_extend('force', _config, config or {})
  
  -- Auto-detect searcher if not specified
  if not _config.ackprg then
    _config.ackprg = detect_searcher()
  end
  
  -- Set global variables for backwards compatibility
  vim.g.ackprg = _config.ackprg
  vim.g.ack_apply_qmappings = _config.apply_qmappings
  vim.g.ack_apply_lmappings = _config.apply_lmappings
  vim.g.ack_qhandler = _config.qhandler
  vim.g.ack_lhandler = _config.lhandler
  
  return _config
end

function M.get()
  return _config
end

return M