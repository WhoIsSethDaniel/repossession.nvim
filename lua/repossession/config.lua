local Path = require 'plenary.path'

local config = {}

local defaults = {
  auto_load = false,
  auto_save = true,
  continuous_save = false,
  session_dir = Path:new(vim.fn.stdpath 'data', 'sessions'):absolute(),
  ignore_ft = {},
  ignore_bt = {},
  whitelist = {},
  blacklist = {},
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
    ignore_ft = { defaults.ignore_ft, 't' },
    ignore_bt = { defaults.ignore_bt, 't' },
    whitelist = { defaults.whitelist, 't' },
    blacklist = { defaults.blacklist, 't' },
  }
  setmetatable(config, { __index = defaults })
end

setmetatable(config, { __index = defaults })

return config
