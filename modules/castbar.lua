local GladiusMoP = _G.GladiusMoP
if not GladiusMoP then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires GladiusMoP", "Cast Bar"))
end
local L = GladiusMoP.L
local LSM

-- global functions
local strfind = string.find
local pairs = pairs
local GetTime = GetTime
local GetSpellInfo, UnitCastingInfo, UnitChannelInfo = GetSpellInfo, UnitCastingInfo, UnitChannelInfo

local CastBar = GladiusMoP:NewModule("CastBar", true, true, {
   castBarAttachTo = "ClassIcon",
   
   castBarHeight = 12,
   castBarAdjustWidth = true,
   castBarWidth = 150,
   
   castBarOffsetX = 0,
   castBarOffsetY = 0,
   
   castBarAnchor = "TOPLEFT",
   castBarRelativePoint = "BOTTOMLEFT",
   
   castBarInverse = false,
   castBarColor = { r = 1, g = 1, b = 0, a = 1 },
   castBarBackgroundColor = { r = 1, g = 1, b = 1, a = 0.3 },
   castBarTexture = "Minimalist",
   
   castIcon = true,
   castIconPosition = "LEFT",      
   
   castText = true,
   castTextSize = 11,
   castTextColor = { r = 2.55, g = 2.55, b = 2.55, a = 1 },
   castTextAlign = "LEFT",
   castTextOffsetX = 0,
   castTextOffsetY = 0,
   
   castTimeText = true,
   castTimeTextSize = 11,
   castTimeTextColor = { r = 2.55, g = 2.55, b = 2.55, a = 1 },
   castTimeTextAlign = "RIGHT",
   castTimeTextOffsetX = 0,
   castTimeTextOffsetY = 0,
})

function CastBar:OnEnable()
   self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "UNIT_SPELLCAST_DELAYED")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "UNIT_SPELLCAST_STOP")
   
   LSM = GladiusMoP.LSM
   
   --[[ set frame type
   if (GladiusMoP.db.castBarAttachTo == "Frame" or GladiusMoP:GetModule(GladiusMoP.db.castBarAttachTo).isBar) then
      self.isBar = true
   else
      self.isBar = false
   end]]
   self.isBar = true
   
   if (not self.frame) then
      self.frame = {}
   end
end

function CastBar:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      self.frame[unit]:SetAlpha(0)
   end
end

function CastBar:GetAttachTo()
   return GladiusMoP.db.castBarAttachTo
end

function CastBar:GetFrame(unit)
   if (GladiusMoP.db.castIcon and GladiusMoP.db.castIconPosition == "LEFT") then
      return self.frame[unit].icon
   else
      return self.frame[unit]
   end
end

function CastBar:GetIndicatorHeight()
   return GladiusMoP.db.castBarHeight
end

function CastBar:UNIT_SPELLCAST_START(event, unit)
   if (not strfind(unit, "arena") or strfind(unit, "pet")) then return end
   if (self.frame[unit]==nil) then return end
	local spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitCastingInfo(unit)
	if (spell) then
      self.frame[unit].isCasting = true
      self.frame[unit].value = (GetTime() - (startTime / 1000))
      self.frame[unit].maxValue = (endTime - startTime) / 1000
      self.frame[unit]:SetMinMaxValues(0, self.frame[unit].maxValue)
      self.frame[unit]:SetValue(self.frame[unit].value)
      self.frame[unit].timeText:SetText(self.frame[unit].maxValue)
      self.frame[unit].icon:SetTexture(icon)
		
		if( rank ~= "" ) then
			self.frame[unit].castText:SetFormattedText("%s (%s)", spell, rank)
		else
			self.frame[unit].castText:SetText(spell)
		end
	end
end

function CastBar:UNIT_SPELLCAST_CHANNEL_START(event, unit)
   if (not strfind(unit, "arena") or strfind(unit, "pet")) then return end
   if (self.frame[unit]==nil) then return end
	local spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitChannelInfo(unit)	
	if (spell) then
		self.frame[unit].isChanneling = true
		self.frame[unit].value = ((endTime / 1000) - GetTime())
		self.frame[unit].maxValue = (endTime - startTime) / 1000
		self.frame[unit]:SetMinMaxValues(0, self.frame[unit].maxValue)
		self.frame[unit]:SetValue(self.frame[unit].value)
		self.frame[unit].timeText:SetText(self.frame[unit].maxValue)
		self.frame[unit].icon:SetTexture(icon)

		if( rank ~= "" ) then
			self.frame[unit].castText:SetFormattedText("%s (%s)", spell, rank)
		else
			self.frame[unit].castText:SetText(spell)
		end
	end	
