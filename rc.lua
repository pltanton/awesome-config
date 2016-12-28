-- Global variables, required for other modules
gears = require("gears")
awful = require("awful")
wibox = require("wibox") -- Widget and layout library
beautiful = require("beautiful") -- Theme handling library
naughty = require("naughty") -- Notification library
menubar = require("menubar")

-- Requiring some extra modules and plugins
require("awful.autofocus")

-- Configuration mainfest
require("modules/error_handling")
require("modules/definitions")
require("modules/keys")
require("modules/bar")
require("modules/signals")
require("modules/rules")
