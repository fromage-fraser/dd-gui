DD_GUI = DD_GUI or {}

-- The visible chrome is one shared frame system rather than a border on every
-- Adjustable.Container.  A shared edge can therefore be painted once when
-- two panels meet, while the same edge can still be moved as a splitter.
DD_GUI.FrameGrid = DD_GUI.FrameGrid or {}
local FrameGrid = DD_GUI.FrameGrid

FrameGrid.regions = FrameGrid.regions or {}
FrameGrid.segments = FrameGrid.segments or {}
FrameGrid.nodes = FrameGrid.nodes or {}
FrameGrid.handles = FrameGrid.handles or { h = {}, v = {} }
FrameGrid.region_colors = FrameGrid.region_colors or {}
FrameGrid.enabled = false
FrameGrid.thickness = 10
FrameGrid.node_size = 14
FrameGrid.hit_size = 14
FrameGrid.minimum_width = 90
FrameGrid.minimum_height = 48
FrameGrid.refresh_timer = nil
FrameGrid.drag = nil
FrameGrid.rendering = false
FrameGrid.gauge_dividers = FrameGrid.gauge_dividers or {}
FrameGrid.underlay_index = 0

FrameGrid.frame_names = {
        ["DD_GUI.Top"] = "LayoutTop",
        ["DD_GUI.Right"] = "LayoutRight",
        ["DD_GUI.Bottom"] = "LayoutBottom",
        ["DD_GUI.EnemyBox"] = "EnemyBox",
        ["DD_GUI.MapBox"] = "MapBox",
        ["DD_GUI.CharsheetBox"] = "CharsheetBox",
        ["DD_GUI.ChannelBox"] = "ChannelBox",
        ["DD_GUI.InventoryBox"] = "InventoryBox",
        ["DD_GUI.AffectBox"] = "AffectBox",
        ["DD_GUI.MainConsole"] = "MainConsole",
        ["compass.back"] = "CompassBox",
}

local function round(value)
        return math.floor((tonumber(value) or 0) + 0.5)
end

local function clone_bounds(bounds)
        return {
                x = bounds.x,
                y = bounds.y,
                width = bounds.width,
                height = bounds.height,
        }
end

local function delete_widget(widget)
        if not widget then
                return
        end

        if type(widget.delete) == "function" then
                pcall(function() widget:delete() end)
        elseif widget.name and type(deleteLabel) == "function" then
                pcall(deleteLabel, widget.name)
        end
end

local function set_clickthrough(widget, enabled)
        if DD_GUI.set_widget_clickthrough then
                DD_GUI.set_widget_clickthrough(widget, enabled)
        end
end

local function widget_bounds(widget)
        if not widget or type(widget.get_x) ~= "function" or
           type(widget.get_y) ~= "function" or
           type(widget.get_width) ~= "function" or
           type(widget.get_height) ~= "function" then
                return nil
        end

        local ok, x, y, width, height = pcall(function()
                return widget:get_x(), widget:get_y(),
                        widget:get_width(), widget:get_height()
        end)
        if not ok then
                return nil
        end

        x = tonumber(x)
        y = tonumber(y)
        width = tonumber(width)
        height = tonumber(height)
        if not x or not y or not width or not height or
           width < 4 or height < 4 then
                return nil
        end

        return {
                x = round(x),
                y = round(y),
                width = math.max(4, round(width)),
                height = math.max(4, round(height)),
        }
end

local function safe_sort(values)
        table.sort(values, function(left, right)
                return left < right
        end)
end

local function contains(values, value)
        for _, item in ipairs(values) do
                if item == value then
                        return true
                end
        end
        return false
end

local function axis_key(value)
        return tostring(round(value))
end

local function node_key(x, y)
        return tostring(round(x)) .. ":" .. tostring(round(y))
end

function FrameGrid:regular_color()
        return DD_GUI.Theme and DD_GUI.Theme.colors and
                DD_GUI.Theme.colors.frame or "rgb(151,27,39)"
end

function FrameGrid:is_regular_color(color)
        return not color or color == self:regular_color()
end

function FrameGrid:base_color()
        -- The transparent braid tiles sit over a true black backing. The
        -- pulse underlay supplies the controlled colour glow only while a
        -- frame is flashing or pulsing.
        return "rgb(0,0,0)"
end

