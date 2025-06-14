self: super:

let sources = import ../../nix/sources.nix; in rec {
  # My vim config
  customVim = with self; {

    toggleterm = vimUtils.buildVimPlugin {
      name = "toggleterm.nvim";
      src = sources."toggleterm.nvim";
    };

    vifm-vim = vimUtils.buildVimPlugin {
      name = "vifm.vim";
      src = sources."vifm.vim";
    };

    which-key-nvim = vimUtils.buildVimPlugin {
      name = "which-key.nvim";
      src = sources."which-key.nvim";
    };

    vim-copilot = vimUtils.buildVimPlugin {
      name = "vim-copilot";
      src = sources.vim-copilot;
    };

    vim-cue = vimUtils.buildVimPlugin {
      name = "vim-cue";
      src = sources.vim-cue;
    };

    vim-fish = vimUtils.buildVimPlugin {
      name = "vim-fish";
      src = sources.vim-fish;
    };

    vim-fugitive = vimUtils.buildVimPlugin {
      name = "vim-fugitive";
      src = sources.vim-fugitive;
    };

    vim-glsl = vimUtils.buildVimPlugin {
      name = "vim-glsl";
      src = sources.vim-glsl;
    };

    vim-misc = vimUtils.buildVimPlugin {
      name = "vim-misc";
      src = sources.vim-misc;
      dependencies  = with vimPlugins; [
        vimPlugins.nvim-dap
        vimPlugins.nvim-dap-ui
        vimPlugins.nvim-dap-virtual-text
        toggleterm-nvim
        vimPlugins.plenary-nvim  # required for telescope
        vimPlugins.telescope-nvim
        vimPlugins.trouble-nvim
        vimPlugins.lspkind-nvim
        vimPlugins.nvim-cmp
        vimPlugins.nvim-treesitter.withAllGrammars
        comment-nvim
      ]
      ++ vimPlugins.nvim-dap-ui.dependencies
      ;
    };

    vim-pgsql = vimUtils.buildVimPlugin {
      name = "vim-pgsql";
      src = sources.vim-pgsql;
    };

    vim-tla = vimUtils.buildVimPlugin {
      name = "tla.vim";
      src = sources.vim-tla;
    };

    dracula = vimUtils.buildVimPlugin {
      name = "dracula";
      src = sources.vim-dracula;
    };

    pigeon = vimUtils.buildVimPlugin {
      name = "pigeon.vim";
      src = sources.vim-pigeon;
    };

    AfterColors = vimUtils.buildVimPlugin {
      name = "AfterColors";
      src = pkgs.fetchFromGitHub {
        owner = "vim-scripts";
        repo = "AfterColors.vim";
        rev = "9936c26afbc35e6f92275e3f314a735b54ba1aaf";
        sha256 = "0j76g83zlxyikc41gn1gaj7pszr37m7xzl8i9wkfk6ylhcmjp2xi";
      };
    };

    vim-devicons = vimUtils.buildVimPlugin {
      name = "vim-devicons";
      src = sources.vim-devicons;
    };

    vim-nord = vimUtils.buildVimPlugin {
      name = "vim-nord";
      src = sources.vim-nord;
    };

    nvim-comment = vimUtils.buildVimPlugin {
      name = "nvim-comment";
      src = sources.nvim-comment;
      buildPhase = ":";
    };

    comment-nvim = vimUtils.buildVimPlugin {
      name = "Comment.nvim";
      src = sources."Comment.nvim";
    };

    nvim-magma = vimUtils.buildVimPlugin {
      name = "nvim-magma";
      src = sources.nvim-magma;
    };

    nvim-plenary = vimUtils.buildVimPlugin {
      name = "nvim-plenary";
      src = sources.nvim-plenary;
      buildPhase = ":";
    };

    nvim-telescope = vimUtils.buildVimPlugin {
      name = "nvim-telescope";
      src = sources.nvim-telescope;
      buildPhase = ":";
    };

    nvim-treesitter = vimUtils.buildVimPlugin {
      name = "nvim-treesitter";
      src = sources.nvim-treesitter;
    };

    nvim-treesitter-playground = vimUtils.buildVimPlugin {
      name = "nvim-treesitter-playground";
      src = sources.nvim-treesitter-playground;
    };

    nvim-lspconfig = vimUtils.buildVimPlugin {
      name = "nvim-lspconfig";
      src = sources.nvim-lspconfig;

      # We have to do this because the build phase runs tests which require
      # git and I don't know how to get git into here.
      buildPhase = ":";
    };

    nvim-lspinstall = vimUtils.buildVimPlugin {
      name = "nvim-lspinstall";
      src = sources.nvim-lspinstall;
    };

    nvim-treesitter-textobjects = vimUtils.buildVimPlugin {
      name = "nvim-treesitter-textobjects";
      src = sources.nvim-treesitter-textobjects;
    };
  };
}
