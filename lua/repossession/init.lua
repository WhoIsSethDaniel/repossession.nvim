local path = require 'plenary.path'
local session = require 'repossession.session'

local extract_session_name = function(name)
  if type(name) == 'table' then
    return name[1]
  end
  return name
end

-- cached because the user can change argc() later and
-- we only care about the value on startup
local cached_argc = vim.fn.argc()
local disable_auto_session = function()
  -- if current_session is non-nil it means a session
  -- has been loaded and we should be auto-saving it
  if session.current_session() ~= nil then
    return false
  end
  if cached_argc > 0 or vim.g.read_from_stdin then
    return true
  end
  return false
end

local is_safe_to_save = function()
  if vim.v.vim_did_enter == 0 then
    return false
  end
  return true
end

local load_session_using_cwd = function(force)
  session.load_session(path:new():absolute(), force)
end

local load_session_using_name = function(name, force)
  session.load_session(name, force)
end

local save_session_by_cwd = function()
  session.save_session(path:new():absolute())
end

local save_session_by_name = function(name)
  session.save_session(name)
end

local load_session = function(name, force)
  local session_name = extract_session_name(name)
  local force_load = force ~= '!' and true or false

  if session_name == nil then
    load_session_using_cwd(force_load)
  else
    load_session_using_name(session_name, force_load)
  end
end

local save_session = function(name)
  local session_name = extract_session_name(name)

  if session_name == nil then
    save_session_by_cwd()
  else
    save_session_by_name(session_name)
  end
end

local auto_load_session = function()
  if not disable_auto_session() then
    load_session_using_cwd(true)
  end
end

local auto_save_session = function()
  if is_safe_to_save() and not disable_auto_session() then
    save_session(session.current_session())
  end
end

return {
  auto_load_session = auto_load_session,
  auto_save_session = auto_save_session,
  load_session = load_session,
  save_session = save_session,
  delete_sessions = session.delete_sessions,
  current_session_name = session.current_session,
}
