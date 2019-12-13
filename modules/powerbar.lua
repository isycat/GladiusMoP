local GladiusMoP = _G.GladiusMoP
if not GladiusMoP then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires GladiusMoP", "Power Bar"))
end
local L = GladiusMoP.L
local LSM

-- global functions
local strfind = string.find
local pairs = pairs
local UnitPower, UnitPowerMax, UnitPowerType = UnitPower, UnitPowerMax, UnitPowerType

local PowerBar = GladiusMoP:NewModule("PowerBar", true, true, {
   powerBarAttachTo = "HealthBar",
   
   powerBarHeight = 15,
   powerBarAdjustWidth = true,
   powerBarWidth = 200,
   
   powerBarInverse = false,
   powerBarColor = { r = 1, g = 1, b = 1, a = 1 },
   powerBarDefaultColor = true,
   powerBarBackgroundColor = { r = 1, g = 1, b = 1, a = 0.3 },
   powerBarTexture = "Minimalist",   
   
   powerBarOffsetX = 0,
   powerBarOffsetY = 0, 
   
   powerBarAnchor = "TOPLEFT",
   powerBarRelativePoint = "BOTTOMLEFT",  
   
   powerBarUseDefaultColorMana = false,
   powerBarColorMana = {r = .18, g = .44, b = .75, a = 1},
   powerBarUseDefaultColorRage = false,
   powerBarColorRage = {r = 1, g = 0, b = 0, a = 1},
   powerBarUseDefaultColorFocus = false,
   powerBarColorFocus = PowerBarColor[2],
   powerBarUseDefaultColorEnergy = false,
   powerBarColorEnergy = {r = 1, g = 1, b = 0, a = 1},
   powerBarUseDefaultColorRunicPower = false,
   powerBarColorRunicPower = {r = 0, g = 0.82, b = 1, a = 1},
})

function PowerBar:OnEnable()
   self:RegisterEvent("UNIT_POWER")
   self:RegisterEvent("UNIT_MAXPOWER", "UNIT_POWER")
   
   self:RegisterEvent("UNIT_MANA", "UNIT_POWER")
   self:RegisterEvent("UNIT_RAGE", "UNIT_POWER")
   self:RegisterEvent("UNIT_ENERGY", "UNIT_POWER")
   self:RegisterEvent("UNIT_FOCUS", "UNIT_POWER")
   self:RegisterEvent("UNIT_RUNIC_POWER", "UNIT_POWER")
   self:RegisterEvent("UNIT_MAXMANA", "UNIT_POWER")
   self:RegisterEvent("UNIT_MAXRAGE", "UNIT_POWER")
   self:RegisterEvent("UNIT_MAXENERGY", "UNIT_POWER")
   self:RegisterEvent("UNIT_MAXFOCUS", "UNIT_POWER")
   self:RegisterEvent("UNIT_MAXRUNIC_POWER", "UNIT_POWER")
   self:RegisterEvent("UNIT_DISPLAYPOWER", "UNIT_POWER")
   
   LSM = GladiusMoP.LSM
   
   -- set frame type
   if (GladiusMoP.db.healthBarAttachTo == "Frame" or strfind(GladiusMoP.db.powerBarRelativePoint, "BOTTOM")) then
      self.isBar = true
   else
      self.isBar = false
   end
   
   if (not self.frame) then
      self.frame = {}
   end
end

function PowerBar:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit]:SetAlpha(0)
   end
end

function PowerBar:GetAttachTo()
   return GladiusMoP.db.powerBarAttachTo
end

function PowerBar:GetFrame(unit)
   return self.frame[unit]
end

function PowerBar:UNIT_POWER(event, unit)
   if (not strfind(unit, "arena") or strfind(unit, "pet")) then return end

   local power, maxPower, powerType = UnitPower(unit), UnitPowerMax(unit), UnitPowerType(unit)
   self:UpdatePower(unit, power, maxPower, powerType)
end

