local GladiusMoP = _G.GladiusMoP
if not GladiusMoP then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires GladiusMoP", "Target Bar"))
end
local L = GladiusMoP.L
local LSM

-- global functions
local strfind = string.find
local pairs = pairs
local UnitClass, UnitGUID, UnitHealth, UnitHealthMax = UnitClass, UnitGUID, UnitHealth, UnitHealthMax

local TargetBar = GladiusMoP:NewModule("TargetBar", true, true, {
   targetBarAttachTo = "Trinket",
   
   targetBarEnableBar = true,
   
   targetBarHeight = 30,
   targetBarAdjustWidth = true,
   targetBarWidth = 200,
   
   targetBarInverse = false,
   targetBarColor = { r = 1, g = 1, b = 1, a = 1 },
   targetBarClassColor = true,
   targetBarBackgroundColor = { r = 1, g = 1, b = 1, a = 0.3 },
   targetBarTexture = "Minimalist", 
   
   targetBarIconPosition = "LEFT",
   targetBarIcon = true,
   targetBarIconCrop = false,
   
   targetBarOffsetX = 10,
   targetBarOffsetY = 0,  
   
   targetBarAnchor = "TOPLEFT",
   targetBarRelativePoint = "TOPRIGHT",
}, { "Target bar with class ", "Class icon on health bar" })

function TargetBar:OnInitialize()
   -- init frames
   self.frame = {}
end

function TargetBar:OnEnable()   
   self:RegisterEvent("UNIT_HEALTH")
   self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH")
   
   self:RegisterEvent("UNIT_TARGET")
   
   LSM = GladiusMoP.LSM
   
   -- set frame type
   if (GladiusMoP.db.targetBarAttachTo == "Frame" or strfind(GladiusMoP.db.targetBarRelativePoint, "BOTTOM")) then
      self.isBar = true
   else
      self.isBar = false
   end
   
   if (not self.frame) then
      self.frame = {}
   end
end

function TargetBar:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit].frame:SetAlpha(0)
   end
end

function TargetBar:SetTemplate(template)
   if (template == 1) then
      -- reset width
      if (GladiusMoP.db.targetBarAttachTo == "HealthBar" and not GladiusMoP.db.healthBarAdjustWidth) then
         GladiusMoP.db.healthBarAdjustWidth = true
      end
   
      -- reset to default
      for k, v in pairs(self.defaults) do
         GladiusMoP.db[k] = v
      end
   else
      if (GladiusMoP.db.modules["HealthBar"]) then
         if (GladiusMoP.db.healthBarAdjustWidth) then
            GladiusMoP.db.healthBarAdjustWidth = false
            GladiusMoP.db.healthBarWidth = GladiusMoP.db.barWidth - GladiusMoP.db.healthBarHeight
         else
            GladiusMoP.db.healthBarWidth = GladiusMoP.db.healthBarWidth - GladiusMoP.db.healthBarHeight
         end
            
         GladiusMoP.db.targetBarEnableBar = false
         GladiusMoP.db.targetBarIcon = true
         GladiusMoP.db.targetBarHeight = GladiusMoP.db.healthBarHeight
         
         GladiusMoP.db.targetBarAttachTo = "HealthBar"
         GladiusMoP.db.targetBarAnchor = "TOPLEFT"
         GladiusMoP.db.targetBarRelativePoint = "TOPRIGHT"
         
         GladiusMoP.db.targetBarOffsetX = 0
         GladiusMoP.db.targetBarOffsetY = 0         
      end
   end
   
   -- set frame type
   if (GladiusMoP.db.targetBarAttachTo == "Frame" or strfind(GladiusMoP.db.targetBarRelativePoint, "BOTTOM")) then
      self.isBar = true
   else
      self.isBar = false
   end
end

function TargetBar:GetAttachTo()
   return GladiusMoP.db.targetBarAttachTo
end

function TargetBar:GetFrame(unit)
   return self.frame[unit].frame
end

