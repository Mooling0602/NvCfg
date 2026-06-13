local function dms_debug()
  local base46 = require("base46")
  local mode = vim.fn.system({ "dms", "ipc", "call", "theme", "getMode" }):gsub("%s+", "")
  local dms_ok = vim.fn.filereadable(vim.fn.stdpath("config") .. "/colors/dms.lua") == 1
  local hl = vim.api.nvim_get_hl(0, { name = "Normal" })
  vim.print("--- DMS debug ---")
  vim.print("DMS mode:     " .. mode)
  vim.print("vim.o.bg:     " .. vim.o.background)
  vim.print("colors_name:  " .. (vim.g.colors_name or "nil"))
  vim.print("transparency: " .. tostring(base46.opts.transparency))
  vim.print("dms.lua:      " .. (dms_ok and "found" or "missing"))
  vim.print("Normal.bg:    " .. tostring(hl.bg))
  vim.print("---")
end
vim.api.nvim_create_user_command("DmsDebug", dms_debug, {})

local function fix_popup_colors()
  local base46 = require("base46")
  local theme = base46.theme_tables["dms"]
  if not theme then return end
  local c = theme.base_30
  local popup_bg = c.black
  local border_fg = c.line

  vim.api.nvim_set_hl(0, "DmsFloatBackdrop", { bg = "#000000" })
  vim.api.nvim_set_hl(0, "LazyBackdrop", { bg = "#000000" })
  vim.api.nvim_set_hl(0, "MasonBackdrop", { bg = "#000000" })

  for _, group in ipairs({
    "NormalFloat",
    "LazyNormal",
    "MasonNormal",
    "Pmenu",
    "CmpDoc",
    "CmpPmenu",
    "BlinkCmpDoc",
    "BlinkCmpMenu",
    "BlinkCmpSignatureHelp",
    "TelescopeNormal",
    "TelescopePrompt",
    "TelescopeResults",
    "TelescopePreview",
  }) do
    vim.api.nvim_set_hl(0, group, { bg = popup_bg })
  end

  -- Floating window borders
  vim.api.nvim_set_hl(0, "FloatBorder",           { fg = border_fg, bg = popup_bg })
  vim.api.nvim_set_hl(0, "TelescopeBorder",       { fg = border_fg, bg = popup_bg })
  vim.api.nvim_set_hl(0, "TelescopePromptBorder", { fg = border_fg, bg = popup_bg })
  vim.api.nvim_set_hl(0, "TelescopeResultsBorder",{ fg = border_fg, bg = popup_bg })
  vim.api.nvim_set_hl(0, "CmpDocBorder",          { fg = border_fg, bg = popup_bg })
  vim.api.nvim_set_hl(0, "BlinkCmpDocBorder",     { fg = border_fg, bg = popup_bg })
  vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder",    { fg = border_fg, bg = popup_bg })
  vim.api.nvim_set_hl(0, "NotifyBorder",          { fg = border_fg, bg = popup_bg })
end

local float_backdrop = { buf = nil, win = nil }

local float_backdrop_filetypes = {
  lazy = true,
  mason = true,
  TelescopePrompt = true,
}

local function get_win_highlight(win)
  return vim.api.nvim_get_option_value("winhighlight", { win = win })
end

local function is_float_backdrop_target(win)
  if win == float_backdrop.win then return false end
  if not vim.api.nvim_win_is_valid(win) then return false end

  local config = vim.api.nvim_win_get_config(win)
  if config.relative == "" then return false end

  local buf = vim.api.nvim_win_get_buf(win)
  if float_backdrop_filetypes[vim.bo[buf].filetype] then return true end

  local winhighlight = get_win_highlight(win)
  return winhighlight:find("LazyNormal", 1, true) ~= nil
    or winhighlight:find("MasonNormal", 1, true) ~= nil
    or winhighlight:find("Telescope", 1, true) ~= nil
end

local function close_float_backdrop()
  local win = float_backdrop.win
  local buf = float_backdrop.buf
  float_backdrop.win = nil
  float_backdrop.buf = nil

  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
  end
  if buf and vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
end

local function open_float_backdrop(zindex)
  local height = math.max(1, vim.o.lines)
  local width = math.max(1, vim.o.columns)

  if float_backdrop.win and vim.api.nvim_win_is_valid(float_backdrop.win) then
    vim.api.nvim_win_set_config(float_backdrop.win, {
      relative = "editor",
      width = width,
      height = height,
      row = 0,
      col = 0,
      zindex = zindex,
    })
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    width = width,
    height = height,
    row = 0,
    col = 0,
    style = "minimal",
    focusable = false,
    border = "none",
    zindex = zindex,
    noautocmd = true,
  })

  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "dms_float_backdrop"
  vim.wo[win].winhighlight = "Normal:DmsFloatBackdrop"
  vim.wo[win].winblend = 75

  float_backdrop.buf = buf
  float_backdrop.win = win
end

local function refresh_float_backdrop()
  local zindex
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if is_float_backdrop_target(win) then
      local config = vim.api.nvim_win_get_config(win)
      local target_zindex = config.zindex or 50
      zindex = zindex and math.min(zindex, target_zindex - 1) or (target_zindex - 1)
    end
  end

  if not zindex then
    close_float_backdrop()
    return
  end

  open_float_backdrop(math.max(1, zindex))
end

local function schedule_float_backdrop_refresh()
  vim.schedule(function()
    pcall(refresh_float_backdrop)
  end)
end

