local GladiusMoP = _G.GladiusMoP
if not GladiusMoP then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires GladiusMoP", "Auras"))
end
local L = GladiusMoP.L
local LSM

-- global functions
local strfind = string.find
local pairs = pairs
local UnitAura, GetSpellInfo = UnitAura, GetSpellInfo
local ceil = math.ceil

local Auras = GladiusMoP:NewModule("Auras", false, true, {
   aurasBuffsAttachTo = "CastBar",
   aurasBuffsAnchor = "TOPLEFT",
   aurasBuffsRelativePoint = "BOTTOMLEFT",
   aurasBuffs = false,
   aurasBuffsGrow = "DOWNRIGHT",
   aurasBuffsSpacingX = 0,
   aurasBuffsSpacingY = 0,
   aurasBuffsPerColumn = 10,
   aurasBuffsMax = 20,
   aurasBuffsHeight = 16,
   aurasBuffsWidth = 16,
   aurasBuffsOffsetX = 0,
   aurasBuffsOffsetY = 0,
   aurasBuffsGloss = false,
   aurasBuffsGlossColor = { r = 1, g = 1, b = 1, a = 0.4 },
   
   aurasDebuffsAttachTo = "ClassIcon",
   aurasDebuffsAnchor = "BOTTOMLEFT",
   aurasDebuffsRelativePoint = "TOPLEFT",
   aurasDebuffs = false,
   aurasDebuffsGrow = "UPRIGHT",
   aurasDebuffsSpacingX = 0,
   aurasDebuffsSpacingY = 0,
   aurasDebuffsPerColumn = 10,
   aurasDebuffsMax = 20,
   aurasDebuffsHeight = 16,
   aurasDebuffsWidth = 16,
   aurasDebuffsOffsetX = 0,
   aurasDebuffsOffsetY = 0,
   aurasDebuffsGloss = false,
   aurasDebuffsGlossColor = { r = 1, g = 1, b = 1, a = 0.4 },
   
   aurasImportantAuras = true,
   aurasFrameAuras = nil,
}, {"Bottom Single Row"})

function Auras:OnEnable()   
   self:RegisterEvent("UNIT_AURA")
   
   LSM = GladiusMoP.LSM   
   
   self.buffFrame = self.buffFrame or {}
   self.debuffFrame = self.debuffFrame or {}
   
   -- set auras
   GladiusMoP.db.aurasFrameAuras = GladiusMoP.db.aurasFrameAuras or self:GetAuraList()
end

function Auras:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.debuffFrame) do
      self.debuffFrame[unit]:Hide()
   end
   
   for unit in pairs(self.buffFrame) do
      self.buffFrame[unit]:Hide()
   end
end

function Auras:SetTemplate(template)
   if (template == 1) then
      GladiusMoP.db.aurasBuffsGrow = "DOWNRIGHT"
      GladiusMoP.db.aurasBuffsAttachTo = "CastBar"
      GladiusMoP.db.aurasBuffsRelativePoint = "BOTTOMLEFT"
      GladiusMoP.db.aurasBuffsAnchor = "TOPLEFT"
      GladiusMoP.db.aurasBuffsSpacingX = 1
      GladiusMoP.db.aurasBuffsHeight = 17
      GladiusMoP.db.aurasBuffsMax = GladiusMoP.db.modules.Trinket and 8 or 6
      GladiusMoP.db.aurasBuffsOffsetY = -1

      GladiusMoP.db.aurasDebuffsGrow = "DOWNLEFT"
      GladiusMoP.db.aurasDebuffsAttachTo = "Trinket"
      GladiusMoP.db.aurasDebuffsRelativePoint = "BOTTOMRIGHT"
      GladiusMoP.db.aurasDebuffsAnchor = "TOPRIGHT"
      GladiusMoP.db.aurasDebuffsSpacingX = 1
      GladiusMoP.db.aurasDebuffsHeight = 17
      GladiusMoP.db.aurasDebuffsMax = GladiusMoP.db.modules.Trinket and 8 or 6
      GladiusMoP.db.aurasDebuffsOffsetY = -1
   end
end

function Auras:GetAttachTo()
   return GladiusMoP.db.aurasAttachTo
end

function Auras:GetFrame(unit)
   return self.buffFrame[unit]
end

function Auras:GetIndicatorHeight()
   local height = 0
   
   if (GladiusMoP.db.aurasBuffs) then
      height = height + GladiusMoP.db.aurasBuffsHeight * ceil(GladiusMoP.db.aurasBuffsMax / GladiusMoP.db.aurasBuffsPerColumn)
   end
   
   if (GladiusMoP.db.aurasDebuffs) then
      height = height + GladiusMoP.db.aurasDebuffsHeight * ceil(GladiusMoP.db.aurasDebuffsMax / GladiusMoP.db.aurasDebuffsPerColumn)
   end
   
   return height
end

function Auras:UNIT_AURA(event, unit)
   if (not strfind(unit, "arena") or strfind(unit, "pet")) then return end
   
   -- buff frame
   for i=1, 40 do
      local name, rank, icon, count, dispelType, duration, expires, caster, isStealable = UnitAura(unit, i, "HELPFUL")     
	  if (self.buffFrame[unit] == nil) then break end
      if (not self.buffFrame[unit][i]) then break end
      
      if (name) then       
         self.buffFrame[unit][i].texture:SetTexture(icon)
         GladiusMoP:Call(GladiusMoP.modules.Timer, "SetTimer", self.buffFrame[unit][i], duration)  
         
         self.buffFrame[unit][i]:SetAlpha(1)
      else
         self.buffFrame[unit][i]:SetAlpha(0)
      end
   end
   
   -- debuff frame
   for i=1, 40 do
      local name, rank, icon, count, dispelType, duration, expires, caster, isStealable = UnitAura(unit, i, "HARMFUL")
      
      if (not self.debuffFrame[unit][i]) then break end
      
      if (name) then       
         self.debuffFrame[unit][i].texture:SetTexture(icon)
         GladiusMoP:Call(GladiusMoP.modules.Timer, "SetTimer", self.debuffFrame[unit][i], duration)  
         
         self.debuffFrame[unit][i]:SetAlpha(1)
      else
         self.debuffFrame[unit][i]:SetAlpha(0)
      end
   end
end

local function updateTooltip(f, unit, index, filter)
   if (GameTooltip:IsOwned(f)) then
		GameTooltip:SetUnitAura(unit, index, filter)
	end
end

