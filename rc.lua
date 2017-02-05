-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
-- Widget libaries
local vicious = require("vicious")


function run_once(prg, args)
  if not prg then
    do return nil end
  end
  if not args then
    args=""
  end
  awful.spawn.with_shell('pgrep -f -u $USER -x ' .. prg .. ' || (' .. prg .. ' ' .. args ..')')
end

-- Custom function to create <span> tags for vicious with some color definition
function colorspan(color, text)
  return '<span color="' .. color .. '">' .. text .. '</span>'
end

-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions

-- Themes define colours, icons, and wallpapers
home = os.getenv("HOME")
--beautiful.init("/usr/share/awesome/themes/default/theme.lua")
beautiful.init(home .. "/.config/awesome/themes/multicolor/theme.lua")

 -- Program Preferences
terminal = "lilyterm"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor
gui_editor = "gvim"
browser = "chromium"
tasks = terminal .. " -e htop"
musicplr = terminal .. " -s -e ncmpcpp"

local tags = {"1 ", "2 ", "3 ", "4 ", "5 ", "6 ", "7 ", "8 ", "9 "}

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Start necessary background services
-- run_once("dbus-launch tomboy")
-- run_once("pnmixer")
run_once("mpd")

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.max,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.magnifier,
    awful.layout.suit.floating,
    awful.layout.suit.max.fullscreen
}
-- }}}

-- {{{ Wallpaper
local function set_wallpaper(s)
    -- Wallpaper
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        -- If wallpaper ist a function, call it with the screen
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end

-- Re-set wallpaper when a screen's geometry changes 
screen.connect_signal("property::geometry", set_wallpaper)
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart },
   { "quit", function () awesome.quit() end}
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "open terminal", terminal }
                                  }
                        })

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = mymainmenu })

-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
-- }}}

