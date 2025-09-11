-- Minimal state for additive updates
local RA_STATE = {
  target = nil,       -- e.g. "wasm32-unknown-unknown"
  features = {},      -- set-like table: { ["feature-name"]=true, ... }
  no_default = false, -- toggle --no-default-features
}

local function features_list()
  local out = {}
  for k, v in pairs(RA_STATE.features) do
    if v then table.insert(out, k) end
  end
  table.sort(out)
  return out
end

-- Build rust-analyzer settings from state and apply
local function apply_ra()
  -- Build feature list from your RA_STATE
  local feats = features_list()

  -- Build the settings we want to apply
  local new_settings = {
    ["rust-analyzer"] = {
      cargo = {
        target = RA_STATE.target,
        noDefaultFeatures = RA_STATE.no_default,
        features = feats,
        buildScripts = { enable = true },
      },
      check = {
        command = "clippy", -- or "check"
        extraArgs = (function()
          local extra = {}
          if RA_STATE.target and #RA_STATE.target > 0 then
            table.insert(extra, "--target"); table.insert(extra, RA_STATE.target)
          end
          if RA_STATE.no_default then
            table.insert(extra, "--no-default-features")
          end
          if #feats > 0 then
            table.insert(extra, "--features"); table.insert(extra, table.concat(feats, ","))
          end
          return extra
        end)(),
      },
      procMacro = { enable = true },
    },
  }

  -- Get active rust-analyzer clients (NVIM 0.10+ API first, then fallback)
  local clients = (vim.lsp.get_clients and vim.lsp.get_clients({ name = "rust_analyzer" }))
      or (function()
        local acc = {}
        for _, c in ipairs(vim.lsp.get_active_clients()) do
          if c.name == "rust_analyzer" then table.insert(acc, c) end
        end
        return acc
      end)()

  if #clients == 0 then
    vim.notify("rust-analyzer LSP client not found (is it started?)", vim.log.levels.WARN)
    return
  end

  -- Apply to all rust-analyzer clients
  for _, client in ipairs(clients) do
    -- Merge with existing settings so we don't clobber unrelated config
    client.config.settings = vim.tbl_deep_extend(
      "force",
      client.config.settings or {},
      new_settings
    )
    -- Notify rust-analyzer the settings changed
    client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
  end

  vim.notify(
    ("rust-analyzer: target=%s  features=[%s]  no_default=%s")
    :format(RA_STATE.target or "∅", table.concat(feats, ","), tostring(RA_STATE.no_default)),
    vim.log.levels.INFO
  )
end


local function get_cargo_features()
  -- Fast and sufficient for listing features
  local out = vim.fn.system({ "cargo", "metadata", "--no-deps", "--format-version", "1" })
  if vim.v.shell_error ~= 0 then
    vim.notify("cargo metadata failed", vim.log.levels.ERROR)
    return nil
  end

  local ok, meta = pcall(vim.json.decode, out)
  if not ok then
    vim.notify("failed to parse cargo metadata JSON", vim.log.levels.ERROR)
    return nil
  end

  local packages = meta.packages or {}
  local pkg ---@type table|nil

  -- 1) Prefer resolve.root when present
  if meta.resolve and meta.resolve ~= vim.NIL and meta.resolve.root and meta.resolve.root ~= vim.NIL then
    local root_id = meta.resolve.root
    for _, p in ipairs(packages) do
      if p.id == root_id then
        pkg = p; break
      end
    end
  end

  -- 2) Otherwise, try to match the package whose manifest lives at <workspace_root>/Cargo.toml
  if not pkg then
    local ws_root = meta.workspace_root
    if ws_root and ws_root ~= vim.NIL then
      -- simple dirname helper (works on POSIX-style paths used by cargo output)
      local function dirname(path) return path:match("^(.*)/[^/]+$") end
      for _, p in ipairs(packages) do
        local dir = p.manifest_path and dirname(p.manifest_path)
        if dir == ws_root then
          pkg = p; break
        end
      end
    end
  end

  -- 3) If the workspace has exactly one member, use it
  if not pkg and meta.workspace_members and #meta.workspace_members == 1 then
    local only_id = meta.workspace_members[1]
    for _, p in ipairs(packages) do
      if p.id == only_id then
        pkg = p; break
      end
    end
  end

  -- 4) Something is wrong, we can't find a root package
  if not pkg then
    vim.notify(
      "Could not determine workspace root package from cargo metadata",
      vim.log.levels.ERROR
    )
    return {}, {}
  end

  -- Collect features
  local list = {}
  for feat, _ in pairs(pkg.features or {}) do
    table.insert(list, feat)
  end
  table.sort(list)

  local defaults = (pkg.features and pkg.features.default) or {}
  return list, defaults, pkg.name
