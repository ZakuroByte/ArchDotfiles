-- ======================
-- Opciones básicas
-- ======================
vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

vim.opt.number = true
vim.opt.relativenumber = false

-- ======================
-- Bootstrap lazy.nvim
-- ======================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- ======================
-- Plugins con lazy.nvim
-- ======================
require("lazy").setup({
  spec = {
    -- Tema
    {
      "ramojus/mellifluous.nvim",
      config = function()
        require("mellifluous").setup({})
        vim.cmd("colorscheme mellifluous")
      end,
    },

    -- Telescope
    {
      "nvim-telescope/telescope.nvim",
      tag = "0.1.8",
      dependencies = { "nvim-lua/plenary.nvim" },
      config = function()
        local builtin = require("telescope.builtin")
        vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
        vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
        vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
        vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
      end,
    },
    -- Neo-tree
    {
      "nvim-neo-tree/neo-tree.nvim",
      branch = "v3.x",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-tree/nvim-web-devicons",
      },
      config = function()
        vim.keymap.set("n", "<C-n>", ":Neotree filesystem reveal left<CR>")
      end,
    },

    -- Treesitter
    {
      "nvim-treesitter/nvim-treesitter",
      build = ":TSUpdate",
      config = function()
        require("nvim-treesitter.configs").setup({
          ensure_installed = { "html", "css", "javascript", "c", "lua", "xml" },
          highlight = { enable = true },
        })
      end,
    },

    -- Autotag
    {
      "windwp/nvim-ts-autotag",
      dependencies = "nvim-treesitter/nvim-treesitter",
      config = true,
    },

    -- Emmet
    {
      "mattn/emmet-vim",
      config = function()
        vim.g.user_emmet_mode = "a"
        vim.g.user_emmet_leader_key = "<C-e>"
      end,
    },

    -- LSP + Autocompletado
    { "williamboman/mason.nvim", config = true },
    { "williamboman/mason-lspconfig.nvim" },
    { "neovim/nvim-lspconfig" },

    -- Autocompletado con nvim-cmp
    {
      "hrsh7th/nvim-cmp",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-nvim-lua",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
        "rafamadriz/friendly-snippets", -- 👈 snippets de VSCode (incluye html:5)
      },
      config = function()
        local cmp = require("cmp")
        local luasnip = require("luasnip")

        require("luasnip.loaders.from_vscode").lazy_load()

        cmp.setup({
          mapping = cmp.mapping.preset.insert({
            ["<Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { "i", "s" }),

            ["<S-Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { "i", "s" }),

            ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ["<C-Space>"] = cmp.mapping.complete(),
          }),
          sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "luasnip" },
            { name = "buffer" },
            { name = "path" },
            { name = "nvim_lua" },
          }),
        })
      end,
    },

    -- Formateo
    {
      "stevearc/conform.nvim",
      config = function()
        require("conform").setup({
          formatters_by_ft = {
            javascript = { "prettierd" },
            html = { "prettierd" },
            css = { "prettierd" },
            c = { "clang-format" },
            lua = { "stylua" },
          },
          format_on_save = {
            timeout_ms = 500,
            lsp_fallback = true,
          },
        })

        vim.keymap.set("n", "<leader>f", function()
          require("conform").format({ async = true, lsp_fallback = true })
        end, { desc = "Format file" })
      end,
    },

    {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      config = function()
        require("mason-tool-installer").setup({
          ensure_installed = { "prettierd", "clang-format", "stylua" },
        })
      end,
    },

    {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      config = true,
    },
  },
  checker = { enabled = true },
})

-- ======================
-- LSP Configuración
-- ======================
local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("mason-lspconfig").setup({
  ensure_installed = {
    "html",
    "cssls",
    "ts_ls", -- 👈 corregido
    "clangd",
  },
  handlers = {
    function(server)
      lspconfig[server].setup({ capabilities = capabilities })
    end,

    ["html"] = function()
      lspconfig.html.setup({
        capabilities = capabilities,
        filetypes = { "html", "htm" },
      })
    end,
  },
})

-- ======================
-- Tema + transparencia
-- ======================
require("mellifluous").setup({})
vim.cmd("colorscheme mellifluous")
vim.cmd("hi Normal guibg=NONE")
vim.cmd("hi NormalNC guibg=NONE")

-- ======================
-- Configuración específica para TXT
-- ======================
vim.api.nvim_create_autocmd("FileType", {
  pattern = "txt",
  callback = function()
    -- Desactivar numeración relativa
    vim.opt.relativenumber = false
    -- Desactivar plugins innecesarios (ejemplo: nvim-autopairs)
    vim.b.auto_pairs_disabled = true
    -- Cualquier otra configuración específica para TXT
    vim.opt.expandtab = false
    vim.opt.shiftwidth = 4
    vim.opt.tabstop = 4
  end,
})
