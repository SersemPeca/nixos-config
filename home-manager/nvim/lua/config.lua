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

-- one-line Lua literal (no newlines/indent), not JSON
local function to_oneline_lua(tbl)
  return vim.inspect(tbl, { newline = "", indent = "" })
end

local function ra_apply_config(bufnr, ra_payload)
  bufnr = bufnr or 0

  -- 0) sanity checks
  if vim.fn.exists(":RustAnalyzer") ~= 2 then
    return vim.notify("RustAnalyzer command not found (is rustaceanvim loaded?)", vim.log.levels.ERROR)
  end
  if vim.fn.bufexists(bufnr) ~= 1 then
    return vim.notify(("Buffer %d does not exist"):format(bufnr), vim.log.levels.ERROR)
  end
  local ra_clients = vim.lsp.get_clients({ bufnr = bufnr, name = "rust-analyzer" })
  if #ra_clients == 0 then
    return vim.notify(("rust-analyzer not attached to buffer %d"):format(bufnr), vim.log.levels.WARN)
  end

  -- 1) build & validate the table string we'll pass to the command
  local lua_tbl = ra_payload
  if lua_tbl:find("[\r\n]") then
    return vim.notify("RustAnalyzer config table contains newline(s): " .. lua_tbl, vim.log.levels.ERROR)
  end
  local ok_eval = pcall(vim.fn.luaeval, lua_tbl)
  if not ok_eval then
    return vim.notify("Invalid Lua table for RustAnalyzer config: " .. lua_tbl, vim.log.levels.ERROR)
  end

  -- 2) run in a *window* that shows the buffer (buf_call alone can be ignored by plugins)
  local cmdline = "noautocmd RustAnalyzer config " .. lua_tbl
  local win = vim.fn.bufwinid(bufnr)
  local created = false
  if win == -1 then
    -- create a tiny throwaway float so we get a real window context
    win = vim.api.nvim_open_win(bufnr, false, {
      relative = "editor",
      row = 0,
      col = 0,
      width = 1,
      height = 1,
      style = "minimal",
      focusable = false,
      zindex = 200,
    })
    created = true
  end

  local ok_cmd, err = pcall(vim.api.nvim_win_call, win, function()
    -- Important: use the *string* form (no structured args, which would quote your table)
    vim.cmd(cmdline)
  end)

  if created then pcall(vim.api.nvim_win_close, win, true) end

  if ok_cmd then
    return
  end

  -- 3) fallback: update the attached RA clients directly (per-buffer)
  vim.notify("RustAnalyzer config failed via command, falling back to LSP: " .. tostring(err), vim.log.levels.WARN)
  for _, client in ipairs(ra_clients) do
    local merged = vim.tbl_deep_extend("force", client.config.settings or {}, {
      ["rust-analyzer"] = ra_payload,
    })
    client.config.settings = merged
    client.notify("workspace/didChangeConfiguration", { settings = merged })
  end
end

-- Build rust-analyzer settings from state and apply
local function apply_ra(bufnr)
  bufnr = bufnr or 0

  local feats = features_list()

  -- INNER table (what :RustAnalyzer config expects)
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

  -- Prefer the command when available
  if vim.fn.exists(":RustAnalyzer") == 2 then
    -- one-line Lua literal (no newlines/indent)
    local lua_tbl = vim.inspect(ra_payload, { newline = "", indent = "" })

    -- Optional: validate we produced a parseable Lua table before calling the command
    local ok_eval, _ = pcall(vim.fn.luaeval, lua_tbl)
    if not ok_eval then
      vim.notify("RustAnalyzer: produced an invalid Lua table: " .. lua_tbl, vim.log.levels.ERROR)
      return
    end

    print(lua_tbl)
    print(bufnr)

    -- vim.api.nvim_buf_call(bufnr, function()
    --   vim.cmd("RustAnalyzer config " .. lua_tbl)
    -- end)

    ra_apply_config(bufnr, lua_tbl)

    -- structured form avoids weird parsing/escaping
    if not ok_cmd then
      vim.notify("RustAnalyzer config failed: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
  else
    -- Fallback: raw LSP notify on attached rust-analyzer clients for this buffer
    local ra_clients = vim.lsp.get_clients({ bufnr = bufnr, name = "rust-analyzer" })
    if #ra_clients == 0 then
      vim.notify("rust-analyzer not attached to this buffer", vim.log.levels.WARN)
      return
    end
    local merged_wrapper
    for _, client in ipairs(ra_clients) do
      merged_wrapper = vim.tbl_deep_extend(
        "force",
        client.config.settings or {},
        { ["rust-analyzer"] = ra_payload } -- wrapper only for LSP
      )
      client.config.settings = merged_wrapper
      client.notify("workspace/didChangeConfiguration", { settings = merged_wrapper })
    end
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
  local bufnr = vim.api.nvim_get_current_buf()

  -- Check if we're being called from a buffer which has rust-analyzer attached to it
  if #vim.lsp.get_clients({ bufnr = bufnr, name = "rust-analyzer" }) == 0 then
    vim.notify("CargoFeatures: run this from a Rust buffer with rust-analyzer attached", vim.log.levels.WARN)
    return
  end

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
        apply_ra(bufnr)
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
