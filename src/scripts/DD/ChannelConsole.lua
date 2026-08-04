DD_GUI = DD_GUI or {}
DD_GUI.Comms = DD_GUI.Comms or {}

-- Keep the top rail readable in the narrow channel box while allowing it to
-- grow to a second row when more channels are available.
DD_GUI.Comms.tab_columns = 8
DD_GUI.Comms.tab_row_height = 8
DD_GUI.Comms.drag_threshold = 5

-- DD4 ANSI reset defaults, converted from its xterm 256-colour indices.
DD_GUI.Comms.tab_definitions = {
        { key = "all",      label = "All",   colour = { 255, 255, 255 } },
        { key = "auction",  label = "Auc",   colour = { 255, 0, 255 } },
        { key = "chat",     label = "Chat",  colour = { 255, 255, 0 } },
        { key = "server",   label = "Serv",  colour = { 0, 128, 128 } },
        { key = "immtalk",  label = "Imm",   colour = { 0, 0, 255 } },
        { key = "music",    label = "Music", colour = { 255, 0, 255 } },
        { key = "question", label = "Quest", colour = { 255, 0, 255 } },
        { key = "shout",    label = "Shout", colour = { 255, 0, 0 } },
        { key = "yell",     label = "Yell",  colour = { 255, 0, 0 } },
        { key = "info",     label = "Info",  colour = { 255, 0, 255 } },
        { key = "clan",     label = "Clan",  colour = { 192, 192, 192 } },
        { key = "dirtalk",  label = "Dir",   colour = { 0, 95, 175 } },
        { key = "arena",    label = "Arena", colour = { 255, 0, 255 } },
        { key = "newbie",   label = "Newb",  colour = { 0, 255, 255 } },
        { key = "say",      label = "Say",   colour = { 255, 255, 255 } },
        { key = "tell",     label = "Tell",  colour = { 0, 255, 0 } },
        { key = "group",    label = "Group", colour = { 0, 255, 0 } },
        { key = "unknown",  label = "Other", colour = { 255, 255, 255 } },
}

function dd_comms_tab_order_path()
        return string.gsub(getMudletHomeDir() .. "/dragons_domain_comms_tabs.txt", "\\", "/")
end

function dd_comms_history_path()
        return string.gsub(getMudletHomeDir() .. "/dragons_domain_comms.log", "\\", "/")
end

local function dd_comms_trim(value)
        return string.gsub(tostring(value or ""), "^%s*(.-)%s*$", "%1")
end

local function dd_comms_title(value)
        value = tostring(value or "")
        if value == "" then
                return value
        end

        return string.upper(string.sub(value, 1, 1)) .. string.sub(value, 2)
end

local function dd_comms_boolean(value)
        return value == true or value == 1 or value == "1" or value == "true"
end

local function dd_comms_escape(value)
        value = tostring(value or "")
        value = string.gsub(value, "\\", "\\\\")
        value = string.gsub(value, "\r", "\\r")
        value = string.gsub(value, "\n", "\\n")
        value = string.gsub(value, "\t", "\\t")
        return value
end

local function dd_comms_unescape(value)
        return string.gsub(value or "", "\\(.)", function(character)
                if character == "n" then
                        return "\n"
                elseif character == "r" then
                        return "\r"
                elseif character == "t" then
                        return "\t"
                end

                return character
        end)
end

function DD_GUI.Comms:build_lookup()
        self.tab_lookup = {}
        self.tab_labels_by_key = {}
        self.default_order = {}

        for _, definition in ipairs(self.tab_definitions) do
                self.tab_lookup[definition.key] = definition
                self.tab_labels_by_key[definition.key] = definition.label
                table.insert(self.default_order, definition.key)
        end
end

function DD_GUI.Comms:ensure_channel_definition(key)
        key = self:normalise_channel_key(key)
        if key == "" or self.tab_lookup[key] then
                return key
        end

        local definition = {
                key = key,
                label = dd_comms_title(key),
                colour = { 255, 255, 255 },
        }

        self.tab_lookup[key] = definition
        self.tab_labels_by_key[key] = definition.label
        table.insert(self.default_order, key)

        if self.preferred_order then
                local already_preferred = false
                for _, preferred_key in ipairs(self.preferred_order) do
                        if preferred_key == key then
                                already_preferred = true
                                break
                        end
                end

                if not already_preferred then
                        table.insert(self.preferred_order, key)
                end
        end

        return key