function FrameGrid:asset_path(name)
        if DD_GUI.asset_path then
                local path = DD_GUI.asset_path("frame/" .. name)
                if type(io.exists) ~= "function" or io.exists(path) then
                        return path
                end
        end
        return nil
end

function FrameGrid:region_id_for_name(name)
        return self.frame_names[tostring(name or "")]
end

function FrameGrid:is_frame_box(box)
        if not box then
                return false
        end
        return box._dd_gui_frame_region_id ~= nil or
                self:region_id_for_name(box.name) ~= nil
end

function FrameGrid:clear_visuals()
        for _, widget in ipairs(self.segments) do
                delete_widget(widget._dd_gui_frame_underlay)
                delete_widget(widget)
        end
        for _, widget in ipairs(self.nodes) do
                delete_widget(widget._dd_gui_frame_underlay)
                delete_widget(widget)
        end
        self.segments = {}
        self.nodes = {}
        self.underlay_index = 0
end

function FrameGrid:clear_handles()
        for _, orientation in ipairs({ "h", "v" }) do
                for _, widget in ipairs(self.handles[orientation] or {}) do
                        delete_widget(widget)
                end
                self.handles[orientation] = {}
        end
end

function FrameGrid:clear()
        if self.refresh_timer and type(killTimer) == "function" then
                killTimer(self.refresh_timer)
        end
        self.refresh_timer = nil
        self.drag = nil
        self:clear_visuals()
        self:clear_handles()
        self.regions = {}
        self.axes = { h = {}, v = {} }
        self.gauge_dividers = {}
end