function Auras:CreateFrame(unit)
   local button = GladiusMoP.buttons[unit]
   if (not button) then return end       
   
   -- create buff frame
   if (not self.buffFrame[unit] and GladiusMoP.db.aurasBuffs) then
      self.buffFrame[unit] = CreateFrame("Frame", "GladiusMoP" .. self.name .. "BuffFrame" .. unit, button)
            
      for i=1, 40 do
         self.buffFrame[unit][i] = CreateFrame("CheckButton", "GladiusMoP" .. self.name .. "BuffFrameIcon" .. i .. unit, button, "ActionButtonTemplate")
         self.buffFrame[unit][i]:SetScript("OnEnter", function(f) 
            GameTooltip:SetUnitAura(unit, i, "HELPFUL")
            f:SetScript("OnUpdate", function(f)
               updateTooltip(f, unit, i, "HELPFUL")
            end)
         end)
         self.buffFrame[unit][i]:SetScript("OnLeave", function(f)
            f:SetScript("OnUpdate", nil)
            GameTooltip:Hide()
         end)
         self.buffFrame[unit][i]:EnableMouse(false)
         self.buffFrame[unit][i]:SetNormalTexture("Interface\\AddOns\\GladiusMoP\\images\\gloss")
         self.buffFrame[unit][i].texture = _G[self.buffFrame[unit][i]:GetName().."Icon"]
         self.buffFrame[unit][i].normalTexture = _G[self.buffFrame[unit][i]:GetName().."NormalTexture"]
         self.buffFrame[unit][i].cooldown = _G[self.buffFrame[unit][i]:GetName().."Cooldown"]
         self.buffFrame[unit][i].cooldown:SetReverse(false)
         
         GladiusMoP:Call(GladiusMoP.modules.Timer, "RegisterTimer", self.buffFrame[unit][i])
      end
   end
   
   -- create debuff frame
   if (not self.debuffFrame[unit] and GladiusMoP.db.aurasDebuffs) then
      self.debuffFrame[unit] = CreateFrame("Frame", "GladiusMoP" .. self.name .. "DebuffFrame" .. unit, button)
      self.debuffFrame[unit]:EnableMouse(false)
      
      for i=1, 40 do
         self.debuffFrame[unit][i] = CreateFrame("CheckButton", "GladiusMoP" .. self.name .. "DebuffFrameIcon" .. i .. unit, button, "ActionButtonTemplate")
         self.debuffFrame[unit][i]:SetScript("OnEnter", function(f) 
            GameTooltip:SetUnitAura(unit, i, "HARMFUL")
            f:SetScript("OnUpdate", function(f)
               updateTooltip(f, unit, i, "HARMFUL")
            end)
         end)
         self.debuffFrame[unit][i]:SetScript("OnLeave", function(f)
            f:SetScript("OnUpdate", nil)
            GameTooltip:Hide()
         end)
         self.debuffFrame[unit][i]:EnableMouse(false)
         self.debuffFrame[unit][i]:SetNormalTexture("Interface\\AddOns\\GladiusMoP\\images\\gloss")
         self.debuffFrame[unit][i].texture = _G[self.debuffFrame[unit][i]:GetName().."Icon"]
         self.debuffFrame[unit][i].normalTexture = _G[self.debuffFrame[unit][i]:GetName().."NormalTexture"]
         self.debuffFrame[unit][i].cooldown = _G[self.debuffFrame[unit][i]:GetName().."Cooldown"]
         self.debuffFrame[unit][i].cooldown:SetReverse(false)
         
         GladiusMoP:Call(GladiusMoP.modules.Timer, "RegisterTimer", self.debuffFrame[unit][i])
      end
   end
   
   if (not GladiusMoP.test) then
      self:UNIT_AURA(nil, unit)
   end
end

