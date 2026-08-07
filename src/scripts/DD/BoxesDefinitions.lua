local function transparent_surface_css(css)
        return (css or ""):gsub(
                "background%-color%s*:%s*[^;]+;",
                "background-color: rgba(0,0,0,0);"
        )
end

local function adjustable_state_css(box)
        if box and box._dd_gui_frame_region_id then
                return ""
        end

        local theme = DD_GUI and DD_GUI.Theme
        local layout_enabled = DD_GUI and DD_GUI.Layout and
                DD_GUI.Layout.enabled

        if theme and layout_enabled then
                return theme:layout_outline_css(box._dd_gui_dragging)
        end

        if box._dd_gui_dragging then
                if theme then
                        return theme:layout_outline_css(true)
                end
                return [[
                        border-style: solid;
                        border-width: 2px;
                        border-color: rgba(255,255,255,220);
                ]]
        end

        return ""
end

local function refresh_adjustable_style(box)
        if not box or not box.adjLabel then
                return
        end

        box.adjLabel:setStyleSheet(
                (box._dd_gui_base_style or "") .. adjustable_state_css(box)
        )
end

DD_GUI.refresh_adjustable_style = refresh_adjustable_style

local function set_adjustable_drag_outline(box, active)
        if not box or not box.adjLabel then
                return
        end

        box._dd_gui_dragging = active == true
        refresh_adjustable_style(box)
end

DD_GUI.set_adjustable_drag_outline = set_adjustable_drag_outline

local function hide_adjustable_controls(box)
        if not box then
                return
        end

        if box.exitLabel and box.exitLabel.hide then
                box.exitLabel:hide()
        end
        if box.minimizeLabel and box.minimizeLabel.hide then
                box.minimizeLabel:hide()
        end
end

DD_GUI.hide_adjustable_controls = hide_adjustable_controls

local function register_adjustable_outline_handlers()
        if DD_GUI.adjustable_outline_handlers_registered then
                return
        end

        registerAnonymousEventHandler("AdjustableContainerReposition", function(
                _, name, _, _, _, _, is_mouse_action)
                if not is_mouse_action or not Adjustable or
                   not Adjustable.Container or not Adjustable.Container.all then
                        return
                end

                set_adjustable_drag_outline(
                        Adjustable.Container.all[name], true)
        end)

        registerAnonymousEventHandler("AdjustableContainerRepositionFinish", function(
                _, name)
                if Adjustable and Adjustable.Container and Adjustable.Container.all then
                        set_adjustable_drag_outline(
                                Adjustable.Container.all[name], false)
                end
        end)

        DD_GUI.adjustable_outline_handlers_registered = true
end

local function raise_children(container)
        if not container or not container.windows or not container.windowList then
                return
        end

        for _, name in ipairs(container.windows) do
                local child = container.windowList[name]
                if child and child.raiseAll then
                        child:raiseAll()
                elseif child and child.raise then
                        child:raise()
                end
        end
end

local function raise_widget(widget)
        if not widget then
                return
        end

        if widget.raise then
                widget:raise()
        elseif widget.raiseAll then
                widget:raiseAll()
        end
end

local function raise_data_surfaces()
        -- Adjustable.Container keeps its drag surface above its children.
        -- Raise the actual data widgets after the frame pass so a transparent
        -- border can never hide text, images, or channel history.
        for _, widget in ipairs({
                DD_GUI and DD_GUI.Mapper,
                EnemyConsole,
                EnemyTPConsoleTop,
                EnemyInfoConsole,
                EnemyConsoleHitpointsContainer,
                EnemyConsoleHitpoints,
                EnemyHitpointsLabel,
                CharsheetConsole,
                CharsheetPFPConsole,
                CharsheetImageFrame,
                InventoryConsole,
                EquippedConsole,
                DD_GUI and DD_GUI.Inventory and DD_GUI.Inventory.stats_label,
                DD_GUI and DD_GUI.InventoryPanelOutline,
                AffectsConsole,
                DD_GUI and DD_GUI.AffectPanelOutline,
        }) do
                raise_widget(widget)
        end

        if DD_GUI and DD_GUI.Comms and DD_GUI.Comms.consoles then
                for _, console in pairs(DD_GUI.Comms.consoles) do
                        raise_widget(console)
                end
        end
