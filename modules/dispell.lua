local GladiusMoP = _G.GladiusMoP
if not GladiusMoP then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires GladiusMoP", "Dispel"))
end
local L = GladiusMoP.L
local LSM

-- global functions
local strfind = string.find
local pairs = pairs
local strformat = string.format
local UnitName, UnitClass, UnitFactionGroup, UnitLevel = UnitName, UnitClass, UnitFactionGroup, UnitLevel

local Dispel = GladiusMoP:NewModule("Dispel", false, true, {
   dispelAttachTo = "Frame",
   dispelAnchor = "TOPLEFT",
   dispelRelativePoint = "TOPRIGHT",
   dispelGridStyleIcon = false,
   dispelGridStyleIconColor = { r = 0, g = 1, b = 0, a = 1 },
   dispelGridStyleIconUsedColor = { r = 1, g = 0, b = 0, a = 1 },
   dispelAdjustSize = true,
   dispelSize = 52,
   dispelOffsetX = 52,
   dispelOffsetY = 0,
   dispelFrameLevel = 2,
   dispelIconCrop = false,
   dispelGloss = true,
   dispelGlossColor = { r = 1, g = 1, b = 1, a = 0.4 },
   dispelCooldown = true,
   dispelCooldownReverse = false,
   dispelFaction = true,
}, { "Dispel icon", "Grid style health bar", "Grid style power bar" })

function Dispel:OnEnable()   
   --self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
   self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
   
   
   LSM = GladiusMoP.LSM   
   
   if (not self.frame) then
      self.frame = {}
   end 
end

function Dispel:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit]:SetAlpha(0)
   end
end

function Dispel:GetAttachTo()
   return GladiusMoP.db.dispelAttachTo
end

function Dispel:GetFrame(unit)
   return self.frame[unit]
end

function Dispel:SetTemplate(template)
   if (template == 1) then
      -- reset width
      if (GladiusMoP.db.targetBarAttachTo == "HealthBar" and not GladiusMoP.db.healthBarAdjustWidth) then
         GladiusMoP.db.healthBarAdjustWidth = true
      end
   
      -- reset to default
      for k, v in pairs(self.defaults) do
         GladiusMoP.db[k] = v
      end
   elseif (template == 2) then
      if (GladiusMoP.db.modules["HealthBar"]) then
         if (GladiusMoP.db.healthBarAdjustWidth) then
            GladiusMoP.db.healthBarAdjustWidth = false
            GladiusMoP.db.healthBarWidth = GladiusMoP.db.barWidth - GladiusMoP.db.healthBarHeight
         else
            GladiusMoP.db.healthBarWidth = GladiusMoP.db.healthBarWidth - GladiusMoP.db.healthBarHeight
         end
         
         GladiusMoP.db.dispelGridStyleIcon = true
           
         GladiusMoP.db.dispelAdjustHeight = false   
         GladiusMoP.db.dispelHeight = GladiusMoP.db.healthBarHeight
         
         GladiusMoP.db.dispelAttachTo = "HealthBar"
         GladiusMoP.db.dispelAnchor = "TOPLEFT"
         GladiusMoP.db.dispelRelativePoint = "TOPRIGHT"
         
         GladiusMoP.db.dispelOffsetX = 52
         GladiusMoP.db.dispelOffsetY = 0         
      end
   else
      if (GladiusMoP.db.modules["PowerBar"]) then
         if (GladiusMoP.db.powerBarAdjustWidth) then
            GladiusMoP.db.powerBarAdjustWidth = false
            GladiusMoP.db.powerBarWidth = GladiusMoP.db.powerBarWidth - GladiusMoP.db.powerBarHeight
         else
            GladiusMoP.db.powerBarWidth = GladiusMoP.db.powerBarWidth - GladiusMoP.db.powerBarHeight
         end
         
         GladiusMoP.db.dispelGridStyleIcon = true
           
         GladiusMoP.db.dispelAdjustHeight = false   
         GladiusMoP.db.dispelHeight = GladiusMoP.db.powerBarHeight
         
         GladiusMoP.db.dispelAttachTo = "PowerBar"
         GladiusMoP.db.dispelAnchor = "TOPLEFT"
         GladiusMoP.db.dispelRelativePoint = "TOPRIGHT"
         
         GladiusMoP.db.dispelOffsetX = 52
         GladiusMoP.db.dispelOffsetY = 0         
      end      
   end