function TargetBar:SetClassIcon(unit)
   if (not self.frame[unit]) then return end
   

      self.frame[unit]:Hide()
      self.frame[unit].icon:Hide()
   
   
   -- get unit class
   local class
   if (not GladiusMoP.test) then
      class = select(2, UnitClass(unit .. "target"))
   else
      class = GladiusMoP.testing[unit].unitClass
   end
   
   
   if (class) then
   
            	  	  	-- color
	  local colorx = self:GetBarColor(class)
      if (colorx == nil) then 
          --fallback, when targeting a pet or totem 
         colorx = GladiusMoP.db.targetBarColor
      end
      
      self.frame[unit]:SetStatusBarColor(colorx.r, colorx.g, colorx.b, colorx.a or 1)
	  
	     local healthx, maxHealthx = UnitHealth(unit .. "target"), UnitHealthMax(unit .. "target")
   self:UpdateHealth(unit, healthx, maxHealthx)
	  
   --print("HELLO FRIEND "..colorx.r.." "..colorx.g.." "..colorx.b)
   --print("HELLO FRIEND "..select(2,UnitClass(unit.."target")))
   
   
      self.frame[unit].icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
      
      local left, right, top, bottom = unpack(CLASS_BUTTONS[class])
      
      if (GladiusMoP.db.targetBarIconCrop) then
         -- zoom class icon
         left = left + (right - left) * 0.07
         right = right - (right - left) * 0.07

         top = top + (bottom - top) * 0.07
         bottom = bottom - (bottom - top) * 0.07
      end

	        self.frame[unit]:Show()
      self.frame[unit].icon:Show()
	  
      self.frame[unit].icon:SetTexCoord(left, right, top, bottom)
   end
end

function TargetBar:UNIT_TARGET(event, unit)
   self:SetClassIcon(unit)
end

function TargetBar:UNIT_HEALTH(event, unit)
   local foundUnit = nil

   for u, _ in pairs(self.frame) do
      if (UnitGUID(unit) == UnitGUID(u .. "target")) then
         foundUnit = u
      end
   end
   
   if (not foundUnit) then return end

   local health, maxHealth = UnitHealth(foundUnit .. "target"), UnitHealthMax(foundUnit .. "target")
   self:UpdateHealth(foundUnit, health, maxHealth)
end

function TargetBar:UpdateHealth(unit, health, maxHealth)
   if (not self.frame[unit]) then
      if (not GladiusMoP.buttons[unit]) then
         GladiusMoP:UpdateUnit(unit)
      else
         self:Update(unit)
      end
   end
  
   -- update min max values
   self.frame[unit]:SetMinMaxValues(0, maxHealth)

   -- inverse bar
   if (GladiusMoP.db.targetBarInverse) then
      self.frame[unit]:SetValue(maxHealth - health)
   else
      self.frame[unit]:SetValue(health)
   end
end

function TargetBar:CreateBar(unit)
   local button = GladiusMoP.buttons[unit]
   if (not button) then return end       
   
   -- create bar + text
   self.frame[unit] = CreateFrame("STATUSBAR", "GladiusMoP" .. self.name .. "Bar" .. unit, button) 
   self.frame[unit].frame = CreateFrame("Frame", "GladiusMoP" .. self.name .. unit, button)   
   self.frame[unit]:SetParent(self.frame[unit].frame)
   
   self.frame[unit].secure = CreateFrame("Button", "GladiusMoP" .. self.name .. "Secure" .. unit, self.frame[unit].frame, "SecureActionButtonTemplate")	
    
   self.frame[unit].background = self.frame[unit]:CreateTexture("GladiusMoP" .. self.name .. unit .. "Background", "BACKGROUND") 
   self.frame[unit].highlight = self.frame[unit]:CreateTexture("GladiusMoP" .. self.name .. "Highlight" .. unit, "OVERLAY")
   self.frame[unit].icon = self.frame[unit].frame:CreateTexture("GladiusMoP" .. self.name .. "IconFrame" .. unit, "ARTWORK") 
   
   self.frame[unit].unit = unit .. "target"
end