end

local function raise_tab_rails()
        local rails = {}
        if DD_GUI.Comms and DD_GUI.Comms.tab_rail then
                table.insert(rails, DD_GUI.Comms.tab_rail)
        end
        if DD_GUI.Inventory and DD_GUI.Inventory.tab_rail then
                table.insert(rails, DD_GUI.Inventory.tab_rail)
        end
        if DD_GUI.Affects and DD_GUI.Affects.tab_rail then
                table.insert(rails, DD_GUI.Affects.tab_rail)
        end

        for _, rail in ipairs(rails) do
                if rail and rail.raiseAll then
                        rail:raiseAll()
                elseif rail and rail.raise then
                        rail:raise()
                end
        end
end

local function raise_tab_controls()
        raise_tab_rails()

        if DD_GUI and DD_GUI.Comms and DD_GUI.Comms.tab_buttons then
                for _, button in pairs(DD_GUI.Comms.tab_buttons) do
                        raise_widget(button)
                end
        end

        if DD_GUI and DD_GUI.Inventory and DD_GUI.Inventory.tab_buttons then
                for _, button in pairs(DD_GUI.Inventory.tab_buttons) do
                        raise_widget(button)
                end
        end

        if DD_GUI and DD_GUI.Affects and DD_GUI.Affects.tab_button then
                raise_widget(DD_GUI.Affects.tab_button)
        end
end

function DD_GUI.raise_info_box_contents()
        if ui and ui.mainconsole_container and ui.mainconsole_container.adjLabel and
           ui.mainconsole_container.adjLabel.raise then
                ui.mainconsole_container.adjLabel:raise()
        end

        if Adjustable and Adjustable.Container and Adjustable.Container.all then
                for _, box in pairs(Adjustable.Container.all) do
                        if box and box.adjLabel and box.adjLabel.raise then
                                box.adjLabel:raise()
                        end
                end

                for _, box in pairs(Adjustable.Container.all) do
                        if box and box.Inside then
                                -- Raise the contents without raising the
                                -- full-size Inside container over the drag
                                -- surface of its parent.
                                raise_children(box.Inside)
                        end
                end

                -- Console widgets can be raised during bootstrap and GMCP
                -- refreshes. Put the tab controls back on top afterwards.
                raise_tab_rails()

                -- Gauge columns use the adjustable container directly so
                -- their short row height does not get consumed by nested
                -- Inside containers.
                for _, box in pairs(Adjustable.Container.all) do
                        if box and box.goInside == false and box.raiseAll then
                                box:raiseAll()
                        end
                end

                -- Keep data surfaces above the full-size transparent frame
                -- labels. Their inset geometry leaves the red border visible,
                -- while raising the frames last can hide all panel content.
                raise_tab_rails()
                raise_data_surfaces()
                raise_tab_controls()

                if ui and ui.mainconsole_container and
                   ui.mainconsole_container.adjLabel and
                   ui.mainconsole_container.adjLabel.raise then
                        ui.mainconsole_container.adjLabel:raise()
                end

                -- The compass overlaps the bottom gauge row at its default
                -- position, so its parent and navigation cells must be raised
                -- last.
                if compass and compass.back and compass.back.raise then
                        compass.back:raise()
                end
                if compass and compass.back and compass.back.Inside and
                   compass.back.Inside.raiseAll then
                        compass.back.Inside:raiseAll()
                end
                if compass and compass.box then
                        if compass.box.raiseAll then
                                compass.box:raiseAll()
                        elseif compass.box.raise then
                                compass.box:raise()
                        end
                end
                if compass and compass.handle and compass.handle.raise then
                        compass.handle:raise()
                end
                raise_tab_controls()
                if DD_GUI.FrameGrid and DD_GUI.FrameGrid.raise then
                        DD_GUI.FrameGrid:raise()
                end
                return
        end

        local box_names = {
                "EnemyBox",
                "MapBox",
                "CharsheetBox",
                "ChannelBox",
                "InventoryBox",
                "AffectBox",
                "GaugesBox",
        }

        for _, box_name in ipairs(box_names) do
                local box = DD_GUI[box_name]
                if box and box.Inside and box.Inside.raiseAll then
                        box.Inside:raiseAll()
                end
        end

        raise_data_surfaces()
        raise_tab_controls()

        if ui and ui.mainconsole_container and
           ui.mainconsole_container.adjLabel and
           ui.mainconsole_container.adjLabel.raise then
                ui.mainconsole_container.adjLabel:raise()
        end
        if compass and compass.back and compass.back.raise then
                compass.back:raise()
        end
        if compass and compass.box and compass.box.raiseAll then
                compass.box:raiseAll()
        end
        if DD_GUI.FrameGrid and DD_GUI.FrameGrid.raise then
                DD_GUI.FrameGrid:raise()
        end
