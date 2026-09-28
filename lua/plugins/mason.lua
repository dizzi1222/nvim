-- Detección de Termux (Android): la mayoría de los DAPs nativos (Rust/C/C#/Go)
-- no publican build precompilado para aarch64/bionic, así que en Termux solo se
-- instalan los tools "portables" (LSPs/formatters) para no contaminar el log de
-- arranque con instalaciones que van a fallar en run_on_start.
local is_termux = vim.fn.isdirectory(vim.env.PREFIX or "") == 1 and (vim.env.PREFIX or ""):match("com%.termux") ~= nil

--Tools que Mason NO puede instalar en Termux.
--
--MasonArma el target de plataforma con `mason-core/platform.lua` -> `check_env()`,
--que intenta detectar la libc con `getconf GNU_LIBC_VERSION` y `ldd --version`.
--En Termux (bionic) NINGUNO de los dos responde, asi que la libc no se detecta y
--el target resuelto es `linux_arm64` (nunca `linux_arm64_gnu`).
--StyLua y lua-language-server solo publican el asset `linux_arm64_gnu`, asi que
--no hay match y Mason aborta con:
--    Package stylua failed: The current platform is unsupported.
--Por eso NO entran en ensure_installed en Termux: se instalan del repo de Termux
--(binarios bionic, ya en el PATH) con:
--    pkg install lua-language-server stylua
--En desktop (NixOS) si los gestiona Mason normalmente.
local termux_native = {
  "lua-language-server",
  "stylua",
}

local ensure_installed = {
  -- LSP (portables)
  "angular-language-server",
  "copilot-language-server", -- GitHub Copilot (npm: @github/copilot-language-server)
  "eslint-lsp",
  "json-lsp",
  "lua-language-server",
  "marksman",

  -- Formatter / Linter / otros (portables)
  "biome",
  "prettier",
  "shfmt",
  "stylua",
  "markdown-toc",
  "markdownlint-cli2",
  "tree-sitter-cli",
}

--Tools que NO gestiona Mason en esta plataforma (vacio = todos gestionados).
local mason_unmanaged = {}

-- DAPs nativos: requieren build ARM/Android que Mason no publica para Termux.
if not is_termux then
  vim.list_extend(ensure_installed, {
    -- LSP
    "jdtls",
    "cpptools",

    -- DAP
    "js-debug-adapter", -- pwa-node/pwa-chrome (JS/TS)
    "codelldb", -- C/C++/Rust
    "delve", -- Go
    "netcoredbg", -- C#
    "php-debug-adapter", -- PHP (Xdebug)
    "java-debug-adapter",
    "java-test",

    -- DAP extras (lua/nvim-dap/)
    -- NOTA: haskell-debug-adapter, erlang-debugger, ocamlearlybird y rdbg se
    -- compilan DESDE FUENTE y requieren toolchain de sistema (cabal, rebar3,
    -- opam, ruby). No van en ensure_installed: Mason reintentaría y fallaría en
    -- cada arranque. Doc: nvim/.config/nvim/lua/nvim-dap/README.md
    "bash-debug-adapter",
    "dart-debug-adapter",
    "kotlin-debug-adapter",
    "local-lua-debugger-vscode",
    "perl-debug-adapter",
  })
else
  mason_unmanaged = termux_native
  ensure_installed = vim.tbl_filter(function(tool)
    return not vim.tbl_contains(termux_native, tool)
  end, ensure_installed)
end

return {
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = ensure_installed,
    },
    -- LazyVim declara `opts_extend = { "ensure_installed" }`, o sea que su lista
    -- propia ({ stylua, shfmt }) se SUMA a la nuestra en el merge de `opts` y no
    -- hay forma de restarla desde `opts`. Por eso sobreescribimos `config` (que si
    -- se reemplaza entero) y ahi filtramos `mason_unmanaged` antes de instalar.
    --
    --Antes esto era un segundo instalador en paralelo (mason-tool-installer con
    --run_on_start) y por el solapamiento con esta lista salia en cada arranque:
    --    Package is already installing. (mason.nvim/lua/mason-core/package/init.lua:124)
    --Ahora hay UN solo instalador (esta config) -> sin race.
    config = function(_, opts)
      if #mason_unmanaged > 0 then
        opts.ensure_installed = vim.tbl_filter(function(tool)
          return not vim.tbl_contains(mason_unmanaged, tool)
        end, opts.ensure_installed)
      end

      require("mason").setup(opts)
      local mr = require("mason-registry")

      mr:on("package:install:success", function()
        vim.defer_fn(function()
          -- trigger FileType event to possibly load this newly installed LSP server
          require("lazy.core.handler.event").trigger({
            event = "FileType",
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)

      mr.refresh(function()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end)
    end,
  },
  { "mason-org/mason-lspconfig.nvim" },
}