end

function DD_GUI.Comms:load_order()
        self:build_lookup()

        local order = { "all" }
        local seen = {}
        seen.all = true
        local file = io.open(dd_comms_tab_order_path(), "r")

        if file then
                for line in file:lines() do
                        local key = dd_comms_trim(line):lower()
                        if key ~= "all" and self.tab_lookup[key] and not seen[key] then
                                table.insert(order, key)
                                seen[key] = true
                        end
                end
                file:close()
        end

        for _, key in ipairs(self.default_order) do
                if not seen[key] then
                        table.insert(order, key)
                end
        end

        self.preferred_order = order
        self.order = { "all" }
end

function DD_GUI.Comms:save_order()
        if not self.preferred_order then
                return
        end

        local file = io.open(dd_comms_tab_order_path(), "w")
        if not file then
                return
        end

        for _, key in ipairs(self.preferred_order) do
                file:write(key .. "\n")
        end

        file:close()
end

function DD_GUI.Comms:load_history()
        self.history = {}
        local file = io.open(dd_comms_history_path(), "r")

        if not file then
                return
        end

        for line in file:lines() do
                local key, raw_channel, speaker, text = string.match(line, "^(.-)\t(.-)\t(.-)\t(.*)$")
                if key and raw_channel and speaker and text then
                        table.insert(self.history, {
                                key = self:normalise_channel_key(dd_comms_unescape(key)),
                                raw_channel = dd_comms_unescape(raw_channel),
                                speaker = dd_comms_unescape(speaker),
                                text = dd_comms_unescape(text),
                        })
                end
        end

        file:close()
end

function DD_GUI.Comms:save_history_entry(key, raw_channel, speaker, text)
        local entry = {
                key = self:normalise_channel_key(key),
                raw_channel = tostring(raw_channel or key or ""),
                speaker = tostring(speaker or ""),
                text = tostring(text or ""),
        }

        self.history = self.history or {}
        table.insert(self.history, entry)

        local file = io.open(dd_comms_history_path(), "a")
        if not file then
                return
        end

        file:write(
                dd_comms_escape(entry.key), "\t",
                dd_comms_escape(entry.raw_channel), "\t",
                dd_comms_escape(entry.speaker), "\t",
                dd_comms_escape(entry.text), "\n")
        file:close()
end

function DD_GUI.Comms:is_channel_visible(key)
        if key == "all" then
                return true
        end

        local state = self.channel_state and self.channel_state[key]
        return state and state.access and state.enabled
end

function DD_GUI.Comms:visible_order()
        local order = { "all" }
        local seen = { all = true }
        local preferred_order = self.preferred_order or self.default_order or {}

        for _, key in ipairs(preferred_order) do
                if not seen[key] and self:is_channel_visible(key) then
                        table.insert(order, key)
                        seen[key] = true
                end
        end

        return order
end

function DD_GUI.Comms:ensure_channel_widget(key)
        if not self.tab_buttons or not self.tab_rail or not self.console_stack then
                return
        end

        local changed = false
        if not self.tab_buttons[key] then
                self:create_tab_button(key)
                changed = true
        end

        if not self.consoles[key] then
                self:create_console(key)
                changed = true
        end

        if changed and DD_GUI.raise_info_box_contents then
                DD_GUI.raise_info_box_contents()
        end
end

function DD_GUI.Comms:refresh_tabs()
        if not self.tab_buttons then
                return
        end

        self.order = self:visible_order()
        local visible = {}
        for _, key in ipairs(self.order) do
                visible[key] = true
        end

        for key, tab in pairs(self.tab_buttons) do
                if visible[key] then
                        tab:show()
                else
                        tab:hide()
                end
        end

        if self.drag_source and not visible[self.drag_source] then
                self.drag_source = nil
                self.drag_target = nil
                self.drag_before_target = nil
                self.dragging = nil
        end

        self:layout_tabs()

        if self.current_tab and not visible[self.current_tab] then
                self:switch_tab("all")
        else
                self:style_tabs()
        end

        if DD_GUI.raise_info_box_contents then
                DD_GUI.raise_info_box_contents()
        end
end

