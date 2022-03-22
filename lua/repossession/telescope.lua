local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
  error 'This plugin requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)'
end

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local make_entry = require 'telescope.make_entry'
local conf = require('telescope.config').values
local session = require 'repossession.session'

local M = {}

M['sessions'] = function(opts)
  opts = opts or {}
  pickers.new(opts, {
    -- previewer = conf.file_previewer(opts),
    prompt_title = 'Saved Sessions',
    finder = finders.new_table {
      results = session.complete_sessions(),
      entry_maker = make_entry.gen_from_file(),
    },
    sorter = conf.file_sorter(opts),
  }):find()
end

function M.register()
  return telescope.register_extension { exports = M }
end

return M
