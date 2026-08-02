DD_GUI = DD_GUI or {}
DD_GUI.Comms = DD_GUI.Comms or {}

DD_GUI.Comms.tab_definitions = {
        { key = "all",      label = "All" },
        { key = "auction",  label = "Auction" },
        { key = "chat",     label = "Chat" },
        { key = "server",   label = "Server" },
        { key = "immtalk",  label = "Imm" },
        { key = "music",    label = "Music" },
        { key = "question", label = "Question" },
        { key = "shout",    label = "Shout" },
        { key = "yell",     label = "Yell" },
        { key = "info",     label = "Info" },
        { key = "clan",     label = "Clan" },
        { key = "dirtalk",  label = "Dir" },
        { key = "arena",    label = "Arena" },
        { key = "newbie",   label = "Newbie" },
        { key = "say",      label = "Say" },
        { key = "tell",     label = "Tell" },
        { key = "group",    label = "Group" },
        { key = "unknown",  label = "Other" },
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
        label:setFgColor(key == self.current_tab and "white" or "cyan")
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
        local tab_height = 100 / tab_count

        for index, key in ipairs(self.order) do
                local tab = self.tab_buttons[key]
                if tab then
                        tab:move("0%", tostring((index - 1) * tab_height) .. "%")
                        tab:resize("100%", tostring(tab_height) .. "%")
                        tab:echo(self:tab_label(key))
                        tab:setAlignment("center")
                        self:style_tab(key)
                end
        end
end

function DD_GUI.Comms:create_tab_button(key)
        local tab = Geyser.Label:new({
                name = "DD_GUI.Comms.Tab." .. key,
                x = "0%",
                y = "0%",
                width = "100%",
                height = "5%",
        }, self.tab_rail)

        tab:setFontSize(7)
        tab:setBold(1)
        tab:setClickCallback("dd_comms_tab_click", key)
        tab:setReleaseCallback("dd_comms_tab_release", key)
        tab:setMoveCallback("dd_comms_tab_move", key)
        tab:setOnLeave("dd_comms_tab_leave", key)

        self.tab_buttons[key] = tab
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
                x = "4%",
                y = "13%",
                width = "29%",
                height = "83%",
        }, DD_GUI.ChannelBox)
        self.tab_rail:setColor(0, 0, 0, 0)

        self.console_stack = Geyser.Label:new({
                name = "DD_GUI.Comms.ConsoleStack",
                x = "35%",
                y = "13%",
                width = "61%",
                height = "83%",
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
        local key = raw_channel:lower()

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

        local raw_channel = comm.channel or comm.notify_channel or comm.notifyChannel or comm.notify or "unknown"
        local key, display_raw_channel = self:resolve_channel(raw_channel)
        local speaker = comm.speaker or comm.talker or comm.sender or ""
        local display_channel = self:display_channel(key, display_raw_channel)
        local message = self:format_message(display_channel, speaker, text)

        self.consoles.all:echo(message)

        if key ~= "all" and self.consoles[key] then
                self.consoles[key]:echo(message)
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

function dd_comms_tab_leave(key)
        if not DD_GUI or not DD_GUI.Comms then
                return
        end

        if DD_GUI.Comms.drag_target == key then
                DD_GUI.Comms.drag_target = nil
                DD_GUI.Comms:style_tab(key)
        end
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
