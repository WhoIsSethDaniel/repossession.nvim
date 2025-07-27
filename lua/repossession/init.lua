local config = require 'repossession.config'
local session = require 'repossession.session'

local extract_session_name = function(name)
  if type(name) == 'table' then
    name = name[1]
  end
  return name
end

-- caching the argc because the user can change argc()
-- later and we only care about the value on startup
local cached_argc = vim.fn.argc()
local auto_session_enabled = function()
  -- if current_session is non-nil it means a session
  -- has been loaded and we should be auto-saving it
  -- even if config.auto is false
  if session.current_session() == nil then
    return false
  end
  if not config.auto then
    return false
  end
  if cached_argc > 0 or vim.g.read_from_stdin then
    return false
  end
  return true
end

local is_safe_to_save = function()
  if vim.v.vim_did_enter == 0 then
    return false
  end
  return true
end

local is_exiting = function()
  if vim.v.exiting == vim.NIL then
    return false
  end
  return true
end

local load_session = function(name, force)
  local session_name = extract_session_name(name)
  session.load_session(session_name, force)
end

local save_session = function(name)
  local session_name = extract_session_name(name)
  session.save_session(session_name, is_exiting())
end

local run_copy_rename = function(args, force, f)
  local source, target
  if #args == 1 then
    source = session.current_session()
    target = args[1]
    if source == nil then
      vim.notify('No current session. Must provide two arguments.', vim.log.levels.ERROR)
      return
    end
  elseif #args == 2 then
    source = args[1]
    target = args[2]
  elseif #args == 0 then
    vim.notify('Not enough arguments. Requires at least one.', vim.log.levels.ERROR)
    return
  else
    vim.notify('Too many arguments. Requires no more than two.', vim.log.levels.ERROR)
    return
  end

  local source_path = session.session_path_from_name(source)
  local target_path = session.session_path_from_name(target)

  if not source_path:is_file() then
    vim.notify(string.format("session '%s' does not exist or is not a file.", source), vim.log.levels.ERROR)
    return
  end
  if target_path:is_file() and not force then
    vim.notify(string.format("target file '%s' already exists.", target), vim.log.levels.ERROR)
    return
  end
  f(source_path, target_path)
end

local rename_session = function(args)
  run_copy_rename(args, false, function(source, target)
    source:rename { new_name = target:absolute() }
  end)
end

local copy_session = function(args, force)
  run_copy_rename(args, force, function(source, target)
    source:copy { destination = target:absolute() }
  end)
end

local auto_save_session = function()
  if is_safe_to_save() and auto_session_enabled() then
    save_session(session.current_session())
  end
end

return {
  auto_save_session = auto_save_session,
  load_session = load_session,
  save_session = save_session,
  copy_session = copy_session,
  rename_session = rename_session,
  delete_sessions = session.delete_sessions,
  current_session_name = session.current_session,
  setup = config.setup,
  complete_sessions = session.complete_sessions,
}