end

function CastBar:UNIT_SPELLCAST_STOP(event, unit)
   if (not strfind(unit, "arena") or strfind(unit, "pet")) then return end   
   self:CastEnd(self.frame[unit])
end

function CastBar:UNIT_SPELLCAST_DELAYED(event, unit)
   if (not strfind(unit, "arena") or strfind(unit, "pet")) then return end
   if (self.frame[unit]==nil) then return end
   local spell, rank, displayName, icon, startTime, endTime, isTradeSkill
   if (event == "UNIT_SPELLCAST_DELAYED") then
      spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitCastingInfo(unit)
   else
      spell, rank, displayName, icon, startTime, endTime, isTradeSkill = UnitChannelInfo(unit)
   end
   
   if (startTime == nil) then return end
   
   self.frame[unit].value = (GetTime() - (startTime / 1000))
   self.frame[unit].maxValue = (endTime - startTime) / 1000
   self.frame[unit]:SetMinMaxValues(0, self.frame[unit].maxValue)
end

function CastBar:CastEnd(bar)
	if(bar) then
	bar.isCasting = nil
	bar.isChanneling = nil
	bar.timeText:SetText("")
	bar.castText:SetText("")
	bar.icon:SetTexture("")
	bar:SetValue(0)
	end
end

function CastBar:CreateBar(unit)
   local button = GladiusMoP.buttons[unit]
   if (not button) then return end      
   
   -- create bar + text
   self.frame[unit] = CreateFrame("STATUSBAR", "GladiusMoP" .. self.name .. unit, button) 
   self.frame[unit].background = self.frame[unit]:CreateTexture("GladiusMoP" .. self.name .. unit .. "Background", "BACKGROUND") 
   self.frame[unit].highlight = self.frame[unit]:CreateTexture("GladiusMoP" .. self.name .. "Highlight" .. unit, "OVERLAY")
   self.frame[unit].castText = self.frame[unit]:CreateFontString("GladiusMoP" .. self.name .. "CastText" .. unit, "OVERLAY")
   self.frame[unit].timeText = self.frame[unit]:CreateFontString("GladiusMoP" .. self.name .. "TimeText" .. unit, "OVERLAY")
   self.frame[unit].icon = self.frame[unit]:CreateTexture("GladiusMoP" .. self.name .. "IconFrame" .. unit, "ARTWORK")
   self.frame[unit].icon.bg = self.frame[unit]:CreateTexture("GladiusMoP" .. self.name .. "IconFrameBackground" .. unit, "BACKGROUND") 
end

local function CastUpdate(self, elapsed)
   if (GladiusMoP.test) then return end

	if ((self.isCasting and not GladiusMoP.db.castBarInverse) or 
       (self.isChanneling and GladiusMoP.db.castBarInverse)) then
		if (self.value >= self.maxValue) then
			self:SetValue(self.maxValue)
			CastBar:CastEnd(self)
			return
		end
		self.value = self.value + elapsed
		self:SetValue(GladiusMoP.db.castBarInverse and (self.maxValue - self.value) or self.value)
		self.timeText:SetFormattedText("%.1f", self.maxValue-self.value)
	elseif ((self.isChanneling and not GladiusMoP.db.castBarInverse) or 
            (self.isCasting and GladiusMoP.db.castBarInverse)) then
		if (self.value <= 0) then
			CastBar:CastEnd(self)
			return
		end
		self.value = self.value - elapsed
		self:SetValue(GladiusMoP.db.castBarInverse and (self.maxValue - self.value) or self.value)
		self.timeText:SetFormattedText("%.1f", self.value)
	end
end

