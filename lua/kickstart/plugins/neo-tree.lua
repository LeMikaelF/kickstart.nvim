-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

local do_setcd = function(state)
  local p = state.tree:get_node().path
  print(p) -- show in command line
  vim.cmd(string.format('exec(":lcd %s")', p))
end

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },
  lazy = false,
  opts = {
    git_status_async = false, -- to avoid tree not refreshing
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
          ['gA'] = 'git_add_all',
          ['gu'] = 'git_unstage_file',
          ['ga'] = 'git_add_file',
          ['gr'] = 'git_revert_file',
          ['gc'] = 'git_commit',
          ['gp'] = 'git_push',
          ['gg'] = 'git_commit_and_push',
          ['<leader>c'] = 'setcd',
          ['<leader>p'] = 'find_files',
          ['<leader>g'] = 'grep',
        },
        hijack_netrw_behavior = 'open_default',
      },
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
      use_libuv_file_watcher = true,
    },
    buffers = {
      follow_current_file = {
        enabled = true,
        leave_dirs_open = false,
      },
    },
    window = {
      position = 'left',
    },
    commands = {
      setcd = function(state)
        do_setcd(state)
      end,
      find_files = function(state)
        do_setcd(state)
        require('telescope.builtin').find_files()
      end,
      grep = function(state)
        do_setcd(state)
        require('telescope.builtin').live_grep()
      end,
    },
  },
}