local function add_region(self, id, widget, options)
        local bounds = options and options.bounds or widget_bounds(widget)
        if not bounds then
                return
        end

        local region = {
                id = id,
                widget = widget,
                bounds = bounds,
                synthetic = options and options.synthetic == true,
                horizontal_only = options and options.horizontal_only == true,
        }
        self.regions[#self.regions + 1] = region
        self.region_by_id[id] = region
end

function FrameGrid:collect_regions()
        self.regions = {}
        self.region_by_id = {}
        self.gauge_dividers = {}

        local definitions = {
                { "EnemyBox", DD_GUI.EnemyBox },
                { "MapBox", DD_GUI.MapBox },
                { "CharsheetBox", DD_GUI.CharsheetBox },
                { "ChannelBox", DD_GUI.ChannelBox },
                { "MainConsole", ui and ui.mainconsole_container },
                { "CompassBox", compass and compass.back },
                { "InventoryBox", DD_GUI.InventoryBox },
                { "AffectBox", DD_GUI.AffectBox },
        }

        for _, definition in ipairs(definitions) do
                add_region(self, definition[1], definition[2])
        end

        -- The gauge columns have deliberate gaps between them, so frame the
        -- whole band using the main console's shared left and right edges.
        -- The fourth column intentionally leaves a small internal pad; using
        -- its right edge here would create a second vertical chain just
        -- before the main-console/right-column junction.
        local first = widget_bounds(DD_GUI.FirstColumn)
        local fourth = widget_bounds(DD_GUI.FourthColumn)
        local bottom = widget_bounds(DD_GUI.Bottom)
        local main_console = widget_bounds(ui and ui.mainconsole_container)
        if first and fourth and bottom then
                local left = main_console and main_console.x or first.x
                local right = main_console and
                        (main_console.x + main_console.width) or
                        (fourth.x + fourth.width)
                add_region(self, "GaugesBand", DD_GUI.Bottom, {
                        synthetic = true,
                        bounds = {
                                x = left,
                                y = bottom.y,
                                width = math.max(4, right - left),
                                height = bottom.height,
                        },
                })

                -- The fixed gaps between gauge columns are wide enough for
                -- a vertical braid. Keep those dividers decorative rather
                -- than treating them as resize splitters, and terminate
                -- each one with a square joiner at the outer frame edges.
                local columns = {}
                for _, column in ipairs({
                        DD_GUI.FirstColumn,
                        DD_GUI.SecondColumn,
                        DD_GUI.ThirdColumn,
                        DD_GUI.FourthColumn,
                }) do
                        local bounds = widget_bounds(column)
                        if bounds then
                                columns[#columns + 1] = bounds
                        end
                end
                table.sort(columns, function(left_column, right_column)
                        return left_column.x < right_column.x
                end)
                for index = 1, #columns - 1 do
                        local left_column = columns[index]
                        local right_column = columns[index + 1]
                        local gap_start = left_column.x + left_column.width
                        local gap_width = right_column.x - gap_start
                        -- The columns normally touch; the gauge's own
                        -- horizontal inset creates the visible black gap.
                        -- Anchor a divider on that shared boundary, while
                        -- avoiding dividers when a user has made columns
                        -- overlap substantially.
                        if gap_width >= -self.thickness / 2 then
                                self.gauge_dividers[#self.gauge_dividers + 1] = {
                                        x = gap_start + gap_width / 2,
                                        y = bottom.y,
                                        height = bottom.height,
                                }
                        end
                end
        end
end

local function add_axis_edge(axes, orientation, position, start, finish,
                             region, side)
        if finish <= start then
                return
        end

        local key = axis_key(position)
        local axis = axes[orientation][key]
        if not axis then
                axis = {
                        position = position,
                        entries = {},
                        points = {},
                }
                axes[orientation][key] = axis
        end

        axis.entries[#axis.entries + 1] = {
                region = region,
                side = side,
                start = start,
                finish = finish,
        }
        axis.points[#axis.points + 1] = start
        axis.points[#axis.points + 1] = finish
end

function FrameGrid:make_axes()
        local axes = { h = {}, v = {} }
        local nodes = {}

        for _, region in ipairs(self.regions) do
                local b = region.bounds
                add_axis_edge(axes, "h", b.y, b.x, b.x + b.width,
                        region, "top")
                add_axis_edge(axes, "h", b.y + b.height, b.x,
                        b.x + b.width, region, "bottom")
                if not region.horizontal_only then
                        add_axis_edge(axes, "v", b.x, b.y, b.y + b.height,
                                region, "left")
                        add_axis_edge(axes, "v", b.x + b.width, b.y,
                                b.y + b.height, region, "right")
                end

                for _, corner in ipairs({
                        { x = b.x, y = b.y },
                        { x = b.x + b.width, y = b.y },
                        { x = b.x, y = b.y + b.height },
                        { x = b.x + b.width, y = b.y + b.height },
                }) do
                        local key = node_key(corner.x, corner.y)
                        nodes[key] = nodes[key] or {
                                x = corner.x,
                                y = corner.y,
                                regions = {},
                        }
                        if not contains(nodes[key].regions, region) then
                                nodes[key].regions[#nodes[key].regions + 1] = region
                        end
                end
        end

        local function materialize_axis(axis_table)
                local result = {}
                for _, axis in pairs(axis_table) do
                        safe_sort(axis.points)
                        local points = {}
                        for _, point in ipairs(axis.points) do
                                if #points == 0 or math.abs(point - points[#points]) > 0.5 then
                                        points[#points + 1] = point
                                end
                        end

                        local start = points[1]
                        local finish = points[#points]
                        if start and finish and finish - start >= 8 then
                                result[#result + 1] = {
                                        position = axis.position,
                                        start = start,
                                        finish = finish,
                                        entries = axis.entries,
                                }
                        end
                end

                table.sort(result, function(left, right)
                        return left.position < right.position
                end)
                return result
        end

        local function merge_nearby_axes(axes_list)
                local result = {}
                for _, axis in ipairs(axes_list) do
                        local match
                        for _, existing in ipairs(result) do
                                local overlap = math.min(existing.finish,
                                        axis.finish) - math.max(existing.start,
                                        axis.start)
                                if math.abs(existing.position - axis.position) <= 2 and
                                   overlap >= 8 then
                                        match = existing
                                        break
                                end
                        end

                        if match then
                                match.position = (match.position + axis.position) / 2
                                match.start = math.min(match.start, axis.start)
                                match.finish = math.max(match.finish, axis.finish)
                                for _, entry in ipairs(axis.entries or {}) do
                                        match.entries[#match.entries + 1] = entry
                                end
                        else
                                result[#result + 1] = axis
                        end
                end

                table.sort(result, function(left, right)
                        return left.position < right.position
                end)
                return result
        end

        self.axes = {
                h = merge_nearby_axes(materialize_axis(axes.h)),
                v = merge_nearby_axes(materialize_axis(axes.v)),
        }

        -- Independent percentage layouts can land a shared corner a pixel
        -- apart after rounding. Merge those near-identical corners so a
        -- junction is always one marker, especially where the gauges meet
        -- the main console and the right-hand column.
        local merged_nodes = {}
        for _, node in pairs(nodes) do
                local match
                for _, existing in pairs(merged_nodes) do
                        if math.abs(existing.x - node.x) <= 2 and
                           math.abs(existing.y - node.y) <= 2 then
                                match = existing
                                break
                        end
                end

                if match then
                        for _, region in ipairs(node.regions) do
                                if not contains(match.regions, region) then
                                        match.regions[#match.regions + 1] = region
                                end
                        end
                else
                        local key = node_key(node.x, node.y)
                        merged_nodes[key] = {
                                x = node.x,
                                y = node.y,
                                regions = node.regions,
                        }
                end
        end
        self.nodes_by_key = merged_nodes
end

local function edge_owner_color(self, entries)
        local regular = self:regular_color()

        -- The enemy/map divider is a shared edge. Give combat state an
        -- explicit priority there so a regular map repaint cannot mask the
        -- enemy pulse on that one side.
        local enemy_color = self.region_colors.EnemyBox
        if enemy_color and enemy_color ~= regular then
                for _, entry in ipairs(entries or {}) do
                        if entry.region and entry.region.id == "EnemyBox" then
                                return enemy_color
                        end
                end
        end

        local selected = regular
        for _, entry in ipairs(entries or {}) do
                local color = self.region_colors[entry.region.id]
                if color and color ~= regular then
                        selected = color
                        break
                end
        end
        return selected
end

function FrameGrid:transparent_css()
        return [[
                background-color: rgba(0,0,0,0);
                border: 0px;
                border-radius: 0px;
                margin: 0px;
        ]]
end

function FrameGrid:underlay_css(color, orientation, node)
        if self:is_regular_color(color) or color == "rgb(0,0,0)" then
                return string.format([[
                        background-color: %s;
                        border: 0px;
                        border-radius: 0px;
                        margin: 0px;
                ]], self:base_color())
        end

        if node then
                return string.format([[
                        background-color: qradialgradient(
                                cx: 0.5, cy: 0.5, radius: 0.72,
                                stop: 0 %s,
                                stop: 0.58 %s,
                                stop: 1 rgba(0,0,0,0)
                        );
                        border: 0px;
                        border-radius: 0px;
                        margin: 0px;
                ]], color, color)
        end

        local x2, y2 = "0", "1"
        if orientation == "v" then
                x2, y2 = "1", "0"
        end

        return string.format([[
                background-color: qlineargradient(
                        x1: 0, y1: 0, x2: %s, y2: %s,
                        stop: 0 rgba(0,0,0,0),
                        stop: 0.28 %s,
                        stop: 0.72 %s,
                        stop: 1 rgba(0,0,0,0)
                );
                border: 0px;
                border-radius: 0px;
                margin: 0px;
        ]], x2, y2, color, color)
end

function FrameGrid:ensure_underlay(widget)
        if not widget then
                return nil
        end
        if widget._dd_gui_frame_underlay then
                return widget._dd_gui_frame_underlay
        end

        local bounds = widget_bounds(widget)
        if not bounds or not Geyser or not Geyser.Label then
                return nil
        end

        self.underlay_index = (self.underlay_index or 0) + 1
        local underlay = Geyser.Label:new({
                name = "DD_GUI.FrameGrid.Underlay." .. self.underlay_index,
                x = bounds.x,
                y = bounds.y,
                width = bounds.width,
                height = bounds.height,
        }, main)
        underlay:setStyleSheet(self:transparent_css())
        set_clickthrough(underlay, true)
        widget._dd_gui_frame_underlay = underlay
        return underlay
end

function FrameGrid:line_style(widget, orientation, color)
        local regular = self:is_regular_color(color)
        local css = string.format([[ 
                background-color: %s;
                border: 0px;
                border-radius: 0px;
                margin: 0px;
        ]], regular and self:base_color() or color)

        local underlay = self:ensure_underlay(widget)
        if underlay then
                underlay:setStyleSheet(self:underlay_css(
                        regular and self:base_color() or color,
                        orientation,
                        false
                ))
        end

        -- Keep the braid foreground in every state. The transparent asset
        -- lets the regular or pulsing colour remain underneath it.
        local asset = self:asset_path(
                orientation == "h" and "horizontal.png" or "vertical.png")
        if asset and type(widget.setTiledBackgroundImage) == "function" then
                -- The braid assets have a transparent backing. Paint the
                -- state colour first so combat pulses sit beneath the links
                -- instead of replacing them with a flat strip.
                widget:setStyleSheet(underlay and self:transparent_css() or css)
                pcall(function() widget:setTiledBackgroundImage(asset) end)
        elseif asset and type(widget.setBackgroundImage) == "function" then
                widget:setStyleSheet(underlay and self:transparent_css() or css)
                pcall(function() widget:setBackgroundImage(asset) end)
        else
                widget:setStyleSheet(underlay and self:transparent_css() or css)
                if type(widget.resetBackgroundImage) == "function" then
                        pcall(function() widget:resetBackgroundImage() end)
                end
        end
        set_clickthrough(widget, true)
end

function FrameGrid:node_style(widget, color)
        local regular = self:is_regular_color(color)
        local css = string.format([[ 
                background-color: %s;
                border: 0px;
                border-radius: 0px;
                margin: 0px;
        ]], regular and self:base_color() or color)

        local underlay = self:ensure_underlay(widget)
        if underlay then
                underlay:setStyleSheet(self:underlay_css(
                        regular and self:base_color() or color,
                        nil,
                        true
                ))
        end

        -- Keep the square joiner foreground while its underlay changes.
        local asset = self:asset_path("node.png")
        if asset and type(widget.setBackgroundImage) == "function" then
                -- Keep the square joiner above the same pulsing underlay as
                -- its adjoining links.
                widget:setStyleSheet(underlay and self:transparent_css() or css)
                pcall(function() widget:setBackgroundImage(asset) end)
        else
                widget:setStyleSheet(underlay and self:transparent_css() or css)
                if type(widget.resetBackgroundImage) == "function" then
                        pcall(function() widget:resetBackgroundImage() end)
                end
        end
        set_clickthrough(widget, true)
end

function FrameGrid:refresh_colors()
        for _, segment in ipairs(self.segments) do
                local color = edge_owner_color(self,
                        segment._dd_gui_frame_entries)
                if color ~= segment._dd_gui_frame_color then
                        self:line_style(
                                segment,
                                segment._dd_gui_frame_orientation,
                                color
                        )
                        segment._dd_gui_frame_color = color
                end
        end

        for _, marker in ipairs(self.nodes) do
                local color = self:regular_color()
                for _, region in ipairs(marker._dd_gui_frame_regions or {}) do
                        local region_color = self.region_colors[region.id]
                        if region_color and not self:is_regular_color(region_color) then
                                color = region_color
                                break
                        end
                end

                if color ~= marker._dd_gui_frame_color then
                        self:node_style(marker, color)
                        marker._dd_gui_frame_color = color
                end
        end

        -- Content widgets can repaint a shared divider after a combat colour
        -- change. Keep the click-through frame layer above those surfaces.
        self:raise()
end

function FrameGrid:draw_visuals()
        local root = main

        local index = 0
        for _, orientation in ipairs({ "h", "v" }) do
                for _, axis in ipairs(self.axes[orientation]) do
                        -- A shared edge is broken at every panel corner so a
                        -- bright combat owner can recolour just its portion.
                        local points = {}
                        for _, entry in ipairs(axis.entries) do
                                points[#points + 1] = entry.start
                                points[#points + 1] = entry.finish
                        end
                        safe_sort(points)
                        local unique = {}
                        for _, point in ipairs(points) do
                                if #unique == 0 or math.abs(point - unique[#unique]) > 0.5 then
                                        unique[#unique + 1] = point
                                end
                        end

                        for point_index = 1, #unique - 1 do
                                local start = unique[point_index]
                                local finish = unique[point_index + 1]
                                if finish - start >= 1 then
                                        local midpoint = (start + finish) / 2
                                        local owners = {}
                                        for _, entry in ipairs(axis.entries) do
                                                if midpoint >= entry.start - 0.5 and
                                                   midpoint <= entry.finish + 0.5 then
                                                        owners[#owners + 1] = entry
                                                end
                                        end
                                        if #owners > 0 then
                                                index = index + 1
                                                local color = edge_owner_color(self, owners)
                                                local constraints
                                                if orientation == "h" then
                                                        constraints = {
                                                                name = "DD_GUI.FrameGrid.Segment." .. index,
                                                                x = round(start),
                                                                y = round(axis.position - self.thickness / 2),
                                                                width = math.max(1, round(finish - start)),
                                                                height = self.thickness,
                                                        }
                                                else
                                                        constraints = {
                                                                name = "DD_GUI.FrameGrid.Segment." .. index,
                                                                x = round(axis.position - self.thickness / 2),
                                                                y = round(start),
                                                                width = self.thickness,
                                                                height = math.max(1, round(finish - start)),
                                                        }
                                                end
                                                local segment = Geyser.Label:new(constraints, root)
                                                segment._dd_gui_frame_orientation = orientation
                                                segment._dd_gui_frame_entries = owners
                                                segment._dd_gui_frame_color = color
                                                self:line_style(segment, orientation, color)
                                                self.segments[#self.segments + 1] = segment
                                        end
                                end
                        end
                end
        end

        local node_index = 0
        for _, node in pairs(self.nodes_by_key or {}) do
                local color = self:regular_color()
                for _, region in ipairs(node.regions) do
                        local region_color = self.region_colors[region.id]
                        if region_color and not self:is_regular_color(region_color) then
                                color = region_color
                                break
                        end
                end
                node_index = node_index + 1
                local half = math.floor(self.node_size / 2)
                local marker = Geyser.Label:new({
                        name = "DD_GUI.FrameGrid.Node." .. node_index,
                        x = round(node.x - half),
                        y = round(node.y - half),
                        width = self.node_size,
                        height = self.node_size,
                }, root)
                marker._dd_gui_frame_regions = node.regions
                marker._dd_gui_frame_color = color
                self:node_style(marker, color)
                self.nodes[#self.nodes + 1] = marker
        end

        local divider_index = 0
        for _, divider in ipairs(self.gauge_dividers or {}) do
                divider_index = divider_index + 1
                local color = self:regular_color()
                local segment = Geyser.Label:new({
                        name = "DD_GUI.FrameGrid.GaugeDivider." .. divider_index,
                        x = round(divider.x - self.thickness / 2),
                        y = round(divider.y),
                        width = self.thickness,
                        height = math.max(1, round(divider.height)),
                }, root)
                segment._dd_gui_frame_orientation = "v"
                segment._dd_gui_frame_entries = {}
                segment._dd_gui_frame_color = color
                self:line_style(segment, "v", color)
                self.segments[#self.segments + 1] = segment

                for _, y in ipairs({ divider.y, divider.y + divider.height }) do
                        local marker = Geyser.Label:new({
                                name = "DD_GUI.FrameGrid.GaugeDividerNode." ..
                                        divider_index .. "." .. tostring(y),
                                x = round(divider.x - self.node_size / 2),
                                y = round(y - self.node_size / 2),
                                width = self.node_size,
                                height = self.node_size,
                        }, root)
                        marker._dd_gui_frame_regions = {}
                        marker._dd_gui_frame_color = color
                        self:node_style(marker, color)
                        self.nodes[#self.nodes + 1] = marker
                end
        end
end

local function handle_css(active)
        if active then
                return [[
                        background-color: rgba(240,235,213,45);
                        border: 1px solid rgb(240,235,213);
                        margin: 0px;
                ]]
        end
        return [[
                background-color: rgba(0,0,0,0);
                border: 0px;
                margin: 0px;
        ]]
end

function FrameGrid:update_handle(handle, orientation, index, spec)
        if not handle or not spec then
                return
        end

        local half = math.floor(self.hit_size / 2)
        if orientation == "h" then
                handle:move(round(spec.start), round(spec.position - half))
                handle:resize(math.max(1, round(spec.finish - spec.start)), self.hit_size)
        else
                handle:move(round(spec.position - half), round(spec.start))
                handle:resize(self.hit_size, math.max(1, round(spec.finish - spec.start)))
        end
        handle:setStyleSheet(handle_css(self.drag and
                self.drag.orientation == orientation and
                self.drag.index == index))
        if self.enabled then
                handle:show()
                set_clickthrough(handle, false)
        else
                handle:hide()
                set_clickthrough(handle, true)
        end
end

function FrameGrid:update_handles()
        local root = main

        for _, orientation in ipairs({ "h", "v" }) do
                local list = self.handles[orientation] or {}
                local specs = self.axes[orientation] or {}
                for index, spec in ipairs(specs) do
                        local handle = list[index]
                        if not handle then
                                handle = Geyser.Label:new({
                                        name = "DD_GUI.FrameGrid.Handle." .. orientation .. "." .. index,
                                        x = 0, y = 0, width = 1, height = 1,
                                }, root)
                                handle:setClickCallback(
                                        "dd_gui_framegrid_handle_click",
                                        orientation, index)
                                handle:setMoveCallback(
                                        "dd_gui_framegrid_handle_move",
                                        orientation, index)
                                handle:setReleaseCallback(
                                        "dd_gui_framegrid_handle_release",
                                        orientation, index)
                                pcall(function()
                                        handle:setCursor(orientation == "h" and
                                                "SizeVer" or "SizeHor")
                                end)
                                list[index] = handle
                        end
                        self:update_handle(handle, orientation, index, spec)
                end
                for index = #specs + 1, #list do
                        list[index]:hide()
                        set_clickthrough(list[index], true)
                end
                self.handles[orientation] = list
        end
end

function FrameGrid:render()
        if self.rendering then
                return
        end
        self.rendering = true
        self:clear_visuals()
        self:collect_regions()
        self:make_axes()
        self:draw_visuals()
        self:update_handles()
        self.rendering = false
        self:raise()
end

function FrameGrid:raise()
        for _, widget in ipairs(self.segments) do
                if widget._dd_gui_frame_underlay and
                   widget._dd_gui_frame_underlay.raise then
                        widget._dd_gui_frame_underlay:raise()
                end
                if widget.raise then widget:raise() end
        end
        for _, widget in ipairs(self.nodes) do
                if widget._dd_gui_frame_underlay and
                   widget._dd_gui_frame_underlay.raise then
                        widget._dd_gui_frame_underlay:raise()
                end
                if widget.raise then widget:raise() end
        end
        for _, orientation in ipairs({ "h", "v" }) do
                for _, widget in ipairs(self.handles[orientation] or {}) do
                        if self.enabled and widget.raise then widget:raise() end
                end
        end
end

function FrameGrid:set_region_color(id, color)
        if not id then
                return
        end
        self.region_colors[id] = color or self:regular_color()
        if #self.regions > 0 then
                self:refresh_colors()
        end
end

function FrameGrid:register()
        self:clear()
        self.region_colors.EnemyBox = DD_GUI.enemy_panel_border or
                self:regular_color()
        self:render()
        self:register_handlers()
end

function FrameGrid:schedule_refresh(delay)
        if self.refresh_timer and type(killTimer) == "function" then
                killTimer(self.refresh_timer)
        end
        if type(tempTimer) ~= "function" then
                self:render()
                return
        end
        self.refresh_timer = tempTimer(delay or 0.05, function()
                self.refresh_timer = nil
                self:render()
        end)
end

function FrameGrid:set_enabled(enabled)
        self.enabled = enabled == true
        if #self.regions == 0 then
                self:render()
        else
                self:update_handles()
                self:raise()
        end
end

function FrameGrid:register_handlers()
        if self.handlers_registered then
                return
        end
        registerAnonymousEventHandler("sysWindowResizeEvent", function()
                if DD_GUI.FrameGrid then
                        DD_GUI.FrameGrid:schedule_refresh(0.05)
                end
        end)
        registerAnonymousEventHandler("AdjustableContainerReposition", function()
                if DD_GUI.FrameGrid and not DD_GUI.FrameGrid.drag then
                        DD_GUI.FrameGrid:schedule_refresh(0.02)
                end
        end)
        registerAnonymousEventHandler("AdjustableContainerRepositionFinish", function()
                if DD_GUI.FrameGrid then
                        DD_GUI.FrameGrid:schedule_refresh(0.02)
                end
        end)
        self.handlers_registered = true
end

local function copy_region_bounds(regions)
        local result = {}
        for _, entry in ipairs(regions or {}) do
                result[entry.region.id] = clone_bounds(entry.region.bounds)
        end
        return result
end

local function set_widget_bounds(region, bounds)
        local widget = region.widget
        if not widget then
                return
        end

        local parent = widget._dd_gui_frame_parent
        local parent_x = parent and parent.get_x and tonumber(parent:get_x()) or 0
        local parent_y = parent and parent.get_y and tonumber(parent:get_y()) or 0

        if region.synthetic then
                if widget.move then
                        pcall(function() widget:move(widget.x or 0,
                                round(bounds.y - parent_y)) end)
                end
                if widget.resize then
                        pcall(function() widget:resize(widget.width or "72%",
                                round(bounds.height)) end)
                end
                return
        end

        if widget.move then
                pcall(function() widget:move(
                        round(bounds.x - parent_x),
                        round(bounds.y - parent_y)) end)
        end
        if widget.resize then
                pcall(function() widget:resize(
                        math.max(4, round(bounds.width)),
                        math.max(4, round(bounds.height))) end)
        end
end

local function clamp_delta(drag, delta)
        local minimum_width = FrameGrid.minimum_width
        local minimum_height = FrameGrid.minimum_height
        local low = -math.huge
        local high = math.huge

        for _, entry in ipairs(drag.entries or {}) do
                local start = drag.start_bounds[entry.region.id]
                if start and not entry.region.horizontal_only then
                        local minimum = entry.region.id == "GaugesBand" and 0 or
                                (drag.orientation == "v" and minimum_width or minimum_height)
                        if drag.orientation == "v" then
                                if entry.side == "left" then
                                        high = math.min(high, start.width - minimum)
                                else
                                        low = math.max(low, minimum - start.width)
                                end
                        else
                                if entry.side == "top" then
                                        high = math.min(high, start.height - minimum)
                                else
                                        low = math.max(low, minimum - start.height)
                                end
                        end
                elseif start and drag.orientation == "h" then
                        if entry.side == "top" then
                                high = math.min(high, start.height - minimum_height)
                        elseif entry.side == "bottom" then
                                low = math.max(low, minimum_height - start.height)
                        end
                end
        end

        return math.max(low, math.min(high, delta))
end

function FrameGrid:apply_drag_delta(delta)
        local drag = self.drag
        if not drag then
                return
        end
        delta = clamp_delta(drag, delta)
        drag.last_delta = delta

        for _, entry in ipairs(drag.entries or {}) do
                local start = drag.start_bounds[entry.region.id]
                if start then
                        local next_bounds = clone_bounds(start)
                        if drag.orientation == "v" and not entry.region.horizontal_only then
                                if entry.side == "left" then
                                        next_bounds.x = start.x + delta
                                        next_bounds.width = start.width - delta
                                elseif entry.side == "right" then
                                        next_bounds.width = start.width + delta
                                end
                        elseif drag.orientation == "h" then
                                if entry.side == "top" then
                                        next_bounds.y = start.y + delta
                                        next_bounds.height = start.height - delta
                                elseif entry.side == "bottom" then
                                        next_bounds.height = start.height + delta
                                end
                        end
                        if next_bounds.width >= 4 and next_bounds.height >= 4 then
                                set_widget_bounds(entry.region, next_bounds)
                        end
                end
        end
        self:render()
end

function FrameGrid:begin_drag(orientation, index, event)
        if not self.enabled or not event or event.button ~= "LeftButton" then
                return
        end
        local spec = self.axes[orientation] and self.axes[orientation][tonumber(index)]
        if not spec then
                return
        end

        local mouse_x, mouse_y = getMousePosition()
        self.drag = {
                orientation = orientation,
                index = tonumber(index),
                mouse = orientation == "h" and mouse_y or mouse_x,
                entries = spec.entries,
                start_bounds = copy_region_bounds(spec.entries),
                last_delta = 0,
        }
        self:update_handles()
end

function FrameGrid:move_drag(orientation, index)
        if not self.drag or self.drag.orientation ~= orientation or
           self.drag.index ~= tonumber(index) then
                return
        end
        local mouse_x, mouse_y = getMousePosition()
        local current = orientation == "h" and mouse_y or mouse_x
        self:apply_drag_delta(current - self.drag.mouse)
end

function FrameGrid:end_drag(orientation, index, event)
        if not self.drag or self.drag.orientation ~= orientation or
           self.drag.index ~= tonumber(index) then
                return
        end
        if event and event.button and event.button ~= "LeftButton" then
                return
        end
        self.drag = nil
        self:update_handles()
        if DD_GUI.Layout and DD_GUI.Layout.save then
                DD_GUI.Layout:save()
        end
        if ui and ui.updatecontent then
                ui.updatecontent()
        end
        self:schedule_refresh(0.02)
end

function dd_gui_framegrid_handle_click(event, orientation, index)
        if DD_GUI.FrameGrid then
                DD_GUI.FrameGrid:begin_drag(orientation, index, event)
        end
end

function dd_gui_framegrid_handle_move(event, orientation, index)
        if DD_GUI.FrameGrid then
                DD_GUI.FrameGrid:move_drag(orientation, index)
        end
end

function dd_gui_framegrid_handle_release(event, orientation, index)
        if DD_GUI.FrameGrid then
                DD_GUI.FrameGrid:end_drag(orientation, index, event)
        end
end
