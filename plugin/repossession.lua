local api = vim.api
local command = api.nvim_create_user_command
local repo = require 'repossession'

if vim.fn.has 'nvim-0.8' == 0 then
  api.nvim_err_writeln 'repossession requires at least Neovim 0.8.0'
  return
end

command('SessionLoad', function(a)
  repo.load_session(a.fargs, a.bang)
end, { bang = true, nargs = '?', force = true, complete = repo.complete_sessions })

command('SessionDelete', function(a)
  repo.delete_sessions(a.fargs)
end, { nargs = '+', force = true, complete = repo.complete_sessions })

command('SessionSave', function(a)
  repo.save_session(a.fargs)
end, { nargs = '?', force = true, complete = repo.complete_sessions })

local REPOGRP = api.nvim_create_augroup('repossession', { clear = true })
api.nvim_create_autocmd('VimLeavePre', {
  group = REPOGRP,
  pattern = '*',
  nested = true,
  callback = repo.auto_save_session,
})
api.nvim_create_autocmd('BufEnter', {
  group = REPOGRP,
  pattern = '*',
  callback = repo.auto_save_session,
})
api.nvim_create_autocmd('StdinReadPre', {
  group = REPOGRP,
  pattern = '*',
  callback = function()
    vim.g.read_from_stdin = true
  end,
})
