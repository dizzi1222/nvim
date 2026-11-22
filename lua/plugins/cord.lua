-- local website = "https://ghaerdi.mod.land"
local website = "https://github.com/dizzi1222"
local blacklist = {
  "nectar",
  "server",
  "web",
}

local is_blacklisted = function(opts)
  return vim.tbl_contains(blacklist, opts.workspace)
end

local function get_ai_agent_info()
  local term_title = (vim.b.term_title or ""):lower()

  local agents = {
    opencode = {
      match = "opencode",
      text = "󰮮  OpenCode",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/opencode-dark.svg",
      tooltip = "OpenCode AI Agent",
    },
    copilot = {
      match = "copilot",
      text = "  Copilot",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/github-copilot.svg",
      tooltip = "GitHub Copilot",
    },
    avante = {
      match = "avante",
      text = "  Avante",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/avante.svg",
      tooltip = "Avante.nvim",
    },
    claude = {
      match = "claude",
      text = "  Claude Code",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/anthropic-claude.svg",
      tooltip = "Claude Code",
    },
    gemini = {
      match = "gemini",
      text = "󰊭  Gemini CLI",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/google-gemini.svg",
      tooltip = "Gemini CLI",
    },
    zed = {
      match = "zed",
      text = "󱃖  Zed",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/zed-industries.svg",
      tooltip = "Zed Editor",
    },
    cursor = {
      match = "cursor",
      text = "󰚩  Cursor",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/cursor.svg",
      tooltip = "Cursor IDE",
    },
    aider = {
      match = "aider",
      text = "󰚩  Aider",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/aider.svg",
      tooltip = "Aider",
    },
    codex = {
      match = "codex",
      text = "󱚡  Codex",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/openai-codex.svg",
      tooltip = "OpenAI Codex",
    },
    codecompanion = {
      match = "codecompanion",
      text = "  CodeCompanion",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/codecompanion.svg",
      tooltip = "CodeCompanion.nvim",
    },
    openclaw = {
      match = "openclaw",
      text = "󰧑  OpenClaw",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/openclaw.svg",
      tooltip = "OpenClaw",
    },
    windsurf = {
      match = "windsurf",
      text = "  Windsurf",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/windsurf.svg",
      tooltip = "Windsurf (Codeium)",
    },
    tabnine = {
      match = "tabnine",
      text = "  TabNine",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/tabnine.svg",
      tooltip = "TabNine",
    },
    fittencode = {
      match = "fittencode",
      text = "  FittenCode",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/fittencode.svg",
      tooltip = "FittenCode",
    },
    aichat = {
      match = "aichat",
      text = "󰚩  AIChat",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/aichat.svg",
      tooltip = "AIChat",
    },
    tgpt = {
      match = "tgpt",
      text = "󰚩  tgpt",
      icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/chatgpt.svg",
      tooltip = "tgpt (ChatGPT)",
    },
  }

  for key, agent in pairs(agents) do
    if term_title:match(agent.match) then
      return agent
    end
  end

  return nil
end

return {
  "vyfor/cord.nvim",
  build = function(plugin)
    pcall(vim.cmd, "Cord update")
    require("dizzi.cord_patch").patch_cord(plugin.dir or plugin.to)
  end,
  event = "VeryLazy",
  init = function()
    -- defer_startup: conecta al primer evento UI en vez de al import (igual auto-conecta).
    -- Cord es el UNICO RP activo; presence esta en plugins/disabled/ con enabled=false.
    vim.g.cord_defer_startup = true

    -- Limpiar el patch antes de que Lazy chequee git status / haga checkout,
    -- y re-aplicarlo automáticamente al terminar update/sync/check/restore.
    local aug = vim.api.nvim_create_augroup("dizzi_cord_patch_sync", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      group = aug,
      pattern = { "LazyUpdatePre", "LazySyncPre", "LazyRestorePre", "LazyCheckPre" },
      callback = function()
        pcall(function()
          require("dizzi.cord_patch").unpatch_cord()
        end)
      end,
    })
    vim.api.nvim_create_autocmd("User", {
      group = aug,
      pattern = { "LazyUpdate", "LazySync", "LazyRestore", "LazyCheck" },
      callback = function()
        pcall(function()
          require("dizzi.cord_patch").patch_cord()
        end)
      end,
    })
  end,
  opts = function()
    return {
      editor = {
        client = "793271441293967371", -- Official Neovim Discord app ID
      },
      display = {
        theme = "default",
        flavor = "dark",
      },
      idle = {
        details = function(opts)
          local ws = opts.workspace_dir or opts.workspace or "Neovim"
          return string.format("Taking a break from %s", ws)
        end,
      },
      text = {
        terminal = function(opts)
          local agent = get_ai_agent_info()
          if agent then
            return agent.text
          end
          local term_title = vim.b.term_title or ""
          return term_title ~= "" and ("  " .. term_title) or "  Terminal"
        end,
        viewing = function(opts)
          return is_blacklisted(opts) and "Viewing a file" or ("Viewing " .. opts.filename)
        end,
        editing = function(opts)
          return is_blacklisted(opts) and "Editing a file" or ("Editing " .. opts.filename)
        end,
        workspace = function(opts)
          local hour = tonumber(os.date("%H"))
          local status = hour >= 22 and "Late night coding"
            or hour >= 18 and "Evening session"
            or hour >= 12 and "Afternoon coding"
            or hour >= 5 and "Morning productivity"
            or "Midnight hacking"

          return is_blacklisted(opts) and status or opts.workspace
        end,
      },
      buttons = {
        {
          label = function(opts)
            return opts.repo_url and "View Repository" or "My Website"
          end,
          url = function(opts)
            if is_blacklisted(opts) then
              return website
            end
            return opts.repo_url or website
          end,
        },
      },
      hooks = {
        post_activity = function(opts, activity)
          local agent = get_ai_agent_info()
          if agent and opts.buftype == "terminal" then
            activity.assets = activity.assets or {}
            activity.assets.large_image = agent.icon
            activity.assets.large_text = agent.tooltip
          end
        end,
      },
    }
  end,
}

