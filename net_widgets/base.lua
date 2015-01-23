local wibox        = require("wibox")
local awful        = require("awful")
local naughty      = require("naughty")
local beautiful    = require("beautiful")

local notification = nil
function widget:hide() 
    if notification ~= nil then
        naughty.destroy(notification)
        notification = nil
    end
end

local function text_grabber()
function widget:show(t_out)
    widget:hide()
    
    notification = naughty.notify({
        preset = fs_notification_preset,
        text = text_grabber(),
        timeout = t_out,
    })
end


function add(widget, updater)
    text_grabber = updater
    widget:connect_signal('mouse::enter', function () widget:show(0) end)
    widget:connect_signal('mouse::leave', function () widget:hide() end)
end
