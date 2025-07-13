-- Modern Lua port of ack.vim
-- Compatible with lazy.nvim
-- Parts of this code are inspired by rg.nvim (https://github.com/doums/rg.nvim)

local M = {}
local cfg = require('ack.config')
local ack_module = require('ack.ack')

function M.setup(config)
  vim.g.ack_setup_called = true
  config = cfg.init(config or {})
  
  -- Check for ack/ag executable
  if not config.ackprg then
    vim.notify('✗ [ack] No ack or ag (the_silver_searcher) found on the system', vim.log.levels.ERROR)
    config.ack_not_found = true
  elseif config.show_notifications then
    local executable = vim.split(config.ackprg, " ")[1]
    vim.notify(string.format('✓ [ack] Using %s for searching', executable), vim.log.levels.INFO)
  end
  
  -- Set up highlight group for window picker
  vim.api.nvim_set_hl(0, 'AckWindowPicker', { 
    fg = '#1e1e1e', 
    bg = '#98c379', 
    bold = true,
    default = true 
  })
  
  ack_module.init(config)
end

-- Export main functions
M.ack = ack_module.ack
M.ack_sync = ack_module.ack_sync
M.ack_from_search = ack_module.ack_from_search
M.ack_help = ack_module.ack_help

-- Test function for window picker
M.test_window_picker = function()
  local window_picker = require('ack.window-picker')
  local config = cfg.get()
  vim.notify("Testing window picker...", vim.log.levels.INFO)
  local win = window_picker.pick_window(config.window_picker)
  if win then
    vim.notify(string.format("Window selected: %d", win), vim.log.levels.INFO)
  else
    vim.notify("No window selected", vim.log.levels.INFO)
  end
end

return M