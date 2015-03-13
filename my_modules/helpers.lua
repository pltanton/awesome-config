local awful     = require("awful")

local helpers = {}

helpers.module_path   = (...):match ("(.+/)[^/]+$") or ""
helpers.ICON_DIR      = awful.util.getdir("config").."/"..helpers.module_path.."my_modules/icons/"

function helpers.is_dpms_enabled()
    local f = io.popen("xset q | grep Enabled")
    return f:read() or false
end

return helpers
