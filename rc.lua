-- {{{ Required libraries
local gears     = require("gears")
local awful     = require("awful")
awful.rules     = require("awful.rules")
require("awful.autofocus")
local wibox     = require("wibox")
local common    = require("awful.widget.common")

local beautiful = require("beautiful")
beautiful.init(os.getenv("HOME") .. "/.config/awesome/theme/theme.lua")

naughty   = require("naughty") -- Should be global
local scratch   = require("scratch")
local lain      = require("lain")
local revelation= require("revelation")
local tyrannical= require("tyrannical")

-- widgets
local APW       = require("apw/widget")
local net_widgets =require("net_widgets")
local my_modules     = require("my_modules")
-- }}}

-- {{{ Error handling
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Autostart applications
function run_once(cmd)
  findme = cmd
  firstspace = cmd:find(" ")
  if firstspace then
     findme = cmd:sub(0, firstspace-1)
  end
  awful.util.spawn_with_shell("pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. ")")
end

run_once("compton -b")
run_once("urxvtd")
run_once("unclutter")
run_once("pidgin")
run_once("mpd")
run_once("mpdscribble")
run_once("conky")
run_once("clipit")
run_once("udisks-glue -f &")
-- }}}

-- {{{ Variable definitions
-- localization
os.setlocale(os.getenv("LANG"))

-- revelation init
revelation.init()


-- common
modkey     = "Mod4"
altkey     = "Mod1"
terminal   = "urxvtc" or "xterm"
editor     = os.getenv("EDITOR") or "vim" or "vi"
editor_cmd = terminal .. " -e " .. editor

-- user defined
browser2 = "vimb-tabbed"
browser = "firefox"
gui_editor = "gvim"

lain.layout.centerfair.nmaster = 3
lain.layout.centerfair.ncol = 2
local layouts = {
    awful.layout.suit.floating,
    lain.layout.uselesstile,
    lain.layout.uselessfair,
    lain.layout.uselesspiral,
}
-- }}}

-- {{{ Tags
tyrannical.tags = {
    {
        name        = "Web",
        init        = true,
        exclusive   = true,
        screen      = {1,2},
        layout      = layouts[2],
        class       = {"Firefox", "chrome", "chromium"}
    },
    {
        name        = "Term",
        init        = true,
        exclusive   = true,
        layout      = layouts[3], 
        screen      = {1,2},
        class       = {"xterm", "urxvt", }
    },
    {
        name        = "Dev",
        init        = true,
        exclusive   = true,
        exclusive   = true,
        screen      = {1,2},
        layout      = layouts[2],
        class       = {"gvim", "idea"}
    },
    {
        name        = "Files",
        init        = true,
        screen      = {1,2},
        layout      = layouts[2], 
        class       = {"pcmanfm"} 
    },
    {
        name        = "Media",
        layout      = layouts[0],
        init        = true,
        class       = {"mpv"}
    },
    {
        name        = "Doc",
        init        = false, -- This tag wont be created at startup, but will be when one of the
                             -- client in the "class" section will start. It will be created on
                             -- the client startup screen
        exclusive   = true,
        layout      = awful.layout.suit.max,
        class       = {
            "Assistant"     , "Okular"         , "Evince"    , "EPDFviewer"   , "xpdf",
            "Xpdf"          , "zathura"                                        }
    } ,
    {
        name        = "Pidgin",
        init        = true,
        screen      = {1},
        layout      = layouts[2],
        execute     = true,
        --hide        = true, 
        mwfact      = 0.20,
        no_focus_stealing_in = true,
        ncol        = 2,
        class       = {"Pidgin"}

    }
}

tyrannical.properties.intrusive = {"urxvt", "arandr"}
tyrannical.properties.float = {"arandr"}

tyrannical.settings.block_children_focus_stealing = true --Block popups ()
tyrannical.settings.group_children = true --Force popups/dialogs to have the same tags as the parent client
-- }}}


-- {{{ Wallpaper
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ Menu
mymainmenu = awful.menu.new({ items = require("menugen").build_menu(),
                              theme = { height = 16, width = 130 }})
-- }}}