function TargetBar:Update(unit)
   -- check parent module
   if (not GladiusMoP:GetModule(GladiusMoP.db.castBarAttachTo)) then
      if (self.frame[unit]) then
         self.frame[unit].frame:Hide()
      end
      return
   end

   -- create power bar
   if (not self.frame[unit]) then 
      self:CreateBar(unit)
   end
   
   -- set bar type 
   local parent = GladiusMoP:GetParent(unit, GladiusMoP.db.targetBarAttachTo)
   
   -- set frame type
   if (GladiusMoP.db.targetBarAttachTo == "Frame" or strfind(GladiusMoP.db.targetBarRelativePoint, "BOTTOM")) then
      self.isBar = true
   else
      self.isBar = false
   end
           
   -- update health bar   
   self.frame[unit].frame:ClearAllPoints()
   
   local width = 1
   if (GladiusMoP.db.targetBarEnableBar) then
      width = GladiusMoP.db.targetBarAdjustWidth and GladiusMoP.dbWidth or GladiusMoP.db.targetBarWidth
   
      -- add width of the widget if attached to an widget
      if (GladiusMoP.db.targetBarAttachTo ~= "Frame" and not strfind(GladiusMoP.db.targetBarRelativePoint, "BOTTOM") and GladiusMoP.db.targetBarAdjustWidth) then
         if (not GladiusMoP:GetModule(GladiusMoP.db.targetBarAttachTo).frame[unit]) then
            GladiusMoP:GetModule(GladiusMoP.db.targetBarAttachTo):Update(unit)
         end
         
         width = width + GladiusMoP:GetModule(GladiusMoP.db.targetBarAttachTo).frame[unit]:GetWidth()
      end
   end
       
   self.frame[unit].frame:SetHeight(GladiusMoP.db.targetBarHeight)  
   self.frame[unit].frame:SetHeight(GladiusMoP.db.targetBarHeight) 
   
   if (GladiusMoP.db.targetBarIcon) then
      width = width + self.frame[unit].frame:GetHeight()
   end      
   self.frame[unit].frame:SetWidth(width)
   
   self.frame[unit].frame:SetPoint(GladiusMoP.db.targetBarAnchor, parent, GladiusMoP.db.targetBarRelativePoint, GladiusMoP.db.targetBarOffsetX + (offsetX or 0), GladiusMoP.db.targetBarOffsetY)

   -- update icon
   
   
	self.frame[unit].icon:ClearAllPoints()
	
	if (GladiusMoP.db.targetBarIcon) then
      self.frame[unit].icon:SetPoint(GladiusMoP.db.targetBarIconPosition, self.frame[unit].frame, GladiusMoP.db.targetBarIconPosition)
      
      self.frame[unit].icon:SetWidth(self.frame[unit].frame:GetHeight())
      self.frame[unit].icon:SetHeight(self.frame[unit].frame:GetHeight())      
      self.frame[unit].icon:SetTexCoord(0, 1, 0, 1)
      
      self.frame[unit].icon:Show()
	  
	  
	  
   else
      self.frame[unit].icon:Hide()
	end

   if (GladiusMoP.db.targetBarEnableBar) then
      self.frame[unit]:ClearAllPoints()
      
      if (GladiusMoP.db.targetBarIcon and GladiusMoP.db.targetBarIconPosition == "LEFT") then
         self.frame[unit]:SetPoint("TOPLEFT", self.frame[unit].icon, "TOPRIGHT")
      else
         self.frame[unit]:SetPoint("TOPLEFT", self.frame[unit].frame, "TOPLEFT")
      end
      self.frame[unit]:SetWidth(width)
      self.frame[unit]:SetHeight(self.frame[unit].frame:GetHeight())
      
      self.frame[unit]:SetMinMaxValues(0, 100)
      self.frame[unit]:SetValue(100)
      self.frame[unit]:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, GladiusMoP.db.targetBarTexture))
      
	  
      -- disable tileing
      self.frame[unit]:GetStatusBarTexture():SetHorizTile(false)
      self.frame[unit]:GetStatusBarTexture():SetVertTile(false)
      
      -- update health bar background
      self.frame[unit].background:ClearAllPoints()
      self.frame[unit].background:SetAllPoints(self.frame[unit])
      
      self.frame[unit].background:SetWidth(self.frame[unit]:GetWidth())
      self.frame[unit].background:SetHeight(self.frame[unit]:GetHeight())	
      
	  
      self.frame[unit].background:SetTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, GladiusMoP.db.targetBarTexture))
      
      self.frame[unit].background:SetVertexColor(GladiusMoP.db.targetBarBackgroundColor.r, GladiusMoP.db.targetBarBackgroundColor.g,
         GladiusMoP.db.targetBarBackgroundColor.b, GladiusMoP.db.targetBarBackgroundColor.a)
	  
	  
      -- disable tileing
      self.frame[unit].background:SetHorizTile(false)
      self.frame[unit].background:SetVertTile(false)
	  
	  
      
      self.frame[unit]:Show()
   else
      self.frame[unit]:Hide()
   end
   
   -- update secure frame
   self.frame[unit].secure:RegisterForClicks("AnyUp")
   self.frame[unit].secure:SetAllPoints(self.frame[unit].frame)
   self.frame[unit].secure:SetWidth(self.frame[unit].frame:GetWidth())
   self.frame[unit].secure:SetHeight(self.frame[unit].frame:GetHeight())
   self.frame[unit].secure:SetFrameStrata("LOW")
   
   self.frame[unit].secure:SetAttribute("unit", unit .. "target")
   self.frame[unit].secure:SetAttribute("type1", "target")
   
	-- update highlight texture
   self.frame[unit].highlight:SetAllPoints(self.frame[unit].frame)   
	self.frame[unit].highlight:SetTexture([=[Interface\QuestFrame\UI-QuestTitleHighlight]=])
   self.frame[unit].highlight:SetBlendMode("ADD")   
   self.frame[unit].highlight:SetVertexColor(1.0, 1.0, 1.0, 1.0)
   self.frame[unit].highlight:SetAlpha(0)
	
	-- hide frame
	self.frame[unit].frame:SetAlpha(0)
	

