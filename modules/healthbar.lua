local GladiusMoP = _G.GladiusMoP
if not GladiusMoP then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires GladiusMoP", "Health Bar"))
end
local L = GladiusMoP.L
local LSM

-- global functions
local strfind = string.find
local pairs = pairs
local UnitHealth, UnitHealthMax, UnitClass = UnitHealth, UnitHealthMax, UnitClass

local HealthBar = GladiusMoP:NewModule("HealthBar", true, true, {
   healthBarAttachTo = "Frame",
   
   healthBarHeight = 25,
   healthBarAdjustWidth = true,
   healthBarWidth = 200,
   
   healthBarInverse = false,
   healthBarColor = { r = 1, g = 1, b = 1, a = 1 },
   healthBarClassColor = true,
   healthBarBackgroundColor = { r = 1, g = 1, b = 1, a = 0.3 },
   healthBarTexture = "Minimalist", 
   
   healthBarOffsetX = 0,
   healthBarOffsetY = 0,  
   
   healthBarAnchor = "TOPLEFT",
   healthBarRelativePoint = "TOPLEFT",
   
   healthBarUseDefaultColorPriest = true,
   healthBarColorPriest = RAID_CLASS_COLORS["PRIEST"],
   healthBarUseDefaultColorPaladin = true,
   healthBarColorPaladin = RAID_CLASS_COLORS["PALADIN"],
   healthBarUseDefaultColorShaman = true,
   healthBarColorShaman = RAID_CLASS_COLORS["SHAMAN"],
   healthBarUseDefaultColorDruid = true,
   healthBarColorDruid = RAID_CLASS_COLORS["DRUID"],
   healthBarUseDefaultColorMage = true,
   healthBarColorMage = RAID_CLASS_COLORS["MAGE"],
   healthBarUseDefaultColorWarlock = true,
   healthBarColorWarlock = RAID_CLASS_COLORS["WARLOCK"],
   healthBarUseDefaultColorHunter = true,
   healthBarColorHunter = RAID_CLASS_COLORS["HUNTER"],
   healthBarUseDefaultColorWarrior = true,
   healthBarColorWarrior = RAID_CLASS_COLORS["WARRIOR"],
   healthBarUseDefaultColorRogue = true,
   healthBarColorRogue = RAID_CLASS_COLORS["ROGUE"],
   healthBarUseDefaultColorDeathknight = true,
   healthBarColorDeathknight = RAID_CLASS_COLORS["DEATHKNIGHT"],
})

function HealthBar:OnEnable()   
   self:RegisterEvent("UNIT_HEALTH")
   self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH")
   
   LSM = GladiusMoP.LSM
   
   -- set frame type
   if (GladiusMoP.db.healthBarAttachTo == "Frame" or strfind(GladiusMoP.db.healthBarRelativePoint, "BOTTOM")) then
      self.isBar = true
   else
      self.isBar = false
   end
   
   if (not self.frame) then
      self.frame = {}
   end
end

function HealthBar:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit]:SetAlpha(0)
   end
end

function HealthBar:GetAttachTo()
   return GladiusMoP.db.healthBarAttachTo
end

function HealthBar:GetFrame(unit)
   return self.frame[unit]
end

function HealthBar:UNIT_HEALTH(event, unit)
   if (not strfind(unit, "arena") or strfind(unit, "pet")) then return end
   
   local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
   self:UpdateHealth(unit, health, maxHealth)
end

function HealthBar:UpdateHealth(unit, health, maxHealth)
   if (not self.frame[unit]) then
      if (not GladiusMoP.buttons[unit]) then
         GladiusMoP:UpdateUnit(unit)
      else
         self:Update(unit)
      end
   end
  
   -- update min max values
   if (self.frame[unit]==nil) then return end
   self.frame[unit]:SetMinMaxValues(0, maxHealth)

   -- inverse bar
   if (GladiusMoP.db.healthBarInverse) then
      self.frame[unit]:SetValue(maxHealth - health)
   else
      self.frame[unit]:SetValue(health)
   end
