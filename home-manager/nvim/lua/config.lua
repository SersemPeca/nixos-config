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

-- Build rust-analyzer settings from state and apply to the client(s) attached to bufnr
local function apply_ra(bufnr)
  bufnr = bufnr or 0

  local feats = features_list()

  local ra_payload = {
    cargo = {
      target = RA_STATE.target,
      noDefaultFeatures = RA_STATE.no_default,
      features = feats,
      buildScripts = { enable = true },
    },
    check = {
      command = "clippy",
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
  }

  -- Find only the rust-analyzer client(s) attached to this buffer
  local attached = vim.lsp.get_clients({ bufnr = bufnr })
  local ra_clients = {}
  for _, c in ipairs(attached) do
    if c.name == "rust_analyzer" or c.name == "rust-analyzer" then
      table.insert(ra_clients, c)
    end
  end
  if #ra_clients == 0 then
    vim.notify(("rust-analyzer not attached to buffer %d (see :LspInfo)"):format(bufnr), vim.log.levels.WARN)
    return
  end

  for _, client in ipairs(ra_clients) do
    if not (client.is_stopped and client:is_stopped()) then
      -- Merge inside the rust-analyzer section so we don't clobber unrelated subkeys
      local existing_ra      = ((client.config and client.config.settings) or {})["rust-analyzer"] or {}
      local merged_ra        = vim.tbl_deep_extend("force", existing_ra, ra_payload)

      -- Write into Neovim's config stores used to answer workspace/configuration
      client.config          = client.config or {}
      client.config.settings = vim.tbl_deep_extend("force", client.config.settings or {},
        { ["rust-analyzer"] = merged_ra })

      -- Some Neovim versions also consult client.settings
      client.settings        = vim.tbl_deep_extend("force", client.settings or {}, { ["rust-analyzer"] = merged_ra })

      -- IMPORTANT: many servers ignore the payload here and re-query via workspace/configuration.
      -- Send an empty object to force a refresh from client.(config.)settings.
      client.notify("workspace/didChangeConfiguration", { settings = vim.empty_dict() })
    end
  end

  vim.notify(
    ("rust-analyzer (buf %d): target=%s  features=[%s]  no_default=%s")
    :format(bufnr, RA_STATE.target or "∅", table.concat(feats, ","), tostring(RA_STATE.no_default)),
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


-- Telescope picker with checkboxes + proper multi-select
function pick_cargo_features_with_telescope()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Ensure RA is attached (accept both names)
  local has_ra = false
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if c.name == "rust_analyzer" or c.name == "rust-analyzer" then
      has_ra = true; break
    end
  end
  if not has_ra then
    vim.notify("CargoFeatures: run this from a Rust buffer with rust-analyzer attached", vim.log.levels.WARN)
    return
  end

  local feats, defaults = get_cargo_features()
  if not feats then return end

  local ok = pcall(require, "telescope")
  if not ok then
    vim.notify("telescope.nvim not found", vim.log.levels.ERROR)
    return
  end

  local pickers       = require("telescope.pickers")
  local finders       = require("telescope.finders")
  local conf          = require("telescope.config").values
  local actions       = require("telescope.actions")
  local action_state  = require("telescope.actions.state")
  local entry_display = require("telescope.pickers.entry_display")

  local defaults_set  = {}
  for _, d in ipairs(defaults or {}) do defaults_set[d] = true end

  local displayer = entry_display.create({
    separator = " ",
    items = {
      { width = 3 },        -- [x]/[ ]
      { remaining = true }, -- feature name + (default) tag
    },
  })

  local function entry_maker(f)
    local enabled = RA_STATE.features[f] == true
    local is_default = defaults_set[f] == true
    return {
      value = f,
      ordinal = f,
      enabled = enabled,
      is_default = is_default,
      display = function(entry)
        local box = entry.enabled and "[x]" or "[ ]"
        local name = entry.value .. (entry.is_default and "  (default)" or "")
        return displayer {
          { box, entry.enabled and "TelescopeResultsIdentifier" or "TelescopeResultsComment" },
          name,
        }
      end,
    }
  end

  local function make_finder()
    return finders.new_table({
      results = feats,
      entry_maker = entry_maker,
    })
  end

  local function sync_from_picker(picker, prompt_bufnr)
    local selected = picker:get_multi_selection()
    if #selected == 0 then
      local one = action_state.get_selected_entry()
      if one then selected = { one } end
    end
    RA_STATE.features = {}
    for _, e in ipairs(selected) do
      RA_STATE.features[e.value] = true
    end
    picker:refresh(make_finder(), { reset_prompt = false })
  end

  pickers.new({}, {
    prompt_title = "Cargo features",
    initial_mode = "normal",
    finder = make_finder(),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local picker = action_state.get_current_picker(prompt_bufnr)

      local function toggle_and_sync(next_fn)
        actions.toggle_selection(prompt_bufnr)
        sync_from_picker(picker, prompt_bufnr)
        if next_fn then next_fn(prompt_bufnr) end
      end

      local function accept()
        sync_from_picker(picker, prompt_bufnr)
        apply_ra(bufnr)
        actions.close(prompt_bufnr)
      end

      map("i", "<CR>", accept)
      map("n", "<CR>", accept)

      map("i", "<Tab>", function() toggle_and_sync(actions.move_selection_next) end)
      map("i", "<S-Tab>", function() toggle_and_sync(actions.move_selection_previous) end)
      map("n", "<Tab>", function() toggle_and_sync() end)
      map("n", "<S-Tab>", function() toggle_and_sync() end)

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

-- Get available Rust targets (prefer installed ones; fall back to full list)
local function get_cargo_targets()
  -- 1) rustup installed targets (fast, likely what you care about)
  local ok1, lines1 = pcall(vim.fn.systemlist, { "rustup", "target", "list", "--installed" })
  if ok1 and lines1 and vim.v.shell_error == 0 and #lines1 > 0 then
    local t = {}
    for _, l in ipairs(lines1) do
      local s = vim.trim(l)
      if #s > 0 then table.insert(t, s) end
    end
    table.sort(t)
    return t
  end

  -- 2) fallback: ask rustc for all known targets
  local ok2, lines2 = pcall(vim.fn.systemlist, { "rustc", "--print", "target-list" })
  if ok2 and lines2 and vim.v.shell_error == 0 and #lines2 > 0 then
    local t = {}
    for _, l in ipairs(lines2) do
      local s = vim.trim(l)
      if #s > 0 then table.insert(t, s) end
    end
    table.sort(t)
    return t
  end

  -- 3) last resort: a tiny curated list so the picker still works
  return {
    "x86_64-unknown-linux-gnu",
    "aarch64-unknown-linux-gnu",
    "x86_64-apple-darwin",
    "aarch64-apple-darwin",
    "wasm32-unknown-unknown",
  }
end

-- Telescope picker: choose a target triple (single select)
function pick_cargo_targets_with_telescope()
  local bufnr = vim.api.nvim_get_current_buf()

  -- Ensure rust-analyzer is attached to this buffer
  local has_ra = false
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if c.name == "rust_analyzer" or c.name == "rust-analyzer" then
      has_ra = true; break
    end
  end
  if not has_ra then
    vim.notify("CargoTargets: run this from a Rust buffer with rust-analyzer attached", vim.log.levels.WARN)
    return
  end

  local targets = get_cargo_targets()
  if not targets or #targets == 0 then
    vim.notify("No Rust targets found (rustup/rustc not available?)", vim.log.levels.ERROR)
    return
  end

  local ok = pcall(require, "telescope")
  if not ok then
    vim.notify("telescope.nvim not found", vim.log.levels.ERROR)
    return
  end

  local pickers       = require("telescope.pickers")
  local finders       = require("telescope.finders")
  local conf          = require("telescope.config").values
  local actions       = require("telescope.actions")
  local action_state  = require("telescope.actions.state")
  local entry_display = require("telescope.pickers.entry_display")

  -- Simple radio bullet UI: (•) for current target, ( ) otherwise
  local displayer     = entry_display.create({
    separator = " ",
    items = {
      { width = 3 },        -- (•) / ( )
      { remaining = true }, -- target triple
    },
  })

  local function entry_maker(t)
    local selected = (RA_STATE.target == t)
    return {
      value = t,
      ordinal = t,
      display = function()
        local bullet = selected and "(•)" or "( )"
        return displayer {
          { bullet, selected and "TelescopeResultsIdentifier" or "TelescopeResultsComment" },
          t,
        }
      end,
    }
  end

  local function make_finder()
    return finders.new_table({
      results = targets,
      entry_maker = entry_maker,
    })
  end

  pickers.new({}, {
    prompt_title = "Cargo targets",
    initial_mode = "normal",
    finder = make_finder(),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local picker = action_state.get_current_picker(prompt_bufnr)

      local function accept()
        local e = action_state.get_selected_entry()
        if e then
          RA_STATE.target = e.value
          apply_ra(bufnr)
        end
        actions.close(prompt_bufnr)
      end

      -- Enter = set target & apply
      map("i", "<CR>", accept)
      map("n", "<CR>", accept)

      -- Optional: <C-c> to clear target (host default)
      map("i", "<C-c>", function()
        RA_STATE.target = nil
        apply_ra(bufnr)
        actions.close(prompt_bufnr)
      end)
      map("n", "<C-c>", function()
        RA_STATE.target = nil
        apply_ra(bufnr)
        actions.close(prompt_bufnr)
      end)

      return true
    end,
  }):find()
end

-- Command to open the targets picker
vim.api.nvim_create_user_command("CargoTargets", function()
  pick_cargo_targets_with_telescope()
end, {})


-- AUTOCOMMANDS

-- Autoformat on save using LSP
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function()
    vim.lsp.buf.format({ async = false })
  end,
})