end




function Dispel:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
if select(2, ...)=="SPELL_DISPEL" then
	local spell = select(12, ...)
	local unit = select(4, ...)
	
   --if (not strfind(unit, "arena") or strfind(unit, "pet")) then return end
   
   if (not(UnitGUID("arena1")==unit or UnitGUID("arena2")==unit or UnitGUID("arena3")==unit or UnitGUID("arena4")==unit or UnitGUID("arena5")==unit)) then return end
   
   
   if (spell == 527                  -- priest Purify  http://mop.wowhead.com/spell=527
      or spell == 4987					--paladin Cleanse http://mop.wowhead.com/spell=4987
	  or spell == 77130					--shaman Purify Spirit http://mop.wowhead.com/spell=77130
	  or spell == 88423					--druid Nature's cure http://mop.wowhead.com/spell=88423
	  ) then
	  
	  if UnitGUID("arena1")==unit then
      self:UpdateDispel("arena1", 8) end
	  if UnitGUID("arena2")==unit then
      self:UpdateDispel("arena2", 8) end
	  if UnitGUID("arena3")==unit then
      self:UpdateDispel("arena3", 8) end
	  if UnitGUID("arena4")==unit then
      self:UpdateDispel("arena4", 8) end
	  if UnitGUID("arena5")==unit then
      self:UpdateDispel("arena5", 8) end
   end

   -- wotf
  -- if (spell == GetSpellInfo(7744)) then	
  --    self:UpdateDispel(unit, 45)
 --  end
end
end

function Dispel:UpdateDispel(unit, duration)
   -- grid style icon
   if (GladiusMoP.db.dispelGridStyleIcon) then
      self.frame[unit].texture:SetVertexColor(GladiusMoP.db.dispelGridStyleIconUsedColor.r, GladiusMoP.db.dispelGridStyleIconUsedColor.g, GladiusMoP.db.dispelGridStyleIconUsedColor.b, GladiusMoP.db.dispelGridStyleIconUsedColor.a)
   end
   
   -- announcement
   if (GladiusMoP.db.announcements.dispel) then
      GladiusMoP:Call(GladiusMoP.modules.Announcements, "Send", strformat(L["DISPEL USED: %s (%s)"], UnitName(unit) or "test", UnitClass(unit) or "test"), 2, unit)   
   end
   
   if (GladiusMoP.db.announcements.dispel or GladiusMoP.db.dispelGridStyleIcon) then
      self.frame[unit].timeleft = duration
      self.frame[unit]:SetScript("OnUpdate", function(f, elapsed)
         self.frame[unit].timeleft = self.frame[unit].timeleft - elapsed
         
         if (self.frame[unit].timeleft <= 0) then
            -- dispel
            if (GladiusMoP.db.dispelGridStyleIcon) then
               self.frame[unit].texture:SetVertexColor(GladiusMoP.db.dispelGridStyleIconColor.r, GladiusMoP.db.dispelGridStyleIconColor.g, GladiusMoP.db.dispelGridStyleIconColor.b, GladiusMoP.db.dispelGridStyleIconColor.a)
            end
            
            -- announcement
            if (GladiusMoP.db.announcements.dispel) then
               GladiusMoP:Call(GladiusMoP.modules.Announcements, "Send", strformat(L["DISPEL READY: %s (%s)"], UnitName(unit) or "", UnitClass(unit) or ""), 2, unit)
            end
            
            self.frame[unit]:SetScript("OnUpdate", nil)
         end
      end)
   end
   
   -- cooldown
   GladiusMoP:Call(GladiusMoP.modules.Timer, "SetTimer", self.frame[unit], duration)   
end