end

function HealthBar:CreateBar(unit)
   local button = GladiusMoP.buttons[unit]
   if (not button) then return end       

   -- create bar + text
   self.frame[unit] = CreateFrame("STATUSBAR", "GladiusMoP" .. self.name .. unit, button) 
   self.frame[unit].background = self.frame[unit]:CreateTexture("GladiusMoP" .. self.name .. unit .. "Background", "BACKGROUND") 
   self.frame[unit].highlight = self.frame[unit]:CreateTexture("GladiusMoP" .. self.name .. "Highlight" .. unit, "OVERLAY")
end

function HealthBar:Update(unit)
   -- check parent module
   if (not GladiusMoP:GetModule(GladiusMoP.db.castBarAttachTo)) then
      if (self.frame[unit]) then
         self.frame[unit]:Hide()
      end
      return
   end

   -- create power bar
   if (not self.frame[unit]) then 
      self:CreateBar(unit)
   end
   
   -- set bar type 
   local parent = GladiusMoP:GetParent(unit, GladiusMoP.db.healthBarAttachTo)
     
   if (GladiusMoP.db.healthBarAttachTo == "Frame" or strfind(GladiusMoP.db.healthBarRelativePoint, "BOTTOM")) then
      self.isBar = true
   else
      self.isBar = false
   end
      
   -- update health bar   
   self.frame[unit]:ClearAllPoints()

   local width = GladiusMoP.db.healthBarAdjustWidth and GladiusMoP.db.barWidth or GladiusMoP.db.healthBarWidth
	
	-- add width of the widget if attached to an widget
	if (GladiusMoP.db.healthBarAttachTo ~= "Frame" and not strfind(GladiusMoP.db.healthBarRelativePoint,"BOTTOM") and GladiusMoP.db.healthBarAdjustWidth) then
      if (not GladiusMoP:GetModule(GladiusMoP.db.healthBarAttachTo).frame[unit]) then
         GladiusMoP:GetModule(GladiusMoP.db.healthBarAttachTo):Update(unit)
      end
      
      width = width + GladiusMoP:GetModule(GladiusMoP.db.healthBarAttachTo).frame[unit]:GetWidth()
	end
		 
   self.frame[unit]:SetHeight(GladiusMoP.db.healthBarHeight)   
   self.frame[unit]:SetWidth(width) 
   	
	self.frame[unit]:SetPoint(GladiusMoP.db.healthBarAnchor, parent, GladiusMoP.db.healthBarRelativePoint, GladiusMoP.db.healthBarOffsetX, GladiusMoP.db.healthBarOffsetY)
	self.frame[unit]:SetMinMaxValues(0, 100)
	self.frame[unit]:SetValue(100)
	self.frame[unit]:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, GladiusMoP.db.healthBarTexture))
	
	-- disable tileing
	self.frame[unit]:GetStatusBarTexture():SetHorizTile(false)
   self.frame[unit]:GetStatusBarTexture():SetVertTile(false)
   
   -- update health bar background
   self.frame[unit].background:ClearAllPoints()
	self.frame[unit].background:SetAllPoints(self.frame[unit])
	
	self.frame[unit].background:SetWidth(self.frame[unit]:GetWidth())
	self.frame[unit].background:SetHeight(self.frame[unit]:GetHeight())	
	
	self.frame[unit].background:SetTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, GladiusMoP.db.healthBarTexture))
	
	self.frame[unit].background:SetVertexColor(GladiusMoP.db.healthBarBackgroundColor.r, GladiusMoP.db.healthBarBackgroundColor.g,
      GladiusMoP.db.healthBarBackgroundColor.b, GladiusMoP.db.healthBarBackgroundColor.a)
	
	-- disable tileing
	self.frame[unit].background:SetHorizTile(false)
   self.frame[unit].background:SetVertTile(false)
	
	-- update highlight texture
	self.frame[unit].highlight:SetAllPoints(self.frame[unit])
	self.frame[unit].highlight:SetTexture([=[Interface\QuestFrame\UI-QuestTitleHighlight]=])
   self.frame[unit].highlight:SetBlendMode("ADD")   
   self.frame[unit].highlight:SetVertexColor(1.0, 1.0, 1.0, 1.0)
   self.frame[unit].highlight:SetAlpha(0)
	
	-- hide frame
	self.frame[unit]:SetAlpha(0)
