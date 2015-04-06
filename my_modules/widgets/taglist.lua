---------------------------------------------------------------------------
-- @author Julien Danjou &lt;julien@danjou.info&gt;
-- @copyright 2008-2009 Julien Danjou
-- @release v3.5.6
---------------------------------------------------------------------------

-- Grab environment we need
local gears     = require("gears")
local capi = { screen = screen,
               awesome = awesome,
               client = client }
local type = type
local setmetatable = setmetatable
local pairs = pairs
local ipairs = ipairs
local table = table
local common = require("awful.widget.common")
local util = require("awful.util")
local tag = require("awful.tag")
local beautiful = require("beautiful")
local flex = require("wibox.layout.flex")
local wibox = require("wibox")
local surface = require("gears.surface")

--- Taglist widget module for awful
-- awful.widget.taglist
local taglist = { mt = {} }
taglist.filter = {}

function taglist.taglist_label(t, args)
    if not args then args = {} end
    local cls = t:clients()
    
    local got_client = #cls > 0
    local is_selected = t.selected
    local is_urgent = false

    for k, c in pairs(cls) do
        if c.urgent then
            is_urgent = true
            break
        end
    end

    return is_selected, got_client, is_urgent
end



local function taglist_update(s, w, buttons, filter, data, style, update_function)
    local tags = {}
    for k, t in ipairs(tag.gettags(s)) do
        if not tag.getproperty(t, "hide") and filter(t) then
            table.insert(tags, t)
        end
    end

    local function label(c) return taglist.taglist_label(c, style) end

    update_function(w, buttons, label, data, tags)
end

--- Get the tag object the given widget appears on.
-- @param widget The widget the look for.
-- @return The tag object.
function taglist.gettag(widget)
    return common.tagwidgets[widget]
end


local function my_list_update(w, buttons, label, data, objects)
    -- update the widgets, creating them if needed
    w:reset()
    for i, o in ipairs(objects) do
        local cache = data[o]
        local s
        if cache then
            s = cache.s
        else
            s = wibox.widget.base.make_widget()
            local height = theme.tagsh or 2

            s.color = theme.bg_normal or "#000000"
            s.fit = function(m, w, h) return w, height end
            s.draw = function(mycross, wibox, cr, width, height)
                cr:set_source_rgb(gears.color.parse_color(s.color))
                cr:rectangle(5,0,width-5,height)
                cr:fill()
            end

            s:buttons(common.create_buttons(buttons, o))
            
            data[o] = {
                s = s
            }
        end

        local is_selected, got_client, is_urgent = label(o)
        if is_selected then 
            s.color = theme.taglist_selected or "#CCCCCC"
        elseif is_urgent then
            s.color = theme.taglist_urgent or "#7f0000"
        elseif got_client then
            s.color = theme.taglist_got_clients or "#555555"
        else
            s.color = theme.bg_normal or "#000000"
        end

        w:add(s)
            
   end
end


--- Create a new taglist widget. The last two arguments (update_function
-- and base_widget) serve to customize the layout of the taglist (eg. to
-- make it vertical). For that, you will need to copy the
-- awful.widget.common.list_update function, make your changes to it
-- and pass it as update_function here. Also change the base_widget if the
-- default is not what you want.
-- @param screen The screen to draw taglist for.
-- @param filter Filter function to define what clients will be listed.
-- @param buttons A table with buttons binding to set.
-- @param style The style overrides default theme.
-- @param update_function Optional function to create a tag widget on each
--        update. @see awful.widget.common.
-- @param base_widget Optional container widget for tag widgets. Default
--        is wibox.layout.fixed.horizontal().
-- bg_focus The background color for focused client.
-- fg_focus The foreground color for focused client.
-- bg_urgent The background color for urgent clients.
-- fg_urgent The foreground color for urgent clients.
-- squares_sel Optional: a user provided image for selected squares.
-- squares_unsel Optional: a user provided image for unselected squares.
-- squares_sel_empty Optional: a user provided image for selected squares for empty tags.
-- squares_unsel_empty Optional: a user provided image for unselected squares for empty tags.
-- squares_resize Optional: true or false to resize squares.
-- font The font.
function taglist.new(screen, filter, buttons, style, update_function, base_widget)
    local uf = update_function or my_list_update
    local w = base_widget or flex.horizontal()

    local data = setmetatable({}, { __mode = 'k' })
    local u = function (s)
        if s == screen then
            taglist_update(s, w, buttons, filter, data, style, uf)
        end
    end
    local uc = function (c) return u(c.screen) end
    local ut = function (t) return u(tag.getscreen(t)) end
    capi.client.connect_signal("focus", uc)
    capi.client.connect_signal("unfocus", uc)
    tag.attached_connect_signal(screen, "property::selected", ut)
    tag.attached_connect_signal(screen, "property::icon", ut)
    tag.attached_connect_signal(screen, "property::hide", ut)
    tag.attached_connect_signal(screen, "property::name", ut)
    tag.attached_connect_signal(screen, "property::activated", ut)
    tag.attached_connect_signal(screen, "property::screen", ut)
    tag.attached_connect_signal(screen, "property::index", ut)
    capi.client.connect_signal("property::urgent", uc)
    capi.client.connect_signal("property::screen", function(c)
        -- If client change screen, refresh it anyway since we don't from
        -- which screen it was coming :-)
        u(screen)
    end)
    capi.client.connect_signal("tagged", uc)
    capi.client.connect_signal("untagged", uc)
    capi.client.connect_signal("unmanage", uc)
    u(screen)
    return w
end

--- Filtering function to include all nonempty tags on the screen.
-- @param t The tag.
-- @param args unused list of extra arguments.
-- @return true if t is not empty, else false
function taglist.filter.noempty(t, args)
    return #t:clients() > 0 or t.selected
end

--- Filtering function to include all tags on the screen.
-- @param t The tag.
-- @param args unused list of extra arguments.
-- @return true
function taglist.filter.all(t, args)
    return true
end

function taglist.mt:__call(...)
    return taglist.new(...)
end

return setmetatable(taglist, taglist.mt)

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
