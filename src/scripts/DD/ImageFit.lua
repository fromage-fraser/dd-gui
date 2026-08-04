DD_GUI = DD_GUI or {}

DD_GUI.ImageFit = DD_GUI.ImageFit or {
        widgets = {},
}

local function image_dimensions(path, fallback)
        local fallback_width = (fallback and fallback.width) or 1
        local fallback_height = (fallback and fallback.height) or 1

        if type(getImageSize) == "function" then
                local ok, width, height = pcall(getImageSize, path)
                if ok and tonumber(width) and tonumber(height) and
                   tonumber(width) > 0 and tonumber(height) > 0 then
                        return tonumber(width), tonumber(height)
                end
        end

        return fallback_width, fallback_height
end

function DD_GUI.ImageFit:refresh_widget(state)
        local widget = state and state.widget
        local parent = state and state.parent
        if not widget or not parent or not widget.get_width or not parent.get_width then
                return
        end

        local parent_width = math.max(1, parent:get_width())
        local parent_height = math.max(1, parent:get_height())
        local x = parent_width * state.x_ratio
        local y = parent_height * state.y_ratio
        local max_width = math.max(1, parent_width * state.width_ratio)
        local max_height = math.max(1, parent_height * state.height_ratio)
        local width
        local height
        if state.stretch then
                width = math.min(max_width, parent_width - x)
                height = math.min(max_height, parent_height - y)
        else
                local image_ratio = state.image_height / state.image_width
                width = math.min(max_width, max_height / image_ratio)
                height = width * image_ratio

                width = math.min(width, parent_width - x)
                height = width * image_ratio
                height = math.min(height, parent_height - y)
                width = height / image_ratio
        end

        x = math.max(0, x)
        y = math.max(0, y)
        width = math.max(1, width)
        height = math.max(1, height)

        if state.align_x == "center" then
                x = parent_width * state.x_ratio + (max_width - width) / 2
        end
        if state.align_y == "center" then
                y = parent_height * state.y_ratio + (max_height - height) / 2
        end

        widget:move(math.floor(x + 0.5), math.floor(y + 0.5))
        widget:resize(math.floor(width + 0.5), math.floor(height + 0.5))

        if state.frame then
                state.frame:move(math.floor(x + 0.5), math.floor(y + 0.5))
                state.frame:resize(
                        math.floor(width + 0.5),
                        math.floor(height + 0.5)
                )
                if state.frame.raise then
                        state.frame:raise()
                end
        end
end

function DD_GUI.ImageFit:refresh_all()
        for _, state in pairs(self.widgets) do
                self:refresh_widget(state)
        end
end

function DD_GUI.ImageFit:set(widget, parent, path, options)
        if not widget or not parent or not path then
                return
        end

        options = options or {}
        local state = self.widgets[widget.name]

        if not state or state.widget ~= widget then
                local parent_width = math.max(1, parent:get_width())
                local parent_height = math.max(1, parent:get_height())
                local widget_x = widget.get_x and widget:get_x() or 0
                local widget_y = widget.get_y and widget:get_y() or 0
                local parent_x = parent.get_x and parent:get_x() or 0
                local parent_y = parent.get_y and parent:get_y() or 0

                state = {
                        widget = widget,
                        parent = parent,
                        x_ratio = options.x_ratio or math.max(0, (widget_x - parent_x) / parent_width),
                        y_ratio = options.y_ratio or math.max(0, (widget_y - parent_y) / parent_height),
                        width_ratio = options.width_ratio or
                                math.max(0.01, widget:get_width() / parent_width),
                        height_ratio = options.height_ratio or
                                math.max(0.01, widget:get_height() / parent_height),
                }
                self.widgets[widget.name] = state
        end

        state.parent = parent
        state.path = path
        state.frame = options.frame or state.frame
        state.align_x = options.align_x or state.align_x
        state.align_y = options.align_y or state.align_y
        if options.stretch ~= nil then
                state.stretch = options.stretch == true
        end
        state.image_width, state.image_height = image_dimensions(path, options.fallback)

        if widget.setBackgroundImage then
                widget:setBackgroundImage(path, "border")
        end

        self:refresh_widget(state)
end

if not DD_GUI.ImageFit.handlers_registered then
        local refresh = function()
                DD_GUI.ImageFit:refresh_all()
        end

        registerAnonymousEventHandler("sysWindowResizeEvent", refresh)
        registerAnonymousEventHandler("AdjustableContainerReposition", refresh)
        DD_GUI.ImageFit.handlers_registered = true
end