local function fix_tabline_colors()
  local base46 = require("base46")
  local theme = base46.theme_tables["dms"]
  if not theme then return end
  local c = theme.base_30

  -- NvChad tabufline uses "Tb" prefix: TbFill, TbBufOn, TbBufOff, etc.
  vim.api.nvim_set_hl(0, "TbFill",              { bg = c.black2 })
  vim.api.nvim_set_hl(0, "TbBufOn",             { fg = c.white, bg = c.black })
  vim.api.nvim_set_hl(0, "TbBufOff",            { fg = c.light_grey, bg = c.black2 })
  vim.api.nvim_set_hl(0, "TbBufOnClose",        { fg = c.red, bg = c.black })
  vim.api.nvim_set_hl(0, "TbBufOffClose",       { fg = c.grey_fg, bg = c.black2 })
  vim.api.nvim_set_hl(0, "TbBufOnModified",     { fg = c.green, bg = c.black })
  vim.api.nvim_set_hl(0, "TbBufOffModified",    { fg = c.red, bg = c.black2 })
  vim.api.nvim_set_hl(0, "TbTabOn",             { fg = c.red, bg = c.black })
  vim.api.nvim_set_hl(0, "TbTabOff",            { fg = c.light_grey, bg = c.black2 })
  vim.api.nvim_set_hl(0, "TbTabNewBtn",         { fg = c.light_grey, bg = c.one_bg })
  vim.api.nvim_set_hl(0, "TbThemeToggleBtn",    { fg = c.light_grey, bg = c.one_bg2 })
  vim.api.nvim_set_hl(0, "TbCloseAllBufsBtn",   { fg = c.black, bg = c.red })
end

local function fix_nvimtree_colors()
  local base46 = require("base46")
  local theme = base46.theme_tables["dms"]
  if not theme then return end
  local c = theme.base_30

  vim.api.nvim_set_hl(0, "NvimTreeNormal",    { bg = c.black })
  vim.api.nvim_set_hl(0, "NvimTreeNormalNC",  { bg = c.black })
  vim.api.nvim_set_hl(0, "NvimTreeCursorLine", { bg = c.black2 })
  vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { fg = c.darker_black, bg = c.black })
  vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { fg = c.line, bg = c.darker_black })
  vim.api.nvim_set_hl(0, "NvimTreeFolderName", { fg = "#2e5a4c" })
  vim.api.nvim_set_hl(0, "NvimTreeFolderIcon", { fg = "#2e5a4c" })
  vim.api.nvim_set_hl(0, "NvimTreeEmptyFolderName", { fg = "#2e5a4c" })
  vim.api.nvim_set_hl(0, "NvimTreeRootFolder", { fg = "#1a6b5a", bold = true })
  vim.api.nvim_set_hl(0, "NvimTreeIndentMarker", { fg = c.one_bg3 })
end

-- Write base46 integration highlights to cache file so lazy-loaded
-- plugins (tabufline, nvimtree, treesitter, etc.) pick up DMS colors.
local function regenerate_cache(name)
  local base46 = require("base46")
  local ok, highlights = pcall(base46.get_integration, name)
  if not ok then return end
  if not highlights then return end
  local cache = {}
  for hlname, hlopts in pairs(highlights) do
    local parts = {}
    for k, v in pairs(hlopts) do
      if type(v) == "string" then
        table.insert(parts, string.format("%s=%q", k, v))
      elseif type(v) == "boolean" then
        table.insert(parts, string.format("%s=%s", k, tostring(v)))
      else
        table.insert(parts, string.format("%s=%s", k, tostring(v)))
      end
    end
    table.insert(cache, string.format(
      "vim.api.nvim_set_hl(0,%q,{%s})", hlname, table.concat(parts, ",")))
  end
  local f = io.open(vim.g.base46_cache .. name, "w")
  if f then f:write(table.concat(cache, "\n")) f:close() end
end

local function load_dms_theme()
  local base46 = require("base46")

  local nvcfg_ok, nvcfg = pcall(require, "nvconfig")
  if nvcfg_ok and nvcfg.base46 then
    base46.setup(nvcfg.base46)
  end

  -- Provide toggle_theme that NvChad's TbToggle_theme button expects
  base46.toggle_theme = function()
    vim.cmd.colorscheme "dms"
  end

  pcall(vim.cmd.colorscheme, "dms")

  -- Regenerate all integration caches so lazy-loaded plugins get correct DMS colors
  for name, _ in pairs(base46.opts.integrations) do
    regenerate_cache(name)
  end

  -- Fix popup borders/backgrounds immediately after theme loads
  vim.defer_fn(fix_popup_colors, 100)
end

-- Load DMS theme after startup delay
vim.defer_fn(load_dms_theme, 1000)

-- Fix nvim-tree: runs AFTER nvim-tree lazy-loads (it overwrites our hl)
vim.api.nvim_create_autocmd("FileType", {
  pattern = "NvimTree",
  once = true,
  callback = function()
    vim.defer_fn(fix_nvimtree_colors, 100)
  end,
})

vim.api.nvim_create_autocmd({ "FileType", "WinNew", "WinClosed", "WinEnter", "BufWinEnter", "BufWinLeave", "VimResized" }, {
  callback = function()
    schedule_float_backdrop_refresh()
  end,
})

-- Fix DMS runtime overrides after ColorScheme change (manual :colorscheme dms).
vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "dms",
  callback = function()
    vim.defer_fn(function()
      fix_tabline_colors()
      fix_popup_colors()
      refresh_float_backdrop()
    end, 100)
  end,
})