-- {{{ Display cycling
-- Get active outputs
local function outputs()
   local outputs = {}
   local xrandr = io.popen("xrandr -q")
   if xrandr then
      for line in xrandr:lines() do
	 output = line:match("^([%w-]+) connected ")
	 if output then
	    outputs[#outputs + 1] = output
	 end
      end
      xrandr:close()
   end

   return outputs
end

local function arrange(out)
   -- We need to enumerate all the way to combinate output. We assume
   -- we want only an horizontal layout.
   local choices  = {}
   local previous = { {} }
   for i = 1, #out do
      -- Find all permutation of length `i`: we take the permutation
      -- of length `i-1` and for each of them, we create new
      -- permutations by adding each output at the end of it if it is
      -- not already present.
      local new = {}
      for _, p in pairs(previous) do
	 for _, o in pairs(out) do
	    if not awful.util.table.hasitem(p, o) then
	       new[#new + 1] = awful.util.table.join(p, {o})
	    end
	 end
      end
      choices = awful.util.table.join(choices, new)
      previous = new
   end

   return choices
end

-- Build available choices
local function menu()
   local menu = {}
   local out = outputs()
   local choices = arrange(out)

   for _, choice in pairs(choices) do
      local cmd = "xrandr"
      -- Enabled outputs
      for i, o in pairs(choice) do
	 cmd = cmd .. " --output " .. o .. " --auto"
	 if i > 1 then
	    cmd = cmd .. " --right-of " .. choice[i-1]
	 end
      end
      -- Disabled outputs
      for _, o in pairs(out) do
	 if not awful.util.table.hasitem(choice, o) then
	    cmd = cmd .. " --output " .. o .. " --off"
	 end
      end

      local label = ""
      if #choice == 1 then
	 label = 'Only <span weight="bold">' .. choice[1] .. '</span>'
      else
	 for i, o in pairs(choice) do
	    if i > 1 then label = label .. " + " end
	    label = label .. '<span weight="bold">' .. o .. '</span>'
	 end
      end

      menu[#menu + 1] = { label,
			  cmd,
                          "/usr/share/icons/Tango/32x32/devices/display.png"}
   end

   return menu
end

-- Display xrandr notifications from choices
local state = { iterator = nil,
		timer = nil,
		cid = nil }
local function xrandr()
   -- Stop any previous timer
   if state.timer then
      state.timer:stop()
      state.timer = nil
   end

   -- Build the list of choices
   if not state.iterator then
      state.iterator = awful.util.table.iterate(menu(),
					function() return true end)
   end

   -- Select one and display the appropriate notification
   local next  = state.iterator()
   local label, action, icon
   if not next then
      label, icon = "Keep the current configuration", "/usr/share/icons/Tango/32x32/devices/display.png"
      state.iterator = nil
   else
      label, action, icon = unpack(next)
   end
   state.cid = naughty.notify({ text = label,
				icon = icon,
				timeout = 4,
				screen = mouse.screen, -- Important, not all screens may be visible
				font = "Free Sans 18",
				replaces_id = state.cid }).id

   -- Setup the timer
   state.timer = timer { timeout = 4 }
   state.timer:connect_signal("timeout",
			  function()
			     state.timer:stop()
			     state.timer = nil
			     state.iterator = nil
			     if action then
				awful.util.spawn(action, false)
			     end
			  end)
   state.timer:start()
end

-- }}}

-- {{{ Wibox
markup      = lain.util.markup
separators  = lain.util.separators

-- Textclock
clockicon = wibox.widget.imagebox(beautiful.widget_clock)
mytextclock = awful.widget.textclock(" %H:%M")

-- calendar
lain.widgets.calendar:attach(mytextclock, { font_size = 10 })

-- MEM
memicon = wibox.widget.imagebox(beautiful.widget_mem)
memwidget = lain.widgets.mem({
    settings = function()
        widget:set_text(" " .. mem_now.used .. "MB ")
    end
})

-- CPU
cpuicon = wibox.widget.imagebox(beautiful.widget_cpu)
cpuwidget = lain.widgets.cpu({
    settings = function()
        widget:set_text(" " .. cpu_now.usage .. "% ")
    end
})

-- Coretemp
tempicon = wibox.widget.imagebox(beautiful.widget_temp)
tempwidget = lain.widgets.temp({
    settings = function()
        widget:set_text(" " .. coretemp_now .. "°C ")
    end
})

-- Battery

baticon = wibox.widget.imagebox(beautiful.widget_battery)
batwidget = lain.widgets.bat({
    battery = "BAT1",
    settings = function()
        if bat_now.status == "Charging" then
            baticon:set_image(beautiful.widget_ac)
        elseif bat_now.perc == "N/A" then
            widget:set_markup(" AC ")
            baticon:set_image(beautiful.widget_ac)
            return
        elseif tonumber(bat_now.perc) <= 5 then
            baticon:set_image(beautiful.widget_battery_empty)
        elseif tonumber(bat_now.perc) <= 15 then
            baticon:set_image(beautiful.widget_battery_low)
        else
            baticon:set_image(beautiful.widget_battery)
        end
        widget:set_markup(" " .. bat_now.perc .. "% ")
    end
})
local function battary_time_grabber()
    f = io.popen("acpi -b | awk '{print $5}' | awk -F \":\" '{print $1\":\"$2 }'")
    str = f:read()
    f.close()
    return str.." remaining"
end

local battery_notify = nil
function batwidget:hide()
    if battary_notify ~= nil then
        naughty.destroy(battary_notify)
        battary_notify = nil
    end
end

function batwidget:show(t_out)
    batwidget:hide()

    battary_notify = naughty.notify({
        preset = fs_notification_preset,
        text = battary_time_grabber(),
        timeout = t_out,
    })
end

batwidget:connect_signal('mouse::enter', function () batwidget:show(0) end)
batwidget:connect_signal('mouse::leave', function () batwidget:hide() end)

-- Keyboard map indicator and changer
handle = io.popen("xkb-switch")
kbdtext = wibox.widget.textbox(handle:read())
handle:close()
    
kbddnotufy = nil
kbdwidget = kbdtext
kbdstrings = {[0] = "en", [1] = "ru", [2] = "dvorak"}
kbdwidget:buttons(awful.util.table.join(awful.button({}, 1, function()
                     os.execute('xkb-switch -n')
                  end))) 

dbus.request_name("session", "ru.gentoo.kbdd")
dbus.add_match("session", "interface='ru.gentoo.kbdd',member='layoutChanged'")
dbus.connect_signal("ru.gentoo.kbdd", function(...) 
        local data = {...}
        local layout = data[2]
        kbdtext:set_markup(kbdstrings[layout])
        
        naughty.destroy(kbddnotufy)
        kbddnotufy = naughty.notify({text = "Layout changed to "..kbdstrings[layout], timeout = 0.5})
    end
)

-- Network widgets
net_wireless    = net_widgets.wireless({interface   = "wlp3s0", 
                  onclick     = terminal .. " -e sudo wifi-menu" }) 

-- Latte (caffeine)
latte = my_modules.latte()

-- Separators
spr = wibox.widget.textbox(' ')
  
    -- left
spr_dl = separators.arrow_left(beautiful.bg_focus, "alpha") 
spr_ld = separators.arrow_left("alpha", beautiful.bg_focus)
    -- right
spr_ld_r = separators.arrow_right(beautiful.bg_focus, "alpha") 
spr_dl_r = separators.arrow_right("alpha", beautiful.bg_focus)

-- Create a wibox for each screen and add it
mywibox = {}
mylayoutbox = {}
mybottomwibox = {}
mypromptbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  -- Without this, the following
                                                  -- :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do

    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt{prompt=" Run: "}

    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                            awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                            awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                            awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                            awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))

    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    
    local function tasklist_update(w, buttons, label, data, objects, nomargin)
        -- update the widgets, creating them if needed
        w:reset()
        for i, o in ipairs(objects) do
            local cache = data[o]
            local ib, tb, bgb, m, l
            if cache then
                ib = cache.ib
                tb = cache.tb
                bgb = cache.bgb
                m   = cache.m
            else
                ib = wibox.widget.imagebox()
                tb = wibox.widget.textbox()
                bgb = wibox.widget.background()
                m = wibox.layout.margin(ib, 4, 4)
                l = wibox.layout.fixed.horizontal()

                -- All of this is added in a fixed widget
                l:fill_space(true)
                l:add(ib)
                --l:add(m)

                -- And all of this gets a background
                bgb:set_widget(l)

                bgb:buttons(common.create_buttons(buttons, o))

                data[o] = {
                    ib = ib,
                    tb = tb,
                    bgb = bgb,
                    m   = m
                }
            end

            local text, bg, bg_image, icon = label(o)
            icon = icon or theme.tasklist_default_icon
            -- The text might be invalid, so use pcall
            if not pcall(tb.set_markup, tb, text) then
                tb:set_markup("<i>&lt;Invalid text&gt;</i>")
            end
            bgb:set_bg(bg)
            if type(bg_image) == "function" then
                bg_image = bg_image(tb,o,m,objects,i)
            end
            bgb:set_bgimage(bg_image)
            ib:set_image(icon)
            w:add(bgb)
        end
    end
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons, nil, tasklist_update, wibox.layout.fixed.horizontal())

    -- Create the wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s, height = 18 })
    --mybottomwibox[s] = awful.wibox({position = "bottom", screen = s, height = 18 })
    

    -- Widgets that are aligned to the upper left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(wibox.widget.background(mylayoutbox[s], beautiful.bg_focus))
    left_layout:add(spr_ld_r)
    left_layout:add(mytaglist[s])
    left_layout:add(spr_dl_r)
    left_layout:add(wibox.widget.background(mypromptbox[s], beautiful.bg_focus))
    left_layout:add(spr_ld_r)
    left_layout:add(spr)
    left_layout:add(mytasklist[s])

    -- Widgets that are aligned to the upper right
    local right_layout = wibox.layout.fixed.horizontal()

    right_layout:add(wibox.widget.systray())
   
    local right_layout_toggle = true
    local function right_layout_add (...)  
        local arg = {...}
        if right_layout_toggle then
            right_layout:add(spr_ld)
            for i, n in pairs(arg) do
                right_layout:add(wibox.widget.background(n ,beautiful.bg_focus))
            end
        else
            right_layout:add(spr_dl)
            for i, n in pairs(arg) do
                right_layout:add(n)
            end
        end
        right_layout_toggle = not right_layout_toggle
    end

    right_layout:add(spr)
    right_layout_add(latte)
    right_layout_add(net_wireless, spr)
    right_layout_add(memicon, memwidget)
    right_layout_add(cpuicon, cpuwidget)
    right_layout_add(tempicon, tempwidget)
    right_layout_add(baticon, batwidget)
    right_layout_add(mytextclock, spr)
    right_layout_add(spr, kbdwidget, spr)
    
    
    -- Volume widget
    if right_layout_toggle then
        apw_left_color = "alpha"
    else 
        apw_left_color = beautiful.bg_focus
    end

    spr_ld_apw1 = separators.arrow_left(apw_left_color, beautiful.apw_fg_color)
    spr_ld_apw2 = separators.arrow_left(apw_left_color, beautiful.apw_mute_fg_color)
    
    apw_spr = wibox.widget.base.make_widget()
    apw_spr.fit = spr_ld.fit

    apw_spr.draw = function(self, wibox, cr, width, height)
        if APW.IsMuted() then
            spr_ld_apw2.draw(self, wibox, cr, width, height)
        else
            spr_ld_apw1.draw(self, wibox, cr, width, height)
        end
    end

    right_layout:add(apw_spr)
    right_layout:add(APW)
    
    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    --layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)
    mywibox[s]:set_widget(layout)