function DD_GUI.Comms:handle_channel_state(state)
        if type(state) ~= "table" then
                return
        end

        local channels = state.channels or state
        if type(channels) ~= "table" then
                return
        end

        self.channel_state = {}

        for _, channel in pairs(channels) do
                if type(channel) == "table" then
                        local key = self:ensure_channel_definition(channel.name or channel.channel)
                        if key ~= "" then
                                self.channel_state[key] = {
                                        access = dd_comms_boolean(channel.access),
                                        enabled = dd_comms_boolean(channel.enabled),
                                        receiving = dd_comms_boolean(channel.receiving),
                                }
                                self:ensure_channel_widget(key)
                        end
                end
        end

        self:refresh_tabs()
end

function DD_GUI.Comms:restore_history()
        if not self.history or not self.consoles then
                return
        end

        for _, entry in ipairs(self.history) do
                local key = self:ensure_channel_definition(entry.key)
                self:ensure_channel_widget(key)
                local raw_channel = entry.raw_channel or key
                local display_channel = self:display_channel(key, raw_channel)
                local message = self:format_message(display_channel, entry.speaker, entry.text)

                self:echo_message(self.consoles.all, key, message)
                if key ~= "all" and self.consoles[key] then
                        self:echo_message(self.consoles[key], key, message)
                end
        end
end

function DD_GUI.Comms:tab_label(key)
        return self.tab_labels_by_key[key] or dd_comms_title(key)
end

function DD_GUI.Comms:tab_colour(key)
        local definition = self.tab_lookup and self.tab_lookup[key]

        if definition and definition.colour then
                return definition.colour
        end

        return { 255, 255, 255 }
end

function DD_GUI.Comms:rgb_string(key)
        local colour = self:tab_colour(key)
        return string.format("%d,%d,%d", colour[1], colour[2], colour[3])
end

function DD_GUI.Comms:normalise_channel_key(raw_channel)
        local key = dd_comms_trim(raw_channel):lower()

        key = string.gsub(key, "^notify%.channel%.", "")
        key = string.gsub(key, "^notify%.", "")

        return key
end

function DD_GUI.Comms:comm_channel(comm)
        local channel = comm.channel
        local notify_channel = comm.notify_channel or comm.notifyChannel or comm.notify

        if not channel or dd_comms_trim(channel) == "" then
                return notify_channel or "unknown"
        end

        local key = self:normalise_channel_key(channel)
        if key == "comm" or key == "communication" or key == "communications" then
                return notify_channel or channel
        end

        return channel
end

function DD_GUI.Comms:tab_css(key)
        if DD_GUI.Theme then
                return DD_GUI.Theme:tab_css(
                        key == self.current_tab,
                        key == self.drag_target and key ~= self.drag_source
                )
        end

        if key == self.current_tab then
                return [[
                        background-color: rgba(0,120,135,190);
                        border-style: solid;
                        border-width: 1px;
                        border-color: cyan;
                        margin: 1px;
                ]]
        end

        if key == self.drag_target and key ~= self.drag_source then
                return [[
                        background-color: rgba(0,0,0,180);
                        border-style: solid;
                        border-width: 1px;
                        border-color: cyan;
                        margin: 1px;
                ]]
        end

        return [[
                background-color: rgba(0,0,0,170);
                border-style: solid;
                border-width: 1px;
                border-color: rgb(45,45,45);
                margin: 1px;
        ]]
end

function DD_GUI.Comms:style_tab(key)
        local label = self.tab_buttons and self.tab_buttons[key]
        if not label then
                return
        end

        label:setStyleSheet(self:tab_css(key))
        if key == self.current_tab then
                label:echo(self:tab_label(key), "black", "c")
        else
                label:echo(self:tab_label(key), "<" .. self:rgb_string(key) .. ">", "c")
        end
end

function DD_GUI.Comms:style_tabs()
        if not self.order then
                return
        end

        for _, key in ipairs(self.order) do
                self:style_tab(key)
        end
end