end

function DD_GUI.new_adjustable_container(cons, parent, options)
        if Adjustable and Adjustable.Container then
                register_adjustable_outline_handlers()
                cons = cons or {}
                cons.padding = cons.padding or 4
                cons.autoLoad = true
                cons.autoSave = true
                cons.defaultDir = ms_path .. "/layout/"
                cons.raiseOnClick = false
                cons.titleText = ""
                cons.titleTxtColor = "black"
                cons.adjLabelstyle = [[
                  background-color: rgba(0,0,0,0);
                  border-style: solid;
                  border-width: 0px;
                  border-color: rgba(0,0,0,0);
                  margin: 0px;
                ]]

                local box = Adjustable.Container:new(cons, parent)
                box.adjLabel:echo("")
                box._dd_gui_base_style = box.adjLabelstyle or ""
                hide_adjustable_controls(box)
                box.setStyleSheet = function(self, css)
                        self._dd_gui_base_style = transparent_surface_css(css)
                        refresh_adjustable_style(self)
                end
                if options and options.direct then
                        box.goInside = false
                end
                box._dd_gui_adjustable = true
                box._dd_gui_frame_parent = parent
                if DD_GUI.FrameGrid and DD_GUI.FrameGrid.region_id_for_name then
                        box._dd_gui_frame_region_id =
                                DD_GUI.FrameGrid:region_id_for_name(cons.name)
                end
                if DD_GUI.Layout and DD_GUI.Layout.apply_box then
                        DD_GUI.Layout:apply_box(box)
                end
                return box
        end

        return nil
end

function DD_GUI.new_adjustable_region(cons, parent, css, options)
        local box = DD_GUI.new_adjustable_container(cons, parent, options)
        if box then
                -- Keep the region background on the drag layer itself.  The
                -- content is raised afterwards, so this never tints it.
                if box.adjLabel and box.adjLabel.setStyleSheet then
                        box._dd_gui_base_style = css or ""
                        box._dd_gui_dragging = false
                        refresh_adjustable_style(box)
                end
                box._dd_gui_region = true
                return box
        end

        local fallback = Geyser.Label:new(cons, parent)
        if css then
                fallback:setStyleSheet(css)
        end
        return fallback
end

local function new_info_box(cons, parent)
        local box = DD_GUI.new_adjustable_container(cons, parent)
        if box then
                return box
        end

        return Geyser.Label:new(cons, parent)
end

local function panel_outline_css()
        if DD_GUI.Theme and DD_GUI.Theme.panel_css then
                return DD_GUI.Theme:panel_css({
                        background = "rgba(0,0,0,0)",
                        margin = 0,
                })
        end

        return [[
                background-color: rgba(0,0,0,0);
                border-style: solid;
                border-width: 2px;
                border-color: rgb(151,27,39);
                border-radius: 0px;
                margin: 0px;
        ]]
end

local function panel_without_outline_css()
        return [[
                background-color: rgba(0,0,0,0);
                border-style: none;
                border-width: 0px;
                border-color: rgba(0,0,0,0);
                border-radius: 0px;
                margin: 0px;
        ]]
end

DD_GUI.panel_surface_css = panel_without_outline_css

