local Path = require 'plenary.path'

local config = {}

local defaults = {
  auto = false,
  session_dir = Path:new(vim.fn.stdpath 'data', 'sessions'):absolute(),
  whitelist_dirs = {},
  blacklist_dirs = {},
  ignore_ft = {},
  ignore_bt = {},
  hooks = {},
}

function config.setup(conf)
  local new = vim.tbl_deep_extend('force', defaults, conf or {})
  if type(new.session_dir) == 'string' then
    new.session_dir = Path:new(new.session_dir)
  end
  vim.validate {
    auto = { new.auto, 'b' },
    session_dir = { new.session_dir, 't' },
    whitelist_dirs = { new.whitelist_dirs, 't' },
    blacklist_dirs = { new.blacklist_dirs, 't' },
    ignore_ft = { new.ignore_ft, 't' },
    ignore_bt = { new.ignore_bt, 't' },
    hooks = { new.hooks, 't' },
  }
  setmetatable(config, { __index = new })
end

setmetatable(config, { __index = defaults })

return config
