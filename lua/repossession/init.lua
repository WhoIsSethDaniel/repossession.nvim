local Path = require 'plenary.path'
local session = require 'repossession.session'
local config = require 'repossession.config'

local extract_session_name = function(name)
  if type(name) == 'table' then
    return name[1]
  end
  return name
end

-- caching the argc because the user can change argc()
-- later and we only care about the value on startup
local cached_argc = vim.fn.argc()
local auto_session_enabled = function()
  -- if current_session is non-nil it means a session
  -- has been loaded and we should be auto-saving it;
  -- even if config.auto is false
  if session.current_session() ~= nil then
    return true
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

local dir_is_in_list = function(dir, list)
  dir = dir:gsub(Path.path.sep .. '*$', '')
  dir = Path:new(dir)
  for _, ldir in pairs(list) do
    if ldir:absolute() == dir:absolute() then
      return true
    end
  end
  return false
end

local cached_lists = {}
local dir_list = function(name, list)
  if cached_lists[name] then
    return cached_lists[name]
  end
  cached_lists[name] = {}
  for _, dir in ipairs(list) do
    for _, gdir in
      ipairs(vim.tbl_filter(function(f)
        return vim.fn.isdirectory(f) > 0 and true or false
      end, vim.fn.glob(dir, _, true)))
    do
      table.insert(cached_lists[name], Path:new(gdir))
    end
  end
  return cached_lists[name]
end

local dir_is_acceptable = function(dir)
  local wl = dir_list('wl', config.whitelist_dirs)
  if #wl > 0 then
    return dir_is_in_list(dir, dir_list('wl', wl))
  end
  if dir_is_in_list(dir, dir_list('bl', config.blacklist_dirs)) then
    return false
  end
  return true
end

local load_session = function(name, force)
  local session_name = extract_session_name(name)
  if force == '!' then
    force = true
  elseif force == '' then
    force = false
  end
  session.load_session(session_name, force)
end

local save_session = function(name)
  local session_name = extract_session_name(name)
  session.save_session(session_name, is_exiting())
end

local auto_load_session = function()
  local session_name = Path:new():absolute()
  if auto_session_enabled() and dir_is_acceptable(session_name) then
    load_session(session_name, true)
  end
end

local auto_save_session = function()
  local session_name = session.current_session() or Path:new():absolute()
  if is_safe_to_save() and auto_session_enabled() and dir_is_acceptable(session_name) then
    save_session(session_name)
  end
end

local continuous_save_session = function()
  if config.continuous_save then
    auto_save_session()
  end
end

return {
  auto_load_session = auto_load_session,
  auto_save_session = auto_save_session,
  continuous_save_session = continuous_save_session,
  load_session = load_session,
  save_session = save_session,
  delete_sessions = session.delete_sessions,
  current_session_name = session.current_session,
  setup = config.setup,
}
