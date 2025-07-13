-- Lazy loading for ack.nvim
-- This file ensures backward compatibility when not using lazy.nvim

if vim.fn.has('nvim-0.7.0') == 0 then
  vim.api.nvim_err_writeln('ack.nvim requires Neovim >= 0.7.0')
  return
end

-- Only load if not already loaded
if vim.g.loaded_ack then
  return
end
vim.g.loaded_ack = true

-- Auto-load with default config if setup wasn't called
vim.api.nvim_create_autocmd('VimEnter', {
  callback = function()
    if not vim.g.ack_setup_called then
      require('ack').setup()
    end
  end,
  once = true,
})