function Auras:Update(unit)   
   GladiusMoP.db.aurasFrameAuras = GladiusMoP.db.aurasFrameAuras or self:GetAuraList()

   -- create frame
   if (not self.buffFrame[unit] or not self.debuffFrame[unit]) then 
      self:CreateFrame(unit)
   end
   
   -- update buff frame 
   if (GladiusMoP.db.aurasBuffs) then  
      self.buffFrame[unit]:ClearAllPoints()
      
      -- anchor point 
      local parent = GladiusMoP:GetParent(unit, GladiusMoP.db.aurasBuffsAttachTo)     
      self.buffFrame[unit]:SetPoint(GladiusMoP.db.aurasBuffsAnchor, parent, GladiusMoP.db.aurasBuffsRelativePoint, GladiusMoP.db.aurasBuffsOffsetX, GladiusMoP.db.aurasBuffsOffsetY)

      -- size
      self.buffFrame[unit]:SetWidth(GladiusMoP.db.aurasBuffsWidth*GladiusMoP.db.aurasBuffsPerColumn+GladiusMoP.db.aurasBuffsSpacingX*GladiusMoP.db.aurasBuffsPerColumn)
      self.buffFrame[unit]:SetHeight(GladiusMoP.db.aurasBuffsHeight*math.ceil(GladiusMoP.db.aurasBuffsMax/gladius.db.aurasBuffsPerColumn)+(GladiusMoP.db.aurasBuffsSpacingY*(math.ceil(GladiusMoP.db.aurasBuffsMax/gladius.db.aurasBuffsPerColumn)+1)))
      
      -- icon points
      local anchor, parent, relativePoint, offsetX, offsetY
      local start, startAnchor = 1, self.buffFrame[unit]
      
      -- grow anchor
      local grow1, grow2, grow3, startRelPoint
      if (GladiusMoP.db.aurasBuffsGrow == "DOWNRIGHT") then
         grow1, grow2, grow3, startRelPoint = "TOPLEFT", "BOTTOMLEFT", "TOPRIGHT", "TOPLEFT"
      elseif (GladiusMoP.db.aurasBuffsGrow == "DOWNLEFT") then
         grow1, grow2, grow3, startRelPoint = "TOPRIGHT", "BOTTOMRIGHT", "TOPLEFT", "TOPRIGHT"
      elseif (GladiusMoP.db.aurasBuffsGrow == "UPRIGHT") then
         grow1, grow2, grow3, startRelPoint = "BOTTOMLEFT", "TOPLEFT", "BOTTOMRIGHT", "BOTTOMLEFT"
      elseif (GladiusMoP.db.aurasBuffsGrow == "UPLEFT") then
         grow1, grow2, grow3, startRelPoint = "BOTTOMRIGHT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"
      end
            
      for i=1, 40 do
         self.buffFrame[unit][i]:ClearAllPoints()
         
         if (GladiusMoP.db.aurasBuffsMax >= i) then        
            if (start == 1) then
               anchor, parent, relativePoint, offsetX, offsetY = grow1, startAnchor, startRelPoint, 0, strfind(GladiusMoP.db.aurasBuffsGrow, "DOWN") and -GladiusMoP.db.aurasBuffsSpacingY or GladiusMoP.db.aurasBuffsSpacingY                  
            else
               anchor, parent, relativePoint, offsetX, offsetY = grow1, self.buffFrame[unit][i-1], grow3, strfind(GladiusMoP.db.aurasBuffsGrow, "LEFT") and -GladiusMoP.db.aurasBuffsSpacingX or GladiusMoP.db.aurasBuffsSpacingX, 0                                
               
               if (start == GladiusMoP.db.aurasBuffsPerColumn) then
                  start = 0
                  startAnchor = self.buffFrame[unit][i - GladiusMoP.db.aurasBuffsPerColumn + 1]
                  startRelPoint = grow2
               end
            end
            
            start = start + 1
         end
      
         self.buffFrame[unit][i]:SetPoint(anchor, parent, relativePoint, offsetX, offsetY)
         
         self.buffFrame[unit][i]:SetWidth(GladiusMoP.db.aurasBuffsWidth)
         self.buffFrame[unit][i]:SetHeight(GladiusMoP.db.aurasBuffsHeight)
         
         -- style action button   
         self.buffFrame[unit][i].normalTexture:SetHeight(self.buffFrame[unit][i]:GetHeight() + self.buffFrame[unit][i]:GetHeight() * 0.4)
         self.buffFrame[unit][i].normalTexture:SetWidth(self.buffFrame[unit][i]:GetWidth() + self.buffFrame[unit][i]:GetWidth() * 0.4)
         
         self.buffFrame[unit][i].normalTexture:ClearAllPoints()
         self.buffFrame[unit][i].normalTexture:SetPoint("CENTER", 0, 0)
         self.buffFrame[unit][i]:SetNormalTexture("Interface\\AddOns\\GladiusMoP\\images\\gloss")
         
         self.buffFrame[unit][i].texture:ClearAllPoints()
         self.buffFrame[unit][i].texture:SetPoint("TOPLEFT", self.buffFrame[unit][i], "TOPLEFT")
         self.buffFrame[unit][i].texture:SetPoint("BOTTOMRIGHT", self.buffFrame[unit][i], "BOTTOMRIGHT")
         
         self.buffFrame[unit][i].normalTexture:SetVertexColor(GladiusMoP.db.aurasBuffsGlossColor.r, GladiusMoP.db.aurasBuffsGlossColor.g, 
            GladiusMoP.db.aurasBuffsGlossColor.b, GladiusMoP.db.aurasBuffsGloss and GladiusMoP.db.aurasBuffsGlossColor.a or 0)
      end
      
      -- hide
      self.buffFrame[unit]:SetAlpha(0)
   end  
   
   -- update debuff frame 
   if (GladiusMoP.db.aurasDebuffs) then  
      self.debuffFrame[unit]:ClearAllPoints()
      
      -- anchor point 
      local parent = GladiusMoP:GetParent(unit, GladiusMoP.db.aurasDebuffsAttachTo)     
      self.debuffFrame[unit]:SetPoint(GladiusMoP.db.aurasDebuffsAnchor, parent, GladiusMoP.db.aurasDebuffsRelativePoint, GladiusMoP.db.aurasDebuffsOffsetX, GladiusMoP.db.aurasDebuffsOffsetY)

      -- size
      self.debuffFrame[unit]:SetWidth(GladiusMoP.db.aurasDebuffsWidth*GladiusMoP.db.aurasDebuffsPerColumn+GladiusMoP.db.aurasDebuffsSpacingX*GladiusMoP.db.aurasDebuffsPerColumn)
      self.debuffFrame[unit]:SetHeight(GladiusMoP.db.aurasDebuffsHeight*math.ceil(GladiusMoP.db.aurasDebuffsMax/gladius.db.aurasDebuffsPerColumn)+(GladiusMoP.db.aurasDebuffsSpacingY*(math.ceil(GladiusMoP.db.aurasDebuffsMax/gladius.db.aurasDebuffsPerColumn)+1)))

      -- icon points
      local anchor, parent, relativePoint, offsetX, offsetY
      local start, startAnchor = 1, self.debuffFrame[unit]
      
      -- grow anchor
      local grow1, grow2, grow3, startRelPoint
      if (GladiusMoP.db.aurasDebuffsGrow == "DOWNRIGHT") then
         grow1, grow2, grow3, startRelPoint = "TOPLEFT", "BOTTOMLEFT", "TOPRIGHT", "TOPLEFT"
      elseif (GladiusMoP.db.aurasDebuffsGrow == "DOWNLEFT") then
         grow1, grow2, grow3, startRelPoint = "TOPRIGHT", "BOTTOMRIGHT", "TOPLEFT", "TOPRIGHT"
      elseif (GladiusMoP.db.aurasDebuffsGrow == "UPRIGHT") then
         grow1, grow2, grow3, startRelPoint = "BOTTOMLEFT", "TOPLEFT", "BOTTOMRIGHT", "BOTTOMLEFT"
      elseif (GladiusMoP.db.aurasDebuffsGrow == "UPLEFT") then
         grow1, grow2, grow3, startRelPoint = "BOTTOMRIGHT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT"
      end
            
      for i=1, 40 do
         self.debuffFrame[unit][i]:ClearAllPoints()
         
         if (GladiusMoP.db.aurasDebuffsMax >= i) then        
            if (start == 1) then
               anchor, parent, relativePoint, offsetX, offsetY = grow1, startAnchor, startRelPoint, 0, strfind(GladiusMoP.db.aurasDebuffsGrow, "DOWN") and -GladiusMoP.db.aurasDebuffsSpacingY or GladiusMoP.db.aurasDebuffsSpacingY                  
            else
               anchor, parent, relativePoint, offsetX, offsetY = grow1, self.debuffFrame[unit][i-1], grow3, strfind(GladiusMoP.db.aurasDebuffsGrow, "LEFT") and -GladiusMoP.db.aurasDebuffsSpacingX or GladiusMoP.db.aurasDebuffsSpacingX, 0                                
               
               if (start == GladiusMoP.db.aurasDebuffsPerColumn) then
                  start = 0
                  startAnchor = self.debuffFrame[unit][i - GladiusMoP.db.aurasDebuffsPerColumn + 1]
                  startRelPoint = grow2
               end
            end
            
            start = start + 1
         end
      
         self.debuffFrame[unit][i]:SetPoint(anchor, parent, relativePoint, offsetX, offsetY)
         
         self.debuffFrame[unit][i]:SetWidth(GladiusMoP.db.aurasDebuffsWidth)
         self.debuffFrame[unit][i]:SetHeight(GladiusMoP.db.aurasDebuffsHeight)
         
         -- style action button   
         self.debuffFrame[unit][i].normalTexture:SetHeight(self.debuffFrame[unit][i]:GetHeight() + self.debuffFrame[unit][i]:GetHeight() * 0.4)
         self.debuffFrame[unit][i].normalTexture:SetWidth(self.debuffFrame[unit][i]:GetWidth() + self.debuffFrame[unit][i]:GetWidth() * 0.4)
         
         self.debuffFrame[unit][i].normalTexture:ClearAllPoints()
         self.debuffFrame[unit][i].normalTexture:SetPoint("CENTER", 0, 0)
         self.debuffFrame[unit][i]:SetNormalTexture("Interface\\AddOns\\GladiusMoP\\images\\gloss")
         
         self.debuffFrame[unit][i].texture:ClearAllPoints()
         self.debuffFrame[unit][i].texture:SetPoint("TOPLEFT", self.debuffFrame[unit][i], "TOPLEFT")
         self.debuffFrame[unit][i].texture:SetPoint("BOTTOMRIGHT", self.debuffFrame[unit][i], "BOTTOMRIGHT")
         
         self.debuffFrame[unit][i].normalTexture:SetVertexColor(GladiusMoP.db.aurasDebuffsGlossColor.r, GladiusMoP.db.aurasDebuffsGlossColor.g, 
            GladiusMoP.db.aurasDebuffsGlossColor.b, GladiusMoP.db.aurasDebuffsGloss and GladiusMoP.db.aurasDebuffsGlossColor.a or 0)
      end
      
      -- hide
      self.debuffFrame[unit]:SetAlpha(0)
   end
   
   -- event
   if (not GladiusMoP.db.aurasDebuffs and not GladiusMoP.db.aurasBuffs) then
      self:UnregisterAllEvents()
   else
      self:RegisterEvent("UNIT_AURA")
   end
