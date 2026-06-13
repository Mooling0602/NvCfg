local M = {}
M.base46 = {
  transparency = true,
  hl_override = {
    -- Solid background for file tree (transparency looks dark)
    NvimTreeNormal = { bg = "black" },
    NvimTreeNormalNC = { bg = "black" },
    NvimTreeCursorLine = { bg = "black2" },
    NvimTreeEndOfBuffer = { fg = "darker_black", bg = "black" },
    NvimTreeWinSeparator = { fg = "darker_black", bg = "darker_black" },
    -- Tabline background follows theme
    TbFill = { bg = "black2" },
    TbBufOn = { fg = "white", bg = "black" },
    TbBufOff = { fg = "light_grey", bg = "black2" },
    TbBufOnClose = { fg = "red", bg = "black" },
    TbBufOffClose = { fg = "grey_fg", bg = "black2" },
    TbBufOnModified = { fg = "green", bg = "black" },
    TbBufOffModified = { fg = "red", bg = "black2" },
    TbTabOn = { fg = "red", bg = "black" },
    TbTabOff = { fg = "light_grey", bg = "black2" },
    TbTabNewBtn = { fg = "light_grey", bg = "one_bg" },
    TbThemeToggleBtn = { fg = "light_grey", bg = "one_bg2" },
    TbCloseAllBufsBtn = { fg = "black", bg = "red" },
    -- Markdown / treesitter: fix dark backgrounds leaking in light mode
    ["@markup.quote"] = { bg = "black2" },
    ["@markup.raw"] = { bg = "black2" },
  },
}
return M
