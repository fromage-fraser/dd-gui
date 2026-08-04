local function transparent_surface_css(css)
        return (css or ""):gsub(
                "background%-color%s*:%s*[^;]+;",
                "background-color: rgba(0,0,0,0);"
        )
end

local function adjustable_state_css(box)
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
function define_boxes()
        local box_css = DD_GUI.Theme and DD_GUI.Theme:panel_css() or [[
          background-color: rgb(0,0,0);
          border-style: solid;
          border-width: 1px;
          border-radius: 0px;
          border-color: grey;
          margin: 1px;
        ]]

        DD_GUI.BoxCSS = CSSMan.new(box_css)
        DD_GUI.EnemyBoxCSS = CSSMan.new(box_css)
        
        DD_GUI.EnemyBox = new_info_box({
          name = "DD_GUI.EnemyBox",
          x = "4%", y = "17%",
          width = "23%",
          height = "83%",
        },DD_GUI.Top)
        DD_GUI.EnemyBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.EnemyBox:echo("<center>GUI.EnemyBox")
        
        DD_GUI.MapBox = new_info_box({
          name = "DD_GUI.MapBox",
          x = "27%", y = "17%",
          width = "27%",
          height = "83%",
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
          x = "54%", y = "17%",
          width = "18%",
          height = "83%",
        },DD_GUI.Top)
        DD_GUI.CharsheetBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.CharsheetBox:echo("<center>GUI.CharsheetBox")
        
        DD_GUI.ChannelBox = new_info_box({
          name = "DD_GUI.ChannelBox",
          x = "72%", y = "17%",
          width = "25%",
          height = "83%",
        },DD_GUI.Top)
        DD_GUI.ChannelBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.ChannelBox:echo("<center>GUI.ChannelBox")
        
        DD_GUI.InventoryBox = new_info_box({
          name = "DD_GUI.InventoryBox",
          x = "0%", y = "36%",
          width = "91%",
          height = "34%",
        },DD_GUI.Right)
        DD_GUI.InventoryBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.InventoryBox:echo("<center>GUI.InventoryBox")
        
        DD_GUI.AffectBox = new_info_box({
          name = "DD_GUI.AffectBox",
          x = "0%", y = "70%",
          width = "91%",
          height = "30%",
        },DD_GUI.Right)
        DD_GUI.AffectBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.AffectBox:echo("<center>GUI.AffectBox")
        
end
