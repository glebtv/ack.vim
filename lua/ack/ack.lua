-- Main ack functionality
-- Parts of this code are inspired by rg.nvim (https://github.com/doums/rg.nvim)

local M = {}
local lvl = vim.log.levels
local _config

-- Helper to expand search pattern
local function expand_pattern(args)
  if args == "" or args == nil then
    return vim.fn.expand("<cword>")
  end
  return args
end

-- Format quickfix/location list
local function get_format(cmd)
  if cmd:match('-g$') then
    return "%f"
  else
    return "%f:%l:%c:%m"
  end
end

-- Window picker for opening files
local window_picker = require('ack.window-picker')

-- Extract filename from quickfix line
local function get_qf_filename()
  -- Get current quickfix entry
  local qf_idx = vim.fn.line('.')
  local qf_list = vim.fn.getqflist()
  
  if qf_idx > 0 and qf_idx <= #qf_list then
    local entry = qf_list[qf_idx]
    local bufnr = entry.bufnr
    
    if bufnr > 0 then
      local filename = vim.api.nvim_buf_get_name(bufnr)
      if filename ~= '' then
        return filename, entry.lnum, entry.col
      end
    end
  end
  
  -- Fallback to pattern matching
  local line = vim.fn.getline('.')
  local filename = vim.fn.matchstr(line, '^\\f\\+')
  return filename, nil, nil
end

-- Open file in first available split
local function open_in_first_split()
  local filename, lnum, col = get_qf_filename()
  
  if filename == '' then
    return
  end
  
  -- Get first available window (not using picker)
  local tabpage = vim.api.nvim_get_current_tabpage()
  local win_ids = vim.api.nvim_tabpage_list_wins(tabpage)
  local current_win = vim.api.nvim_get_current_win()
  
  for _, win_id in ipairs(win_ids) do
    if win_id ~= current_win then
      local bufid = vim.api.nvim_win_get_buf(win_id)
      local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufid })
      local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufid })
      
      -- Skip special windows
      if not vim.tbl_contains(_config.window_picker.exclude.filetype, filetype) and
         not vim.tbl_contains(_config.window_picker.exclude.buftype, buftype) then
        vim.api.nvim_set_current_win(win_id)
        vim.cmd('edit ' .. vim.fn.fnameescape(filename))
        if lnum then
          vim.api.nvim_win_set_cursor(0, {lnum, col or 0})
        end
        return
      end
    end
  end
  
  -- No suitable window found, use default behavior
  vim.cmd('normal! <CR>')
end

-- Open file with window picker
local function open_file_with_picker()
  -- Use window picker if enabled
  if _config.window_picker.enable then
    local target_win = window_picker.pick_window(_config.window_picker)
    
    if target_win then
      -- Get file info from quickfix
      local filename, lnum, col = get_qf_filename()
      
      if filename ~= '' then
        -- Switch to target window and open file
        vim.api.nvim_set_current_win(target_win)
        vim.cmd('edit ' .. vim.fn.fnameescape(filename))
        if lnum then
          vim.api.nvim_win_set_cursor(0, {lnum, col or 0})
        end
        return
      end
    end
  end
  
  -- Fallback to default behavior
  vim.cmd('normal! <CR>')
end

