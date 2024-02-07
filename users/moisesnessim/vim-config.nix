{ sources, pkgs }:
''
"--------------------------------------------------------------------
" Fix vim paths so we load the vim-misc directory
let g:vim_home_path = "~/.vim"

" This works on NixOS 21.05
let vim_misc_path = split(&packpath, ",")[0] . "/pack/home-manager/start/vim-misc/vimrc.vim"
if filereadable(vim_misc_path)
  execute "source " . vim_misc_path
endif

" This works on NixOS 21.11
let vim_misc_path = split(&packpath, ",")[0] . "/pack/home-manager/start/vimplugin-vim-misc/vimrc.vim"
if filereadable(vim_misc_path)
  execute "source " . vim_misc_path
endif

" This works on NixOS 22.11
let vim_misc_path = split(&packpath, ",")[0] . "/pack/myNeovimPackages/start/vimplugin-vim-misc/vimrc.vim"
if filereadable(vim_misc_path)
  execute "source " . vim_misc_path
endif

lua <<EOF
---------------------------------------------------------------------
-- Add our custom treesitter parsers
local parser_config = require "nvim-treesitter.parsers".get_parser_configs()

parser_config.proto = {
  install_info = {
    url = "${sources.tree-sitter-proto}", -- local path or git repo
    files = {"src/parser.c"}
  },
  filetype = "proto", -- if filetype does not agrees with parser name
}

---------------------------------------------------------------------
-- Add our treesitter textobjects
require'nvim-treesitter.configs'.setup {
  textobjects = {
    select = {
      enable = true,
      keymaps = {
        -- You can use the capture groups defined in textobjects.scm
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
        ["ic"] = "@class.inner",
      },
    },

    move = {
      enable = true,
      set_jumps = true, -- whether to set jumps in the jumplist
      goto_next_start = {
        ["]m"] = "@function.outer",
        ["]]"] = "@class.outer",
      },
      goto_next_end = {
        ["]M"] = "@function.outer",
        ["]["] = "@class.outer",
      },
      goto_previous_start = {
        ["[m"] = "@function.outer",
        ["[["] = "@class.outer",
      },
      goto_previous_end = {
        ["[M"] = "@function.outer",
        ["[]"] = "@class.outer",
      },
    },
  },
}


---------------------------------------------------------------------

require'nvim-surround'.setup()

local capabilities = require('cmp_nvim_lsp').default_capabilities()

local lspconfig = require'lspconfig'

-- Configure F# LSP
lspconfig.fsautocomplete.setup {
    cmd = { "${pkgs.fsautocomplete}/bin/fsautocomplete", "--adaptive-lsp-server-enabled" },
    capabilities = capabilities,
    root_dir = function(filename, _)
        local root
        -- in order of preference:
        -- * git repository root
        -- * directory containing a solution file
        -- * directory containing an fsproj file
        -- * directory with fsx scripts
        root = lspconfig.util.find_git_ancestor(filename)
        root = root or lspconfig.util.root_pattern("*.sln")(filename)
        root = root or lspconfig.util.root_pattern("*.fsproj")(filename)
        root = root or lspconfig.util.root_pattern("*.fsx")(filename)
        return root
      end,
}

-- Configure C# LSP
local pid = vim.fn.getpid()
lspconfig.omnisharp.setup{
    cmd = { '${pkgs.omnisharp-roslyn}/bin/OmniSharp', "--languageserver" , "--hostPID", tostring(pid) },
    capabilities = capabilities,
    -- disable semantic tokens provider
    on_attach = function(client, bufnr)
        client.server_capabilities.semanticTokensProvider = nil
        require'omnisharp'.on_attach(client, bufnr)
    end,
}


-- Configure Nix LSP
lspconfig.nixd.setup{
    cmd = { "${pkgs.nixd}/bin/nixd" },
    capabilities = capabilities,
}

-- Configure Java LSP
lspconfig.java_language_server.setup{
    cmd = { "${pkgs.java-language-server}/bin/java-language-server" },
    capabilities = capabilities,
}

-- Configure Yaml LSP
lspconfig.yamlls.setup {
    cmd = { "${pkgs.yaml-language-server}/bin/yaml-language-server", "--stdio" },
    settings = { yaml = { keyOrdering = false } },
    capabilities = capabilities,
}

-- Configure Lua LSP
lspconfig.lua_ls.setup {
  cmd = { "${pkgs.lua-language-server}/bin/lua-language-server" },
  on_init = function(client)
    local path = client.workspace_folders[1].name
    if not vim.loop.fs_stat(path..'/.luarc.json') and not vim.loop.fs_stat(path..'/.luarc.jsonc') then
      client.config.settings = vim.tbl_deep_extend('force', client.config.settings, {
        Lua = {
          runtime = {
            -- Tell the language server which version of Lua you're using
            -- (most likely LuaJIT in the case of Neovim)
            version = 'LuaJIT'
          },
          -- Make the server aware of Neovim runtime files
          workspace = {
            checkThirdParty = false,
         -- library = {
         --   vim.env.VIMRUNTIME
              -- "''${3rd}/luv/library"
              -- "''${3rd}/busted/library",
         -- }
            -- or pull in all of 'runtimepath'. NOTE: this is a lot slower
            library = vim.api.nvim_get_runtime_file("", true)
          }
        }
      })

      client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
    end
    return true
  end
}

-- Configure Rust LSP
lspconfig.rust_analyzer.setup {}

-- Debugging

local dap = require('dap')

dap.adapters.coreclr = {
    type = 'executable',
    command = '${pkgs.netcoredbg}/bin/netcoredbg',
    args = { '--interpreter=vscode' },
}

dap.configurations.cs = {
  {
    type = 'coreclr',
    name = 'Launch',
    request = 'launch',
    program = function()
      return vim.fn.input('Path to dll ', vim.fn.getcwd() .. '/bin/Debug/', 'file')
    end,
    stopOnEntry = false,
  },
}

dap.configurations.fsharp = {
  {
    type = 'coreclr',
    name = 'Launch',
    request = 'launch',
    program = function()
      return vim.fn.input('Path to dll ', vim.fn.getcwd() .. '/bin/Debug/', 'file')
    end,
    stopOnEntry = false,
  },
}

EOF

''