end

function HealthBar:GetBarColor(class)
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

function HealthBar:Show(unit)
   local testing = GladiusMoP.test
   
   -- show frame
   self.frame[unit]:SetAlpha(1)
   
   -- get unit class
   local class
   if (not testing) then
      class = select(2, UnitClass(unit))
   else
      class = GladiusMoP.testing[unit].unitClass
   end 
   
   -- set color
   if (not GladiusMoP.db.healthBarClassColor) then
      local color = GladiusMoP.db.healthBarColor
      self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
   else			
      local color = self:GetBarColor(class)
      self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
   end

   -- call event
   if (not GladiusMoP.test) then
      self:UNIT_HEALTH("UNIT_HEALTH", unit)
   end
end

function HealthBar:Reset(unit)
   if (not self.frame[unit]) then return end

   -- reset bar
   self.frame[unit]:SetMinMaxValues(0, 1)
   self.frame[unit]:SetValue(1)
   
   -- hide
	self.frame[unit]:SetAlpha(0)
end

function HealthBar:Test(unit)   
   -- set test values
   local maxHealth = GladiusMoP.testing[unit].maxHealth
   local health = GladiusMoP.testing[unit].health
   self:UpdateHealth(unit, health, maxHealth)
end

function HealthBar:GetOptions()
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
                  healthBarClassColor = {
                     type="toggle",
                     name=L["Health bar class color"],
                     desc=L["Toggle health bar class color"],
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
                  healthBarColor = {
                     type="color",
                     name=L["Health bar color"],
                     desc=L["Color of the health bar"],
                     hasAlpha=true,
                     get=function(info) return GladiusMoP:GetColorOption(info) end,
                     set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, a) end,
                     disabled=function() return GladiusMoP.dbi.profile.healthBarClassColor or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  healthBarBackgroundColor = {
                     type="color",
                     name=L["Health bar background color"],
                     desc=L["Color of the health bar background"],
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
                  healthBarInverse = {
                     type="toggle",
                     name=L["Health bar inverse"],
                     desc=L["Inverse the health bar"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=20,
                  },
                  healthBarTexture = {
                     type="select",
                     name=L["Health bar texture"],
                     desc=L["Texture of the health bar"],
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
                  healthBarAdjustWidth = {
                     type="toggle",
                     name=L["Health bar adjust width"],
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
                  healthBarWidth = {
                     type="range",
                     name=L["Health bar width"],
                     desc=L["Width of the health bar"],
                     min=10, max=500, step=1,
                     disabled=function() return GladiusMoP.dbi.profile.healthBarAdjustWidth or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=15,
                  },
                  healthBarHeight = {
                     type="range",
                     name=L["Health bar height"],
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
                  healthBarAttachTo = {
                     type="select",
                     name=L["Health Bar Attach To"],
                     desc=L["Attach health bar to the given frame"],
                     values=function() return GladiusMoP:GetModules(self.name) end,
                     set=function(info, value) 
                        local key = info.arg or info[#info]
                        
                        if (strfind(GladiusMoP.db.healthBarRelativePoint, "BOTTOM")) then
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
                  healthBarAnchor = {
                     type="select",
                     name=L["Health Bar Anchor"],
                     desc=L["Anchor of the health bar"],
                     values=function() return GladiusMoP:GetPositions() end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  healthBarRelativePoint = {
                     type="select",
                     name=L["Health Bar Relative Point"],
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
                  healthBarOffsetX = {
                     type="range",
                     name=L["Health bar offset X"],
                     desc=L["X offset of the health bar"],
                     min=-100, max=100, step=1,
                     disabled=function() return  not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=20,
                  },
                  healthBarOffsetY = {
                     type="range",
                     name=L["Health bar offset Y"],
                     desc=L["Y offset of the health bar"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     min=-100, max=100, step=1,
                     order=25,
                  },  
               },
            },             
         },
      },
      healthDefaultColors = {  
         type="group",
         name=L["Health colors"],
         hidden=function() return not GladiusMoP.db.advancedOptions end,
         order=2,
         args = {
            healthBarUseDefaultColorPriest = {
               type="toggle",
               name=L["Default priest color"],
               desc=L["Toggle default priest color"],
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=0,
            },
            healthBarColorPriest = {
               type="color",
               name=L["Priest color"],
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
            healthBarUseDefaultColorPaladin = {
               type="toggle",
               name=L["Default paladin color"],
               desc=L["Toggle default paladin color"],
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=10,
            },
            healthBarColorPaladin = {
               type="color",
               name=L["Paladin color"],
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
            healthBarUseDefaultColorShaman = {
               type="toggle",
               name=L["Default shaman color"],
               desc=L["Toggle default shaman color"],
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=20,
            },
            healthBarColorShaman = {
               type="color",
               name=L["Shaman color"],
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
            healthBarUseDefaultColorDruid = {
               type="toggle",
               name=L["Default druid color"],
               desc=L["Toggle default druid color"],
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=30,
            },
            healthBarColorDruid = {
               type="color",
               name=L["Druid color"],
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
            healthBarUseDefaultColorMage = {
               type="toggle",
               name=L["Default mage color"],
               desc=L["Toggle default mage color"],
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=40,
            },
            healthBarColorMage = {
               type="color",
               name=L["Mage color"],
               get=function(info) return GladiusMoP:GetColorOption(info) end,
               set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=45,
            },
            sep5 = {                     
               type = "description",
               name="",
               width="full",
               order=47,
            },
            healthBarUseDefaultColorWarlock = {
               type="toggle",
               name=L["Default warlock color"],
               desc=L["Toggle default warlock color"],
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=50,
            },
            healthBarColorWarlock = {
               type="color",
               name=L["Warlock color"],
               get=function(info) return GladiusMoP:GetColorOption(info) end,
               set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=55,
            },
            sep6 = {                     
               type = "description",
               name="",
               width="full",
               order=57,
            },
            healthBarUseDefaultColorHunter = {
               type="toggle",
               name=L["Default hunter color"],
               desc=L["Toggle default hunter color"],
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=60,
            },
            healthBarColorHunter = {
               type="color",
               name=L["Hunter color"],
               get=function(info) return GladiusMoP:GetColorOption(info) end,
               set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=65,
            },
            sep7 = {                     
               type = "description",
               name="",
               width="full",
               order=67,
            },
            healthBarUseDefaultColorWarrior = {
               type="toggle",
               name=L["Default warrior color"],
               desc=L["Toggle default warrior color"],
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=70,
            },
            healthBarColorWarrior = {
               type="color",
               name=L["Warrior color"],
               get=function(info) return GladiusMoP:GetColorOption(info) end,
               set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=75,
            },
            sep8 = {                     
               type = "description",
               name="",
               width="full",
               order=77,
            },
            healthBarUseDefaultColorRogue = {
               type="toggle",
               name=L["Default rogue color"],
               desc=L["Toggle default eogue color"],
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=80,
            },
            healthBarColorRogue = {
               type="color",
               name=L["Rogue color"],
               get=function(info) return GladiusMoP:GetColorOption(info) end,
               set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=85,
            },
            sep9 = {                     
               type = "description",
               name="",
               width="full",
               order=87,
            },
            healthBarUseDefaultColorDeathknight = {
               type="toggle",
               name=L["Default death knight color"],
               desc=L["Toggle default death knight color"],
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=90,
            },
            healthBarColorDeathknight = {
               type="color",
               name=L["Death knight color"],
               get=function(info) return GladiusMoP:GetColorOption(info) end,
               set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, 1) end,
               disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
               order=95,
            },
         },
      },
   }
end