end

function Auras:Show(unit)
   local testing = GladiusMoP.test
      
   -- show buff frame
   if (self.buffFrame[unit]) then 
      self.buffFrame[unit]:SetAlpha(1)
      
      for i=1, GladiusMoP.db.aurasBuffsMax do
         self.buffFrame[unit][i]:SetAlpha(1)
      end
   end
   
   -- show debuff frame
   if (self.debuffFrame[unit]) then
      self.debuffFrame[unit]:SetAlpha(1)
      
      for i=1, GladiusMoP.db.aurasDebuffsMax do
         self.debuffFrame[unit][i]:SetAlpha(1)
      end
   end
end

function Auras:Reset(unit)  
   if (self.buffFrame[unit]) then 
      -- hide buff frame
      self.buffFrame[unit]:SetAlpha(0)
      
      for i=1, 40 do
         self.buffFrame[unit][i].texture:SetTexture("")
         self.buffFrame[unit][i]:SetAlpha(0)
      end
   end
   
   if (self.debuffFrame[unit]) then 
      -- hide debuff frame
      self.debuffFrame[unit]:SetAlpha(0)
      
      for i=1, 40 do
         self.debuffFrame[unit][i].texture:SetTexture("")
         self.debuffFrame[unit][i]:SetAlpha(0)
      end
   end
end

function Auras:Test(unit)   
   -- test buff frame
   if (self.buffFrame[unit]) then
      for i=1, GladiusMoP.db.aurasBuffsMax do
         self.buffFrame[unit][i].texture:SetTexture(GetSpellTexture(21562))
      end
   end
   
   -- test debuff frame
   if (self.debuffFrame[unit]) then
      for i=1, GladiusMoP.db.aurasDebuffsMax do
         self.debuffFrame[unit][i].texture:SetTexture(GetSpellTexture(589))
      end
   end
end