function PowerBar:UpdatePower(unit, power, maxPower, powerType)
   if (not self.frame[unit]) then return end   
   local testing = GladiusMoP.test
   
   if (not self.frame[unit]) then
      if (not GladiusMoP.buttons[unit]) then
         GladiusMoP:UpdateUnit(unit)
      else
         self:Update(unit)
      end
   end

   -- update min max values
   self.frame[unit]:SetMinMaxValues(0, maxPower)
   
   -- inverse bar
   if (GladiusMoP.db.powerBarInverse) then
      self.frame[unit]:SetValue(maxPower - power)
   else
      self.frame[unit]:SetValue(power)
   end
   
   -- update bar color
   if (GladiusMoP.db.powerBarDefaultColor) then		
      local color = self:GetBarColor(powerType)
      self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b)
   end
end

function PowerBar:CreateBar(unit)
   local button = GladiusMoP.buttons[unit]
   if (not button) then return end      
   
   -- create bar + text
   self.frame[unit] = CreateFrame("STATUSBAR", "GladiusMoP" .. self.name .. unit, button) 
   self.frame[unit].background = self.frame[unit]:CreateTexture("GladiusMoP" .. self.name .. unit .. "Background", "BACKGROUND") 
   self.frame[unit].highlight = self.frame[unit]:CreateTexture("GladiusMoP" .. self.name .. "Highlight" .. unit, "OVERLAY")
end

function PowerBar:Update(unit)
   -- check parent module
   if (not GladiusMoP:GetModule(GladiusMoP.db.castBarAttachTo)) then
      if (self.frame[unit]) then
         self.frame[unit]:Hide()
      end
      return
   end

   -- get unit powerType
   local powerType
   if (not testing) then
      powerType = UnitPowerType(unit)
   else
      powerType = GladiusMoP.testing[unit].powerType
   end

   -- create power bar
   if (not self.frame[unit]) then 
      self:CreateBar(unit)
   end
     
   -- set bar type 
   local parent = GladiusMoP:GetParent(unit, GladiusMoP.db.powerBarAttachTo)
     
   if (GladiusMoP.db.healthBarAttachTo == "Frame" or strfind(GladiusMoP.db.powerBarRelativePoint, "BOTTOM")) then
      self.isBar = true
   else
      self.isBar = false
   end
      
   -- update power bar   
   self.frame[unit]:ClearAllPoints()

   local width = GladiusMoP.db.powerBarAdjustWidth and GladiusMoP.db.barWidth or GladiusMoP.db.powerBarWidth
	
	-- add width of the widget if attached to an widget
	if (GladiusMoP.db.healthBarAttachTo ~= "Frame" and not strfind(GladiusMoP.db.powerBarRelativePoint, "BOTTOM") and GladiusMoP.db.powerBarAdjustWidth) then
      if (not GladiusMoP:GetModule(GladiusMoP.db.powerBarAttachTo).frame[unit]) then
         GladiusMoP:GetModule(GladiusMoP.db.powerBarAttachTo):Update(unit)
      end
      
      width = width + GladiusMoP:GetModule(GladiusMoP.db.powerBarAttachTo).frame[unit]:GetWidth()
	end
		 
	self.frame[unit]:SetHeight(GladiusMoP.db.powerBarHeight)    
   self.frame[unit]:SetWidth(width) 
   	
	self.frame[unit]:SetPoint(GladiusMoP.db.powerBarAnchor, parent, GladiusMoP.db.powerBarRelativePoint, GladiusMoP.db.powerBarOffsetX, GladiusMoP.db.powerBarOffsetY)
	self.frame[unit]:SetMinMaxValues(0, 100)
	self.frame[unit]:SetValue(100)
	self.frame[unit]:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, GladiusMoP.db.powerBarTexture))
	
	-- disable tileing
	self.frame[unit]:GetStatusBarTexture():SetHorizTile(false)
   self.frame[unit]:GetStatusBarTexture():SetVertTile(false)
   
   -- update power bar background
   self.frame[unit].background:ClearAllPoints()
	self.frame[unit].background:SetAllPoints(self.frame[unit])
	
	self.frame[unit].background:SetWidth(self.frame[unit]:GetWidth())
	self.frame[unit].background:SetHeight(self.frame[unit]:GetHeight())	
	
	self.frame[unit].background:SetTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, GladiusMoP.db.powerBarTexture))
	
	self.frame[unit].background:SetVertexColor(GladiusMoP.db.powerBarBackgroundColor.r, GladiusMoP.db.powerBarBackgroundColor.g,
      GladiusMoP.db.powerBarBackgroundColor.b, GladiusMoP.db.powerBarBackgroundColor.a)
	
	-- disable tileing
	self.frame[unit].background:SetHorizTile(false)
   self.frame[unit].background:SetVertTile(false)
   
   -- set color
   if (not GladiusMoP.db.powerBarDefaultColor) then
      local color = GladiusMoP.db.powerBarColor
      self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
   else			
      local color = self:GetBarColor(powerType)
      self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b)
   end
	
	-- update highlight texture
	self.frame[unit].highlight:SetAllPoints(self.frame[unit])
	self.frame[unit].highlight:SetTexture([=[Interface\QuestFrame\UI-QuestTitleHighlight]=])
   self.frame[unit].highlight:SetBlendMode("ADD")   
   self.frame[unit].highlight:SetVertexColor(1.0, 1.0, 1.0, 1.0)
   self.frame[unit].highlight:SetAlpha(0)
   
	-- hide frame
   self.frame[unit]:SetAlpha(0)
