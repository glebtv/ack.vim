-- Window picker module for ack.nvim
-- Inspired by nvim-tree.lua's window picker implementation
-- Copyright notice: This implementation is inspired by nvim-tree.lua which is
-- Copyright (c) 2019 Yazdani Kiyan and licensed under the MIT License

local M = {}

-- Get single char from user input
local function get_user_input_char()
  local c = vim.fn.getchar()
  while type(c) ~= "number" do
    c = vim.fn.getchar()
  end
  return vim.fn.nr2char(c)
end

-- Get all windows in the current tabpage that are usable
local function get_usable_win_ids(exclude_config)
  local tabpage = vim.api.nvim_get_current_tabpage()
  local win_ids = vim.api.nvim_tabpage_list_wins(tabpage)
  local current_win = vim.api.nvim_get_current_win()
  
  -- Get current window's buffer info to check if it's quickfix
  local current_bufid = vim.api.nvim_win_get_buf(current_win)
  local current_buftype = vim.api.nvim_get_option_value('buftype', { buf = current_bufid })
  local is_quickfix = current_buftype == 'quickfix'
  
  local results = {}
  for _, id in ipairs(win_ids) do
    local should_include = true
    
    -- Skip the current window only if it's quickfix
    if id == current_win and is_quickfix then
      should_include = false
    else
      local bufid = vim.api.nvim_win_get_buf(id)
      
      -- Check excluded buffer options
      for option, values in pairs(exclude_config) do
        local ok, option_value = pcall(vim.api.nvim_get_option_value, option, { buf = bufid })
        if ok and vim.tbl_contains(values, option_value) then
          should_include = false
          break
        end
      end
      
      if should_include then
        -- Check if window is focusable and not floating
        local win_config = vim.api.nvim_win_get_config(id)
        if not (win_config.focusable and not win_config.external and win_config.relative == "") then
          should_include = false
        end
      end
    end
    
    if should_include then
      table.insert(results, id)
    end
  end
  
  return results
end

-- Pick a window using letter labels
function M.pick_window(config)
  local selectable = get_usable_win_ids(config.exclude)
  
  -- If no windows, return nil
  if #selectable == 0 then
    return nil
  end
  
  -- If only one window and not forcing picker, return it directly
  if #selectable == 1 and not config.force_picker then
    return selectable[1]
  end
  
  -- Check if we have enough chars for all windows
  if #config.chars < #selectable then
    vim.notify(string.format("More windows (%d) than window_picker.chars (%d).", #selectable, #config.chars), vim.log.levels.ERROR)
    return nil
  end
  
  -- Save original statuslines
  local win_opts_original = {}
  local win_map = {}
  local laststatus = vim.o.laststatus
  vim.o.laststatus = 2
  
  -- Set up picker UI
  for i, win_id in ipairs(selectable) do
    local char = config.chars:sub(i, i)
    
    -- Save original statusline
    local ok, statusline = pcall(vim.api.nvim_get_option_value, "statusline", { win = win_id })
    local ok_hl, winhl = pcall(vim.api.nvim_get_option_value, "winhl", { win = win_id })
    
    win_opts_original[win_id] = {
      statusline = ok and statusline or "",
      winhl = ok_hl and winhl or "",
    }
    
    -- Set picker statusline
    win_map[char] = win_id
    vim.api.nvim_set_option_value("statusline", "%#AckWindowPicker#%=" .. char .. "%=", { win = win_id })
    vim.api.nvim_set_option_value("winhl", "StatusLine:AckWindowPicker,StatusLineNC:AckWindowPicker", { win = win_id })
  end
  
  -- Show prompt and get user input
  vim.cmd("redraw")
  if vim.opt.cmdheight._value ~= 0 then
    print("Pick window: ")
  end
  
  local ok, resp = pcall(get_user_input_char)
  resp = (resp or ""):upper()
  
  -- Clear prompt
  if vim.opt.cmdheight._value ~= 0 then
    vim.cmd("normal! :")
  end
  
  -- Restore original statuslines
  for win_id, opts in pairs(win_opts_original) do
    if vim.api.nvim_win_is_valid(win_id) then
      for opt, value in pairs(opts) do
        pcall(vim.api.nvim_set_option_value, opt, value, { win = win_id })
      end
    end
  end
  
  vim.o.laststatus = laststatus
  
  -- Return selected window
  if ok and vim.tbl_contains(vim.split(config.chars, ""), resp) then
    return win_map[resp]
  end
  
  return nil
end

return M