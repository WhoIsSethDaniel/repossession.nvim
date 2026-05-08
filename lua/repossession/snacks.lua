local M = {}
local Snacks = require 'snacks'
local session = require 'repossession'

function M.sessions()
  Snacks.picker.pick {
    title = 'Choose a session to load',
    layout = { preview = false },
    finder = function()
      local items = {}
      for _, name in pairs(session.complete_sessions()) do
        table.insert(items, {
          name = name,
          text = name,
        })
      end
      return items
    end,
    actions = {
      delete_session = function(picker, item)
        session.delete_sessions { item.name }
        picker:refresh()
      end,
    },
    win = {
      input = {
        keys = {
          ['<c-d>'] = { 'delete_session', mode = { 'n', 'i' } },
        },
      },
    },
    format = function(item)
      return { { item.name }, {} }
    end,
    confirm = function(picker, item)
      picker:close()
      session.load_session(item.name)
    end,
  }
end

return M
