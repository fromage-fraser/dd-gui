DD_GUI = DD_GUI or {}
DD_GUI.Comms = DD_GUI.Comms or {}

DD_GUI.Comms.tab_columns = 2

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

function DD_GUI.Comms:load_order()
        self:build_lookup()

        local order = {}
        local seen = {}
        local file = io.open(dd_comms_tab_order_path(), "r")

        if file then
                for line in file:lines() do
                        local key = dd_comms_trim(line):lower()
                        if self.tab_lookup[key] and not seen[key] then
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

        self.order = order
end

function DD_GUI.Comms:save_order()
        if not self.order then
                return
        end

        local file = io.open(dd_comms_tab_order_path(), "w")
        if not file then
                return
        end

        for _, key in ipairs(self.order) do
                file:write(key .. "\n")
        end

        file:close()
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
                        background-color: rgba(50,80,90,180);
                        border-style: solid;
                        border-width: 1px;
                        border-color: cyan;
                        margin: 1px;
                ]]
        end

        return [[
                background-color: rgba(20,20,20,170);
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
                label:echo(self:tab_label(key), "white", "c")
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
        local tab_columns = math.max(1, self.tab_columns or 1)
        local tab_rows = math.ceil(tab_count / tab_columns)
        local tab_width = 100 / tab_columns
        local tab_height = 100 / tab_rows

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

        tab:setFontSize(8)
        tab:setBold(1)
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

        self.tab_rail = Geyser.Label:new({
                name = "DD_GUI.Comms.TabRail",
                x = "3%",
                y = "12%",
                width = "24%",
                height = "84%",
        }, DD_GUI.ChannelBox)
        self.tab_rail:setColor(0, 0, 0, 0)

        self.console_stack = Geyser.Label:new({
                name = "DD_GUI.Comms.ConsoleStack",
                x = "29%",
                y = "12%",
                width = "67%",
                height = "84%",
        }, DD_GUI.ChannelBox)
        self.console_stack:setColor(0, 0, 0, 255)

        for _, key in ipairs(self.default_order) do
                self:create_tab_button(key)
                self:create_console(key)
        end

        self:layout_tabs()
        self:switch_tab("all")
        ChannelConsole = self.consoles.all
end

function DD_GUI.Comms:switch_tab(key)
        if not self.consoles or not self.consoles[key] then
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

function DD_GUI.Comms:reorder(source, target)
        if source == target or not self.order then
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

        table.insert(self.order, target_index, source)
        self:layout_tabs()
        self:save_order()
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

function dd_comms_tab_click(key)
        if not DD_GUI or not DD_GUI.Comms then
                return
        end

        DD_GUI.Comms.drag_source = key
        DD_GUI.Comms.drag_target = nil
        DD_GUI.Comms:switch_tab(key)
end

function dd_comms_tab_move(key)
        if not DD_GUI or not DD_GUI.Comms or not DD_GUI.Comms.drag_source then
                return
        end

        DD_GUI.Comms.drag_target = key
        DD_GUI.Comms:style_tabs()
end

function dd_comms_tab_enter(key)
        if not DD_GUI or not DD_GUI.Comms or not DD_GUI.Comms.drag_source then
                return
        end

        DD_GUI.Comms.drag_target = key
        DD_GUI.Comms:style_tabs()
end

function dd_comms_tab_leave(key)
        if not DD_GUI or not DD_GUI.Comms then
                return
        end

        DD_GUI.Comms:style_tab(key)
end

function dd_comms_tab_release(key)
        if not DD_GUI or not DD_GUI.Comms then
                return
        end

        local source = DD_GUI.Comms.drag_source
        local target = DD_GUI.Comms.drag_target or key

        if source and source ~= target then
                DD_GUI.Comms:reorder(source, target)
                DD_GUI.Comms:switch_tab(source)
        else
                DD_GUI.Comms:switch_tab(key)
        end

        DD_GUI.Comms.drag_source = nil
        DD_GUI.Comms.drag_target = nil
        DD_GUI.Comms:style_tabs()
end

function build_channel_console()
        DD_GUI.Comms:build()
end
