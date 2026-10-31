local uv = vim.uv or vim.loop

local PTD_REPOSITORIES = {
  "Cincinnatus-Institute-of-Craftsmanship/ptd-talento-back",
  "Cincinnatus-Institute-of-Craftsmanship/ptd-talento-front",
  "dizzi1222/ptd-talento-back",
  "dizzi1222/ptd-talento-front",
}

local function is_file(path)
  local stat = uv.fs_stat(path)
  return stat ~= nil and stat.type == "file"
end

local function ptd_repository(context)
  if not context.remote then
    return nil
  end
  for _, repository in ipairs(PTD_REPOSITORIES) do
    if context.remote:sub(-#repository) == repository then
      return repository
    end
  end
end

local function ptd_connections(context, helpers)
  local is_backend = ptd_repository(context):match("%-back$") ~= nil
  local candidates = is_backend and { vim.fs.joinpath(context.root, ".env") }
    or {
      vim.fs.joinpath(vim.fs.dirname(context.root), "ptd-talento-back", ".env"),
      vim.fn.expand("~/workspace/ptd-talento-back/.env"),
    }
  local env_file = vim.iter(candidates):find(is_file)
  if not env_file then
    error("Proyecto PTD detectado, pero no se encontró ptd-talento-back/.env")
  end

  local base, err = helpers.read_sql_env(env_file)
  if not base then
    error(err)
  end
  local prefix = base.database:gsub("%-dev$", "")
  local proxy_hint = string.format(
    "cloud-sql-proxy --address 127.0.0.1 --port %d cic-ptd-dev:us-east1:cic-ptd-dev",
    base.port
  )
  local environments = {
    { database = base.database, environment = "main", id = "main-sql", label = "MAIN / DEV · PostgreSQL" },
    { database = prefix .. "-qa", environment = "qa", id = "qa-sql", label = "QA · PostgreSQL" },
    { database = prefix .. "-prod", environment = "prod", id = "prod-sql", label = "PROD · PostgreSQL" },
  }

  return vim.tbl_map(function(environment)
    return vim.tbl_extend("force", environment, {
      adapter = "lazysql",
      env_file = base.env_file,
      host = "127.0.0.1",
      port = base.port,
      proxy_hint = proxy_hint,
      sslmode = "disable",
      username = base.username,
    })
  end, environments)
end

return {
  {
    "dizzi1222/dbtui.nvim",
    lazy = false,
    config = function()
      require("dbtui").setup({
        keymap = "<leader>gz",
        language = "es",
        profiles = {
          {
            connections = ptd_connections,
            match = function(context)
              return ptd_repository(context) ~= nil
            end,
            name = "PTD Talento",
          },
        },
      })
    end,
  },
}
