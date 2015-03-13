local wibox         = require("wibox")
local awful         = require("awful")
local naughty       = require("naughty")
local helpers       = require("my_modules.helpers")

local latte = {}

local enable        = helpers.ICON_DIR .. "coffe_on.png"
local disable       = helpers.ICON_DIR .. "coffe_off.png"


local widget = wibox.widget.imagebox()

-- Update icon
function widget.set(enabled) 
    if enabled then    
        widget:set_image(disable)    
    else
        widget:set_image(enable)
    end
end


-- Toggle
function widget.toggle()
    if helpers.is_dpms_enabled() then
        awful.util.spawn_with_shell("xset s off && xset -dpms &")
        naughty.notify({text = "DPMS Disabled."})
        widget.set(false)
    else
        awful.util.spawn_with_shell("xset s on && xset +dpms &")
        naughty.notify({text = "DPMS Enabled."})
        widget.set(true)
    end
end

local function create()
    -- Init
    widget:set(helpers.is_dpms_enabled()) 

    -- Add onclick event
    widget:buttons(awful.util.table.join(
        awful.button({}, 1, function() 
            widget:toggle() 
        end)
    ))

    return widget
end

return setmetatable(latte, {__call = function(_,...) return create(...) end})