-- Apply quickfix mappings
local function apply_qf_mappings()
  if not _config.apply_qmappings then
    return
  end
  
  -- Override default mappings to use window picker
  if _config.window_picker.enable then
    -- Regular keys
    vim.keymap.set('n', 'o', open_file_with_picker, 
      { buffer = true, silent = true, desc = 'Open with window picker' })
    vim.keymap.set('n', '<CR>', open_file_with_picker, 
      { buffer = true, silent = true, desc = 'Open with window picker' })
    -- Mouse support
    vim.keymap.set('n', '<2-LeftMouse>', open_file_with_picker,
      { buffer = true, silent = true, desc = 'Open with window picker (mouse)' })
  else
    vim.keymap.set('n', 'o', '<CR>', { buffer = true, silent = true })
    vim.keymap.set('n', '<2-LeftMouse>', '<CR>', { buffer = true, silent = true })
  end
  
  local mappings = {
    go = '<CR><C-w>p',
    t = '<C-w><CR><C-w>T',
    T = '<C-w><CR><C-w>TgT<C-w>j',
    h = '<C-w><CR><C-w>K',
    H = '<C-w><CR><C-w>K<C-w>b',
    v = '<C-w><CR><C-w>H<C-w>b<C-w>J<C-w>t',
    gv = '<C-w><CR><C-w>H<C-w>b<C-w>J',
    q = ':cclose<CR>'
  }
  
  for key, cmd in pairs(mappings) do
    vim.keymap.set('n', key, cmd, { buffer = true, silent = true })
  end
  
  -- 's' opens in first available split immediately
  vim.keymap.set('n', 's', open_in_first_split, 
    { buffer = true, silent = true, desc = 'Open in first available split' })
end

-- Async exit handler
local async_exit = vim.schedule_wrap(function(obj)
  local code = obj.code
  if code == 0 then
    local matches = vim.split(obj.stdout, '\n', { trimempty = true })
    local count = #matches
    
    if count == 0 then
      vim.notify('No matches found', lvl.INFO)
      return
    end
    
    if _config.show_notifications then
      if count > 1 then
        vim.notify(string.format('Found %d matches', count), lvl.INFO)
      elseif count == 1 then
        vim.notify('Found 1 match', lvl.INFO)
      end
    end
    
    vim.fn.setqflist({}, 'r', {
      title = 'Ack Results',
      lines = matches,
      quickfixtextfunc = _config.qf_format,
    })
    
    vim.cmd(_config.qhandler)
  elseif code == 1 then
    vim.notify('No matches found', lvl.INFO)
  else
    vim.notify(string.format('✕ [ack] failed [%d]', code), lvl.ERROR)
  end
end)

-- Main ack function
function M.ack(cmd, args, use_loclist, async)
  if _config.ack_not_found then
    vim.notify('✗ [ack] rg/ag/ack not found on the system', lvl.ERROR)
    return
  end
  
  -- Save all buffers that have changes
  local ok, _ = pcall(vim.cmd, 'wa')
  
  vim.cmd('redraw')
  
  local pattern = expand_pattern(args)
  if _config.show_notifications then
    vim.notify("Ack Searching...", lvl.INFO)
  end
  
  -- Set format
  local format = get_format(cmd)
  
  -- Build command
  local ack_cmd = vim.split(_config.ackprg, " ")
  table.insert(ack_cmd, pattern)
  
  if async and vim.fn.exists('*dispatch#compile_command') == 1 and _config.use_dispatch then
    -- Use dispatch.vim for async
    vim.opt_local.errorformat = format
    vim.opt_local.makeprg = table.concat(ack_cmd, " ")
    vim.fn['dispatch#compile_command'](0, {}, 'M.on_ack_finished', {})
  else
    -- Use native async
    vim.system(ack_cmd, { text = true }, async_exit)
  end
  
  -- Set search register
  local search_str = pattern:match('"(.-)%"') or pattern
  vim.fn.setreg('/', search_str)
end

-- Synchronous version
function M.ack_sync(cmd, args, use_loclist)
  M.ack(cmd, args, use_loclist, false)
end

-- Search from search register
function M.ack_from_search(cmd, args, use_loclist)
  local search = vim.fn.getreg('/')
  -- Translate vim regex to perl regex
  search = search:gsub('\\[<>]', '\\b')
  M.ack(cmd, '"' .. search .. '" ' .. args, use_loclist, true)
end

-- Get doc locations
local function get_doc_locations()
  local paths = {}
  for _, p in ipairs(vim.split(vim.o.runtimepath, ',')) do
    local doc_path = p .. '/doc/'
    if vim.fn.isdirectory(doc_path) == 1 then
      table.insert(paths, doc_path .. '*.txt')
    end
  end
  return table.concat(paths, ' ')