end

function TargetBar:GetBarColor(class)
   if (class == "PRIEST" and not GladiusMoP.db.healthBarUseDefaultColorPriest) then
      return GladiusMoP.db.healthBarColorPriest
   elseif (class == "PALADIN" and not GladiusMoP.db.healthBarUseDefaultColorPaladin) then
      return GladiusMoP.db.healthBarUseDefaultColorPaladin
   elseif (class == "SHAMAN" and not GladiusMoP.db.healthBarUseDefaultColorShaman) then
      return GladiusMoP.db.healthBarColorShaman
   elseif (class == "DRUID" and not GladiusMoP.db.healthBarUseDefaultColorDruid) then
      return GladiusMoP.db.healthBarColorDruid      
   elseif (class == "MAGE" and not GladiusMoP.db.healthBarUseDefaultColorMage) then
      return GladiusMoP.db.healthBarColorMage
   elseif (class == "WARLOCK" and not GladiusMoP.db.healthBarUseDefaultColorWarlock) then
      return GladiusMoP.db.healthBarColorWarlock
   elseif (class == "HUNTER" and not GladiusMoP.db.healthBarUseDefaultColorHunter) then
      return GladiusMoP.db.healthBarColorHunter
   elseif (class == "WARRIOR" and not GladiusMoP.db.healthBarUseDefaultColorWarrior) then
      return GladiusMoP.db.healthBarColorWarrior
   elseif (class == "ROGUE" and not GladiusMoP.db.healthBarUseDefaultColorRogue) then
      return GladiusMoP.db.healthBarColorRogue
   elseif (class == "DEATHKNIGHT" and not GladiusMoP.db.healthBarUseDefaultColorDeathknight) then
      return GladiusMoP.db.healthBarColorDeathknight
   end
   
   return RAID_CLASS_COLORS[class]
end

function TargetBar:Show(unit)
   local testing = GladiusMoP.test
   
   -- show frame
   self.frame[unit].frame:SetAlpha(1)
   
   -- set secure frame
   self.frame[unit].secure:SetFrameStrata("DIALOG")
   
   -- get unit class
   local class
   if (not testing) then
      class = select(2, UnitClass(unit .. "target"))
   else
      class = GladiusMoP.testing[unit].unitClass
   end 
   
   -- set color
   if (not GladiusMoP.db.targetBarClassColor) then
      local color = GladiusMoP.db.targetBarColor
      self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
   else			
      local color = self:GetBarColor(class)
      if (color == nil) then 
         -- fallback, when targeting a pet or totem 
         color = GladiusMoP.db.targetBarColor
      end
      
      self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
   end
   
   -- set class icon
   TargetBar:SetClassIcon(unit)

   -- call event
   if (not GladiusMoP.test) then
      self:UNIT_HEALTH("UNIT_HEALTH", unit)
   end
end

function TargetBar:Reset(unit)
   if (not self.frame[unit]) then return end

   -- reset bar
   self.frame[unit]:SetMinMaxValues(0, 1)
   self.frame[unit]:SetValue(1)
   
   -- reset texture
   self.frame[unit].icon:SetTexture("")
   
   -- hide
	self.frame[unit].frame:SetAlpha(0)
end

function TargetBar:Test(unit)   
   -- set test values
   local maxHealth = GladiusMoP.testing[unit].maxHealth
   local health = GladiusMoP.testing[unit].health
   self:UpdateHealth(unit, health, maxHealth)
end