function Dispel:CreateFrame(unit)
   local button = GladiusMoP.buttons[unit]
   if (not button) then return end       
   
   
   -- create frame
   self.frame[unit] = CreateFrame("CheckButton", "GladiusMoP" .. self.name .. "Frame" .. unit, button, "ActionButtonTemplate")
   self.frame[unit]:EnableMouse(false)
   self.frame[unit]:SetNormalTexture("Interface\\AddOns\\GladiusMoP\\images\\gloss")
   self.frame[unit].texture = _G[self.frame[unit]:GetName().."Icon"]
   self.frame[unit].normalTexture = _G[self.frame[unit]:GetName().."NormalTexture"]
   self.frame[unit].cooldown = _G[self.frame[unit]:GetName().."Cooldown"]
   
end

function Dispel:Update(unit)   
   -- create frame
   if (not self.frame[unit]) then 
      self:CreateFrame(unit)
   end
   
   -- update frame   
   self.frame[unit]:ClearAllPoints()
   
   -- anchor point 
   local parent = GladiusMoP:GetParent(unit, GladiusMoP.db.dispelAttachTo)     
   self.frame[unit]:SetPoint(GladiusMoP.db.dispelAnchor, parent, GladiusMoP.db.dispelRelativePoint, GladiusMoP.db.dispelOffsetX, GladiusMoP.db.dispelOffsetY)
   
   -- frame level
   self.frame[unit]:SetFrameLevel(GladiusMoP.db.dispelFrameLevel)
   
   if (GladiusMoP.db.dispelAdjustSize) then
      if (self:GetAttachTo() == "Frame") then   
         local height = false
         --[[ need to rethink that
         for _, module in pairs(GladiusMoP.modules) do
            if (module:GetAttachTo() == self.name) then
               height = false
            end
         end]]
         
         if (height) then
            self.frame[unit]:SetWidth(GladiusMoP.buttons[unit].height)   
            self.frame[unit]:SetHeight(GladiusMoP.buttons[unit].height)   
         else
            self.frame[unit]:SetWidth(GladiusMoP.buttons[unit].frameHeight)              
            self.frame[unit]:SetHeight(GladiusMoP.buttons[unit].frameHeight)   
         end
      else
         self.frame[unit]:SetWidth(GladiusMoP:GetModule(self:GetAttachTo()).frame[unit]:GetHeight() or 1)   
         self.frame[unit]:SetHeight(GladiusMoP:GetModule(self:GetAttachTo()).frame[unit]:GetHeight() or 1) 
      end
   else
      self.frame[unit]:SetWidth(GladiusMoP.db.dispelSize)         
      self.frame[unit]:SetHeight(GladiusMoP.db.dispelSize)  
   end 
   
   -- set frame mouse-interactable area
   if (self:GetAttachTo() == "Frame") then
      local left, right, top, bottom = GladiusMoP.buttons[unit]:GetHitRectInsets()
      
      if (strfind(GladiusMoP.db.dispelRelativePoint, "LEFT")) then
         left = -self.frame[unit]:GetWidth() + GladiusMoP.db.dispelOffsetX
      else
         right = -self.frame[unit]:GetWidth() + -GladiusMoP.db.dispelOffsetX
      end
      
      -- search for an attached frame
      --[[for _, module in pairs(GladiusMoP.modules) do
         if (module.attachTo and module:GetAttachTo() == self.name and module.frame and module.frame[unit]) then
            local attachedPoint = module.frame[unit]:GetPoint()
            
            if (strfind(GladiusMoP.db.trinketRelativePoint, "LEFT") and (not attachedPoint or (attachedPoint and strfind(attachedPoint, "RIGHT")))) then
               left = left - module.frame[unit]:GetWidth()
            elseif (strfind(GladiusMoP.db.trinketRelativePoint, "RIGHT") and (not attachedPoint or (attachedPoint and strfind(attachedPoint, "LEFT")))) then
               right = right - module.frame[unit]:GetWidth()
            end
         end
      end]]
      
      -- top / bottom
      if (self.frame[unit]:GetHeight() > GladiusMoP.buttons[unit]:GetHeight()) then
         bottom = -(self.frame[unit]:GetHeight() - GladiusMoP.buttons[unit]:GetHeight()) + GladiusMoP.db.dispelOffsetY
      end

      GladiusMoP.buttons[unit]:SetHitRectInsets(left, right, 0, 0) 
      GladiusMoP.buttons[unit].secure:SetHitRectInsets(left, right, 0, 0)
   end
   
   -- style action button   
   self.frame[unit].normalTexture:SetHeight(self.frame[unit]:GetHeight() + self.frame[unit]:GetHeight() * 0.4)
	self.frame[unit].normalTexture:SetWidth(self.frame[unit]:GetWidth() + self.frame[unit]:GetWidth() * 0.4)
	
	self.frame[unit].normalTexture:ClearAllPoints()
	self.frame[unit].normalTexture:SetPoint("CENTER", 0, 0)
	self.frame[unit]:SetNormalTexture("Interface\\AddOns\\GladiusMoP\\images\\gloss")
	
	self.frame[unit].texture:ClearAllPoints()
	self.frame[unit].texture:SetPoint("TOPLEFT", self.frame[unit], "TOPLEFT")
	self.frame[unit].texture:SetPoint("BOTTOMRIGHT", self.frame[unit], "BOTTOMRIGHT")
	
	if (not GladiusMoP.db.dispelIconCrop and not GladiusMoP.db.dispelGridStyleIcon) then
      self.frame[unit].texture:SetTexCoord(0, 1, 0, 1)
   else
      self.frame[unit].texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
   end
	
	self.frame[unit].normalTexture:SetVertexColor(GladiusMoP.db.dispelGlossColor.r, GladiusMoP.db.dispelGlossColor.g, 
      GladiusMoP.db.dispelGlossColor.b, GladiusMoP.db.dispelGloss and GladiusMoP.db.dispelGlossColor.a or 0)
      
   -- cooldown
   if (GladiusMoP.db.dispelCooldown) then
      self.frame[unit].cooldown:Show()
   else
      self.frame[unit].cooldown:Hide()
   end
   
   self.frame[unit].cooldown:SetReverse(GladiusMoP.db.dispelCooldownReverse)
   GladiusMoP:Call(GladiusMoP.modules.Timer, "RegisterTimer", self.frame[unit], GladiusMoP.db.dispelCooldown)
   
   -- hide
   self.frame[unit]:SetAlpha(0)