end

function PowerBar:GetBarColor(powerType)
   if (powerType == 0 and not GladiusMoP.db.powerBarUseDefaultColorMana) then
      return GladiusMoP.db.powerBarColorMana
   elseif (powerType == 1 and not GladiusMoP.db.powerBarUseDefaultColorRage) then
      return GladiusMoP.db.powerBarColorRage
   elseif (powerType == 2 and not GladiusMoP.db.powerBarUseDefaultColorFocus) then
      return GladiusMoP.db.powerBarColorFocus
   elseif (powerType == 3 and not GladiusMoP.db.powerBarUseDefaultColorEnergy) then
      return GladiusMoP.db.powerBarColorEnergy
   elseif (powerType == 6 and not GladiusMoP.db.powerBarUseDefaultColorRunicPower) then
      return GladiusMoP.db.powerBarColorRunicPower
   end
   
   return PowerBarColor[powerType]
end

function PowerBar:Show(unit)
   local testing = GladiusMoP.test
   
   -- show frame
   self.frame[unit]:SetAlpha(1)

   if (not GladiusMoP.test) then
      self:UNIT_POWER("UNIT_POWER", unit)
   end
end

function PowerBar:Reset(unit)
   -- reset bar
   self.frame[unit]:SetMinMaxValues(0, 1)
   self.frame[unit]:SetValue(1)
   
   -- hide
	self.frame[unit]:SetAlpha(0)
end

function PowerBar:Test(unit)     
   -- set test values
   local maxPower, power
   
   -- power type
   local powerType = GladiusMoP.testing[unit].powerType
   
   maxPower = GladiusMoP.testing[unit].maxPower  
   power = GladiusMoP.testing[unit].power
   
   self:UpdatePower(unit, power, maxPower, powerType)
end