function TargetBar:GetOptions()
   return {
      general = {  
         type="group",
         name=L["General"],
         order=1,
         args = {
            bar = {
               type="group",
               name=L["Bar"],
               desc=L["Bar settings"],  
               inline=true,                
               order=1,
               args = {  
                  targetBarEnableBar = {
                     type="toggle",
                     name=L["Target bar health bar"],
                     desc=L["Toggle health bar display"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=3,
                  },
                  targetBarClassColor = {
                     type="toggle",
                     name=L["Target bar class color"],
                     desc=L["Toggle health bar class color"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  sep2 = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=7,
                  },
                  targetBarColor = {
                     type="color",
                     name=L["Target bar color"],
                     desc=L["Color of the health bar"],
                     hasAlpha=true,
                     get=function(info) return GladiusMoP:GetColorOption(info) end,
                     set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, a) end,
                     disabled=function() return GladiusMoP.dbi.profile.targetBarClassColor or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  targetBarBackgroundColor = {
                     type="color",
                     name=L["Target bar background color"],
                     desc=L["Color of the health bar background"],
                     hasAlpha=true,
                     get=function(info) return GladiusMoP:GetColorOption(info) end,
                     set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, a) end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=15,
                  },
                  sep3 = {                     
                     type = "description",
                     name="",
                     width="full",
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=17,
                  },
                  targetBarInverse = {
                     type="toggle",
                     name=L["Target bar inverse"],
                     desc=L["Inverse the health bar"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=20,
                  },
                  targetBarTexture = {
                     type="select",
                     name=L["Target bar texture"],
                     desc=L["Texture of the health bar"],
                     dialogControl = "LSM30_Statusbar",
                     values = AceGUIWidgetLSMlists.statusbar,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=25,
                  },
                  sep4 = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=27,
                  },
                  targetBarIcon = {
                     type="toggle",
                     name=L["Target bar class icon"],
                     desc=L["Toggle the target bar class icon"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=30,
                  },
                  targetBarIconPosition = {
                     type="select",
                     name=L["Target bar icon position"],
                     desc=L["Position of the target bar class icon"],
                     values={ ["LEFT"] = L["LEFT"], ["RIGHT"] = L["RIGHT"] },
                     disabled=function() return not GladiusMoP.dbi.profile.targetBarIcon or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=35,
                  },
                  sep6 = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=37,
                  },
                  targetBarIconCrop = {
                     type="toggle",
                     name=L["Target Bar Icon Crop Borders"],
                     desc=L["Toggle if the target bar icon borders should be cropped or not."],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=40,
                  },
               },
            },
            size = {
               type="group",
               name=L["Size"],
               desc=L["Size settings"],  
               inline=true,                
               order=2,
               args = {
                  targetBarAdjustWidth = {
                     type="toggle",
                     name=L["Target bar adjust width"],
                     desc=L["Adjust health bar width to the frame width"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=13,
                  },                  
                  targetBarWidth = {
                     type="range",
                     name=L["Target bar width"],
                     desc=L["Width of the health bar"],
                     min=10, max=500, step=1,
                     disabled=function() return GladiusMoP.dbi.profile.targetBarAdjustWidth or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=15,
                  },
                  targetBarHeight = {
                     type="range",
                     name=L["Target bar height"],
                     desc=L["Height of the health bar"],
                     min=10, max=200, step=1,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=20,
                  },
               },
            },
            position = {
               type="group",
               name=L["Position"],
               desc=L["Position settings"],  
               inline=true, 
               hidden=function() return not GladiusMoP.db.advancedOptions end,               
               order=3,
               args = {
                  targetBarAttachTo = {
                     type="select",
                     name=L["Target Bar Attach To"],
                     desc=L["Attach health bar to the given frame"],
                     values=function() return GladiusMoP:GetModules(self.name) end,
                     set=function(info, value) 
                        local key = info.arg or info[#info]                                                                        
                        GladiusMoP.dbi.profile[key] = value
                        
                        -- set frame type
                        if (GladiusMoP.db.targetBarAttachTo == "Frame" or strfind(GladiusMoP.db.targetBarRelativePoint, "BOTTOM")) then
                           self.isBar = true
                        else
                           self.isBar = false
                        end
                                             
                        GladiusMoP:UpdateFrame()
                     end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     width="double",
                     order=5,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=7,
                  },
                  targetBarAnchor = {
                     type="select",
                     name=L["Target Bar Anchor"],
                     desc=L["Anchor of the health bar"],
                     values=function() return GladiusMoP:GetPositions() end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  targetBarRelativePoint = {
                     type="select",
                     name=L["Target Bar Relative Point"],
                     desc=L["Relative point of the health bar"],
                     values=function() return GladiusMoP:GetPositions() end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=15,               
                  },
                  sep2 = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=17,
                  },
                  targetBarOffsetX = {
                     type="range",
                     name=L["Target bar offset X"],
                     desc=L["X offset of the health bar"],
                     min=-100, max=100, step=1,
                     disabled=function() return  not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=20,
                  },
                  targetBarOffsetY = {
                     type="range",
                     name=L["Target bar offset Y"],
                     desc=L["Y offset of the health bar"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     min=-100, max=100, step=1,
                     order=25,
                  },  
               },
            },             
         },
      },
   }
end
