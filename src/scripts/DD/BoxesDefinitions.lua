local function new_info_box(cons, parent)
        if Adjustable and Adjustable.Container then
                cons.padding = 4
                cons.autoLoad = true
                cons.autoSave = true
                cons.defaultDir = ms_path .. "/layout/"
                cons.raiseOnClick = false
                cons.titleText = ""
                cons.titleTxtColor = "black"
                cons.adjLabelstyle = [[
                  background-color: rgba(0,0,0,0%);
                  border-style: solid;
                  border-width: 0px;
                  border-color: rgba(0,0,0,0%);
                  margin: 0px;
                ]]

                local box = Adjustable.Container:new(cons, parent)
                box.adjLabel:echo("")
                box.exitLabel:hide()
                box.minimizeLabel:hide()
                box.setStyleSheet = function(self, css)
                        self.adjLabel:setStyleSheet(css)
                end
                return box
        end

        return Geyser.Label:new(cons, parent)
end
function define_boxes()

        DD_GUI.BoxCSS = CSSMan.new([[
          background-color: rgba(0,0,0,100);
          border-style: solid;
          border-width: 0px;
          border-radius: 0px;
          border-color: red;
          margin: 1px;
        ]])
        
        DD_GUI.EnemyBoxCSS = CSSMan.new([[
          background-color: rgba(0,0,0,100);
          border-style: solid;
          border-width: 2px;
          border-radius: 0px;
          border-color: red;
          margin: 0px;
        ]])
        
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
          width = "24%",
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
        
        
        DD_GUI.CharsheetBox = new_info_box({
          name = "DD_GUI.CharsheetBox",
          x = "51%", y = "17%",
          width = "23%",
          height = "83%",
        },DD_GUI.Top)
        DD_GUI.CharsheetBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.CharsheetBox:echo("<center>GUI.CharsheetBox")
        
        DD_GUI.ChannelBox = new_info_box({
          name = "DD_GUI.ChannelBox",
          x = "74%", y = "17%",
          width = "23%",
          height = "83%",
        },DD_GUI.Top)
        DD_GUI.ChannelBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.ChannelBox:echo("<center>GUI.ChannelBox")
        
        DD_GUI.InventoryBox = new_info_box({
          name = "DD_GUI.InventoryBox",
          x = "0%", y = "36%",
          width = "89%",
          height = "34%",
        },DD_GUI.Right)
        DD_GUI.InventoryBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.InventoryBox:echo("<center>GUI.InventoryBox")
        
        DD_GUI.AffectBox = new_info_box({
          name = "DD_GUI.AffectBox",
          x = "0%", y = "70%",
          width = "89%",
          height = "30%",
        },DD_GUI.Right)
        DD_GUI.AffectBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.AffectBox:echo("<center>GUI.AffectBox")
        
        DD_GUI.GaugesBox = new_info_box({
          name = "DD_GUI.GaugesBox",
          x = "5%", y = 0,
          width = "95%",
          height = "100%",
        },DD_GUI.Bottom)
        DD_GUI.GaugesBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
        --GUI.GaugesBox:echo("<center>GUI.GaugesBox")
end
