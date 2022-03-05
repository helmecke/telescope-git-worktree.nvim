local has_telescope, telescope = pcall(require, "telescope")
if not has_telescope then
  error "This plugin requires nvim-telescope/telescope.nvim"
end

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local entry_display = require "telescope.pickers.entry_display"
local utils = require "telescope.utils"

local function gen_from_git_worktree()
  local displayer = entry_display.create {
    separator = " ",
    items = {
      { width = 20 },
      { remaining = true },
    },
  }

  local make_display = function(entry)
    return displayer {
      { string.sub(entry.ordinal, 2, -2), "TelescopeResultsIdentifier" },
      { entry.sha },
    }
  end

  return function(entry)
    if entry == "" then
      return nil
    end

    local splitted = utils.max_split(entry)
    local path = splitted[1]
    local branch_name = splitted[3]
    local sha = splitted[2]

    return {
      value = path,
      ordinal = branch_name,
      sha = sha,
      display = make_display,
    }
  end
end

local worktrees = function(opts)
  opts = opts or {}
  opts.entry_maker = vim.F.if_nil(opts.entry_maker, gen_from_git_worktree())
  opts.show_branch = true

  pickers.new(opts, {
    prompt_title = "Git Worktrees",
    finder = finders.new_oneshot_job(
      vim.tbl_flatten {
        { "git", "worktree", "list" },
      },
      opts
    ),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.cmd("cd " .. selection.value)
        print(selection.value)
      end)
      return true
    end,
  }):find()
end

return telescope.register_extension {
  exports = {
    git_worktrees = worktrees,
  },
}
