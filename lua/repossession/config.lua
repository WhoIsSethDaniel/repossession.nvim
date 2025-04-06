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
  for key, value in pairs {
    auto = { new.auto, 'boolean' },
    session_dir = { new.session_dir, 'table' },
    ignore_ft = { new.ignore_ft, 'table' },
    ignore_bt = { new.ignore_bt, 'table' },
    hooks = { new.hooks, 'table' },
  } do
    vim.validate(key, value[1], value[2], value[3])
  end
  setmetatable(config, { __index = new })
end

setmetatable(config, { __index = defaults })

return config
