-- This file contains the configuration for the nvim-dap plugin in Neovim.

return {
  {
    -- Plugin: nvim-dap
    -- URL: https://github.com/mfussenegger/nvim-dap
    -- Description: Debug Adapter Protocol client implementation for Neovim.
    "mfussenegger/nvim-dap",
    recommended = true, -- Recommended plugin
    desc = "Debugging support. Requires language specific adapters to be configured. (see lang extras)",

    dependencies = {
      -- Plugin: nvim-dap-ui
      -- URL: https://github.com/rcarriga/nvim-dap-ui
      -- Description: A UI for nvim-dap.
      "rcarriga/nvim-dap-ui",

      -- Plugin: nvim-dap-virtual-text
      -- URL: https://github.com/theHamsta/nvim-dap-virtual-text
      -- Description: Virtual text for the debugger.
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {}, -- Default options
      },
    },

    -- Keybindings for nvim-dap
    keys = {
      { "<leader>d", "", desc = "+debug", mode = { "n", "v" } }, -- Group for debug commands
      {
        "<leader>dr",
        function()
          require("dap").restart()
        end,
        desc = "Restart Debugger",
      },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "Breakpoint Condition",
      },
      {
        "<leader>dD",
        function()
          require("dap").clear_breakpoints()
        end,
        desc = "Clear All Breakpoints",
      },
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle Breakpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Continue",
      },
      {
        "<leader>da",
        function()
          require("dap").continue({ before = get_args })
        end,
        desc = "Run with Args",
      },
      {
        "<leader>dC",
        function()
          require("dap").run_to_cursor()
        end,
        desc = "Run to Cursor",
      },
      {
        "<leader>dg",
        function()
          require("dap").goto_()
        end,
        desc = "Go to Line (No Execute)",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Step Into",
      },
      {
        "<leader>dj",
        function()
          require("dap").down()
        end,
        desc = "Down",
      },
      {
        "<leader>dk",
        function()
          require("dap").up()
        end,
        desc = "Up",
      },
      {
        "<leader>dl",
        function()
          require("dap").run_last()
        end,
        desc = "Run Last",
      },
      {
        "<leader>do",
        function()
          require("dap").step_out()
        end,
        desc = "Step Out",
      },
      {
        "<leader>dO",
        function()
          require("dap").step_over()
        end,
        desc = "Step Over",
      },
      {
        "<leader>dp",
        function()
          require("dap").pause()
        end,
        desc = "Pause",
      },
      {
        "<leader>dz",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
      {
        "<leader>ds",
        function()
          require("dap").session()
        end,
        desc = "Session",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate",
      },
      {
        "<leader>dw",
        function()
          require("dap.ui.widgets").hover()
        end,
        desc = "Widgets",
      },
    },

    config = function()
      local dap = require("dap")

      -- Directorio del archivo actual (no getcwd). Debe definirse ANTES de
      -- usarse: las configs C# (program/preflight) y los hints lo llaman y en
      -- Lua una local function solo es visible DESPUES de su declaracion.
      local function buf_dir()
        local f = vim.fn.expand("%:p")
        if f ~= "" then
          return vim.fn.fnamemodify(f, ":h")
        end
        return vim.fn.getcwd()
      end

      -- Load mason-nvim-dap if available, disabling auto-handler for js-debug-adapter to prevent adapter override
      if LazyVim.has("mason-nvim-dap.nvim") then
        local opts = LazyVim.opts("mason-nvim-dap.nvim") or {}
        opts.handlers = opts.handlers or {}
        -- "js" es el dap source name en mason-nvim-dap para js-debug-adapter.
        -- No-op handler evita que mason-nvim-dap sobrescriba los adaptadores pwa-* nativos.
        opts.handlers["js"] = function() end
        require("mason-nvim-dap").setup(opts)
      end

      -- Set highlight for DapStoppedLine
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      -- Define signs for DAP
      for name, sign in pairs(LazyVim.config.icons.dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define(
          "Dap" .. name,
          { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
        )
      end

      -- Setup DAP configuration using VsCode launch.json file
      local vscode = require("dap.ext.vscode")
      local json = require("plenary.json")
      vscode.json_decode = function(str)
        return vim.json.decode(json.json_strip_comments(str))
      end

      -- Function to load environment variables
      local function load_env_variables()
        local variables = {}
        for k, v in pairs(vim.fn.environ()) do
          variables[k] = v
        end

        -- Load variables from .env file manually
        local env_file_path = vim.fn.getcwd() .. "/.env"
        local env_file = io.open(env_file_path, "r")
        if env_file then
          for line in env_file:lines() do
            for key, value in string.gmatch(line, "([%w_]+)=([%w_]+)") do
              variables[key] = value
            end
          end
          env_file:close()
        else
          print("Error: .env file not found in " .. env_file_path)
        end
        return variables
      end

      -- Add the env property to each existing Go configuration
      for _, config in pairs(dap.configurations.go or {}) do
        config.env = load_env_variables
      end

      -- JS/TS launch configurations
      for _, language in ipairs({ "typescriptreact", "typescript", "javascript", "javascriptreact" }) do
        local configs = {
          {
            type = "pwa-node",
            request = "launch",
            name = "Launch file",
            -- Patron ESTANDAR pwa-node: `program` = archivo a ejecutar +
            -- `stopOnEntry = true` pausa en la 1ra linea, dejando que el debugger
            -- (vscode-js-debug) inicie la sesion.
            program = function()
              return vim.fn.expand("%:p")
            end,
            cwd = function()
              return vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
            end,
            stopOnEntry = true,
            sourceMaps = true,
            resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
          },
          {
            type = "pwa-node",
            request = "attach",
            name = "Attach to process",
            processId = require("dap.utils").pick_process,
            cwd = "${workspaceFolder}",
            sourceMaps = true,
          },
        }

        if language == "typescript" or language == "typescriptreact" then
          -- TS con imports SIN extension ("./talent" -> .ts/.d.ts): Node nativo
          -- (strip-types) NO los resuelve, ESM exige extension explicita. Esta
          -- config es la UNICA para .ts/.tsx (proyectos reales) y resuelve el
          -- proyecto en RUNTIME (no al cargar el plugin): el root se toma del
          -- buffer activo al lanzar, no del cwd/buffer de arranque de nvim.
          -- Asi la opcion aparece aunque hayas abierto nvim desde ~ o con otro
          -- archivo.
          --   - package.json SIN "type": "module" (CommonJS, ej. Express/TypeORM
          --     con ts-node-dev) -> `node -r ts-node/register/transpile-only`
          --     (mismo registro que ts-node-dev; fuerza require()/import a CJS
          --     y evita el ciclo "Cannot require() ES Module in a cycle").
          --   - package.json con "type": "module" -> `--loader ts-node/esm`.
          -- Si ts-node no esta en node_modules, se lanza un error claro al
          -- ejecutar (el hint de typescript recomienda instalarlo con pnpm/npm).
          table.insert(configs, {
            type = "pwa-node",
            request = "launch",
            name = "Launch TS (project)",
            runtimeExecutable = "node",
            runtimeArgs = function()
              local proj_root = vim.fs.root(0, "tsconfig.json") or vim.fn.getcwd()
              local ts_bin = proj_root .. "/node_modules/.bin/ts-node"
              if vim.fn.filereadable(ts_bin) ~= 1 then
                error(
                  "ts-node no encontrado en "
                    .. ts_bin
                    .. ". Instalalo primero: `pnpm add -D ts-node-dev` (o `npm i -D ts-node-dev`)."
                )
              end
              local pkg_f = io.open(proj_root .. "/package.json", "r")
              local is_esm = false
              if pkg_f then
                local pkg_c = pkg_f:read("*a")
                pkg_f:close()
                is_esm = pkg_c:match('"type"%s*:%s*"module"') ~= nil
              end
              if is_esm then
                return { "--loader", "ts-node/esm", "--no-warnings" }
              end
              return { "-r", "ts-node/register/transpile-only", "--no-warnings" }
            end,
            program = function()
              return vim.fn.expand("%:p")
            end,
            cwd = function()
              -- Raiz del proyecto TS (tsconfig.json) en vez del dir del buffer:
              -- dotenv/config (app.ts) lee .env desde el cwd; con el dir del
              -- buffer (ej. src/) no encontraba .env y pasaba a pasar
              -- CINCINNATUS_DOMAIN undefined.
              return vim.fs.root(0, "tsconfig.json") or vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
            end,
            environment = function()
              local proj_root = vim.fs.root(0, "tsconfig.json") or vim.fn.getcwd()
              return { TS_NODE_PROJECT = proj_root .. "/tsconfig.json" }
            end,
            stopOnEntry = true,
            sourceMaps = true,
            resolveSourceMapLocations = { "!**/node_modules/**" },
          })
        end

        vim.list_extend(configs, {
          {
            type = "pwa-chrome",
            request = "launch",
            name = "Launch Chrome (React/Dev)",
            url = "http://localhost:5173",
            webRoot = "${workspaceFolder}",
            runtimeExecutable = "/home/diego/.nix-profile/bin/chromium",
            sourceMaps = true,
          },
          {
            type = "pwa-chrome",
            request = "attach",
            name = "Attach to Chrome",
            port = 9222,
            webRoot = "${workspaceFolder}",
            sourceMaps = true,
          },
          {
            type = "pwa-node",
            request = "launch",
            name = "Debug Jest Tests",
            runtimeExecutable = "node",
            runtimeArgs = {
              "./node_modules/jest/bin/jest.js",
              "--runInBand",
            },
            rootPath = "${workspaceFolder}",
            cwd = "${workspaceFolder}",
            console = "integratedTerminal",
            internalConsoleOptions = "neverOpen",
            sourceMaps = true,
          },
          {
            type = "pwa-node",
            request = "launch",
            name = "Debug Mocha Tests",
            runtimeExecutable = "node",
            runtimeArgs = {
              "./node_modules/mocha/bin/mocha.js",
            },
            rootPath = "${workspaceFolder}",
            cwd = "${workspaceFolder}",
            console = "integratedTerminal",
            internalConsoleOptions = "neverOpen",
            sourceMaps = true,
          },
        })

        dap.configurations[language] = configs
      end

      -- ══════════════════════════════════════════════════════════
      -- Adapters JS/TS (pwa-*) NATIVOS de nvim-dap
      -- ══════════════════════════════════════════════════════════
      -- Se lanza `dapDebugServer.js` como executable server y nvim-dap conecta.
      -- `port = "${port}"` + `executable` hace que nvim-dap genere un puerto
      -- LIBRE POR SESION, lo sustituya en los args y conecte (multi-session).
      -- ⚠️ NO compilar vscode-js-debug a mano con gulp: los builds recientes
      -- (HEAD/main) tienen un bug conocido que rompe el stepping ("No stopped
      -- threads. Cannot move" al hacer step over/into/out). Usar el binario
      -- empaquetado y versionado de Mason (:MasonInstall js-debug-adapter).
      -- Con executable + ${port} nvim-dap inyecta el puerto directamente, sin
      -- depender del stdout del binario. Elimina el error 1492 de raiz y, con
      -- stopOnEntry en las configs, tambien el "No stopped threads".
      -- Resolver el path del debugger via mason-registry (NO hardcodear): asi nunca
      -- se rompe si cambia el layout interno del paquete js-debug-adapter entre
      -- versiones. get_install_path() apunta al lugar real donde Mason lo instalo.
      local mason_registry = require("mason-registry")
      local pkg = mason_registry.is_installed("js-debug-adapter") and mason_registry.get_package("js-debug-adapter")
      local js_debug_server = pkg and (pkg:get_install_path() .. "/js-debug/src/dapDebugServer.js")
      if not js_debug_server or vim.fn.filereadable(js_debug_server) == 0 then
        vim.notify(
          "js-debug-adapter no encontrado. Corre :MasonInstall js-debug-adapter y reinicia nvim",
          vim.log.levels.ERROR,
          { title = "nvim-dap: JS/TS" }
        )
      end
      local node_bin = vim.fn.exepath("node")
      for _, name in ipairs({ "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal" }) do
        dap.adapters[name] = {
          type = "server",
          -- host EXPLICITO: nvim-dap tiene un bug documentado si falta host+port
          -- juntos en un adapter type=server (queda sin conectar en silencio).
          host = "127.0.0.1",
          port = "${port}",
          executable = {
            command = node_bin,
            args = { js_debug_server, "${port}", "127.0.0.1" },
          },
        }
      end

      -- ══════════════════════════════════════════════════════════
      -- UI FIX: layout en columnas, winbar, controls
      -- ══════════════════════════════════════════════════════════
      vim.schedule(function()
        local dapui = require("dapui")
        dapui.setup({
          expand_lines = false,
          wrap = true, -- wrap en todos los paneles DAP (Scopes, Watches, etc.)
          render = { max_value_lines = 100, max_type_length = 80 },
          controls = { enabled = true, element = "repl" },
          layouts = {
            {
              elements = {
                { id = "scopes", size = 0.40 },
                { id = "breakpoints", size = 0.20 },
                { id = "stacks", size = 0.10 },
                { id = "watches", size = 0.20 },
              },
              size = 32,
              position = "left",
            },
            {
              elements = { "repl", "console" },
              size = 10,
              position = "bottom",
            },
          },
        })

        -- Winbar: nombre de cada panel (DAP Scopes, Watches, etc.)
        local group = vim.api.nvim_create_augroup("MyDapUiWinbar", { clear = true })
        vim.api.nvim_create_autocmd("BufWinEnter", {
          group = group,
          pattern = { "DAP*", "dap-repl" },
          callback = function()
            vim.wo.winbar = "%t"
          end,
        })
        -- WinBar highlights = estilo lualine
        vim.api.nvim_create_autocmd("ColorScheme", {
          group = group,
          pattern = "*",
          callback = function()
            local ok1, lc = pcall(vim.api.nvim_get_hl, 0, { name = "lualine_c_normal", link = false })
            local ok2, nm = pcall(vim.api.nvim_get_hl, 0, { name = "Normal", link = false })
            local bg = (ok1 and lc.bg) or (ok2 and nm.bg) or "#1e1e2e"
            local fg = (ok1 and lc.fg) or (ok2 and nm.fg) or "#cdd6f4"
            vim.api.nvim_set_hl(0, "WinBar", { bg = bg, fg = fg, bold = true })
            vim.api.nvim_set_hl(0, "WinBarNC", { bg = bg, fg = fg, bold = false })
          end,
        })
        if vim.g.colors_name then
          vim.api.nvim_exec_autocmds("ColorScheme", { pattern = vim.g.colors_name })
        end
      end)

      -- ══════════════════════════════════════════════════════════
      -- MULTI-LENGUAJE: C/C++/Rust, Go, C#, Java, PHP
      -- ══════════════════════════════════════════════════════════

      -- Helper: buscar binario compilado
      local function find_executable()
        local file = vim.fn.expand("%:p")
        if file == "" then
          return nil
        end
        local dir = vim.fn.fnamemodify(file, ":h")
        local name = vim.fn.fnamemodify(file, ":t:r")
        local candidates = {
          dir .. "/out/" .. name,
          dir .. "/build/" .. name,
          dir .. "/bin/" .. name,
          dir .. "/target/debug/" .. name,
          dir .. "/" .. name,
        }
        for _, path in ipairs(candidates) do
          -- OJO: filereadable() devuelve 1 TAMBIEN para directorios (ej.
          -- "src/pages" del front se lanzaba como ejecutable). Comprobar
          -- isdirectory() evita tratar carpetas como binario.
          if vim.fn.filereadable(path) == 1 and vim.fn.isdirectory(path) == 0 then
            return path
          end
        end
        -- Sin binario: nil. El preflight (auto-build con confirmacion) decide
        -- que hacer en vez de pedir input con el cwd del workspace.
        return nil
      end

      -- C/C++/Rust (codelldb)
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = { command = "codelldb", args = { "--port", "${port}" } },
      }
      local native_cfg = {
        type = "codelldb",
        request = "launch",
        name = "Launch file",
        program = find_executable,
        -- cwd al dir del buffer (NO ${workspaceFolder}: evita heredar el
        -- workspace del front y lanzar basura de ahi).
        cwd = function()
          return buf_dir()
        end,
        stopAtEntry = false,
      }
      dap.configurations.c = { native_cfg }
      dap.configurations.cpp = { native_cfg }
      dap.configurations.rust = { native_cfg }

      -- Go (delve)
      dap.adapters.delvete = {
        type = "server",
        port = "${port}",
        executable = { command = "dlv", args = { "dap", "-l", "127.0.0.1:${port}" } },
      }
      dap.configurations.go = {
        { type = "delvete", request = "launch", name = "Launch", program = "${file}" },
        { type = "delvete", request = "launch", name = "Launch package", program = "./${fileDirname}" },
      }

      -- C# (netcoredbg)
      dap.adapters.netcoredbg = {
        type = "executable",
        command = "netcoredbg",
        args = { "--interpreter=vscode" },
      }
      dap.configurations.cs = {
        {
          type = "netcoredbg",
          request = "launch",
          name = "Launch .NET",
          program = function()
            -- Usar buf_dir() (dir del archivo, no getcwd) para que el dll se
            -- encuentre aunque nvim se haya abierto desde otro directorio.
            -- `vim.fn.glob(...)` con 3er arg `1` (list) devuelve una TABLA de
            -- rutas, no un string: tomar matches[1] directamente (NO split).
            local root = buf_dir()
            local matches = vim.fn.glob(root .. "/bin/Debug/**/*.dll", 0, 1)
            local dll = ""
            if type(matches) == "table" and #matches > 0 then
              dll = matches[1]
            end
            if dll ~= "" then
              return dll
            end
            return vim.fn.input("Path to dll: ", root .. "/bin/Debug/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopAtEntry = false,
        },
      }

      -- Java: el adapter `java` y la config los registra el extra LazyVim
      -- `lazyvim.plugins.extras.lang.java` via `require("jdtls").setup_dap()`.
      -- El bundle java-debug-adapter es un fragmento OSGi que SOLO corre DENTRO
      -- de jdtls (no es un .jar lanzable standalone). Quien active la depuracion
      -- Java debe tener jdtls corriendo (LSP de Java) y los bundles en
      -- $MASON/share/java-debug-adapter. NO configurar `dap.adapters.java` aqui.

      -- PHP (Xdebug listen mode via php-debug-adapter de vscode-php-debug)
      -- ⚠️ REQUIERE instalar el adapter primero:
      --    :MasonInstall php-debug-adapter
      --    (NO es "php" a secas: `php` no implementa el protocolo DAP, por eso
      --    el error "Debug adapter didn't respond").
      dap.adapters.php = {
        type = "executable",
        command = vim.fn.stdpath("data") .. "/mason/bin/php-debug-adapter",
      }
      dap.configurations.php = {
        {
          type = "php",
          request = "launch",
          name = "Listen for Xdebug",
          port = 9003,
          -- Con el servidor built-in `php -S` corrido desde el dir del archivo,
          -- PHP ve el script con su ruta REAL local (ej. /tmp/testphp/index.php),
          -- NO como /var/www/... Por eso NO se mapea a /var/www (romperia el
          -- breakpoint). Si se abre el mismo archivo en nvim y el server corre
          -- desde el mismo dir, no hace falta pathMappings.
        },
      }

      -- Python (debugpy). Requiere: pip install debugpy (opcional en venv).
      -- Detecta el intérprete: `.venv/bin/python` del proyecto, si no el de nix.
      local function find_python()
        local venv = vim.fn.getcwd() .. "/.venv/bin/python"
        if vim.fn.filereadable(venv) == 1 then
          return venv
        end
        return vim.fn.exepath("python3") ~= "" and vim.fn.exepath("python3") or "/home/diego/.nix-profile/bin/python3"
      end
      local py = find_python()
      dap.adapters.python = {
        type = "executable",
        command = py,
        args = { "-m", "debugpy.adapter" },
      }
      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Launch file",
          program = function()
            return vim.fn.expand("%:p")
          end,
          cwd = function()
            return vim.fn.fnamemodify(vim.fn.expand("%:p"), ":h")
          end,
          pythonPath = py,
          console = "integratedTerminal",
        },
        {
          type = "python",
          request = "launch",
          name = "Attach to debugpy (launcher)",
          connect = { host = "127.0.0.1", port = 5678 },
          justMyCode = false,
        },
      }

      -- ══════════════════════════════════════════════════════════
      -- NOTIFICACIONES FALLBACK por lenguaje
      -- Cuando el debugger falla (falta compilar, adapter no instalado,
      -- intérprete ausente, etc.), se muestra el comando/requsito correcto
      -- según el lenguaje del buffer en vez de un error criptico.
      -- ══════════════════════════════════════════════════════════

      -- build_hints[filetype] = funcion() -> { comando, descripcion }
      -- Cada hint se genera EN TIEMPO DE USO con el directorio del buffer
      -- actual (no al cargar el config, que capturaria el primer archivo).
      local build_hints = {
        rust = function()
          local src = vim.fn.fnamemodify(vim.fn.expand("%:t"), ":t")
          local name = vim.fn.fnamemodify(src, ":t:r")
          if name == "" then
            name = "main"
          end
          return {
            "cd " .. buf_dir() .. " && rustc -g -o build/" .. name .. " " .. src,
            "Falta compilar el binario que lanza codelldb.",
          }
        end,
        c = function()
          local src = vim.fn.fnamemodify(vim.fn.expand("%:t"), ":t")
          local name = vim.fn.fnamemodify(src, ":t:r")
          if name == "" then
            name = "main"
          end
          return {
            "cd " .. buf_dir() .. " && gcc -g -o build/" .. name .. " " .. src,
            "Falta compilar el binario nativo.",
          }
        end,
        cpp = function()
          local src = vim.fn.fnamemodify(vim.fn.expand("%:t"), ":t")
          local name = vim.fn.fnamemodify(src, ":t:r")
          if name == "" then
            name = "main"
          end
          return {
            "cd " .. buf_dir() .. " && g++ -g -o build/" .. name .. " " .. src,
            "Falta compilar el binario nativo.",
          }
        end,
        cs = function()
          return {
            "cd " .. buf_dir() .. " && dotnet build",
            "No se encontró el .dll en bin/Debug. Compilá el proyecto .NET.",
          }
        end,
        java = function()
          return {
            "Java DAP: 1) :MasonInstall jdtls 2) abrir un .java que este en un PROYECTO Java real (pom.xml o build.gradle — los archivos sueltos 'non-project' no debugean) 3) reiniciar nvim DESDE la raiz del proyecto para que jdtls lo importe 4) <leader>dc. El override plugins/java-dap.lua hace la config 'Launch Main Class' la UNICA (default) con stopOnEntry, y elimina la estatica 'Debug (Attach) - Remote' (attach 5005) que confundia.",
            "Java: 'Error on attach to 127.0.0.1:5005' = jdtls NO reconocio el proyecto (non-project) y cae a la config estatica 'Attach - Remote' del extra LazyVim, que apunta a 5005 sin que haya un debuggee escuchando. No es la config real. CAUSA RAIZ: jdtls usa `vim.lsp.config.jdtls.root_markers` (nvim-lspconfig/lsp/jdtls.lua) que SOLO reconoce mvnw/gradlew/settings.gradle/.git y build.xml/pom.xml/build.gradle — **NO incluye .project/.classpath**. Asi que los markers Eclipse NO bastan: /tmp/testjava necesita un `pom.xml` minimo (YA CREADO) + layout Maven src/main/java. Reiniciá nvim desde /tmp/testjava y abrí src/main/java/com/example/Main.java para que jdtls lo importe como proyecto y registre el adapter `java`.",
            "Java: 'Could not resolve java executable' = jdtls no resuelve el JDK en NixOS. JAVA_HOME se setea solo al arrancar nvim (lua/config/options.lua). Reiniciá nvim para que jdtls lo herede.",
            "Atajos DAP (LazyVim): <leader>dc = Continue, <leader>do = Step Over, <leader>di = Step Into, <leader>dt = Step Out, <leader>db = togglear breakpoint, <leader>ds = Stop. En Java al pausar en la 1ra linea (stopOnEntry) usá <leader>do (Step Over) para ir linea a linea y <leader>dc para seguir hasta el siguiente breakpoint.",
          }
        end,
        php = function()
          local script = vim.fn.fnamemodify(vim.fn.expand("%:t"), ":t")
          return {
            "Debug PHP: 0) PREREQUISITO: comprobar que la extension Xdebug esta CARGADA en PHP -> `php -m | grep xdebug` (debe listar 'xdebug'). Si NO aparece, el debug nunca conecta (el adapter escucha en 9003 pero Xdebug no existe). Instalar la extension xdebug primero.",
            "Debug PHP: 1) :MasonInstall php-debug-adapter (hecho)  2) levantar el servidor con Xdebug en OTRA terminal ANTES de <leader>dc:\n"
              .. "    cd "
              .. buf_dir()
              .. " && php -d xdebug.mode=debug -d xdebug.start_with_request=yes -d xdebug.client_host=127.0.0.1 -d xdebug.client_port=9003 -S localhost:8000\n"
              .. "  3) <leader>dc -> 'Listen for Xdebug'  4) DISPARAR una request HTTP para que Xdebug conecte\n"
              .. "    (el adapter NO conecta con solo escuchar; necesita una peticion):\n"
              .. "    xdg-open http://localhost:8000/"
              .. script
              .. "   (abre el navegador con el script actual)\n"
              .. "    o el equivalente manual: curl http://localhost:8000/"
              .. script
              .. "\n"
              .. "  Solo con una peticion al servidor Xdebug se activa y conecta al puerto 9003.",
            "nvim-dap quedó 'Running Listen for Xdebug' pero Xdebug no conecta: (a) verificar `php -m | grep xdebug`, (b) disparar una request HTTP (xdg-open o curl http://localhost:8000/index.php).",
          }
        end,
        python = function()
          return {
            "debugpy ya viene en work.nix; si sigue sin verse: python3 -m pip install debugpy",
            "debugpy no encontrado para la depuración Python.",
          }
        end,
        typescript = function()
          -- Detecta si el buffer pertenece a un backend Node (Express/TypeORM,
          -- tsconfig CommonJS) o a un frontend Vite/React. El hint cambia para
          -- no sugerir Launch Chrome en un servidor que corre en Node.
          local ts_root = vim.fs.root(0, "tsconfig.json")
          local is_backend = false
          local is_vite = false
          if ts_root then
            local pkg_file = io.open(ts_root .. "/package.json", "r")
            if pkg_file then
              local pkg = pkg_file:read("*a")
              pkg_file:close()
              is_vite = pkg:match('"vite"') ~= nil
              is_backend = (pkg:match('"express"') or pkg:match('"typeorm"') or pkg:match('"fastify"')) ~= nil
            end
          end
          if is_backend or (ts_root and not is_vite) then
            local ts_bin = ts_root and (ts_root .. "/node_modules/.bin/ts-node") or nil
            local has_ts_node = ts_bin and vim.fn.filereadable(ts_bin) == 1
            if not has_ts_node then
              return {
                "Debug TS Backend (Express/Node): 1) Este proyecto no tiene ts-node; instalalo como devDependency: `pnpm add -D ts-node-dev` (o `npm i -D ts-node-dev`); trae ts-node + el loader que resuelve imports sin extensión. Sin él, 'Launch TS (project)' fallará con un error claro. 2) Levantá la BD antes si el server la necesita: `~/cloud-sql-proxy --port 5433 cic-ptd-dev:us-east1:cic-ptd-dev`. 3) <leader>dc → elige 'Launch TS (project)' (elige CJS o ESM según el package.json; en CommonJS NO da 'Cannot require() ES Module in a cycle'). 4) Si el server ya corre, también podés 'Attach to process'. 5) .d.ts NO se ejecuta (solo tipos).",
              }
            end
            return {
              "Debug TS Backend (Express/Node): 1) Levantá la BD antes si el server la necesita: `~/cloud-sql-proxy --port 5433 cic-ptd-dev:us-east1:cic-ptd-dev`. 2) <leader>dc → elige 'Launch TS (project)' (elige CJS o ESM según el package.json; en CommonJS NO da 'Cannot require() ES Module in a cycle'). 3) Si el server ya corre con ts-node-dev, también podés 'Attach to process'. 4) .d.ts NO se ejecuta (solo tipos).",
            }
          end
          return {
            "Debug TS (Vite/React = NO es un script node): 1) PRIMERO levantá el proyecto → `npm run dev` (o tu runner, ej. <leader>l s); el debugger va a atacar el bundler, sin eso los breakpoints de .ts/.tsx no existen todavia. 2) <leader>dc → elige 'Launch Chrome (React/Dev)' (abre Chromium en :5173). 3) Un archivo JS SUELTO (sin bundler/backend) sí funciona con 'Launch file' directo: es una decision de contexto — script standalone no necesita pre-requisito; app Vite sí (como PHP con su servidor Xdebug). 4) .d.ts NO se ejecuta (solo tipos).",
            "TS: fallo al correr directo con pwa-node = la app corre sobre Vite (browser), no sobre Node. Node no resuelve tipos ('PayloadAction') ni imports bundler. Levantá el proyecto (npm run dev) y usá Launch Chrome.",
          }
        end,
        typescriptreact = function()
          return {
            "Debug TSX (Vite/React): 1) PRIMERO levantá la app → `npm run dev` (o tu runner, ej. <leader>l s) — el debugger ataca el dev-server del bundler, que es quien tiene compilado el .tsx en memoria con sourcemaps; sin servidor no hay código que depurar (igual que PHP necesita su servidor Xdebug). 2) <leader>dc → elige 'Launch Chrome (React/Dev)' (:5173). 3) Solo en scripts JS sueltos (sin Vite/React) sirve 'Launch file' directo, es contexto, no otra config. 4) .d.ts = solo tipos, no es ejecutable.",
            "TSX: 'Cannot find module' / errores de runtime con pwa-node = esperado: esto es una app de browser con moduleResolution bundler. Node no la puede ejecutar sola. Levantá el proyecto (npm run dev) + Launch Chrome.",
          }
        end,
      }

      -- Devuelve el hint { comando, descripcion } para el filetype actual (o nil).
      -- Fuente UNICA: 1) build_hints del plugin principal; 2) native.lua;
      -- 3) modulos extras (bash, cobol, dart, ...) que exponen `get_hint()`.
      -- Asi cada lenguaje mantiene SU hint independiente pero <leader>dx/F8
      -- queda unificado (sin re-definiciones que se pisen entre si).
      local function get_build_hint()
        local maker = build_hints[vim.bo.filetype]
        if maker then
          return maker()
        end
        local extra_langs = {
          "bash",
          "cobol",
          "dart",
          "erlang",
          "haskell",
          "kotlin",
          "lua",
          "native",
          "ocaml",
          "perl",
          "ruby",
        }
        for _, lang in ipairs(extra_langs) do
          local ok_mod, mod = pcall(require, "nvim-dap." .. lang)
          if ok_mod and type(mod.get_hint) == "function" then
            local res = mod.get_hint(vim.bo.filetype)
            if res and type(res) == "table" and res[1] then
              return { res[1], res[2] or "Requiere build/requisito previo." }
            end
          end
        end
        return nil
      end

      -- Muestra la notificacion fallback con el comando/requsito correcto.
      -- Usa vim.notify normal (NO se sobrescribe vim.notify globalmente para no
      -- romper Noice; el aviso de Java/PHP se dispara desde preflight + hooks).
      local function notify_build_hint()
        local hint = get_build_hint()
        if not hint then
          return
        end
        local text = "\n" .. hint[2] .. "\n\n▶ " .. hint[1] .. "\n"
        vim.notify(text, vim.log.levels.WARN, { title = "nvim-dap: requiere build/requisito" })
        -- Intenta mostrar tambien como notificacion de sistema (notify-send)
        if vim.fn.executable("notify-send") == 1 then
          os.execute("notify-send -u normal 'nvim-dap: build hint' '" .. hint[1]:gsub("'", "") .. "' &")
        end
      end

      -- Hacer que <F5>/<leader>dc muestre el hint antes de lanzar si el
      -- artefacto no existe (fail-fast con aviso claro).
      -- 1) Rust/C/C++: si el binario no esta, avisar el comando de compilacion.
      -- 2) C#: si no hay .dll en bin/Debug, avisar dotnet build.
      -- 3) Java: avisar que requiere jdtls (bundle OSGi; ver extra LazyVim java).
      -- ⚠️ Definida ANTES de dap_continue_with_preflight: en Lua un `local
      -- function` solo es visible despues de su declaracion; llamarlo antes
      -- resolvia a un global nil -> E5108 "attempt to call global 'preflight_check'".
      -- ▸ AUTO-BUILD con confirmacion (F2)
      -- Cuando el artefacto (binario/.dll) no existe, <leader>dc ofrece
      -- compilar con el comando correcto y lanza el debug solo tras exito.
      -- c/cpp/rust → gcc/g++/rustc; cs → dotnet build; cobol → cobc.
      -- build_specs[ft] = function() -> nil | {
      --   missing = bool,          -- true si falta algo que compilar
      --   cmd = string,            -- comando shell para el build
      --   create_first = bool,     -- opcional: hay que generar proyecto (dotnet new)
      -- }
      -- Usa el NOMBRE real del buffer (no "main" hardcodeado) para que mida
      -- igual que find_executable() (build/<name>, o ./<name> en cobol).
      local function buffer_src_name()
        local src = vim.fn.fnamemodify(vim.fn.expand("%:t"), ":t")
        local name = vim.fn.fnamemodify(src, ":t:r")
        if name == "" then
          name = "main"
        end
        return src, name
      end

      local function has_files(patterns)
        for _, p in ipairs(patterns) do
          local matches = vim.fn.glob(buf_dir() .. "/" .. p, 0, 1)
          if type(matches) == "table" and #matches > 0 then
            return true
          end
        end
        return false
      end

      local build_specs = {
        cpp = function()
          local src, name = buffer_src_name()
          return {
            missing = vim.fn.filereadable(buf_dir() .. "/build/" .. name) ~= 1,
            cmd = "mkdir -p build && g++ -g -o build/" .. name .. " " .. src,
          }
        end,
        c = function()
          local src, name = buffer_src_name()
          return {
            missing = vim.fn.filereadable(buf_dir() .. "/build/" .. name) ~= 1,
            cmd = "mkdir -p build && gcc -g -o build/" .. name .. " " .. src,
          }
        end,
        rust = function()
          local src, name = buffer_src_name()
          return {
            missing = vim.fn.filereadable(buf_dir() .. "/build/" .. name) ~= 1,
            cmd = "mkdir -p build && rustc -g -o build/" .. name .. " " .. src,
          }
        end,
        cs = function()
          local has_proj = has_files({ "*.csproj", "*.sln" })
          if not has_proj then
            return {
              missing = true,
              create_first = true,
              cmd = "dotnet new console --use-program-main",
            }
          end
          local dlls = vim.fn.glob(buf_dir() .. "/bin/Debug/**/*.dll", 0, 1)
          local has_dll = type(dlls) == "table" and #dlls > 0
          return {
            missing = not has_dll,
            cmd = "dotnet build",
          }
        end,
        cobol = function()
          local src, name = buffer_src_name()
          return {
            missing = vim.fn.filereadable(buf_dir() .. "/" .. name) ~= 1,
            cmd = "cobc -g -o " .. name .. " " .. src,
          }
        end,
      }

      -- Continue con preflight: si falta compilar, pregunta con vim.ui.select.
      -- "Compilar y lanzar" corre el build (jobstart) y tras exit 0 lanza DAP;
      -- "Solo ver hint" muestra la guia; "Cancelar" no hace nada.
      -- En PHP ya NO se dispara xdg-open/aviso en cada continue (el evento
      -- `initialized` avisa una sola vez por sesion).
      local function dap_continue_with_preflight()
        local spec_maker = build_specs[vim.bo.filetype]
        local spec = spec_maker and spec_maker() or nil
        if spec and spec.missing then
          local label = spec.create_first and "Crear proyecto y lanzar" or "Compilar y lanzar"
          vim.ui.select({ label, "Solo ver hint", "Cancelar" }, {
            prompt = "[" .. vim.bo.filetype .. "] falta el artefacto de build",
          }, function(choice)
            if not choice or choice == "Cancelar" then
              return
            end
            if choice == "Solo ver hint" then
              notify_build_hint()
              return
            end
            vim.notify("▶ " .. spec.cmd, vim.log.levels.INFO, { title = "nvim-dap: build" })
            vim.fn.jobstart({ "sh", "-lc", spec.cmd }, {
              cwd = buf_dir(),
              on_exit = function(_, code)
                vim.schedule(function()
                  if code == 0 then
                    vim.notify("Build OK. Lanzando debug...", vim.log.levels.INFO, { title = "nvim-dap" })
                    dap.continue()
                  else
                    vim.notify(
                      "Build falló (exit " .. tostring(code) .. "): " .. spec.cmd,
                      vim.log.levels.ERROR,
                      { title = "nvim-dap: build" }
                    )
                    notify_build_hint()
                  end
                end)
              end,
            })
          end)
          return
        end
        dap.continue()
      end

      -- Hook: detectar errores de lanzamiento reales del adapter y mostrar el
      -- hint correcto. Cuando el binario no existe (codelldb: "is not a valid
      -- executable"), falta debugpy, o el adapter no responde, el evento
      -- "output" (stderr) lo reporta. Filtramos patrones conocidos por lenguaje.
      -- UN AVISO por sesion: sin esto, un continue que emite warnings (ej. PHP
      -- o Xdebug) re-dispara el hint en cada output = spam.
      local notified_on_session = {}
      dap.listeners.after.event["output"] = function(session, body)
        if not body or type(body) ~= "table" then
          return
        end
        local session_key = session and session.id or "anon"
        if notified_on_session[session_key] then
          return
        end
        local out = body.output or ""
        local ft = vim.bo.filetype
        local known = out:match("not a valid executable")
          or out:match("does not exist")
          or out:match("No module named ['\"]debugpy")
          or out:match("adapter didn't respond")
          or out:match("0x80070002")
          or out:match("No such file or directory")
        if known and build_hints[ft] then
          notified_on_session[session_key] = true
          notify_build_hint()
        end
      end

      -- PHP: al iniciar sesion tipo listen, recordar levantar el servidor con
      -- Xdebug ANTES de conectar y DISPARAR una request HTTP (si no, queda
      -- "Running Listen for Xdebug" sin respuesta). El hint aparece
      -- proactivamente en el evento initialized.
      dap.listeners.after.event["initialized"] = function()
        if vim.bo.filetype == "php" then
          vim.notify(
            "\nPHP: 'Listen for Xdebug' activo. Servidor + request HTTP:\n\n▶ " .. build_hints.php()[1],
            vim.log.levels.INFO,
            { title = "nvim-dap: PHP listen" }
          )
        end
      end

      -- Keymap global: <leader>dx siempre muestra el hint del lenguaje actual.
      -- (Complementa al <F8>; util si el usuario no uso <F8>.)
      vim.keymap.set("n", "<leader>dx", function()
        local hint = get_build_hint()
        if hint then
          vim.notify(
            "[" .. vim.bo.filetype .. "]\n\n" .. hint[2] .. "\n\n▶ " .. hint[1],
            vim.log.levels.INFO,
            { title = "nvim-dap: build hint" }
          )
        else
          vim.notify("Sin hint registrado para filetype: " .. vim.bo.filetype, vim.log.levels.INFO, {
            title = "nvim-dap",
          })
        end
      end, { desc = "DAP: mostrar hint de build/requisito" })

      -- Override <leader>dc y <leader>da (definidos arriba en keys) para que hagan
      -- preflight ANTES de lanzar. Sin wrappear vim.notify: preflight avisa lo que
      -- falta (compilar, o el bloqueo Java) antes de dejar que LazyVim/dap corra.
      vim.keymap.set("n", "<leader>dc", dap_continue_with_preflight, { desc = "DAP: continue" })
      vim.keymap.set("n", "<F9>", dap_continue_with_preflight, { desc = "DAP: continue" })

      -- Keymap manual para ver el hint de build del lenguaje actual.
      local function dap_hint_keymap()
        local hint = get_build_hint()
        if hint then
          vim.notify("[" .. vim.bo.filetype .. "]" .. "\n▶ " .. hint[1], vim.log.levels.INFO, {
            title = "nvim-dap: build hint",
          })
        else
          vim.notify("Sin hint registrado para filetype: " .. vim.bo.filetype, vim.log.levels.INFO, {
            title = "nvim-dap",
          })
        end
      end
      vim.keymap.set("n", "<F8>", dap_hint_keymap, { desc = "DAP: mostrar hint de build" })

      -- ══════════════════════════════════════════════════════════
      -- LENGUAJES ADICIONALES (Mason) — SEPARADOS EN lua/nvim-dap/
      -- Bash, COBOL, Dart, Haskell, Kotlin, Lua, Perl, Ruby, etc.
      -- Cada lenguaje en su propio modulo: lua/nvim-dap/<lenguaje>.lua
      -- ══════════════════════════════════════════════════════════
      local ok_extras, err_extras = pcall(require, "nvim-dap.extras")
      if not ok_extras then
        vim.notify(
          "nvim-dap/extras no cargó: " .. tostring(err_extras),
          vim.log.levels.ERROR,
          { title = "nvim-dap: extras" }
        )
      else
        err_extras.setup(dap) -- pcall: (true, module); el modulo va en el 2º retorno
      end
    end,
  },
}