end

function Dispel:Show(unit)
   local testing = GladiusMoP.test
      
   -- show frame
   self.frame[unit]:SetAlpha(1)
   
   if (GladiusMoP.db.dispelGridStyleIcon) then
      self.frame[unit].texture:SetTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, "Minimalist"))
      self.frame[unit].texture:SetVertexColor(GladiusMoP.db.dispelGridStyleIconColor.r, GladiusMoP.db.dispelGridStyleIconColor.g, GladiusMoP.db.dispelGridStyleIconColor.b, GladiusMoP.db.dispelGridStyleIconColor.a)
   else
      local dispelIcon
	  local playerClass, englishClass = UnitClass(unit);
   
      if (not testing) then    
            	
			if (englishClass == "PRIEST" ) then
				dispelIcon = "Interface\\Icons\\spell_holy_dispelmagic"
			
			elseif (englishClass == "SHAMAN" ) then
				dispelIcon = "Interface\\Icons\\ability_shaman_cleansespirit"
			
			elseif (englishClass == "PALADIN" ) then
				dispelIcon = "Interface\\Icons\\spell_holy_purify"
			
			elseif (englishClass == "DRUID" ) then
				dispelIcon = "Interface\\Icons\\ability_shaman_cleansespirit"
				
			elseif (englishClass == "MAGE" ) then
				dispelIcon = "Interface\\Icons\\spell_nature_removecurse"
				
			end
         
      else
         if (englishClass == "PRIEST" or unit=="arena1") then
            dispelIcon = "Interface\\Icons\\spell_holy_dispelmagic"
			
		 elseif (englishClass == "SHAMAN" or unit=="arena2") then
			dispelIcon = "Interface\\Icons\\ability_shaman_cleansespirit"
			
		 elseif (englishClass == "PALADIN" or unit=="arena3") then
            dispelIcon = "Interface\\Icons\\spell_holy_purify"
			
		 elseif (englishClass == "DRUID" or unit=="arena4") then
			dispelIcon = "Interface\\Icons\\ability_shaman_cleansespirit"
			
		 elseif (englishClass == "MAGE" or unit=="arena5") then
				dispelIcon = "Interface\\Icons\\spell_nature_removecurse"
		 end 
       end   
           
      self.frame[unit].texture:SetTexture(dispelIcon)
      
      if (GladiusMoP.db.dispelIconCrop) then
         self.frame[unit].texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
      end
      
      self.frame[unit].texture:SetVertexColor(1, 1, 1, 1)
   end
