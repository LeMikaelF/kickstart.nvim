-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
    'theHamsta/nvim-dap-virtual-text',
  },
  keys = {
    -- Basic debugging keymaps, feel free to change to your liking!
    {
      '<F5>',
      function()
        require('dap').continue()
      end,
      desc = 'Debug: Start/Continue',
    },
    {
      '<F1>',
      function()
        require('dap').step_into()
      end,
      desc = 'Debug: Step Into',
    },
    {
      '<F2>',
      function()
        require('dap').step_over()
      end,
      desc = 'Debug: Step Over',
    },
    {
      '<F3>',
      function()
        require('dap').step_out()
      end,
      desc = 'Debug: Step Out',
    },
    {
      '<leader>db',
      function()
        require('dap').toggle_breakpoint()
      end,
      desc = 'Debug: toggle [b]reakpoint',
    },
    {
      '<leader>dB',
      function()
        require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ')
      end,
      desc = 'Debug: set [B]reakpoint condition',
    },
    {
      '<leader>dt',
      function()
        require('dap').terminate()
      end,
      desc = 'Debug: [t]erminate',
    },
    {
      '<leader>?',
      function()
        ---@diagnostic disable-next-line: missing-fields
        require('dapui').eval(nil, { enter = true })
      end,
    },
    -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
    {
      '<F7>',
      function()
        require('dapui').toggle()
      end,
      desc = 'Debug: See last session result.',
    },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'
    require('nvim-dap-virtual-text').setup()

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
      },
    }

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    ---@diagnostic disable-next-line: missing-fields
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
      layouts = {
        {
          elements = {
            {
              id = 'scopes',
              size = 0.25,
            },
            {
              id = 'breakpoints',
              size = 0.25,
            },
            {
              id = 'stacks',
              size = 0.25,
            },
            {
              id = 'watches',
              size = 0.25,
            },
          },
          position = 'right',
          size = 40,
        },
        {
          elements = { {
            id = 'repl',
            size = 0.5,
          }, {
            id = 'console',
            size = 0.5,
          } },
          position = 'bottom',
          size = 10,
        },
      },
    }

    -- Change breakpoint icons
    vim.api.nvim_set_hl(0, 'DapBreak', { fg = '#e51400' })
    vim.api.nvim_set_hl(0, 'DapStop', { fg = '#ffcc00' })
    local breakpoint_icons = vim.g.have_nerd_font
        and { Breakpoint = '', BreakpointCondition = '', BreakpointRejected = '', LogPoint = '', Stopped = '' }
      or { Breakpoint = '●', BreakpointCondition = '⊜', BreakpointRejected = '⊘', LogPoint = '◆', Stopped = '⭔' }
    for type, icon in pairs(breakpoint_icons) do
      local tp = 'Dap' .. type
      local hl = (type == 'Stopped') and 'DapStop' or 'DapBreak'
      vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
    end

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Install golang specific config
    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has 'win32' == 0,
      },
    }

    dap.configurations.rust = {
      {
        name = 'Turso server – step a query',
        type = 'codelldb',
        request = 'launch',
        program = '${workspaceFolder}/target/debug/turso',
        args = { '--db-path', 'test.db', '--http-listen-addr', '127.0.0.1:8080' },
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        sourceLanguages = { 'rust', 'c', 'cpp' },
        initCommands = {
          'break set -n sqlite3_prepare_v3',
          'break set -n sqlite3VdbeExec',
        },
      },
      {
        name = 'Attach to running process (get PID first)',
        type = 'codelldb',
        request = 'attach',
        pid = '${command:pickProcess}',
      },
    }

    require('dap').adapters.codelldb = {
      type = 'executable',
      command = 'codelldb',
    }

    -- from https://github.com/mxsdev/nvim-dap-vscode-js/issues/42#issuecomment-1519065750
    require('dap').adapters['pwa-node'] = {
      type = 'server',
      host = 'localhost',
      port = '${port}',
      executable = {
        command = 'js-debug-adapter',
        args = { '${port}' },
      },
    }
    for _, language in ipairs { 'typescript', 'javascript' } do
      require('dap').configurations[language] = {
        {
          -- from https://www.reddit.com/r/neovim/comments/y7dvva/typescript_debugging_in_neovim_with_nvimdap/
          name = 'Launch',
          type = 'pwa-node',
          request = 'launch',
          program = '${file}',
          rootPath = '${workspaceFolder}',
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          skipFiles = { '<node_internals>/**' },
          protocol = 'inspector',
          console = 'integratedTerminal',
        },
        {
          name = 'Debug current Ava test',
          type = 'pwa-node',
          request = 'launch',
          runtimeExecutable = 'node',
          runtimeArgs = {
            '${workspaceFolder}/node_modules/ava/entrypoints/cli.mjs',
            '--serial', -- run one test file at a time (much nicer for break-points)
            '${file}',
          },
          cwd = '${workspaceFolder}',
          rootPath = '${workspaceFolder}',
          sourceMaps = true,
          protocol = 'inspector',
          console = 'integratedTerminal',
          outputCapture = 'std',
          skipFiles = { '<node_internals>/**' },
        },
        {
          name = 'Launch with Ava runner',
          type = 'pwa-node',
          request = 'launch',
          program = 'npx',
          args = '${file}',
          rootPath = '${workspaceFolder}',
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          skipFiles = { '<node_internals>/**' },
          protocol = 'inspector',
          console = 'integratedTerminal',
        },
        -- this is a WIP
        -- see https://codeberg.org/mfussenegger/nvim-dap/wiki/C-C---Rust-(via--codelldb)
        {
          type = 'codelldb',
          request = 'launch',
          name = 'Debug Ava Test (debug Rust side)',
          args = { '${file}' },
          sourceLanguages = { 'rust' },
          cwd = '${workspaceFolder}',
          runtimeExecutable = 'node',
          program = 'node',
          runtimeArgs = {
            '${workspaceFolder}/node_modules/ava/entrypoints/cli.mjs',
            '--serial', -- run one test file at a time (much nicer for break-points)
            '${file}',
          },
          preLaunchTask = 'yarn build:debug',
        },
        {
          name = 'Debug Ava Test (debug Rust side 2)',
          type = 'codelldb',
          request = 'launch',
          program = 'node',
          args = {
            vim.fn.expand '${workspaceFolder}/node_modules/ava/entrypoints/cli.mjs',
            '--serial',
            vim.fn.expand '${file}',
          },
          cwd = vim.fn.expand '${workspaceFolder}',
          sourceLanguages = { 'rust' },
          preLaunchTask = function()
            -- run your task; adjust to match your setup
            os.execute('cd ' .. vim.fn.expand '${workspaceFolder}' .. ' && yarn build:debug')
          end,
        },
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach to node',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
        },
      }
    end
  end,
}