function PowerBar:GetOptions()
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
                  powerBarDefaultColor = {
                     type="toggle",
                     name=L["Power Bar Default Color"],
                     desc=L["Toggle power bar default color"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=7,
                  },
                  powerBarColor = {
                     type="color",
                     name=L["Power Bar Color"],
                     desc=L["Color of the power bar"],
                     hasAlpha=true,
                     get=function(info) return GladiusMoP:GetColorOption(info) end,
                     set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, a) end,
                     disabled=function() return GladiusMoP.dbi.profile.powerBarDefaultColor or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  powerBarBackgroundColor = {
                     type="color",
                     name=L["Power Bar Background Color"],
                     desc=L["Color of the power bar background"],
                     hasAlpha=true,
                     get=function(info) return GladiusMoP:GetColorOption(info) end,
                     set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, a) end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=15,
                  }, 
                  sep2 = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=17,
                  }, 
                  powerBarInverse = {
                     type="toggle",
                     name=L["Power Bar Inverse"],
                     desc=L["Inverse the power bar"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=20,
                  },         
                  powerBarTexture = {
                     type="select",
                     name=L["Power Bar Texture"],
                     desc=L["Texture of the power bar"],
                     dialogControl = "LSM30_Statusbar",
                     values = AceGUIWidgetLSMlists.statusbar,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=25,
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
                  powerBarAdjustWidth = {
                     type="toggle",
                     name=L["Power Bar Adjust Width"],
                     desc=L["Adjust power bar width to the frame width"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=13,
                  },
                  powerBarWidth = {
                     type="range",
                     name=L["Power Bar Width"],
                     desc=L["Width of the power bar"],
                     min=10, max=500, step=1,
                     disabled=function() return GladiusMoP.dbi.profile.powerBarAdjustWidth or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=15,
                  },
                  powerBarHeight = {
                     type="range",
                     name=L["Power Bar Height"],
                     desc=L["Height of the power bar"],
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
                  powerBarAttachTo = {
                     type="select",
                     name=L["Power Bar Attach To"],
                     desc=L["Attach power bar to the given frame"],
                     values=function() return GladiusMoP:GetModules(self.name) end,
                     set=function(info, value) 
                        local key = info.arg or info[#info]
                        
                        if (strfind(GladiusMoP.db.powerBarRelativePoint, "BOTTOM")) then
                           self.isBar = true
                        else
                           self.isBar = false
                        end
                        
                        GladiusMoP.dbi.profile[key] = value
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
                  powerBarAnchor = {
                     type="select",
                     name=L["Power Bar Anchor"],
                     desc=L["Anchor of the power bar"],
                     values=function() return GladiusMoP:GetPositions() end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  powerBarRelativePoint = {
                     type="select",
                     name=L["Power Bar Relative Point"],
                     desc=L["Relative point of the power bar"],
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
                  powerBarOffsetX = {
                     type="range",
                     name=L["Power Bar Offset X"],
                     desc=L["X offset of the power bar"],
                     min=-100, max=100, step=1,
                     disabled=function() return  not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=20,
                  },
                  powerBarOffsetY = {
                     type="range",
                     name=L["Power Bar Offset Y"],
                     desc=L["X offset of the power bar"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     min=-100, max=100, step=1,
                     order=25,
                  },
               },
            },
         },
      },      
      powerDefaultColors = {  
         type="group",
         name=L["Power colors"],
         hidden=function() return not GladiusMoP.db.advancedOptions end,
         order=4,
         args = {
            powerBarUseDefaultColorMana = {
               type="toggle",
               name=L["Default Power Mana Color"],
               desc=L["Toggle default power mana color"],
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=0,
            },
            powerBarColorMana = {
               type="color",
               name=L["Power Mana Color"],
               get=function(info) return GladiusMoP:GetColorOption(info) end,
               set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=5,
            },
            sep = {                     
               type = "description",
               name="",
               width="full",
               order=7,
            },
            powerBarUseDefaultColorRage = {
               type="toggle",
               name=L["Default Power Rage Color"],
               desc=L["Toggle default power rage color"],
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=10,
            },
            powerBarColorRage = {
               type="color",
               name=L["Power Rage Color"],
               get=function(info) return GladiusMoP:GetColorOption(info) end,
               set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=15,
            },
            sep2 = {                     
               type = "description",
               name="",
               width="full",
               order=17,
            },
            powerBarUseDefaultColorFocus = {
               type="toggle",
               name=L["Default Power Focus Color"],
               desc=L["Toggle default power focus color"],
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=20,
            },
            powerBarColorFocus = {
               type="color",
               name=L["Power Focus Color"],
               get=function(info) return GladiusMoP:GetColorOption(info) end,
               set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=25,
            },
            sep3 = {                     
               type = "description",
               name="",
               width="full",
               order=27,
            },
            powerBarUseDefaultColorEnergy = {
               type="toggle",
               name=L["Default Power Energy Color"],
               desc=L["Toggle default power energy color"],
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=30,
            },
            powerBarColorEnergy = {
               type="color",
               name=L["Power Energy Color"],
               get=function(info) return GladiusMoP:GetColorOption(info) end,
               set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=35,
            },
            sep4 = {                     
               type = "description",
               name="",
               width="full",
               order=37,
            },
            powerBarUseDefaultColorRunicPower = {
               type="toggle",
               name=L["Default Power Runic Power Color"],
               desc=L["Toggle default power runic power color"],
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=40,
            },
            powerBarColorRunicPower = {
               type="color",
               name=L["Power Runic Power Color"],
               get=function(info) return GladiusMoP:GetColorOption(info) end,
               set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=45,
            },
         },
      },
   }
end
