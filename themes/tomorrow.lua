-----------------------------------
--    "Tomorrow" awesome theme   --
-- By Plotnikov Anton (pltanton) --
-----------------------------------

-- Tomorrow colors defenition

local black          = "#1d1f21"
local darkest_gray   = "#282a2e"
local dark_gray      = "#373b41"
local gray           = "#969896"
local light_gray     = "#b4b7b4"
local lighter_gray   = "#c5c8c6"
local lighterst_gray = "#e0e0e0"
local white          = "#ffffff"
local red            = "#cc6666"
local orange         = "#de935f"
local yellow         = "#f0c674"
local green          = "#b5bd68"
local lemon          = "#8abeb7"
local blue           = "#81a2be"
local purple         = "#b294bb"
local dark_Red       = "#a3685a"

-- {{{ Main
local theme = {}
theme.wallpaper = "~/.background.png"
-- }}}

-- {{{ Fonts
theme.font      = "terminus 9"
-- }}}

-- {{{ Colors
theme.fg_normal  = lighter_gray
theme.fg_focus   = blue
theme.fg_urgent  = black
theme.bg_normal  = black
theme.bg_focus   = black
theme.bg_urgent  = red
theme.bg_systray = theme.bg_normal

theme.tasklist_fg_focus  = theme.fg_normal
-- }}}

-- {{{ Borders
theme.useless_gap   = 2
theme.border_width  = 2
theme.border_normal = black
theme.border_focus  = gray
theme.border_marked = purple
-- }}}

-- {{{ Layout
local icons_dir = awful.util.get_configuration_dir().."/themes/icons/"
theme.layout_fairv      = icons_dir.."fairv.png"
theme.layout_fairh      = icons_dir.."fairh.png"
theme.layout_fullscreen = icons_dir.."full.png"
theme.layout_floating   = icons_dir.."float.png"
-- }}}

return theme

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