function CastBar:Update(unit)
   -- check parent module
   if (not GladiusMoP:GetModule(GladiusMoP.db.castBarAttachTo)) then
      if (self.frame[unit]) then
         self.frame[unit]:Hide()
      end
      return
   end

   local testing = GladiusMoP.test
   
   -- create power bar
   if (not self.frame[unit]) then 
      self:CreateBar(unit)
   end
   
   -- set bar type 
   local parent = GladiusMoP:GetParent(unit, GladiusMoP.db.castBarAttachTo)
     
  --[[ if (GladiusMoP.db.castBarAttachTo == "Frame" or GladiusMoP:GetModule(GladiusMoP.db.castBarAttachTo).isBar) then
      self.isBar = true
   else
      self.isBar = false
   end]]
      
   -- update power bar   
   self.frame[unit]:ClearAllPoints()

   local width = GladiusMoP.db.castBarAdjustWidth and GladiusMoP.db.barWidth or GladiusMoP.db.castBarWidth
   if (GladiusMoP.db.castIcon) then
       width = width - GladiusMoP.db.castBarHeight
	end
	
	-- add width of the widget if attached to an widget
	if (GladiusMoP.db.castBarAttachTo ~= "Frame" and not GladiusMoP:GetModule(GladiusMoP.db.castBarAttachTo).isBar and GladiusMoP.db.castBarAdjustWidth) then
      if (not GladiusMoP:GetModule(GladiusMoP.db.castBarAttachTo).frame or not GladiusMoP:GetModule(GladiusMoP.db.castBarAttachTo).frame[unit]) then
         GladiusMoP:GetModule(GladiusMoP.db.castBarAttachTo):Update(unit)
      end
      
      width = width + GladiusMoP:GetModule(GladiusMoP.db.castBarAttachTo).frame[unit]:GetWidth()
	end
		 
	self.frame[unit]:SetHeight(GladiusMoP.db.castBarHeight)   
   self.frame[unit]:SetWidth(width)
	
	local offsetX
   if (not strfind(GladiusMoP.db.castBarAnchor, "RIGHT") and strfind(GladiusMoP.db.castBarRelativePoint, "RIGHT")) then
      offsetX = GladiusMoP.db.castIcon and GladiusMoP.db.castIconPosition == "LEFT" and self.frame[unit]:GetHeight() or 0      
   elseif (not strfind(GladiusMoP.db.castBarAnchor, "LEFT") and strfind(GladiusMoP.db.castBarRelativePoint, "LEFT")) then
      offsetX = GladiusMoP.db.castIcon and GladiusMoP.db.castIconPosition == "RIGHT" and -self.frame[unit]:GetHeight() or 0      
   elseif (strfind(GladiusMoP.db.castBarAnchor, "LEFT") and strfind(GladiusMoP.db.castBarRelativePoint, "LEFT")) then
      offsetX = GladiusMoP.db.castIcon and GladiusMoP.db.castIconPosition == "LEFT" and self.frame[unit]:GetHeight() or 0      
   elseif (strfind(GladiusMoP.db.castBarAnchor, "RIGHT") and strfind(GladiusMoP.db.castBarRelativePoint, "RIGHT")) then
      offsetX = GladiusMoP.db.castIcon and GladiusMoP.db.castIconPosition == "RIGHT" and -self.frame[unit]:GetHeight() or 0      
   end
   
	self.frame[unit]:SetPoint(GladiusMoP.db.castBarAnchor, parent, GladiusMoP.db.castBarRelativePoint, GladiusMoP.db.castBarOffsetX + (offsetX or 0), GladiusMoP.db.castBarOffsetY)	
	self.frame[unit]:SetMinMaxValues(0, 100)
	self.frame[unit]:SetValue(0)
	self.frame[unit]:SetStatusBarTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, GladiusMoP.db.castBarTexture))
	
	-- updating
	self.frame[unit]:SetScript("OnUpdate", CastUpdate)
	
	-- disable tileing
	self.frame[unit]:GetStatusBarTexture():SetHorizTile(false)
   self.frame[unit]:GetStatusBarTexture():SetVertTile(false)
   
	-- set color
   local color = GladiusMoP.db.castBarColor
   self.frame[unit]:SetStatusBarColor(color.r, color.g, color.b, color.a)
   
   -- update cast text   
	self.frame[unit].castText:SetFont(LSM:Fetch(LSM.MediaType.FONT, GladiusMoP.db.globalFont), GladiusMoP.db.castTextSize)
	
	local color = GladiusMoP.db.castTextColor
	self.frame[unit].castText:SetTextColor(color.r, color.g, color.b, color.a)
	
	self.frame[unit].castText:SetShadowOffset(1, -1)
	self.frame[unit].castText:SetShadowColor(0, 0, 0, 1)
	self.frame[unit].castText:SetJustifyH(GladiusMoP.db.castTextAlign)
	self.frame[unit].castText:SetPoint(GladiusMoP.db.castTextAlign, GladiusMoP.db.castTextOffsetX, GladiusMoP.db.castTextOffsetY)
	
	-- update cast time text   
	self.frame[unit].timeText:SetFont(LSM:Fetch(LSM.MediaType.FONT, GladiusMoP.db.globalFont), GladiusMoP.db.castTimeTextSize)
	
	local color = GladiusMoP.db.castTimeTextColor
	self.frame[unit].timeText:SetTextColor(color.r, color.g, color.b, color.a)
	
	self.frame[unit].timeText:SetShadowOffset(1, -1)
	self.frame[unit].timeText:SetShadowColor(0, 0, 0, 1)
	self.frame[unit].timeText:SetJustifyH(GladiusMoP.db.castTimeTextAlign)
	self.frame[unit].timeText:SetPoint(GladiusMoP.db.castTimeTextAlign, GladiusMoP.db.castTimeTextOffsetX, GladiusMoP.db.castTimeTextOffsetY)    
	
	-- update icon
	self.frame[unit].icon:ClearAllPoints()
	self.frame[unit].icon:SetPoint(GladiusMoP.db.castIconPosition == "LEFT" and "RIGHT" or "LEFT", self.frame[unit], GladiusMoP.db.castIconPosition)
	
	self.frame[unit].icon:SetWidth(self.frame[unit]:GetHeight())
	self.frame[unit].icon:SetHeight(self.frame[unit]:GetHeight())
	
	self.frame[unit].icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	
	self.frame[unit].icon.bg:ClearAllPoints()
	self.frame[unit].icon.bg:SetAllPoints(self.frame[unit].icon)	
	self.frame[unit].icon.bg:SetTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, GladiusMoP.db.castBarTexture))
	self.frame[unit].icon.bg:SetVertexColor(GladiusMoP.db.castBarBackgroundColor.r, GladiusMoP.db.castBarBackgroundColor.g,
      GladiusMoP.db.castBarBackgroundColor.b, GladiusMoP.db.castBarBackgroundColor.a)
	
	
	if (not GladiusMoP.db.castIcon) then
      self.frame[unit].icon:SetAlpha(0)
   else
      self.frame[unit].icon:SetAlpha(1)
	end
	
	-- update cast bar background
   self.frame[unit].background:ClearAllPoints()
	self.frame[unit].background:SetAllPoints(self.frame[unit])	
	
	-- Maybe it looks better if the background covers the whole castbar
	--[[
	if (GladiusMoP.db.castIcon) then
      self.frame[unit].background:SetWidth(self.frame[unit]:GetWidth() + self.frame[unit].icon:GetWidth())
	else      
      self.frame[unit].background:SetWidth(self.frame[unit]:GetWidth())
   end	
   --]]
   
   self.frame[unit].background:SetHeight(self.frame[unit]:GetHeight())
	
	self.frame[unit].background:SetTexture(LSM:Fetch(LSM.MediaType.STATUSBAR, GladiusMoP.db.castBarTexture))
	
	self.frame[unit].background:SetVertexColor(GladiusMoP.db.castBarBackgroundColor.r, GladiusMoP.db.castBarBackgroundColor.g,
      GladiusMoP.db.castBarBackgroundColor.b, GladiusMoP.db.castBarBackgroundColor.a)
	
	-- disable tileing
	self.frame[unit].background:SetHorizTile(false)
   self.frame[unit].background:SetVertTile(false)
	
	-- update highlight texture
	self.frame[unit].highlight:SetAllPoints(self.frame[unit])
	self.frame[unit].highlight:SetTexture([=[Interface\QuestFrame\UI-QuestTitleHighlight]=])
   self.frame[unit].highlight:SetBlendMode("ADD")   
   self.frame[unit].highlight:SetVertexColor(1.0, 1.0, 1.0, 1.0)
   self.frame[unit].highlight:SetAlpha(0)
	
	-- hide
	self.frame[unit]:SetAlpha(0)