function DD_GUI.Comms:layout_tabs()
        if not self.order or not self.tab_buttons then
                return
        end

        local tab_count = #self.order
        local tab_columns = math.min(math.max(1, self.tab_columns or 1), tab_count)
        local tab_rows = math.ceil(tab_count / tab_columns)
        local tab_width = 100 / tab_columns
        local tab_height = 100 / tab_rows

        -- The tabs now occupy the top of the box. Resize the console below
        -- them so a changing channel list never overlaps either view.
        if self.tab_rail and self.console_stack then
                local tab_rail_height = math.max(10, tab_rows * (self.tab_row_height or 8))
                local console_y = 3 + tab_rail_height + 2
                local console_height = math.max(20, 100 - console_y - 3)

                self.tab_rail:move("3%", "3%")
                self.tab_rail:resize("94%", tostring(tab_rail_height) .. "%")
                self.console_stack:move("3%", tostring(console_y) .. "%")
                self.console_stack:resize("94%", tostring(console_height) .. "%")
        end

        for index, key in ipairs(self.order) do
                local tab = self.tab_buttons[key]
                if tab then
                        local tab_index = index - 1
                        local tab_column = tab_index % tab_columns
                        local tab_row = math.floor(tab_index / tab_columns)

                        tab:move(tostring(tab_column * tab_width) .. "%", tostring(tab_row * tab_height) .. "%")
                        tab:resize(tostring(tab_width) .. "%", tostring(tab_height) .. "%")
                        self:style_tab(key)
                end
        end
end

function DD_GUI.Comms:create_tab_button(key)
        local tab = Geyser.Label:new({
                name = "DD_GUI.Comms.Tab." .. key,
                x = "0%",
                y = "0%",
                width = "50%",
                height = "10%",
        }, self.tab_rail)

        if DD_GUI.Theme then
                DD_GUI.Theme:style_label(tab, 8, true)
        else
                tab:setFontSize(8)
                tab:setBold(1)
        end
        tab:setClickCallback("dd_comms_tab_click", key)
        tab:setReleaseCallback("dd_comms_tab_release", key)
        tab:setMoveCallback("dd_comms_tab_move", key)

        if type(setLabelOnEnter) == "function" then
                setLabelOnEnter(tab.name, "dd_comms_tab_enter", key)
        end

        if type(setLabelOnLeave) == "function" then
                setLabelOnLeave(tab.name, "dd_comms_tab_leave", key)
        else
                tab:setOnLeave("dd_comms_tab_leave", key)
        end

        self.tab_buttons[key] = tab
end

function DD_GUI.Comms:echo_message(console, key, message)
        if not console or not message then
                return
        end

        local colour = self:tab_colour(key)

        if type(setFgColor) == "function" and console.name then
                setFgColor(console.name, colour[1], colour[2], colour[3])
        end

        console:echo(message)
end

function DD_GUI.Comms:create_console(key)
        local console = Geyser.MiniConsole:new({
                name = "DD_GUI.Comms.Console." .. key,
                x = "0%",
                y = "0%",
                width = "100%",
                height = "100%",
                autoWrap = true,
                color = "black",
                scrollBar = true,
                fontSize = 8,
        }, self.console_stack)

        if DD_GUI.Theme then
                DD_GUI.Theme:style_console(console, 8)
        end

        if console.setBufferSize then
                console:setBufferSize(100000, 1000)
        end

        if console.clear then
                console:clear()
        end

        console:enableCommandLine()
        console:hide()
        self.consoles[key] = console
end

function DD_GUI.Comms:build()
        if ChannelConsole and ChannelConsole.hide then
                ChannelConsole:hide()
        end

        if type(disableTrigger) == "function" then
                pcall(disableTrigger, "Channels")
        end

        self:load_order()
        self.tab_buttons = {}
        self.consoles = {}
        self.channel_state = {}
        self.drag_source = nil
        self.drag_target = nil
        self.drag_before_target = nil
        self.drag_press_x = nil
        self.drag_press_y = nil
        self.dragging = nil

        self.tab_rail = Geyser.Label:new({
                name = "DD_GUI.Comms.TabRail",
                x = "3%",
                y = "3%",
                width = "94%",
                height = "10%",
        }, DD_GUI.ChannelBox)
        self.tab_rail:setColor(0, 0, 0, 0)

        self.console_stack = Geyser.Label:new({
                name = "DD_GUI.Comms.ConsoleStack",
                x = "3%",
                y = "15%",
                width = "94%",
                height = "82%",
        }, DD_GUI.ChannelBox)
        self.console_stack:setColor(0, 0, 0, 255)

        for _, key in ipairs(self.default_order) do
                self:create_tab_button(key)
                self:create_console(key)
        end

        self:load_history()
        self:restore_history()
        self:refresh_tabs()
        self:layout_tabs()
        self:switch_tab("all")
        ChannelConsole = self.consoles.all

        if gmcp and gmcp.Char and gmcp.Char.Channels then
                self:handle_channel_state(gmcp.Char.Channels)
        end