-- {{{ Wibox

decoSpace = wibox.widget.textbox('   ')

-- Clock Widget
iconClock = wibox.widget.imagebox()
iconClock:set_image(beautiful.widget_clock)

widgetClock = wibox.widget.textclock(colorspan(beautiful.fg_blue, "%a %d %b %H:%M"))

-- MEM widget
iconMem = wibox.widget.imagebox()
iconMem:set_image(beautiful.widget_mem)

widgetMem = wibox.widget.textbox()
vicious.register(widgetMem, vicious.widgets.mem, colorspan(beautiful.fg_yellow, '$1% [$2MB/$3MB]'), 13)

-- CPU widget
iconCPU = wibox.widget.imagebox()
iconCPU:set_image(beautiful.widget_cpu)
iconCPU:buttons(awful.util.table.join(awful.button({ }, 1, function () awful.spawn(tasks, false) end)))

widgetCPU = wibox.widget.textbox()
vicious.register(widgetCPU, vicious.widgets.cpu, colorspan(beautiful.fg_blue, '1%'), 3)

-- Temp widget
iconTemp = wibox.widget.imagebox()
iconTemp:set_image(beautiful.widget_temp)

widgetTemp = wibox.widget.textbox()
vicious.register(widgetTemp, vicious.widgets.thermal, colorspan(beautiful.fg_red, '$1°C'), 9, {"coretemp.0", "core"} )

-- MPD Icon and Widget
iconMPD = wibox.widget.imagebox()
iconMPD:set_image(beautiful.widget_music)
iconMPD:buttons(awful.util.table.join(awful.button({ }, 1, function () awful.spawn.with_shell(musicplr) end)))

widgetMPD = wibox.widget.textbox()
vicious.register(widgetMPD, vicious.widgets.mpd,
function(widget, args)
  if (args["{state}"] == "Play") then
    iconMPD:set_image(beautiful.widget_music_on)
    text = colorspan(beautiful.fg_red, args["{Title}"])
    text = text .. colorspan(beautiful.fg_normal, " - ")
    return text .. colorspan(beautiful.fg_green, args["{Artist}"])
  elseif (args["{state}"] == "Pause") then
    iconMPD:set_image(beautiful.widget_music)
    return colorspan(beautiful.fg_normal, "... paused ...")
  else
    iconMPD:set_image(beautiful.widget_music)
    return ""
  end
end, 1)

-- Volume widget
iconVol = wibox.widget.imagebox()
iconVol:set_image(beautiful.widget_vol)

widgetVol = wibox.widget.textbox()
vicious.register(widgetVol, vicious.widgets.volume,
function (widget, args)
  if (args[2] ~= "♩" ) then
    if (args[1] == 0) then iconVol:set_image(beautiful.widget_vol_no)
    elseif (args[1] <= 50) then iconVol:set_image(beautiful.widget_vol_low)
    else iconVol:set_image(beautiful.widget_vol)
    end
  else iconVol:set_image(beautiful.widget_vol_mute)
  end
  return colorspan(beautiful.fg_blue, args[1] .. '%')
end, 1, "Master")


-- Create a wibox for each screen and add it
mytopwibox = {}
mybotwibox = {}
mypromptbox = {}
mylayoutbox = {}
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

awful.screen.connect_for_each_screen(function(s)
    -- Wallpaper
    set_wallpaper(s)

    -- Each screen has its own tag table. Using globally configured tags list
    awful.tag(tags, s, layouts[1])

    -- Create a promptbox for each screen
    s.mypromptbox = awful.widget.prompt()
    -- Create an imagebox widget which will contains an icon indicating which layout we're using.
    -- We need one layoutbox per screen.
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(awful.util.table.join(
                           awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                           awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                           awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    s.mytasklist = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the wibox
    s.mytopwibox = awful.wibar({ position = "top", screen = s })
    s.mybotwibox = awful.wibar({ position = "bottom", screen = s })

    -- Widgets that are aligned to the left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mylauncher)
    left_layout:add(s.mytaglist)
    left_layout:add(s.mypromptbox)

    -- Widgets that are aligned to the right
    local right_layout = wibox.layout.fixed.horizontal()
    if s.index == 1 then
      right_layout:add(decoSpace)
      right_layout:add(wibox.widget.systray())
      right_layout:add(decoSpace)
    end
    right_layout:add(iconClock)
    right_layout:add(widgetClock)

    right_layout:add(decoSpace)

    right_layout:add(s.mylayoutbox)

    -- Widgets that go in the middle
    local center_layout = wibox.layout.fixed.horizontal()

    center_layout:add(iconMPD)
    center_layout:add(widgetMPD)

    center_layout:add(decoSpace)

    center_layout:add(iconCPU)
    center_layout:add(widgetCPU)

    center_layout:add(decoSpace)

    center_layout:add(iconMem)
    center_layout:add(widgetMem)

    center_layout:add(decoSpace)

    center_layout:add(iconTemp)
    center_layout:add(widgetTemp)

    center_layout:add(decoSpace)

    center_layout:add(iconVol)
    center_layout:add(widgetVol)

    -- Now create the top widget box
    local layout = wibox.layout.align.horizontal()
    layout.expand = "none"
    layout.children = { left_layout, center_layout, right_layout }

    s.mytopwibox:set_widget(layout)

    -- Now create the bottom widget box
    local layout = wibox.layout.align.horizontal()
    layout.second = s.mytasklist

    s.mybotwibox:set_widget(layout)
end)
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show() end),

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

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey, "Control" }, "n", awful.client.restore),

    -- Prompt
    awful.key({ modkey }, "r",     function () awful.screen.focused().mypromptbox:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run {
                      prompt = "Run Lua code: ",
                      textbox = awful.screen.focused().mypromptbox.widget,
                      exe_callback = awful.util.eval,
                      history_path = awful.util.get_cache_dir() .. "/history_eval"
                  }
              end),
    -- Menubar
    awful.key({ modkey }, "p", function() menubar.show() end),

    -- Sound control
    awful.key({ modkey, "Control" }, "Down", function () awful.spawn(musicplr, false ) vicious.force({ mpdwidget } ) end),
    awful.key({ modkey, "Control" }, "Up", function () awful.spawn( "mpc toggle", false ) vicious.force({ mpdwidget } ) end),
    awful.key({ modkey, "Control" }, "Left", function () awful.spawn( "mpc prev", false ) vicious.force({ mpdwidget } ) end ),
    awful.key({ modkey, "Control" }, "Right", function () awful.spawn( "mpc next", false ) vicious.force({ mpdwidget } ) end ),
    awful.key({ modkey, "Control" }, "m", function () awful.spawn( "pamixer --toggle-mute", false ) vicious.force({ volumewidget } ) end ),
    awful.key({ modkey, "Shift" }, "Left", function () awful.spawn( "mpc volume -1", false ) vicious.force({ mpdwidget } ) end ),
    awful.key({ modkey, "Shift" }, "Right", function () awful.spawn( "mpc volume +1", false ) vicious.force({ mpdwidget } ) end )
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Control" }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      function (c) c:mode_to_screen() end),
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
        -- View tag only
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = awful.screen.focused()
                        local tag = screen.tags[i]
                        if tag then
                            tag:view_only()
                        end
                  end),
        -- View tag only across all screens
        awful.key({ modkey , "Mod1" }, "#" .. i + 9,
                  function ()
                        for s in screen do
                           local tag = s.tags[i]
                           if tag then
                             tag:viewonly()
                           end
                        end
                  end),
        -- Toggle tag display
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = awful.screen.focused()
                      local tag = screen.tags[i]
                      if tag then
                          awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:move_to_tag(tag)
                          end
                      end
                  end),
        -- Toggle tag on focused client
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus then
                          local tag = client.focus.screen.tags[i]
                          if tag then
                              client.focus:toggle_tag(tag)
                          end
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
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen 
      }
    },

    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    -- Put Time Tracker on admin Tag
    { rule = { class = "Time Tracker" },
      properties = { screen = 1, tag = tags[2] } },
    -- Put Browsers into proper position.
    { rule = { class = "Firefox" },
      properties = { screen = 1, tag = tags[3] } },
    { rule = { class = "Chromium" },
       properties = { screen = 1, tag = tags[3] } },
    -- Put IM, Skype and Mail Client on proper screens.
    { rule = { class = "Thunderbird" },
      properties = { screen = 1, tag = tags[4] } },
    { rule = { class = "Pidgin" },
      properties = { screen = 1, tag = tags[4] } },
    { rule = { class = "Skype" },
      properties = { screen = 1, tag = tags[4] } },
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

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- Widgets that are aligned to the left
        local left_layout = wibox.layout.fixed.horizontal()
        left_layout:add(awful.titlebar.widget.iconwidget(c))

        -- Widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- The title goes in the middle
        local title = awful.titlebar.widget.titlewidget(c)
        title:buttons(awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                ))

        -- Now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_left(left_layout)
        layout:set_right(right_layout)
        layout:set_middle(title)

        awful.titlebar(c):set_widget(layout)
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}