end

function CastBar:Show(unit)
   -- show frame
   self.frame[unit]:SetAlpha(1)
end

function CastBar:Reset(unit)
   -- reset bar
   self.frame[unit]:SetMinMaxValues(0, 1)
   self.frame[unit]:SetValue(0)

   -- reset text
   if (self.frame[unit].castText:GetFont()) then
      self.frame[unit].castText:SetText("")
   end
   
   if (self.frame[unit].timeText:GetFont()) then
      self.frame[unit].timeText:SetText("")
   end
   
   -- hide
	self.frame[unit]:SetAlpha(0)
end

function CastBar:Test(unit)
   if (unit == "arena1") then
      self.frame[unit].isCasting = true
      self.frame[unit].value = GladiusMoP.db.castBarInverse and 0 or 1
      self.frame[unit].maxValue = 1
      self.frame[unit]:SetMinMaxValues(0, self.frame[unit].maxValue)
      self.frame[unit]:SetValue(self.frame[unit].value)
      
      if (GladiusMoP.db.castTimeText) then
         self.frame[unit].timeText:SetFormattedText("%.1f", self.frame[unit].maxValue - self.frame[unit].value)
      else
         self.frame[unit].timeText:SetText("")
      end
      
      local texture = select(3, GetSpellInfo(1))
      self.frame[unit].icon:SetTexture(texture)
      
      if (GladiusMoP.db.castText) then
         self.frame[unit].castText:SetText(L["Example Spell Name"])
      else
         self.frame[unit].castText:SetText("")
      end
   end