end

function Dispel:Reset(unit)
   if (not self.frame[unit]) then return end

   -- reset frame
   local dispelIcon
   
   if (UnitFactionGroup("player") == "Horde" and GladiusMoP.db.dispelFaction) then
      dispelIcon = "Interface\\Icons\\INV_Jewelry_Necklace_38"
   else
      dispelIcon = "Interface\\Icons\\INV_Jewelry_Necklace_37"
   end
   
   self.frame[unit].texture:SetTexture(dispelIcon)
   
   if (GladiusMoP.db.dispelIconCrop) then
      self.frame[unit].texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
   end
   
   self.frame[unit]:SetScript("OnUpdate", nil)
   
   -- reset cooldown
   GladiusMoP:Call(GladiusMoP.modules.Timer, "HideTimer", self.frame[unit])
   
   -- hide
	self.frame[unit]:SetAlpha(0)
end

function Dispel:Test(unit)   
   -- test
   if (unit == "arena1") then
      self:UpdateDispel(unit, 8)
   end
    if (unit == "arena2") then
      self:UpdateDispel(unit, 8)
   end
    if (unit == "arena3") then
      self:UpdateDispel(unit, 8)
   end
    if (unit == "arena4") then
      self:UpdateDispel(unit, 8)
   end
 
end

-- Add the announcement toggle
function Dispel:OptionsLoad()
   GladiusMoP.options.args.Announcements.args.general.args.announcements.args.dispel = {
      type="toggle",
      name=L["Dispel"],
      desc=L["Announces when an enemy cast a dispel."],
      disabled=function() return not GladiusMoP.db.modules[self.name] end,
   }
end