end

-- Search in help files
function M.ack_help(cmd, args, use_loclist)
  local help_args = args .. ' ' .. get_doc_locations()
  M.ack(cmd, help_args, use_loclist, true)
end

-- Callback for dispatch
function M.on_ack_finished(request)
  local qfcount = #vim.fn.getqflist()
  if _config.show_notifications then
    vim.notify(string.format('Found %d matches', qfcount), lvl.INFO)
  end
end

-- Initialize module
function M.init(config)
  _config = config
  
  -- Create autocmd group for quickfix mappings
  local augroup = vim.api.nvim_create_augroup('AckQuickfixMappings', { clear = true })
  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = 'qf',
    callback = function()
      -- Only apply to quickfix windows created by ack
      local title = vim.fn.getqflist({ title = 0 }).title or ""
      if title:match("Ack Results") then
        apply_qf_mappings()
      end
    end
  })
  
  -- Create commands
  vim.api.nvim_create_user_command('Ack', function(opts)
    M.ack('grep' .. (opts.bang and '!' or ''), opts.args, false, true)
  end, {
    bang = true,
    nargs = '*',
    desc = 'Run ack search asynchronously'
  })
  
  vim.api.nvim_create_user_command('AckSync', function(opts)
    M.ack_sync('grep' .. (opts.bang and '!' or ''), opts.args, false)
  end, {
    bang = true,
    nargs = '*',
    desc = 'Run ack search synchronously'
  })
  
  vim.api.nvim_create_user_command('AckAdd', function(opts)
    M.ack('grepadd' .. (opts.bang and '!' or ''), opts.args, false, true)
  end, {
    bang = true,
    nargs = '*',
    desc = 'Add ack results to current list'
  })
  
  vim.api.nvim_create_user_command('AckFromSearch', function(opts)
    M.ack_from_search('grep' .. (opts.bang and '!' or ''), opts.args, false)
  end, {
    bang = true,
    nargs = '*',
    desc = 'Search using current search register'
  })
  
  vim.api.nvim_create_user_command('LAck', function(opts)
    M.ack('lgrep' .. (opts.bang and '!' or ''), opts.args, true, true)
  end, {
    bang = true,
    nargs = '*',
    desc = 'Run ack search to location list'
  })
  
  vim.api.nvim_create_user_command('LAckAdd', function(opts)
    M.ack('lgrepadd' .. (opts.bang and '!' or ''), opts.args, true, true)
  end, {
    bang = true,
    nargs = '*',
    desc = 'Add ack results to location list'
  })
  
  vim.api.nvim_create_user_command('AckFile', function(opts)
    M.ack('grep' .. (opts.bang and '!' or '') .. ' -g', opts.args, false, true)
  end, {
    bang = true,
    nargs = '*',
    desc = 'Search for files matching pattern'
  })
  
  vim.api.nvim_create_user_command('AckHelp', function(opts)
    M.ack_help('grep' .. (opts.bang and '!' or ''), opts.args, false)
  end, {
    bang = true,
    nargs = '*',
    desc = 'Search in help files'
  })
  
  vim.api.nvim_create_user_command('LAckHelp', function(opts)
    M.ack_help('lgrep' .. (opts.bang and '!' or ''), opts.args, true)
  end, {
    bang = true,
    nargs = '*',
    desc = 'Search in help files (location list)'
  })
  
  -- Test command for window picker
  vim.api.nvim_create_user_command('AckTestPicker', function()
    local picker = require('ack.window-picker')
    local win = picker.pick_window(_config.window_picker)
    if win then
      vim.notify(string.format("Window selected: %d", win), vim.log.levels.INFO)
    else
      vim.notify("No window selected or cancelled", vim.log.levels.INFO)
    end
  end, {
    desc = 'Test the window picker'
  })
end

return M