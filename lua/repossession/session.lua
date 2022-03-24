local Path = require 'plenary.path'
local scan = require 'plenary.scandir'
local config = require 'repossession.config'

local encode_path = function(dir)
  return dir:gsub(Path.path.sep, '%%'):gsub('%%*$', '')
end

local unencode_path = function(dir)
  return dir:gsub('%%', Path.path.sep)
end

local vim_escaped_path = function(p)
  return p:gsub('%%', '\\%%')
end

local saved_sessions_dir = function()
  return config.session_dir
end

local session_path_from_name = function(session_name)
  local encoded_name = encode_path(session_name)
  return Path:new(saved_sessions_dir(), encoded_name .. '.vim')
end

local run_hook = function(name)
  local cmd = config.hooks[name]
  if not cmd then
    return
  end

  local ok, result
  if type(cmd) == 'function' then
    ok, result = pcall(cmd)
  else
    ok, result = pcall(vim.cmd, cmd)
  end
  if not ok then
    vim.nvim_err_writeln(string.format('hook %s had a problem during run: %s', name, result))
  end
end

local current = {
  loading = false,
  name = nil,
}
local current_session = function()
  return current['name']
end
local set_current_session = function(name)
  current['name'] = name
end

local is_safe_to_load = function()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_option(buffer, 'modified') then
      return false
    end
  end
  return true
end

local wipe_all_buffers = function()
  local this = vim.api.nvim_get_current_buf()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buffer) and this ~= buffer then
      vim.api.nvim_buf_delete(buffer, { force = true })
    end
  end
  vim.api.nvim_buf_delete(this, { force = true })
end

local wipe_ignored_buffers = function()
  for _, buffer in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buffer) then
      local ft = vim.api.nvim_buf_get_option(buffer, 'filetype')
      local bt = vim.api.nvim_buf_get_option(buffer, 'buftype')
      if vim.tbl_contains(config.ignore_ft, ft) or vim.tbl_contains(config.ignore_bt, bt) then
        vim.api.nvim_buf_delete(buffer, { force = true })
      end
    end
  end
end

local delete_sessions = function(session_names)
  run_hook 'pre_delete_session'
  for _, session_name in ipairs(session_names) do
    local session_path = session_path_from_name(session_name)

    if not session_path:is_file() then
      vim.api.nvim_err_writeln(
        string.format("session '%s' does not exist or is not a file. Cannot delete session.", session_name)
      )
    else
      session_path:rm()
    end
  end
  run_hook 'post_delete_session'
end

local save_session = function(session_name, filter)
  if current['loading'] then
    return
  end

  local session_path = session_path_from_name(session_name)

  local session_dir = session_path:parent()
  if not session_dir:is_dir() then
    session_dir:mkdir()
  end

  -- if you don't delete the args bad things happen
  vim.api.nvim_command '%argdelete'

  -- idea borrowed from Obsession;
  -- tpope says 'blank' and 'options' are not useful to save
  local oldopts = vim.opt.sessionoptions
  vim.opt.sessionoptions:remove 'blank'
  vim.opt.sessionoptions:remove 'options'

  if filter then
    wipe_ignored_buffers()
  end

  run_hook 'pre_save_session'

  local ok, result = pcall(vim.api.nvim_command, 'mksession! ' .. vim_escaped_path(session_path:absolute()))
  if not ok then
    vim.api.nvim_err_writeln(string.format('Failed to save session: %s, reason: %s', session_name, result))
  end

  run_hook 'post_save_session'

  vim.opt.sessionoptions = oldopts
end

local load_session = function(session_name, force_load)
  local session_path = session_path_from_name(session_name)

  if not session_path:exists() then
    if not force_load then
      vim.api.nvim_err_writeln(
        string.format("session '%s' does not exist. Cannot load non-existent session.", session_name)
      )
    end
    return
  end

  if not force_load and not is_safe_to_load() then
    vim.api.nvim_err_writeln 'Some buffers are un-saved. Use ! to save all buffers (if possible) and load the session.'
    return
  end

  -- can still fail if some unsaved buffers are unnamed
  vim.api.nvim_command 'silent wall'

  -- gotta do this outside of the schedule;
  -- this kills all clients for all buffers;
  -- see :h vim.lsp.stop_client()
  vim.lsp.stop_client(vim.lsp.get_active_clients())

  current['loading'] = true
  vim.schedule(function()
    run_hook 'pre_load_session'
    wipe_all_buffers()
    local ok, result = pcall(vim.api.nvim_command, 'silent source ' .. vim_escaped_path(session_path:absolute()))
    if not ok then
      vim.api.nvim_err_writeln(string.format('Failed to restore session: %s, reason: %s', session_name, result))
    end
    set_current_session(session_name)
    run_hook 'post_load_session'
    current['loading'] = false
  end)
end

local complete_sessions = function()
  local session_paths = scan.scan_dir(saved_sessions_dir():absolute(), { depth = 1, add_dirs = false })
  local session_names = {}
  for _, session_path in ipairs(session_paths) do
    local name = unencode_path(Path:new(session_path):name()):gsub('%.vim$', '')
    table.insert(session_names, name)
  end
  return session_names
end

return {
  current_session = current_session,
  complete_sessions = complete_sessions,
  save_session = save_session,
  load_session = load_session,
  delete_sessions = delete_sessions,
}
