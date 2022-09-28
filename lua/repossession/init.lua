local session = require 'repossession.session'
local config = require 'repossession.config'

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

local auto_save_session = function()
  if is_safe_to_save() and auto_session_enabled() then
    save_session(session.current_session())
  end
end

return {
  auto_save_session = auto_save_session,
  load_session = load_session,
  save_session = save_session,
  delete_sessions = session.delete_sessions,
  current_session_name = session.current_session,
  setup = config.setup,
  complete_sessions = session.complete_sessions,
}