function Dispel:GetOptions()
   return {
      general = {  
         type="group",
         name=L["General"],
         order=1,
         args = {
            widget = {
               type="group",
               name=L["Widget"],
               desc=L["Widget settings"],  
               inline=true,                
               order=1,
               args = {
                  dispelGridStyleIcon = {
                     type="toggle",
                     name=L["Dispel Grid Style Icon"],
                     desc=L["Toggle dispel grid style icon"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=7,
                  },
                  dispelGridStyleIconColor = {
                     type="color",
                     name=L["Dispel Grid Style Icon Color"],
                     desc=L["Color of the dispel grid style icon"],
                     hasAlpha=true,
                     get=function(info) return GladiusMoP:GetColorOption(info) end,
                     set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, a) end,
                     disabled=function() return not GladiusMoP.dbi.profile.dispelGridStyleIcon or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=10,
                  }, 
                  dispelGridStyleIconUsedColor = {
                     type="color",
                     name=L["Dispel Grid Style Icon Used Color"],
                     desc=L["Color of the dispel grid style icon when it's on cooldown"],
                     hasAlpha=true,
                     get=function(info) return GladiusMoP:GetColorOption(info) end,
                     set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, a) end,
                     disabled=function() return not GladiusMoP.dbi.profile.dispelGridStyleIcon or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=12,
                  },                   
                  sep1 = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=13,
                  },
                  dispelCooldown = {
                     type="toggle",
                     name=L["Dispel Cooldown Spiral"],
                     desc=L["Display the cooldown spiral for important auras"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=15,
                  },
                  dispelCooldownReverse = {
                     type="toggle",
                     name=L["Dispel Cooldown Reverse"],
                     desc=L["Invert the dark/bright part of the cooldown spiral"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=20,
                  },
                  sep2 = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=23,
                  },
                  dispelGloss = {
                     type="toggle",
                     name=L["Dispel Gloss"],
                     desc=L["Toggle gloss on the dispel icon"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=25,
                  },
                  dispelGlossColor = {
                     type="color",
                     name=L["Dispel Gloss Color"],
                     desc=L["Color of the dispel icon gloss"],
                     get=function(info) return GladiusMoP:GetColorOption(info) end,
                     set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, a) end,
                     hasAlpha=true,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=30,
                  },
                  sep3 = {                     
                     type = "description",
                     name="",
                     width="full",
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=33,
                  },
                  dispelIconCrop = {
                     type="toggle",
                     name=L["Dispel Icon Border Crop"],
                     desc=L["Toggle if the borders of the dispel icon should be cropped"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=35,
                  },
                  dispelFaction = {
                     type="toggle",
                     name=L["Dispel Icon Faction"],
                     desc=L["Toggle if the dispel icon should be changing based on the opponents faction"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=40,
                  },
                  sep3 = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=43,
                  },
                  dispelFrameLevel = {
                     type="range",
                     name=L["Dispel Frame Level"],
                     desc=L["Frame level of the dispel"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     min=1, max=5, step=1,
                     width="double",
                     order=45,
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
                  dispelAdjustSize = {
                     type="toggle",
                     name=L["Dispel Adjust Size"],
                     desc=L["Adjust dispel size to the frame size"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  dispelSize = {
                     type="range",
                     name=L["Dispel Size"],
                     desc=L["Size of the dispel"],
                     min=10, max=100, step=1,
                     disabled=function() return GladiusMoP.dbi.profile.dispelAdjustSize or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=10,
                  },               
               },
            },
            position = {
               type="group",
               name=L["Position"],
               desc=L["Position settings"],  
               inline=true,                
               order=3,
               args = {
                  dispelAttachTo = {
                     type="select",
                     name=L["Dispel Attach To"],
                     desc=L["Attach dispel to the given frame"],
                     values=function() return GladiusMoP:GetModules(self.name) end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     arg="general",
                     order=5,
                  },
                  dispelPosition = {
                     type="select",
                     name=L["Dispel Position"],
                     desc=L["Position of the dispel"],
                     values={ ["LEFT"] = L["Left"], ["RIGHT"] = L["Right"] },
                     get=function() return strfind(GladiusMoP.db.dispelAnchor, "RIGHT") and "LEFT" or "RIGHT" end,
                     set=function(info, value)
                        if (value == "LEFT") then
                           GladiusMoP.db.dispelAnchor = "TOPRIGHT"
                           GladiusMoP.db.dispelRelativePoint = "TOPLEFT"
                        else
                           GladiusMoP.db.dispelAnchor = "TOPLEFT"
                           GladiusMoP.db.dispelRelativePoint = "TOPRIGHT"
                        end
                        
                        GladiusMoP:UpdateFrame(info[1])
                     end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     hidden=function() return GladiusMoP.db.advancedOptions end,
                     order=6,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=7,
                  },
                  dispelAnchor = {
                     type="select",
                     name=L["Dispel Anchor"],
                     desc=L["Anchor of the dispel"],
                     values=function() return GladiusMoP:GetPositions() end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=10,
                  },
                  dispelRelativePoint = {
                     type="select",
                     name=L["Dispel Relative Point"],
                     desc=L["Relative point of the dispel"],
                     values=function() return GladiusMoP:GetPositions() end,
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
                  dispelOffsetX = {
                     type="range",
                     name=L["Dispel Offset X"],
                     desc=L["X offset of the dispel"],
                     min=-100, max=100, step=1,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=20,
                  },
                  dispelOffsetY = {
                     type="range",
                     name=L["Dispel Offset Y"],
                     desc=L["Y  offset of the dispel"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     min=-50, max=50, step=1,
                     order=25,
                  },
               },
            },
         },
      },
   }
end