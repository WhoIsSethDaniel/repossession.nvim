local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
  error 'This plugin requires telescope.nvim (https://github.com/nvim-telescope/telescope.nvim)'
end

local finders = require 'telescope.finders'
local make_entry = require 'telescope.make_entry'
local pickers = require 'telescope.pickers'
local conf = require('telescope.config').values
local action_state = require 'telescope.actions.state'
local actions = require 'telescope.actions'
local session = require 'repossession'

local M = {}

M['sessions'] = function(opts)
  opts = opts or {}
  pickers
    .new(opts, {
      -- previewer = conf.file_previewer(opts),
      prompt_title = 'Saved Sessions',
      finder = finders.new_table {
        results = session.complete_sessions(),
        entry_maker = make_entry.gen_from_string(),
      },
      sorter = conf.file_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          session.load_session(selection)
        end)
        actions.remove_selection:enhance {
          post = function()
            local selection = action_state.get_selected_entry()
            session.delete_sessions(selection)

            -- redraw with new input
            local picker = action_state.get_current_picker(prompt_bufnr)
            for i, v in pairs(picker.finder.results) do
              if v == selection then
                table.remove(picker.finder.results, i)
              end
            end
            picker:refresh()
          end,
        }
        map('i', '<C-d>', actions.remove_selection)
        map('n', '<C-d>', actions.remove_selection)
        return true
      end,
    })
    :find()
end

function M.register()
  return telescope.register_extension { exports = { sessions = M['sessions'] } }
end

return M