end
-- }}}
 

-- {{{ Mouse Bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings(Hotkeys)
globalkeys = awful.util.table.join(
    -- Screenshot
    awful.key({}, "Print", function() awful.util.spawn("screengrab --region") end),
    awful.key({ modkey }, "Print", function() awful.util.spawn("screengrab --fullscreen") end),

    -- Display cycling
    awful.key({ modkey }, "F9", xrandr),

    -- Move clienth through tags
    awful.key({ modkey, "Shift"   }, "Left",
    function (c)
        local curidx = awful.tag.getidx()
        if curidx == 1 then
            awful.client.movetotag(tags[client.focus.screen][#tags[client.focus.screen]])
        else
            awful.client.movetotag(tags[client.focus.screen][curidx - 1])
        end
        awful.tag.viewidx(-1)
    end),
    awful.key({ modkey, "Shift"   }, "Right",
    function (c)
        local curidx = awful.tag.getidx()
        if curidx == #tags[client.focus.screen] then
            awful.client.movetotag(tags[client.focus.screen][1])
        else
            awful.client.movetotag(tags[client.focus.screen][curidx + 1])
        end
        awful.tag.viewidx(1)
    end),
    
    -- Move client throught screens
    awful.key({ modkey, "Shift" }, ",",      function(c) awful.client.movetoscreen(c,c.screen-1) end ),
    awful.key({ modkey, "Shift" }, ".",      function(c) awful.client.movetoscreen(c,c.screen+1) end ),
    
    -- Move focus to screen
    awful.key({modkey,            }, "F1",     function () awful.screen.focus(1) end),
    awful.key({modkey,            }, "F2",     function () awful.screen.focus(2) end),

    -- Tag browsing
    awful.key({ modkey }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey }, "Escape", awful.tag.history.restore),

    -- Non-empty tag browsing
    awful.key({ altkey }, "Left", function () lain.util.tag_view_nonempty(-1) end),
    awful.key({ altkey }, "Right", function () lain.util.tag_view_nonempty(1) end),

    -- Default client nawigation
    awful.key({ altkey }, "k", --forward
        function ()
            local tag = awful.tag.selected()
            for i=1, #tag:clients() do
              tag:clients()[i].minimized = false end
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ altkey }, "j", --backward
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),

    -- By direction client focus
    awful.key({ modkey }, "j",
        function()
            awful.client.focus.bydirection("down")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "k",
        function()
            awful.client.focus.bydirection("up")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "h",
        function()
            awful.client.focus.bydirection("left")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "l",
        function()
            awful.client.focus.bydirection("right")
            if client.focus then client.focus:raise() end
        end),

    -- Show Menu
    awful.key({ modkey }, "w",
        function ()
            mymainmenu:show({ keygrabber = true })
        end),

    -- Show/Hide Wibox
    awful.key({ modkey }, "b", function ()
        mywibox[mouse.screen].visible = not mywibox[mouse.screen].visible
        --mybottomwibox[mouse.screen].visible = not mybottomwibox[mouse.screen].visible
    end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),
    awful.key({ altkey, "Shift"   }, "l",      function () awful.tag.incmwfact( 0.05)     end),
    awful.key({ altkey, "Shift"   }, "h",      function () awful.tag.incmwfact(-0.05)     end),
    awful.key({ modkey, "Shift"   }, "l",      function () awful.tag.incnmaster(-1)       end),
    awful.key({ modkey, "Shift"   }, "h",      function () awful.tag.incnmaster( 1)       end),
    awful.key({ modkey, "Control" }, "l",      function () awful.tag.incncol(-1)          end),
    awful.key({ modkey, "Control" }, "h",      function () awful.tag.incncol( 1)          end),
    awful.key({ modkey,           }, "space",  function () awful.layout.inc(layouts,  1)  end),
    awful.key({ modkey, "Shift"   }, "space",  function () awful.layout.inc(layouts, -1)  end),
    awful.key({ modkey, "Control" }, "n",      awful.client.restore),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r",      awesome.restart),
    awful.key({ modkey, "Shift"   }, "q",      awesome.quit),

    -- Dropdown terminal
    awful.key({ modkey,	          }, "z",      function () scratch.drop(terminal) end),

    -- Screensaver
    awful.key({ modkey }, "F12", function () awful.util.spawn("lock") end),

    -- Brightness
    awful.key({ }, "XF86MonBrightnessDown", function ()
        awful.util.spawn("xbacklight -dec 10") end),
    awful.key({ }, "XF86MonBrightnessUp", function ()
        awful.util.spawn("xbacklight -inc 10") end),

    -- Volume control
    awful.key({ }, "XF86AudioRaiseVolume",  APW.Up),
    awful.key({ }, "XF86AudioLowerVolume",  APW.Down),
    awful.key({ }, "XF86AudioMute",         APW.ToggleMute),

    -- MPD control
    awful.key({ altkey, "Control" }, "Up",
        function ()
            awful.util.spawn_with_shell("mpc toggle || ncmpcpp toggle || ncmpc toggle || pms toggle")
            mpdwidget.update()
        end),
    awful.key({ altkey, "Control" }, "Down",
        function ()
            awful.util.spawn_with_shell("mpc stop || ncmpcpp stop || ncmpc stop || pms stop")
            mpdwidget.update()
        end),
    awful.key({ altkey, "Control" }, "Left",
        function ()
            awful.util.spawn_with_shell("mpc prev || ncmpcpp prev || ncmpc prev || pms prev")
            mpdwidget.update()
        end),
    awful.key({ altkey, "Control" }, "Right",
        function ()
            awful.util.spawn_with_shell("mpc next || ncmpcpp next || ncmpc next || pms next")
            mpdwidget.update()
        end),

    -- Revelation keys
    awful.key({ modkey }, "e", revelation), -- all apps
    awful.key({ altkey }, "e", function()
      revelation( {curr_tag_only=true} )
      end),

    -- Copy to clipboard
    awful.key({ modkey }, "c", function () os.execute("xsel -p -o | xsel -i -b") end),

    -- User programs
    awful.key({ modkey }, "q", function () awful.util.spawn(browser) end),
    awful.key({ modkey }, "i", function () awful.util.spawn(browser2) end),
    awful.key({ modkey }, "s", function () awful.util.spawn(gui_editor) end),
    awful.key({ modkey }, "g", function () awful.util.spawn(graphics) end),

    -- Prompt
    awful.key({ modkey }, "r", function () mypromptbox[mouse.screen]:run() end),
    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = " Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
    )   

    clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",       function (c) 
                                                    c.fullscreen = not c.fullscreen  
                                                end),
    awful.key({ modkey, "Shift"   }, "c",       function (c) 
                                                    if c.fullscreen then
                                                        c.fullscreen = not c.fullscreen
                                                    end
                                                    c:kill()                         
                                                end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.movetotag(tag)
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.toggletag(tag)
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { class = "Screengrab" },
      properties = {
      floating = true      
    }},
    
    { rule = { class = "conky" },
      properties = {
      floating = true,
      sticky = true,
      ontop = false,
      focusable = false,
      size_hints = {"program_position", "program_size"}
    } },    

    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons,
	                   size_hints_honor = false } },

    { rule = { class = "MPlayer" },
          properties = { floating = true } },


    { rule = { class = "Gimp", role = "gimp-image-window" },
          properties = { maximized_horizontal = true,
                         maximized_vertical = true } },

    { rule = { class = "Shutter"},
            properties = { floating = true } },
    
    { rule = { class = "Pidgin", role = "conversation"},
        properties = { callback = awful.client.setslave } }, 
    
    -- Firefox rules
    { rule = { class = "Firefox", role="Preferences" },
        properties = { floating = true } },
    
    { rule = { class = "Navigator" },
        properties = { border_width = 0,
                       border_color = beautiful.border_focus } },

    { rule = { class = "Plugin-container" }, 
        properties = { focus = yes,
                       floating = true, 
                       fullscreen = true, 
                       border_width = 0,
                       border_color = beautiful.border_normal } },     
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup and not c.size_hints.user_position
       and not c.size_hints.program_position then
        awful.placement.no_overlap(c)
        awful.placement.no_offscreen(c)
    end
end)

client.connect_signal("focus",
    function(c)
        if c.maximized_horizontal == true and c.maximized_vertical == true then
            c.border_width = 0
            c.border_color = beautiful.border_normal
        else
            c.border_width = beautiful.border_width
            c.border_color = beautiful.border_focus
        end
    end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- {{{ Arrange signal handler
for s = 1, screen.count() do screen[s]:connect_signal("arrange", function ()
        local clients = awful.client.visible(s)
        local layout  = awful.layout.getname(awful.layout.get(s))

        if #clients > 0 then -- Fine grained borders and floaters control
            for _, c in pairs(clients) do -- Floaters always have borders
                if awful.client.floating.get(c) or layout == "floating" then
                    c.border_width = beautiful.border_width

                -- No borders with only one visible client
                elseif #clients == 1 or layout == "max" then
                    clients[1].border_width = 0
                    awful.client.moveresize(0, 0, 2, 2, clients[1])
                else
                    c.border_width = beautiful.border_width
                end
            end
        end
      end)
end
-- }}}
