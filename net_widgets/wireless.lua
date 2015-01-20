local wibox        = require("wibox")
local awful        = require("awful")
local naughty      = require("naughty")
local beautiful    = require("beautiful")

local widget = wibox.layout.fixed.horizontal()
local connected = false

-- Settings
local ICON_DIR  = awful.util.getdir("config").."/net_widgets/icons/"
local INTERFACE = "wlp1s0"

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
        local essid     = " N/A "
        local mac       = " N/A "
        local bitrate   = " N/A "   
        local f = io.popen("iwconfig "..INTERFACE)
       
        line    = f:read()      -- wlp1s0    IEEE 802.11abgn  ESSID:"ESSID" 
        essid   = string.match(line, "ESSID:\"(.+)\"") or essid
        line    = f:read()      -- Mode:Managed  Frequency:2.437 GHz  Access Point: aa:bb:cc:dd:ee:ff
        mac     = string.match(line, "Access Point: (.+)") or mac
        line    = f:read()      -- Bit Rate=36 Mb/s   Tx-Power=15 dBm 
        bitrate = string.match(line, "Bit Rate=(.+/s)") or bitrate

        msg = 
            "<span>".. -- configurable font here
            "ESSID:\t\t"..essid.."\n"..
            "BSSID:\t\t"..mac.."\n"..
            "Bit rate:\t"..bitrate..
            "</span>"

        --msg = awful.util.pread(" iwconfig wlp1s0 | awk 'NR==1 {printf \"ESSID:\\t\\t%s\\nIIIE:\\t\\t%s\\n\", substr($4,8,length($4)-8), $3} NR==2 {printf \"Acces Point:\\t%s\", $6}' ")
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
net_icon:set_image(ICON_DIR.."wireless_na.png")
local net_text = wibox.widget.textbox()
net_text:set_text(" N/A ")
local net_timer = timer({ timeout = 5 })
local function net_update() 
    local signal_level = tonumber(awful.util.pread("awk 'NR==3 {printf \"%3.0f\" ,($3/70)*100}' /proc/net/wireless"))
    if signal_level == nil then
        connected = false
        net_text:set_text(" N/A ")
        net_icon:set_image(ICON_DIR.."wireless_na.png")
    else
        connected = true
        net_text:set_text(string.format("%3d%%", signal_level))
        if signal_level < 25 then
            net_icon:set_image(ICON_DIR.."wireless_0.png")
        elseif signal_level < 50 then
            net_icon:set_image(ICON_DIR.."wireless_1.png")
        elseif signal_level < 75 then
            net_icon:set_image(ICON_DIR.."wireless_2.png")
        else 
            net_icon:set_image(ICON_DIR.."wireless_3.png")
        end
    end
end

net_update()
net_timer:connect_signal("timeout", net_update)
net_timer:start()

widget:add(net_icon)
widget:add(net_text)

widget:connect_signal('mouse::enter', function () widget:show(0) end)
widget:connect_signal('mouse::leave', function () widget:hide() end)

return widget
