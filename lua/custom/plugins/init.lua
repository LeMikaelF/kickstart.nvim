-- disable netrw at the very start of your init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- optionally enable 24-bit colour
vim.opt.termguicolors = true

vim.opt.winborder = 'double'

vim.keymap.set('n', '<Leader>i', function()
  vim.diagnostic.open_float()
end, { desc = 'Open Diagnostic Float' })

vim.keymap.set({ 'i', 's' }, 'jk', '<Esc>')
vim.keymap.set({ 'i', 's' }, 'kj', '<Esc>')

-- remap 'a' to 'cc' if on a blank line
vim.keymap.set('n', 'a', function()
  local line = vim.fn.getline '.'
  if line:match '^%s*$' and vim.fn.col '.' == 1 then
    vim.api.nvim_feedkeys('cc', 'n', false)
  else
    vim.api.nvim_feedkeys('a', 'n', false)
  end
end, { noremap = true, silent = true })

vim.keymap.set({ 'n', 'x' }, '<leader>hh', function()
  require('mini.git').show_range_history()
end, { desc = 'show range [h]istory' })

vim.keymap.set({ 'n' }, 'C-S-I', ':bnext<CR>', { desc = 'next buffer' })
vim.keymap.set({ 'n' }, 'C-S-O', ':bprev<CR>', { desc = 'previous buffer' })

local function closeAllFloatingWindows()
  vim.keymap.set('n', '<esc>', function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative == 'win' then
        vim.api.nvim_win_close(win, false)
      end
    end
  end)
end

vim.keymap.set({ 'n' }, '<esc>', closeAllFloatingWindows, { desc = 'close all floating windows' })

vim.keymap.set({ 'n' }, '<leader>tn', ':Neotree toggle<CR>', { desc = 'toggle Neotree' })

