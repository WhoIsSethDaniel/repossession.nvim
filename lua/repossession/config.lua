local Path = require 'plenary.path'

local config = {}

local defaults = {
  auto_load = false,
  auto_save = false,
  continuous_save = false,
  session_dir = Path:new(vim.fn.stdpath 'data', 'sessions'):absolute(),
  whitelist_dirs = {},
  blacklist_dirs = {},
}

function config.setup(conf)
  defaults = vim.tbl_deep_extend('force', defaults, conf or {})
  if type(defaults.session_dir) == 'string' then
    defaults.session_dir = Path:new(defaults.session_dir)
  end
  vim.validate {
    auto_load = { defaults.auto_load, 'b' },
    auto_save = { defaults.auto_save, 'b' },
    continuous_save = { defaults.continuous_save, 'b' },
    session_dir = { defaults.session_dir, 't' },
    whitelist_dirs = { defaults.whitelist_dirs, 't' },
    blacklist_dirs = { defaults.blacklist_dirs, 't' },
  }
  setmetatable(config, { __index = defaults })
end

setmetatable(config, { __index = defaults })

return config