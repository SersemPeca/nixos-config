local M = {}

-- Helper: read features from cargo metadata
function M.get_cargo_features()
  -- Neovim 0.9: use vim.fn.system; Neovim 0.10+: use vim.system
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

  -- Heuristic: prefer the workspace root package if present; otherwise first package
  local pkg
  if meta.resolve and meta.resolve.root then
    local root_id = meta.resolve.root
    for _, p in ipairs(meta.packages or {}) do
      if p.id == root_id then
        pkg = p; break
      end
    end
  end
  pkg = pkg or (meta.packages and meta.packages[1])
  if not pkg then return {} end

  -- pkg.features is a map: name -> array of feature deps
  local list = {}
  for feat, _ in pairs(pkg.features or {}) do
    table.insert(list, feat)
  end
  table.sort(list)
  return list, (pkg.features and pkg.features.default) or {}
end

-- Telescope picker
function M.pick_cargo_features_with_telescope()
  local feats, defaults = get_cargo_features()
  if not feats then return end
  local has_telescope, telescope = pcall(require, "telescope")
  if not has_telescope then
    vim.notify("telescope.nvim not found", vim.log.levels.ERROR)
    return
  end
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers.new({}, {
    prompt_title = "Cargo features",
    finder = finders.new_table({
      results = feats,
      entry_maker = function(f)
        return {
          value = f,
          display = f,
          ordinal = f,
          -- mark defaults visually
          -- (Telescope doesn't render hl here by default, but you can customize)
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      local function accept()
        local sel = action_state.get_multi_selection()
        if #sel == 0 then sel = { action_state.get_selected_entry() } end
        -- reset & set features chosen
        RA_STATE.features = {}
        for _, e in ipairs(sel) do RA_STATE.features[e.value] = true end
        apply_ra()
        actions.close(prompt_bufnr)
      end
      map("i", "<CR>", accept)
      map("n", "<CR>", accept)
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

-- Expose a command
vim.api.nvim_create_user_command("CargoFeatures", function()
  pick_cargo_features_with_telescope()
end, {})

return M