end

function CastBar:GetOptions()
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
                  castBarColor = {
                     type="color",
                     name=L["Cast Bar Color"],
                     desc=L["Color of the cast bar"],
                     hasAlpha=true,
                     get=function(info) return GladiusMoP:GetColorOption(info) end,
                     set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, a) end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=5,
                  },    
                  castBarBackgroundColor = {
                     type="color",
                     name=L["Cast Bar Background Color"],
                     desc=L["Color of the cast bar background"],
                     hasAlpha=true,
                     get=function(info) return GladiusMoP:GetColorOption(info) end,
                     set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, a) end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=10,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=13,
                  },               
                  castBarInverse = {
                     type="toggle",
                     name=L["Cast Bar Inverse"],
                     desc=L["Inverse the cast bar"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     hidden=function() return not GladiusMoP.db.advancedOptions end,
                     order=15,
                  },
                  castBarTexture = {
                     type="select",
                     name=L["Cast Bar Texture"],
                     desc=L["Texture of the cast bar"],
                     dialogControl = "LSM30_Statusbar",
                     values = AceGUIWidgetLSMlists.statusbar,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=20,
                  },
                  sep2 = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=23,
                  },
                  castIcon = {
                     type="toggle",
                     name=L["Cast Bar Icon"],
                     desc=L["Toggle the cast icon"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=25,
                  },
                  castIconPosition = {
                     type="select",
                     name=L["Cast Bar Icon Position"],
                     desc=L["Position of the cast bar icon"],
                     values={ ["LEFT"] = L["LEFT"], ["RIGHT"] = L["RIGHT"] },
                     disabled=function() return not GladiusMoP.dbi.profile.castIcon or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=30,
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
                  castBarAdjustWidth = {
                     type="toggle",
                     name=L["Cast Bar Adjust Width"],
                     desc=L["Adjust cast bar width to the frame width"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=13,
                  },
                  castBarWidth = {
                     type="range",
                     name=L["Cast Bar Width"],
                     desc=L["Width of the cast bar"],
                     min=10, max=500, step=1,
                     disabled=function() return GladiusMoP.dbi.profile.castBarAdjustWidth or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=15,
                  },
                  castBarHeight = {
                     type="range",
                     name=L["Cast Bar Height"],
                     desc=L["Height of the cast bar"],
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
                  castBarAttachTo = {
                     type="select",
                     name=L["Cast Bar Attach To"],
                     desc=L["Attach cast bar to the given frame"],
                     values=function() return GladiusMoP:GetModules(self.name) end,
                     set=function(info, value) 
                        local key = info.arg or info[#info]
                        
                        --[[if (GladiusMoP.db.castBarAttachTo == "Frame" or GladiusMoP:GetModule(GladiusMoP.db.castBarAttachTo).isBar) then
                           self.isBar = true
                        else
                           self.isBar = false
                        end]]
                        
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
                  castBarAnchor = {
                     type="select",
                     name=L["Cast Bar Anchor"],
                     desc=L["Anchor of the cast bar"],
                     values=function() return GladiusMoP:GetPositions() end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  castBarRelativePoint = {
                     type="select",
                     name=L["Cast Bar Relative Point"],
                     desc=L["Relative point of the cast bar"],
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
                  castBarOffsetX = {
                     type="range",
                     name=L["Cast Bar Offset X"],
                     desc=L["X offset of the cast bar"],
                     min=-100, max=100, step=1,
                     disabled=function() return  not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=20,
                  }, 
                  castBarOffsetY = {
                     type="range",
                     name=L["Cast Bar Offset Y"],
                     desc=L["Y offset of the castbar"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     min=-100, max=100, step=1,
                     order=25,
                  },          
               },
            },
         },
      },
      castText = {  
         type="group",
         name=L["Cast Text"],
         order=2,
         args = { 
            text = {  
               type="group",
               name=L["Text"],
               desc=L["Text settings"],  
               inline=true,                
               order=1,
               args = {
                  castText = {
                     type="toggle",
                     name=L["Cast Text"],
                     desc=L["Toggle cast text"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=7,
                  },
                  castTextColor = {
                     type="color",
                     name=L["Cast Text Color"],
                     desc=L["Text color of the cast text"],
                     hasAlpha=true,
                     get=function(info) return GladiusMoP:GetColorOption(info) end,
                     set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, a) end,
                     disabled=function() return not GladiusMoP.dbi.profile.castText or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  castTextSize = {
                     type="range",
                     name=L["Cast Text Size"],
                     desc=L["Text size of the cast text"],
                     min=1, max=20, step=1,
                     disabled=function() return not GladiusMoP.dbi.profile.castText or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=15,
                  },                  
               },
            },
            position = {  
               type="group",
               name=L["Position"],
               desc=L["Position settings"],  
               inline=true,
               hidden=function() return not GladiusMoP.db.advancedOptions end,                
               order=2,
               args = {
                  castTextAlign = {
                     type="select",
                     name=L["Cast Text Align"],
                     desc=L["Text align of the cast text"],
                     values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
                     disabled=function() return not GladiusMoP.dbi.profile.castText or not GladiusMoP.dbi.profile.modules[self.name] end,
                     width="double",
                     order=5,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=7,
                  },
                  castTextOffsetX = {
                     type="range",
                     name=L["Cast Text Offset X"],
                     desc=L["X offset of the cast text"],
                     min=-100, max=100, step=1,
                     disabled=function() return not GladiusMoP.dbi.profile.castText or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  castTextOffsetY = {
                     type="range",
                     name=L["Cast Text Offset Y"],
                     desc=L["Y offset of the cast text"],
                     disabled=function() return not GladiusMoP.dbi.profile.castText or not GladiusMoP.dbi.profile.modules[self.name] end,
                     min=-100, max=100, step=1,
                     order=15,
                  },
               },
            },
         },
      },
      castTimeText = {  
         type="group",
         name=L["Cast Time Text"],
         order=3,
         args = { 
            text = {  
               type="group",
               name=L["Text"],
               desc=L["Text settings"],  
               inline=true,                
               order=1,
               args = {
                  castTimeText = {
                     type="toggle",
                     name=L["Cast Time Text"],
                     desc=L["Toggle cast time text"],
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=7,
                  },
                  castTimeTextColor = {
                     type="color",
                     name=L["Cast Time Text Color"],
                     desc=L["Text color of the cast time text"],
                     hasAlpha=true,
                     get=function(info) return GladiusMoP:GetColorOption(info) end,
                     set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, a) end,
                     disabled=function() return not GladiusMoP.dbi.profile.castTimeText or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  castTimeTextSize = {
                     type="range",
                     name=L["Cast Time Text Size"],
                     desc=L["Text size of the cast time text"],
                     min=1, max=20, step=1,
                     disabled=function() return not GladiusMoP.dbi.profile.castTimeText or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=15,
                  },
                  
               },
            },
            position = {  
               type="group",
               name=L["Position"],
               desc=L["Position settings"],  
               inline=true,
               hidden=function() return not GladiusMoP.db.advancedOptions end,                
               order=2,
               args = {
                  castTimeTextAlign = {
                     type="select",
                     name=L["Cast Time Text Align"],
                     desc=L["Text align of the cast time text"],
                     values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
                     disabled=function() return not GladiusMoP.dbi.profile.castTimeText or not GladiusMoP.dbi.profile.modules[self.name] end,
                     width="double",
                     order=5,
                  },
                  sep = {                     
                     type = "description",
                     name="",
                     width="full",
                     order=7,
                  },
                  castTimeTextOffsetX = {
                     type="range",
                     name=L["Cast Time Offset X"],
                     desc=L["X Offset of the cast time text"],
                     min=-100, max=100, step=1,
                     disabled=function() return not GladiusMoP.dbi.profile.castTimeText or not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  castTimeTextOffsetY = {
                     type="range",
                     name=L["Cast Time Offset Y"],
                     desc=L["Y Offset of the cast time text"],
                     disabled=function() return not GladiusMoP.dbi.profile.castTimeText or not GladiusMoP.dbi.profile.modules[self.name] end,
                     min=-100, max=100, step=1,
                     order=15,
                  },
               },
            },
         },
      },
   }
end