end

function DD_GUI.Comms:switch_tab(key)
        if not self.consoles or not self.consoles[key] or not self:is_channel_visible(key) then
                key = "all"
        end

        if self.current_tab and self.consoles[self.current_tab] then
                self.consoles[self.current_tab]:hide()
        end

        self.current_tab = key
        self.consoles[key]:show()
        ChannelConsole = self.consoles[key]
        self:style_tabs()
end

function DD_GUI.Comms:reorder(source, target, before_target)
        if source == target or source == "all" or target == "all" or not self.order then
                return
        end

        local source_index
        local target_index

        for index, key in ipairs(self.order) do
                if key == source then
                        source_index = index
                elseif key == target then
                        target_index = index
                end
        end

        if not source_index or not target_index then
                return
        end

        table.remove(self.order, source_index)

        if source_index < target_index then
                target_index = target_index - 1
        end

        if not before_target then
                target_index = target_index + 1
        end

        table.insert(self.order, target_index, source)

        local preferred_source_index
        local preferred_target_index
        for index, key in ipairs(self.preferred_order or {}) do
                if key == source then
                        preferred_source_index = index
                elseif key == target then
                        preferred_target_index = index
                end
        end

        if preferred_source_index and preferred_target_index then
                table.remove(self.preferred_order, preferred_source_index)
                if preferred_source_index < preferred_target_index then
                        preferred_target_index = preferred_target_index - 1
                end

                if not before_target then
                        preferred_target_index = preferred_target_index + 1
                end

                table.insert(self.preferred_order, preferred_target_index, source)
        end

        self:layout_tabs()
        self:save_order()
end

function DD_GUI.Comms:tab_event_position(key, event)
        if not event or event.x == nil or event.y == nil then
                return nil, nil
        end

        local tab = self.tab_buttons and self.tab_buttons[key]
        if not tab or not tab.get_x or not tab.get_y then
                return nil, nil
        end

        local local_x = tonumber(event.x)
        local local_y = tonumber(event.y)
        if not local_x or not local_y then
                return nil, nil
        end

        -- Mudlet's globalX/globalY are screen coordinates, while Geyser's
        -- get_x/get_y values are relative to the Mudlet window.
        return tab:get_x() + local_x, tab:get_y() + local_y
end

function DD_GUI.Comms:drop_location(x, y)
        x = tonumber(x)
        y = tonumber(y)
        if not x or not y or not self.order then
                return nil
        end

        for _, key in ipairs(self.order) do
                local tab = self.tab_buttons and self.tab_buttons[key]
                if tab and tab.get_x and tab.get_y and tab.get_width and tab.get_height then
                        local tab_x = tab:get_x()
                        local tab_y = tab:get_y()
                        local width = tab:get_width()
                        local height = tab:get_height()

                        if x >= tab_x and x <= tab_x + width and
                           y >= tab_y and y <= tab_y + height then
                                return key, x < tab_x + (width / 2)
                        end
                end
        end

        return nil
end

function DD_GUI.Comms:update_drag_target(key, event, fallback)
        if not self.drag_source or not self.dragging then
                return
        end

        local x, y = self:tab_event_position(key, event)
        local target, before_target = self:drop_location(x, y)
        target = target or fallback
        before_target = before_target == nil and true or before_target

        if target ~= self.drag_target or before_target ~= self.drag_before_target then
                self.drag_target = target
                self.drag_before_target = before_target
                self:style_tabs()
        end
end

function DD_GUI.Comms:resolve_channel(channel)
        local raw_channel = dd_comms_trim(channel)
        local key = self:normalise_channel_key(raw_channel)

        if key == "" then
                return "unknown", "unknown"
        end

        if string.match(key, "^tell%s+") then
                return "tell", raw_channel
        end

        if self.tab_lookup[key] then
                return key, raw_channel
        end

        return "unknown", raw_channel
end

function DD_GUI.Comms:display_channel(key, raw_channel)
        if key == "tell" and raw_channel and raw_channel:lower() ~= "tell" then
                return dd_comms_title(raw_channel)
        end

        return self:tab_label(key)
end