local function ensure_panel_outline(panel, name)
        if not panel then
                return nil
        end

        -- Affects' native adjustable frame can be replaced during tab
        -- rebuilds. Keep a transparent child outline tied to the panel so
        -- its border survives those repaints and follows user resizing.
        local outline = panel._dd_gui_panel_outline
        if outline and outline.container ~= panel then
                if type(outline.delete) == "function" then
                        pcall(function() outline:delete() end)
                end
                outline = nil
        end
        if not outline then
                local constraints = {
                        name = name,
                        x = "0%",
                        y = "0%",
                        width = "100%",
                        height = "100%",
                }

                -- Adjustable.Container normally redirects children into its
                -- padded Inside container. Temporarily bypass that redirect
                -- so this transparent frame sits on the panel's true outer
                -- bounds and has no inset gap.
                local go_inside = panel.goInside
                panel.goInside = false
                outline = Geyser.Label:new(constraints, panel)
                panel.goInside = go_inside
                panel._dd_gui_panel_outline = outline
        end

        outline:setStyleSheet(panel_outline_css())
        outline:show()
        if DD_GUI.set_widget_clickthrough then
                DD_GUI.set_widget_clickthrough(outline, true)
        end

        -- The explicit outline is the single visible frame for these two
        -- panels. Remove the adjustable surface border so a repaint cannot
        -- create a second line or leave one panel frameless.
        if panel.adjLabel then
                panel._dd_gui_base_style = panel_without_outline_css()
                if DD_GUI.refresh_adjustable_style then
                        DD_GUI.refresh_adjustable_style(panel)
                else
                        panel.adjLabel:setStyleSheet(panel._dd_gui_base_style)
                end
        end
        return outline
end

DD_GUI.ensure_panel_outline = ensure_panel_outline

function define_boxes()
        -- The shared frame layer owns all major panel edges. Keeping the
        -- content surfaces borderless prevents double lines at every join.
        local box_css = panel_without_outline_css()

        DD_GUI.BoxCSS = CSSMan.new(box_css)
        DD_GUI.EnemyBoxCSS = CSSMan.new(box_css)
        
        DD_GUI.EnemyBox = new_info_box({
          name = "DD_GUI.EnemyBox",
          x = "4%", y = "0%",
          width = "23%",
          height = "100%",
        },DD_GUI.Top)
        DD_GUI.EnemyBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.EnemyBox:echo("<center>GUI.EnemyBox")
        
        DD_GUI.MapBox = new_info_box({
          name = "DD_GUI.MapBox",
          x = "27%", y = "0%",
          width = "27%",
          height = "100%",
        },DD_GUI.Top)
        DD_GUI.MapBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.MapBox:echo("<center>GUI.MapBox")
        
        --main = Geyser.Container:new({x=0,y=88,width="93%",height="100%",name="mapper container"})
        DD_GUI.Mapper = Geyser.Mapper:new({
          name = "DD_GUI.Mapper",
          x = "0", y = "0", -- edit here if you want to move it
          width = "100%", 
          height = "100%"
        }, DD_GUI.MapBox)
        DD_GUI.Mapper:setColor(0, 0, 0, 255)
        
        
        DD_GUI.CharsheetBox = new_info_box({
          name = "DD_GUI.CharsheetBox",
          x = "54%", y = "0%",
          width = "18%",
          height = "100%",
        },DD_GUI.Top)
        DD_GUI.CharsheetBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.CharsheetBox:echo("<center>GUI.CharsheetBox")
        
        DD_GUI.ChannelBox = new_info_box({
          name = "DD_GUI.ChannelBox",
          x = "72%", y = "0%",
          width = "25%",
          height = "100%",
        },DD_GUI.Top)
        DD_GUI.ChannelBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.ChannelBox:echo("<center>GUI.ChannelBox")
        
        DD_GUI.InventoryBox = new_info_box({
          name = "DD_GUI.InventoryBox",
          x = "0%", y = "35.11%",
          width = "89.29%",
          height = "36.17%",
        },DD_GUI.Right)
        DD_GUI.InventoryBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.InventoryBox:echo("<center>GUI.InventoryBox")
        
        DD_GUI.AffectBox = new_info_box({
          name = "DD_GUI.AffectBox",
          x = "0%", y = "71.28%",
          width = "89.29%",
          height = "28.72%",
        },DD_GUI.Right)
        DD_GUI.AffectBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.AffectBox:echo("<center>GUI.AffectBox")

        DD_GUI.InventoryPanelOutline = nil
        DD_GUI.AffectPanelOutline = nil
        
end