function Auras:GetOptions()
   GladiusMoP.db.aurasFrameAuras = GladiusMoP.db.aurasFrameAuras or self:GetAuraList()
   
   local options = {
      buffs = {  
         type="group",
         name=L["Buffs"],
         childGroups="tab",
         order=1,
         args = {
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
                        aurasBuffs = {
                           type="toggle",
                           name=L["Auras Buffs"],
                           desc=L["Toggle aura buffs"],
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=5,
                        },
                        aurasBuffsGrow = {
                           type="select",
                           name=L["Auras Column Grow"],
                           desc=L["Grow direction of the auras"],
                           values=function() return {
                              ["UPLEFT"] = L["Up Left"],
                              ["UPRIGHT"] = L["Up Right"],
                              ["DOWNLEFT"] = L["Down Left"],
                              ["DOWNRIGHT"] = L["Down Right"],
                           }
                           end,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=10,
                        }, 
                        sep = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=13,
                        },                        
                        aurasBuffsPerColumn = {
                           type="range",
                           name=L["Aura Icons Per Column"],
                           desc=L["Number of aura icons per column"],
                           min=1, max=50, step=1,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=15,
                        },
                        aurasBuffsMax = {
                           type="range",
                           name=L["Aura Icons Max"],
                           desc=L["Number of max buffs"],
                           min=1, max=40, step=1,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=20,
                        },  
                        sep2 = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=23,
                        },   
                        aurasBuffsGloss = {
                           type="toggle",
                           name=L["Auras Gloss"],
                           desc=L["Toggle gloss on the auras icon"],
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           hidden=function() return not GladiusMoP.db.advancedOptions end,
                           order=25,
                        },
                        aurasBuffsGlossColor = {
                           type="color",
                           name=L["Auras Gloss Color"],
                           desc=L["Color of the auras icon gloss"],
                           get=function(info) return GladiusMoP:GetColorOption(info) end,
                           set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, a) end,
                           hasAlpha=true,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           hidden=function() return not GladiusMoP.db.advancedOptions end,
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
                        aurasBuffsWidth = {
                           type="range",
                           name=L["Aura Icon Width"],
                           desc=L["Width of the aura icons"],
                           min=10, max=100, step=1,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=5,
                        },
                        aurasBuffsHeight = {
                           type="range",
                           name=L["Aura Icon Height"],
                           desc=L["Height of the aura icon"],
                           min=10, max=100, step=1,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=10,
                        },   
                        sep = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=13,
                        },
                        aurasBuffsSpacingY = {
                           type="range",
                           name=L["Auras Spacing Vertical"],
                           desc=L["Vertical spacing of the auras"],
                           min=0, max=30, step=1,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=15,
                        },
                        aurasBuffsSpacingX = {
                           type="range",
                           name=L["Auras Spacing Horizontal"],
                           desc=L["Horizontal spacing of the auras"],
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           min=0, max=30, step=1,
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
                        aurasBuffsAttachTo = {
                           type="select",
                           name=L["Auras Attach To"],
                           desc=L["Attach auras to the given frame"],
                           values=function() return GladiusMoP:GetModules(self.name) end,
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
                        aurasBuffsAnchor = {
                           type="select",
                           name=L["Auras Anchor"],
                           desc=L["Anchor of the auras"],
                           values=function() return GladiusMoP:GetPositions() end,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=10,
                        },
                        aurasBuffsRelativePoint = {
                           type="select",
                           name=L["Auras Relative Point"],
                           desc=L["Relative point of the auras"],
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
                        aurasBuffsOffsetX = {
                           type="range",
                           name=L["Auras Offset X"],
                           desc=L["X offset of the auras"],
                           min=-100, max=100, step=1,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=20,
                        },
                        aurasBuffsOffsetY = {
                           type="range",
                           name=L["Auras Offset Y"],
                           desc=L["Y  offset of the auras"],
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           min=-50, max=50, step=1,
                           order=25,
                        },
                     },
                  },
               },
            },
            --[[filter = {  
               type="group",
               name=L["Filter"],
               childGroups="tree",
               hidden=function() return not GladiusMoP.db.advancedOptions end,
               order=2,
               args = {
                  whitelist = {  
                     type="group",
                     name=L["Whitelist"],
                     order=1,
                     args = {
                     },
                  },
                  blacklist = {  
                     type="group",
                     name=L["Blacklist"],
                     order=2,
                     args = {
                     },
                  },
                  filterFunction = {  
                     type="group",
                     name=L["Filter Function"],
                     order=3,
                     args = {
                     },
                  },
               },
            },]]
         },
      },
      debuffs = {  
         type="group",
         name=L["Debuffs"],
         childGroups="tab",
         order=2,
         args = {
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
                        aurasDebuffs = {
                           type="toggle",
                           name=L["Auras Debuffs"],
                           desc=L["Toggle aura debuffs"],
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=5,
                        },
                        aurasDebuffsGrow = {
                           type="select",
                           name=L["Auras Column Grow"],
                           desc=L["Grow direction of the auras"],
                           values=function() return {
                              ["UPLEFT"] = L["Up Left"],
                              ["UPRIGHT"] = L["Up Right"],
                              ["DOWNLEFT"] = L["Down Left"],
                              ["DOWNRIGHT"] = L["Down Right"],
                           }
                           end,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=10,
                        }, 
                        sep = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=13,
                        },                        
                        aurasDebuffsPerColumn = {
                           type="range",
                           name=L["Aura Icons Per Column"],
                           desc=L["Number of aura icons per column"],
                           min=1, max=50, step=1,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=15,
                        },
                        aurasDebuffsMax = {
                           type="range",
                           name=L["Aura Icons Max"],
                           desc=L["Number of max Debuffs"],
                           min=1, max=40, step=1,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=20,
                        },  
                        sep2 = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=23,
                        },   
                        aurasDebuffsGloss = {
                           type="toggle",
                           name=L["Auras Gloss"],
                           desc=L["Toggle gloss on the auras icon"],
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           hidden=function() return not GladiusMoP.db.advancedOptions end,
                           order=25,
                        },
                        aurasDebuffsGlossColor = {
                           type="color",
                           name=L["Auras Gloss Color"],
                           desc=L["Color of the auras icon gloss"],
                           get=function(info) return GladiusMoP:GetColorOption(info) end,
                           set=function(info, r, g, b, a) return GladiusMoP:SetColorOption(info, r, g, b, a) end,
                           hasAlpha=true,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           hidden=function() return not GladiusMoP.db.advancedOptions end,
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
                        aurasDebuffsWidth = {
                           type="range",
                           name=L["Aura Icon Width"],
                           desc=L["Width of the aura icons"],
                           min=10, max=100, step=1,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=5,
                        },
                        aurasDebuffsHeight = {
                           type="range",
                           name=L["Aura Icon Height"],
                           desc=L["Height of the aura icon"],
                           min=10, max=100, step=1,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=10,
                        },   
                        sep = {                     
                           type = "description",
                           name="",
                           width="full",
                           order=13,
                        },
                        aurasDebuffsSpacingY = {
                           type="range",
                           name=L["Auras Spacing Vertical"],
                           desc=L["Vertical spacing of the auras"],
                           min=0, max=30, step=1,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=15,
                        },
                        aurasDebuffsSpacingX = {
                           type="range",
                           name=L["Auras Spacing Horizontal"],
                           desc=L["Horizontal spacing of the auras"],
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           min=0, max=30, step=1,
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
                        aurasDebuffsAttachTo = {
                           type="select",
                           name=L["Auras Attach To"],
                           desc=L["Attach auras to the given frame"],
                           values=function() return GladiusMoP:GetModules(self.name) end,
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
                        aurasDebuffsAnchor = {
                           type="select",
                           name=L["Auras Anchor"],
                           desc=L["Anchor of the auras"],
                           values=function() return GladiusMoP:GetPositions() end,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=10,
                        },
                        aurasDebuffsRelativePoint = {
                           type="select",
                           name=L["Auras Relative Point"],
                           desc=L["Relative point of the auras"],
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
                        aurasDebuffsOffsetX = {
                           type="range",
                           name=L["Auras Offset X"],
                           desc=L["X offset of the auras"],
                           min=-100, max=100, step=1,
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           order=20,
                        },
                        aurasDebuffsOffsetY = {
                           type="range",
                           name=L["Auras Offset Y"],
                           desc=L["Y  offset of the auras"],
                           disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                           min=-50, max=50, step=1,
                           order=25,
                        },
                     },
                  },
               },
            },
            --[[filter = {  
               type="group",
               name=L["Filter"],
               childGroups="tree",
               hidden=function() return not GladiusMoP.db.advancedOptions end,
               order=2,
               args = {
                  whitelist = {  
                     type="group",
                     name=L["Whitelist"],
                     order=1,
                     args = {
                     },
                  },
                  blacklist = {  
                     type="group",
                     name=L["Blacklist"],
                     order=2,
                     args = {
                     },
                  },
                  filterFunction = {  
                     type="group",
                     name=L["Filter Function"],
                     order=3,
                     args = {
                     },
                  },
               },
            },]]
         },
      },      
      auraList = {  
         type="group",
         name=L["Auras"],
         childGroups="tree",
         order=3,
         args = {      
            newAura = {
               type = "group",
               name = L["New Aura"],
               desc = L["New Aura"],
               inline=true,
               order = 1,
               args = {
                  name = {
                     type = "input",
                     name = L["Name"],
                     desc = L["Name of the aura"],
                     get=function() return Auras.newAuraName or "" end,
                     set=function(info, value) Auras.newAuraName = value end,
                     order=1,
                  },
                  priority = {
                     type= "range",
                     name = L["Priority"],
                     desc = L["Select what priority the aura should have - higher equals more priority"],
                     get=function() return Auras.newAuraPriority or "" end,
                     set=function(info, value) Auras.newAuraPriority = value end,
                     min=0,
                     max=12,
                     step=1,
                     order=2,
                  },
                  add = {
                     type = "execute",
                     name = L["Add new Aura"],
                     func = function(info)
                        GladiusMoP.dbi.profile.aurasFrameAuras[Auras.newAuraName] = Auras.newAuraPriority 
                        GladiusMoP.options.args[self.name].args.auraList.args[Auras.newAuraName] = Auras:SetupAura(Auras.newAuraName, Auras.newAuraPriority)
                     end,
                     order=3,
                  },
               },
            },
         },
      },
   }
   
   -- set auras
   if (not GladiusMoP.db.aurasFrameAuras) then
      GladiusMoP.db.aurasFrameAuras = self:GetAuraList()
   end
  
   for aura, priority in pairs(GladiusMoP.db.aurasFrameAuras) do
      options.auraList.args[aura] = self:SetupAura(aura, priority)
   end
   
   return options