function DD_GUI.Comms:format_message(channel, speaker, text)
        speaker = dd_comms_trim(speaker)
        text = tostring(text or "")

        local speaker_prefix = ""
        if speaker ~= "" then
                speaker_prefix = speaker .. ": "
        end

        return string.format("[%s] %s%s\n", channel, speaker_prefix, text)
end

function DD_GUI.Comms:handle_comm(comm)
        if not comm or not self.consoles then
                return
        end

        local text = comm.text or comm.message
        if text == nil then
                return
        end

        local raw_channel = self:comm_channel(comm)
        local key, display_raw_channel = self:resolve_channel(raw_channel)
        local speaker = comm.speaker or comm.talker or comm.sender or ""
        local display_channel = self:display_channel(key, display_raw_channel)
        local message = self:format_message(display_channel, speaker, text)

        self:ensure_channel_definition(key)
        self:ensure_channel_widget(key)
        self:save_history_entry(key, display_raw_channel, speaker, text)
        self:echo_message(self.consoles.all, key, message)

        if key ~= "all" and self.consoles[key] then
                self:echo_message(self.consoles[key], key, message)
        end
end

function DD_GUI.Comms:handle_gmcp()
        if not gmcp or not gmcp.Comm or not gmcp.Comm.Channel then
                return
        end

        self:handle_comm(gmcp.Comm.Channel.Text)
end

function dd_comms_tab_click(key, event)
        if not DD_GUI or not DD_GUI.Comms then
                return
        end

        if event and event.button and event.button ~= "LeftButton" then
                return
        end

        DD_GUI.Comms.drag_source = key
        DD_GUI.Comms.drag_target = key
        DD_GUI.Comms.drag_before_target = true
        DD_GUI.Comms.dragging = false
        DD_GUI.Comms.drag_press_x, DD_GUI.Comms.drag_press_y =
                DD_GUI.Comms:tab_event_position(key, event)
        DD_GUI.Comms:switch_tab(key)
end

function dd_comms_tab_move(key, event)
        if not DD_GUI or not DD_GUI.Comms or not DD_GUI.Comms.drag_source then
                return
        end

        if not event or not event.buttons or not table.contains(event.buttons, "LeftButton") then
                return
        end

        local source = DD_GUI.Comms.drag_source
        local x, y = DD_GUI.Comms:tab_event_position(source, event)
        if not DD_GUI.Comms.dragging then
                local distance_x = math.abs((x or 0) - (DD_GUI.Comms.drag_press_x or x or 0))
                local distance_y = math.abs((y or 0) - (DD_GUI.Comms.drag_press_y or y or 0))
                if math.max(distance_x, distance_y) < DD_GUI.Comms.drag_threshold then
                        return
                end

                DD_GUI.Comms.dragging = true
        end

        DD_GUI.Comms:update_drag_target(source, event, key)
end

function dd_comms_tab_enter(key, event)
        if not DD_GUI or not DD_GUI.Comms or not DD_GUI.Comms.dragging then
                return
        end

        DD_GUI.Comms:update_drag_target(key, event, key)
end

function dd_comms_tab_leave(key)
        if not DD_GUI or not DD_GUI.Comms then
                return
        end

        DD_GUI.Comms:style_tab(key)
end

function dd_comms_tab_release(key, event)
        if not DD_GUI or not DD_GUI.Comms then
                return
        end

        local source = DD_GUI.Comms.drag_source
        local target = DD_GUI.Comms.drag_target or key
        local before_target = DD_GUI.Comms.drag_before_target
        if source and DD_GUI.Comms.dragging then
                local x, y = DD_GUI.Comms:tab_event_position(source, event)
                local event_target, event_before_target = DD_GUI.Comms:drop_location(x, y)
                target = event_target or target
                before_target = event_before_target == nil and before_target or event_before_target
        end

        if source and DD_GUI.Comms.dragging and source ~= target then
                DD_GUI.Comms:reorder(source, target, before_target)
                DD_GUI.Comms:switch_tab(source)
        else
                DD_GUI.Comms:switch_tab(source or key)
        end

        DD_GUI.Comms.drag_source = nil
        DD_GUI.Comms.drag_target = nil
        DD_GUI.Comms.drag_before_target = nil
        DD_GUI.Comms.drag_press_x = nil
        DD_GUI.Comms.drag_press_y = nil
        DD_GUI.Comms.dragging = nil
        DD_GUI.Comms:style_tabs()
end

function build_channel_console()
        DD_GUI.Comms:build()
end
