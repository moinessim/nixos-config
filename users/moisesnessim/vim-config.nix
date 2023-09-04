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

let mapleader = " "

lua <<EOF
---------------------------------------------------------------------

-- Set leader key
vim.g.mapleader = ' '
vim.o.number = true
vim.o.relativenumber = true

-- Yanks go on clipboard
vim.opt.clipboard = 'unnamedplus'

-- Cd into directory of current buffer
vim.keymap.set('n', '<leader>cd','%:p:h<CR>:pwd<CR>', {} )

-- Clear highlighted search
vim.keymap.set('n', '<C-N>', ':nohlsearch<CR>', {} )

-- vifm plugin keybindings
vim.keymap.set('n', '<leader>s', ':SplitVifm<CR>', {} )
vim.keymap.set('n', '<leader>v', ':VsplitVifm<CR>', {} )
vim.keymap.set('n', '<leader>d', ':DiffVifm<CR>', {} )

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
-- Configure F# LSP
require'lspconfig'.fsautocomplete.setup {
    cmd = { "${pkgs.fsautocomplete}/bin/fsautocomplete", "--adaptive-lsp-server-enabled" }
}



-- Configure Keybindings for LSP

-- Global mappings.
-- See `:help vim.diagnostic.*` for documentation on any of the below functions
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- Use LspAttach autocommand to only map the following keys
-- after the language server attaches to the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})


-- Configure keybindings for terminal

vim.keymap.del('t', '<Esc>')
vim.keymap.del('t', 'JK')
vim.keymap.del('t', 'Jk')
vim.keymap.del('t', 'JJ')
vim.keymap.del('t', 'Jj')
vim.keymap.del('t', 'jK')
vim.keymap.del('t', 'jk')
vim.keymap.del('t', 'jJ')
vim.keymap.del('t', 'jj')

-- Escape from terminal into buffer
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-N>', {})

-- Split terminal
vim.keymap.set('n', '<leader>t', ':sp | :term<CR>', {})


-- Configure keybindings for Telescope

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

-- Git keybindings

vim.keymap.set('n', '<leader>gs', ':G<CR>', {})
vim.keymap.set('n', '<leader>gp', ':G push<CR>', {})
vim.keymap.set('n', '<leader>gpF', ':G push --force<CR>', {})
vim.keymap.set('n', '<leader>gf', ':G fetch<CR>', {})
vim.keymap.set('n', '<leader>gP', ':G pull<CR>', {})


EOF
''