end

-- Telescope picker
function pick_cargo_features_with_telescope()
  local feats, defaults = get_cargo_features()
  if not feats then return end

  local ok, _ = pcall(require, "telescope")
  if not ok then
    vim.notify("telescope.nvim not found", vim.log.levels.ERROR)
    return
  end

  local pickers      = require("telescope.pickers")
  local finders      = require("telescope.finders")
  local conf         = require("telescope.config").values
  local actions      = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = "Cargo features",
    initial_mode = "normal",
    finder = finders.new_table({
      results = feats,
      entry_maker = function(f)
        return {
          value = f,
          display = f,
          ordinal = f,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local function accept()
        local picker = action_state.get_current_picker(prompt_bufnr)
        local sel = picker:get_multi_selection()

        -- If nothing was toggled, take the currently highlighted entry
        if #sel == 0 then
          local one = action_state.get_selected_entry()
          if one then sel = { one } end
        end

        -- Reset & set chosen features
        RA_STATE.features = {}
        for _, e in ipairs(sel) do
          RA_STATE.features[e.value] = true
        end
        apply_ra()
        actions.close(prompt_bufnr)
      end

      map("i", "<CR>", accept)
      map("n", "<CR>", accept)

      -- Multi-select UX
      map("i", "<Tab>", function()
        actions.toggle_selection(prompt_bufnr)
        actions.move_selection_next(prompt_bufnr)
      end)
      map("i", "<S-Tab>", function()
        actions.toggle_selection(prompt_bufnr)
        actions.move_selection_previous(prompt_bufnr)
      end)
      map("n", "<Tab>", actions.toggle_selection)
      map("n", "<S-Tab>", actions.toggle_selection)

      return true
    end,
  }):find()
end

-- Commands (additive / subtractive)
vim.api.nvim_create_user_command("RustSetTarget", function(opts)
  RA_STATE.target = (opts.args ~= "" and opts.args) or nil
  apply_ra()
end, { nargs = "?" })

vim.api.nvim_create_user_command("RustAddFeature", function(opts)
  for feat in opts.args:gmatch("%S+") do RA_STATE.features[feat] = true end
  apply_ra()
end, { nargs = "+" })

vim.api.nvim_create_user_command("RustRemoveFeature", function(opts)
  for feat in opts.args:gmatch("%S+") do RA_STATE.features[feat] = nil end
  apply_ra()
end, { nargs = "+" })

vim.api.nvim_create_user_command("RustClearFeatures", function()
  RA_STATE.features = {}
  apply_ra()
end, {})

vim.api.nvim_create_user_command("RustNoDefaultFeatures", function(opts)
  local v = opts.args:lower()
  if v == "on" or v == "true" or v == "1" then
    RA_STATE.no_default = true
  elseif v == "off" or v == "false" or v == "0" then
    RA_STATE.no_default = false
  else
    vim.notify("Usage: :RustNoDefaultFeatures on|off", vim.log.levels.WARN)
    return
  end
  apply_ra()
end, { nargs = 1, complete = function() return { "on", "off" } end })

-- Expose a command
vim.api.nvim_create_user_command("CargoFeatures", function()
  pick_cargo_features_with_telescope()
end, {})

-- AUTOCOMMANDS

-- Autoformat on save using LSP
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})