end

local function setAura(info, value)
	if (info[#(info)] == "name") then   
      -- create new aura
      GladiusMoP.options.args["ClassIcon"].args.auraList.args[value] = ClassIcon:SetupAura(value, GladiusMoP.dbi.profile.aurasFrameAuras[info[#(info) - 1]])
		GladiusMoP.dbi.profile.aurasFrameAuras[value] = GladiusMoP.dbi.profile.aurasFrameAuras[info[#(info) - 1]]
		
		-- delete old aura
		GladiusMoP.dbi.profile.aurasFrameAuras[info[#(info) - 1]] = nil 
		GladiusMoP.options.args["ClassIcon"].args.auraList.args = {}
		
		for aura, priority in pairs(GladiusMoP.dbi.profile.aurasFrameAuras) do
         GladiusMoP.options.args["ClassIcon"].args.auraList.args[aura] = ClassIcon:SetupAura(aura, priority)
      end
   else
      GladiusMoP.dbi.profile.aurasFrameAuras[info[#(info) - 1]] = value
	end
end

local function getAura(info)
   if (info[#(info)] == "name") then
      return info[#(info) - 1]
   else      
      return GladiusMoP.dbi.profile.aurasFrameAuras[info[#(info) - 1]]
   end
end

function Auras:SetupAura(aura, priority)
   return {
      type = "group",
      name = aura,
      desc = aura,
      get = getAura,
      set = setAura,
      args = {
         name = {
            type = "input",
            name = L["Name"],
            desc = L["Name of the aura"],
            order=1,
         },
         priority = {
            type= "range",
            name = L["Priority"],
            desc = L["Select what priority the aura should have - higher equals more priority"],
            min=0,
            max=12,
            step=1,
            order=2,
         },
         delete = {
            type = "execute",
            name = L["Delete"],
            func = function(info)
               GladiusMoP.dbi.profile.aurasFrameAuras[info[#(info) - 1]] = nil 
               
               local newAura = GladiusMoP.options.args["Auras"].args.auraList.args.newAura
               GladiusMoP.options.args["Auras"].args.auraList.args = {
                  newAura = newAura,
               }
               
               for aura, priority in pairs(GladiusMoP.dbi.profile.aurasFrameAuras) do
                  GladiusMoP.options.args["Auras"].args.auraList.args[aura] = self:SetupAura(aura, priority)
               end
            end,
            order=3,
         },
      },
   }
end

function Auras:GetAuraList()
	local auraTable = setmetatable({
		-- Spell Name			Priority (higher = more priority)
		-- sprints
		[GetSpellInfo(108843)]  = 0,    -- Blazing Speed
		[GetSpellInfo(65081)]   = 0,    -- Body and Soul
		[GetSpellInfo(108212)]  = 0,    -- Burst of Speed
		[GetSpellInfo(68992)]   = 0,    -- Darkflight
		[GetSpellInfo(1850)]    = 0,    -- Dash
		[GetSpellInfo(137452)]  = 0,    -- Displacer Beast
		[GetSpellInfo(114239)]  = 0,    -- Phantasm
		[GetSpellInfo(118922)]  = 0,    -- Pothaste
		[GetSpellInfo(85499)]   = 0,    -- Speed of Light
		[GetSpellInfo(2983)]    = 0,    -- Sprint
		[GetSpellInfo(06898)]   = 0,    -- Stampeding Roar
		[GetSpellInfo(116841)]  = 0,    -- Tiger's Lust
		-- snares
		[GetSpellInfo(5116)]    = 1,    -- Concussive Shot
		[GetSpellInfo(120)]     = 1,    -- Cone of Cold
		[GetSpellInfo(13809)]   = 1,    -- Frost Trap
		-- dispellable buffs
		[GetSpellInfo(16188)]   = 2,    -- Ancestral Swiftness
		[GetSpellInfo(54428)]   = 2,    -- Divine Plea
		[GetSpellInfo(31842)]   = 3,    -- Divine Favor
		[GetSpellInfo(6346)]    = 2,    -- Fear Ward
		[GetSpellInfo(112965)]  = 2,    -- Fingers of Frost
		[GetSpellInfo(1044)]    = 2,    -- Hand of Freedom
		[GetSpellInfo(1022)]    = 2,    -- Hand of Protection
		[GetSpellInfo(114039)]  = 2,    -- Hand of Purity
		[GetSpellInfo(6940)]    = 2,    -- Hand of Sacrifice
		[GetSpellInfo(11426)]   = 2,    -- Ice Barrier
		[GetSpellInfo(29166)]   = 2,    -- Innervate
		[GetSpellInfo(53271)]   = 2,    -- Master's Call
		[GetSpellInfo(132158)]  = 2,    -- Nature's Swiftness
		[GetSpellInfo(69369)]   = 2,    -- Predatory Swiftness
		[GetSpellInfo(12043)]   = 2,    -- Presence of Mind
		[GetSpellInfo(48108)]   = 2,    -- Pyroblast!
		-- damage reduction auras
		[GetSpellInfo(108978)]  = 3,    -- Alter Time
		[GetSpellInfo(108271)]  = 3,    -- Astral Shift
		[GetSpellInfo(22812)]   = 3,    -- Barkskin
		[GetSpellInfo(18499)]   = 3,    -- Berserker Rage
		[GetSpellInfo(111397)]  = 3,    -- Blood Horror
		[GetSpellInfo(74001)]   = 3,    -- Combat Readiness
		[GetSpellInfo(31224)]   = 3,    -- Cloak of Shadows
		[GetSpellInfo(108359)]  = 3,    -- Dark Regeneration
		[GetSpellInfo(118038)]  = 3,    -- Die by the Sword
		[GetSpellInfo(498)]     = 3,    -- Divine Protection
		[GetSpellInfo(5277)]    = 3,    -- Evasion
		[GetSpellInfo(113613)]  = 3,    -- Growl (Rogue Symbiosis)
		[GetSpellInfo(47788)]   = 3,    -- Guardian Spirit
		[GetSpellInfo(48792)]   = 3,    -- Icebound Fortitude
		[GetSpellInfo(1463)]    = 3,    -- Incanter's Ward
		[GetSpellInfo(116267)]  = 3,    -- Incanter's Absorption
		[GetSpellInfo(66)]      = 3,    -- Invisibility
		[GetSpellInfo(102342)]  = 3,    -- Ironbark
		[GetSpellInfo(12975)]   = 3,    -- Last Stand
		[GetSpellInfo(49039)]   = 3,    -- Lichborne
		[GetSpellInfo(116849)]  = 3,    -- Life Cocoon
		[GetSpellInfo(114028)]  = 3,    -- Mass Spell Reflection
		[GetSpellInfo(106922)]  = 3,    -- Might of Ursoc
		[GetSpellInfo(30884)]   = 3,    -- Nature's Guardian
		[GetSpellInfo(124974)]  = 3,    -- Nature's Vigil
		[GetSpellInfo(137562)]  = 3,    -- Nimble Brew
		[GetSpellInfo(33206)]   = 3,    -- Pain Suppression
		[GetSpellInfo(53480)]   = 3,    -- Roar of Sacrifice
		[GetSpellInfo(122286)]  = 3,    -- Savage Defense (Protection Warrior Symbiosis)
		[GetSpellInfo(30823)]   = 3,    -- Shamanistic Rage
		[GetSpellInfo(871)]     = 3,    -- Shield Wall
		[GetSpellInfo(112833)]  = 3,    -- Spectral Guise
		[GetSpellInfo(23920)]   = 3,    -- Spell Reflection
		[GetSpellInfo(113306)]  = 3,    -- Survival Instincts (Brewmaster Monk Symbiosis)
		-- offsensive melee
		[GetSpellInfo(13750)]   = 4,    -- Adrenaline Rush
		[GetSpellInfo(107574)]  = 4,    -- Avatar
		[GetSpellInfo(106952)]  = 4,    -- Berserk
		[GetSpellInfo(12292)]   = 4,    -- Bloodbath
		[GetSpellInfo(12292)]   = 4,    -- Death Wish
		[GetSpellInfo(51271)]   = 4,    -- Pillar of Frost
		[GetSpellInfo(1719)]    = 4,    -- Recklessness
		[GetSpellInfo(121471)]  = 4,    -- Shadow Blades
		[GetSpellInfo(51713)]   = 4,    -- Shadow Dance
		[GetSpellInfo(49016)]   = 4,    -- Unholy Frenzy
		-- roots and disarms
		[GetSpellInfo(676)]     = 5,    -- Disarm
		[GetSpellInfo(51722)]   = 5,    -- Dismantle
		[GetSpellInfo(64695)]   = 5,    -- Earthgrab
		[GetSpellInfo(339)]     = 5,    -- Entangling Roots
		[GetSpellInfo(33395)]   = 5,    -- Freeze (Pet Nova)
		[GetSpellInfo(122)]     = 5,    -- Frost Nova
		[GetSpellInfo(102051)]  = 5,    -- Frostjaw
		[GetSpellInfo(126458)]  = 5,    -- Grapple Weapon
		[GetSpellInfo(102359)]  = 5,    -- Mass Entanglement
		[GetSpellInfo(136634)]  = 5,    -- Narrow Escape
		[GetSpellInfo(115197)]  = 5,    -- Partial Paralysis
		-- offensive auras
		[GetSpellInfo(12042)]   = 6,    -- Arcane Power
		[GetSpellInfo(114049)]  = 6,    -- Ascendance
		[GetSpellInfo(31884)]   = 6,    -- Avenging Wrath
		[GetSpellInfo(113858)]  = 6,    -- Dark Soul: Instability
		[GetSpellInfo(113861)]  = 6,    -- Dark Soul: Knowledge
		[GetSpellInfo(113860)]  = 6,    -- Dark Soul: Misery
		[GetSpellInfo(16166)]   = 6,    -- Elemental Mastery
		[GetSpellInfo(108288)]  = 6,    -- Heart of the Wild
		[GetSpellInfo(12472)]   = 6,    -- Icy Veins
		[GetSpellInfo(106731)]  = 6,    -- Incarnation
		[GetSpellInfo(10060)]   = 6,    -- Power Infusion
		[GetSpellInfo(3045)]    = 6,    -- Rapid Fire
		[GetSpellInfo(48505)]   = 6,    -- Starfall
		[GetSpellInfo(34692)]   = 6,    -- The Beast Within
		-- immunities
		[GetSpellInfo(31821)]   = 7,    -- Devotion Aura
		[GetSpellInfo(115723)]  = 7,    -- Glyph of Ice Block
		[GetSpellInfo(8178)]    = 7,    -- Grounding Totem Effect
		[GetSpellInfo(131558)]  = 7,    -- Spiritwalker's Aegis
		[GetSpellInfo(104773)]  = 7,    -- Unending Resolve
		[GetSpellInfo(124488)]  = 7,    -- Zen Focus
		-- silences
		[GetSpellInfo(1330)]    = 8,    -- Garrote - Silence
		[GetSpellInfo(114237)]  = 8,    -- Glyph of Fae Silence
		[GetSpellInfo(111340)]  = 8,    -- Ice Ward (Root)
		[GetSpellInfo(55021)]   = 8,    -- Improved Counterspell
		[GetSpellInfo(115782)]  = 8,    -- Optical Blast
		[GetSpellInfo(15487)]   = 8,    -- Silence
		[GetSpellInfo(34490)]   = 8,    -- Silencing Shot
		[GetSpellInfo(116709)]  = 8,    -- Spear Hand Strike
		[GetSpellInfo(19647)]   = 8,    -- Spell Lock
		[GetSpellInfo(47476)]   = 8,    -- Strangulate
		-- disorients and stuns
		[GetSpellInfo(108194)]  = 9,    -- Asphyxiate
		[GetSpellInfo(89766)]   = 9,    -- Axe Toss
		[GetSpellInfo(90337)]   = 9,    -- Bad Manner
		[GetSpellInfo(127361)]  = 9,    -- Bear Hug (Windwalker Monk Symbiosis)
		[GetSpellInfo(105421)]  = 9,    -- Blinding Light
		[GetSpellInfo(100)]     = 9,    -- Charge
		[GetSpellInfo(119392)]  = 9,    -- Charging Ox Wave
		[GetSpellInfo(1833)]    = 9,    -- Cheap Shot
		[GetSpellInfo(122283)]  = 9,    -- Death Coil (Symbiosis)
		[GetSpellInfo(44572)]   = 9,    -- Deep Freeze
		[GetSpellInfo(99)]      = 9,    -- Disorienting Roar
		[GetSpellInfo(31661)]   = 9,    -- Dragon's Breath
		[GetSpellInfo(105593)]  = 9,    -- Fist of Justice
		[GetSpellInfo(47481)]   = 9,    -- Gnaw
		[GetSpellInfo(1776)]    = 9,    -- Gouge
		[GetSpellInfo(853)]     = 9,    -- Hammer of Justice
		[GetSpellInfo(88625)]   = 9,    -- Holy Word: Chastise
		[GetSpellInfo(19577)]   = 9,    -- Intimidation
		[GetSpellInfo(408)]     = 9,    -- Kidney Shot
		[GetSpellInfo(119381)]  = 9,    -- Leg Sweep
		[GetSpellInfo(126246)]  = 9,    -- Lullaby
		[GetSpellInfo(22570)]   = 9,    -- Maim
		[GetSpellInfo(5211)]    = 9,    -- Mighty Bash
		[GetSpellInfo(6789)]    = 9,    -- Mortal Coil
		[GetSpellInfo(50245)]   = 9,    -- Pin
		[GetSpellInfo(126355)]  = 9,    -- Paralyzing Quill
		[GetSpellInfo(9005)]    = 9,    -- Pounce
		[GetSpellInfo(64044)]   = 9,    -- Psychic Horror
		[GetSpellInfo(115001)]  = 9,    -- Remorseless Winter
		[GetSpellInfo(19503)]   = 9,    -- Scatter Shot
		[GetSpellInfo(46968)]   = 9,    -- Shockwave
		[GetSpellInfo(50519)]   = 9,    -- Sonic Blast
		[GetSpellInfo(118905)]  = 9,    -- Static Charge (Capacitor Totem Stun)
		[GetSpellInfo(107570)]  = 9,    -- Storm Bolt
		[GetSpellInfo(16979)]   = 9,    -- Wild Charge
		-- cc
		[GetSpellInfo(710)]     = 10,   -- Banish
		[GetSpellInfo(2094)]    = 10,   -- Blind
		[GetSpellInfo(33786)]   = 10,   -- Cyclone
		[GetSpellInfo(605)]     = 10,   -- Dominate Mind
		[GetSpellInfo(5782)]    = 10,   -- Fear
		[GetSpellInfo(55041)]   = 10,   -- Freezing Trap Effect
		[GetSpellInfo(1499)]    = 10,   -- Freezing Trap Effect
		[GetSpellInfo(3355)]    = 10,   -- Freezing Trap (Trap Launcher)
		[GetSpellInfo(60192)]   = 10,   -- Freezing Trap (Trap Launcher)
		[GetSpellInfo(51514)]   = 10,   -- Hex
		[GetSpellInfo(2637)]    = 10,   -- Hibernate
		[GetSpellInfo(5484)]    = 10,   -- Howl of Terror
		[GetSpellInfo(5246)]    = 10,   -- Intimidating Shout
		[GetSpellInfo(113004)]  = 10,   -- Intimidating Roar (Symbiosis)
		[GetSpellInfo(115268)]  = 10,   -- Mesmerize
		[GetSpellInfo(115078)]  = 10,   -- Paralysis
		[GetSpellInfo(118)]     = 10,   -- Polymorph
		[GetSpellInfo(61305)]   = 10,   -- Polymorph (Black Cat)
		[GetSpellInfo(28272)]   = 10,   -- Polymorph (Pig)
		[GetSpellInfo(61025)]   = 10,   -- Polymorph (Serpent)
		[GetSpellInfo(28271)]   = 10,   -- Polymorph (Turtle)
		[GetSpellInfo(8122)]    = 10,   -- Psychic Scream
		[GetSpellInfo(113792)]  = 10,   -- Psychic Terror (psyfiend)
		[GetSpellInfo(20066)]   = 10,   -- Repentance
		[GetSpellInfo(113724)]  = 10,   -- Ring of Frost
		[GetSpellInfo(6770)]    = 10,   -- Sap
		[GetSpellInfo(1513)]    = 10,   -- Scare Beast
		[GetSpellInfo(6358)]    = 10,   -- Seduction
		[GetSpellInfo(9484)]    = 10,   -- Shackle Undead
		[GetSpellInfo(19386)]   = 10,   -- Wyvern Sting
		-- Immunity
		[GetSpellInfo(48707)]   = 11,   -- Anti-Magic Shell
		[GetSpellInfo(46924)]   = 11,   -- Bladestorm
		[GetSpellInfo(110913)]  = 11,   -- Dark Bargain
		[GetSpellInfo(19263)]   = 11,   -- Deterrence
		[GetSpellInfo(47585)]   = 11,   -- Dispersion
		[GetSpellInfo(642)]     = 11,   -- Divine Shield
		[GetSpellInfo(45438)]   = 11,   -- Ice Block
		-- Drinking
		[GetSpellInfo(118358)]  = 12,   -- Drinking
	}, {
      __index = function(t, index) 
         if (index ~= nil) then
            return rawget(t, index)
         else
            return nil
         end            
      end
   })
   
   return auraTable
end
