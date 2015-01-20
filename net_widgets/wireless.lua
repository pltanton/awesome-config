local wibox        = require("wibox")
local awful        = require("awful")
local naughty      = require("naughty")
local beautiful    = require("beautiful")

local widget = wibox.layout.fixed.horizontal()
local connected = false

local notification = nil
function widget:hide() 
    if notification ~= nil then
        naughty.destroy(notification)
        notification = nil
    end
end

function widget:show(t_out)
    widget:hide()
    
    local msg
    if connected then
        msg = awful.util.pread(" iwconfig wlp1s0 | awk 'NR==1 {printf \"ESSID:\\t\\t%s\\nIIIE:\\t\\t%s\\n\", substr($4,8,length($4)-8), $3} NR==2 {printf \"Acces Point:\\t%s\", $6}' ")
    else
        msg = "Wireless network is disconnected"
    end
    
    notification = naughty.notify({
        preset = fs_notification_preset,
        text = msg,
        timeout = t_out,
    })
end

local net_icon = wibox.widget.imagebox()
local net_text = wibox.widget.textbox()
local net_timer = timer({ timeout = 2 })
local function net_update() 
    local signal_level = awful.util.pread("awk 'NR==3 {printf \"%3.0f%\" ,($3/70)*100}' /proc/net/wireless")
    if signal_level == '' then
        connected = false
        net_text:set_text(" N/A ")
    else
        connected = true
        net_text:set_text(signal_level)
    end
end

net_icon:set_image(beautiful.widget_net)
net_text:set_text(" N/A ")
net_timer:connect_signal("timeout", net_update)
net_timer:start()

widget:add(net_icon)
widget:add(net_text)

widget:connect_signal('mouse::enter', function () widget:show(0) end)
widget:connect_signal('mouse::leave', function () widget:hide() end)

return widget