return {
  {
    'windwp/nvim-ts-autotag',
    version = '*',
    lazy = false,
    dependencies = 'nvim-treesitter/nvim-treesitter',
    config = function()
      require('nvim-ts-autotag').setup {
        --   enable_close = true, -- Auto close tags
        --   enable_rename = true, -- Auto rename pairs of tags
        --   enable_close_on_slash = false, -- Auto close on trailing </
      }
    end,
  },
  {
    'hrsh7th/cmp-nvim-lsp-signature-help',
    version = '*',
    lazy = false,
  },
  -- {
  --   name = 'neotest-minitest',
  --   enabled = 'false', -- doesn't work,
  --   dir = '/Users/mikael.francoeur/programming/nvim/neotest-minitest',
  -- },
  {
    'nvim-neotest/neotest',
    version = '5.6.1',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      'marilari88/neotest-vitest',
      'nvim-neotest/neotest-jest',
      'olimorris/neotest-rspec',
      -- 'zidhuss/neotest-minitest',
      -- TODO restore this when neotest-minitest is fixed
      -- 'neotest-minitest',
      'mrcjkb/rustaceanvim',
    },
    lazy = false,
    config = function()
      local neotest = require 'neotest'
      ---@diagnostic disable-next-line: missing-fields
      neotest.setup {
        adapters = {
          require 'neotest-vitest',
          require 'neotest-jest' {
            jestCommand = 'npm test --',
            jestConfigFile = 'custom.jest.config.ts',
            env = { CI = true },
            cwd = function()
              return vim.fn.getcwd()
            end,
          },
          require 'neotest-rspec',
          -- require 'neotest-minitest',
          require 'rustaceanvim.neotest',
          require 'neotest-ava',
        },

        output_panel = {
          enabled = true,
          open = 'botright vsplit | vertical resize 80',
        },
      }

      ---@format disable
      vim.keymap.set('n', '<leader>tt', function()
        neotest.run.run(vim.fn.expand '%')
      end, { desc = 'Run File (Neotest)' })
      vim.keymap.set('n', '<leader>tT', function()
        neotest.run.run(vim.uv.cwd())
      end, { desc = 'Run All Test Files (Neotest)' })
      vim.keymap.set('n', '<leader>tr', function()
        neotest.run.run()
      end, { desc = 'Run Nearest (Neotest)' })
      vim.keymap.set('n', '<leader>tl', function()
        neotest.run.run_last()
      end, { desc = 'Run Last (Neotest)' })
      vim.keymap.set('n', '<leader>ts', function()
        neotest.summary.toggle()
      end, { desc = 'Toggle Summary (Neotest)' })
      vim.keymap.set('n', '<leader>to', function()
        neotest.output.open { enter = true, auto_close = true }
      end, { desc = 'Show Output (Neotest)' })
      vim.keymap.set('n', '<leader>tO', function()
        neotest.output_panel.toggle()
      end, { desc = 'Toggle Output Panel (Neotest)' })
      vim.keymap.set('n', '<leader>tS', function()
        neotest.run.stop()
      end, { desc = 'Stop (Neotest)' })
      vim.keymap.set('n', '<leader>tw', function()
        neotest.watch.toggle(vim.fn.expand '%')
      end, { desc = 'Toggle Watch (Neotest)' })
      vim.keymap.set('n', '<leader>tc', function()
        neotest.output_panel.clear()
      end, { desc = 'Clear Neotest Output Panel' })

      vim.api.nvim_set_keymap('n', '<leader>twr', "<cmd>lua require('neotest').run.run({ vitestCommand = 'npx vitest --watch' })<cr>", { desc = 'Run Watch' })

      vim.api.nvim_set_keymap(
        'n',
        '<leader>twf',
        "<cmd>lua require('neotest').watch.toggle({ vim.fn.expand('%'), vitestCommand = 'npx vitest --watch' })<cr>",
        -- "<cmd>lua require('neotest').run.run({ vim.fn.expand('%'), vitestCommand = 'npx vitest --watch' })<cr>",
        { desc = 'Run Watch File' }
      )
    end,
    -- stylua: ignore
    -- keys = {
    --   {"<leader>t", "", desc = "+test"},
    -- },
  },
  {
    name = 'lsp_lines',
    url = 'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
    commit = 'a92c755f182b89ea91bd8a6a2227208026f27b4d',
    dependencies = 'nvim-lspconfig',
    init = function()
      -- Disable virtual_text since it's redundant due to lsp_lines.
      vim.diagnostic.config {
        virtual_text = false,
      }

      vim.keymap.set('', '<Leader>l', require('lsp_lines').toggle, { desc = 'Toggle lsp_lines' })
    end,
    opts = {},
  },
  {
    'morhetz/gruvbox',
    priority = 1001, -- Make sure to load this before all the other start plugins.
  },
  {
    'EdenEast/nightfox.nvim',
    priority = 1001, -- Make sure to load this before all the other start plugins.
  },
  -- code outline
  {
    'stevearc/aerial.nvim',
    opts = {},
    -- Optional dependencies
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'nvim-tree/nvim-web-devicons',
    },
    keys = {
      {
        '<leader>ta',
        '<cmd>AerialToggle<cr>',
        desc = 'Toggle Aerial (symbol map)',
      },
    },
  },
  {
    'savq/melange-nvim',
    priority = 1001, -- Make sure to load this before all the other start plugins.
  },
  {
    'jmacadie/telescope-hierarchy.nvim',
    dependencies = {
      {
        'nvim-telescope/telescope.nvim',
        dependencies = { 'nvim-lua/plenary.nvim' },
      },
    },
    keys = {
      {
        '<leader>si',
        '<cmd>Telescope hierarchy incoming_calls<cr>',
        desc = 'LSP: [S]earch [I]ncoming Calls',
      },
      {
        '<leader>so',
        '<cmd>Telescope hierarchy outgoing_calls<cr>',
        desc = 'LSP: [S]earch [O]utgoing Calls',
      },
    },
    opts = {
      -- don't use `defaults = { }` here, do this in the main telescope spec
      extensions = {
        hierarchy = {
          -- telescope-hierarchy.nvim config, see below
        },
        -- no other extensions here, they can have their own spec too
      },
    },
    config = function(_, opts)
      -- Calling telescope's setup from multiple specs does not hurt, it will happily merge the
      -- configs for us. We won't use data, as everything is in it's own namespace (telescope
      -- defaults, as well as each extension).
      require('telescope').setup(opts)
      require('telescope').load_extension 'hierarchy'
    end,
  },
  {
    'pocco81/auto-save.nvim',
    opts = {
      enabled = false,
    },
    keys = {
      {
        '<leader>tx',
        '<cmd>ASToggle<cr>',
        desc = 'Toggle autosave',
      },
    },
  },
  {
    -- disabled because I didn't like it
    'nvim-treesitter/nvim-treesitter-context',
    enabled = false,
    config = function()
      vim.keymap.set('n', '[c', function()
        require('treesitter-context').go_to_context(vim.v.count1)
      end, { silent = true })
    end,
    opts = {
      max_lines = 3,
    },
  },
  { 'savq/melange-nvim' },
  {
    'mrcjkb/rustaceanvim',
    version = '^6',
    lazy = false,
    init = function()
      vim.g.rustaceanvim = {
        server = {
          default_settings = {
            ['rust-analyzer'] = {
              procMacro = {
                ignored = {
                  ['napi-derive'] = { 'napi' },
                },
              },
              diagnostics = {
                disabled = { 'proc-macro-disabled', 'unlinked-file' },
                experimental = {
                  enable = true,
                },
              },
              check = {
                command = 'clippy',
                workspace = false,
                -- had to set this to true so that it will pick up tests
                allTargets = true,
              },
              cargo = {
                allTargets = false,
                targetDir = true,
              },
            },
          },
        },
      }
    end,
  },
  {
    'NeogitOrg/neogit',
    lazy = false,
    opts = {
      integrations = {
        diffview = true,
        telescope = true,
      },
    },
    dependencies = {
      'nvim-lua/plenary.nvim', -- required
      'sindrets/diffview.nvim', -- optional - Diff integration

      -- Only one of these is needed.
      'nvim-telescope/telescope.nvim', -- optional
      -- 'ibhagwan/fzf-lua', -- optional
      -- 'echasnovski/mini.pick', -- optional
      -- 'folke/snacks.nvim', -- optional
    },
    keys = {
      {
        '<leader>hn',
        '<cmd>Neogit kind=vsplit<cr>',
        desc = 'open [n]eogit in right split',
      },
      {
        '<leader>hm',
        '<cmd>Neogit<cr>',
        desc = 'open [n]eogit',
      },
    },
  },
  {
    'mxsdev/nvim-dap-vscode-js',
    ft = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
  },
  {
    'theHamsta/nvim-dap-virtual-text',
  },
  {
    'chrisgrieser/nvim-rulebook',
    opts = {
      ignoreComments = {
        rustc = {
          comment = '#[allow(%s)]',
          location = 'prevLine',
          multiRuleIgnore = true,
          multiRuleSeparator = ', ',
          docs = 'https://doc.rust-lang.org/reference/attributes/diagnostics.html#r-attributes.diagnostics.expect',
        },
      },
    },
    keys = {
      {
        '<leader>ri',
        function()
          require('rulebook').ignoreRule()
        end,
        desc = '[r]ulebook: [i]gnore rule',
      },
      {
        '<leader>rl',
        function()
          require('rulebook').lookupRule()
        end,
        desc = '[r]ulebook: [l]ookup rule',
      },
      {
        '<leader>ry',
        function()
          require('rulebook').yankDiagnosticCode()
        end,
        desc = '[r]ulebook: [y]ank diagnostic code',
      },
      {
        '<leader>rf',
        function()
          require('rulebook').suppressFormatter()
        end,
        desc = '[r]ulebook: suppress [f]ormatter',
      },
    },
  },
  {
    'allaman/emoji.nvim',
    version = '1.0.0',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
    },
    keys = {
      {
        '<leader>se',
        function()
          require('telescope').load_extension('emoji').emoji()
        end,
        desc = '[S]earch [E]moji',
      },
    },
  },
  {
    'madskjeldgaard/cppman.nvim',
    commit = '801c5b178ee1246bc8ee044984d5758933b2baca',
    dependencies = {
      'MunifTanjim/nui.nvim',
    },
    lazy = false,
    cmd = 'CPPMan',
    config = function()
      local cppman = require 'cppman'
      cppman.setup()

      vim.keymap.set('n', '<leader>cm', function()
        cppman.open_cppman_for(vim.fn.expand '<cword>')
      end)

      vim.keymap.set('n', '<leader>cc', function()
        cppman.input()
      end)
    end,
    keys = {
      {
        '<leader>K',
        function()
          require('cppman').open_cppman_for(vim.fn.expand '<cword>')
        end,
        ft = { 'c', 'cpp' },
      },
    },
  },
  {
    'chentoast/marks.nvim',
    event = 'VeryLazy',
    opts = {},
  },
}
