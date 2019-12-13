
local GladiusMoP = _G.GladiusMoP
if not GladiusMoP then
  DEFAULT_CHAT_FRAME:AddMessage(format("Module %s requires GladiusMoP", "Tags"))
end
local L = GladiusMoP.L
local LSM

-- global functions
local strfind = string.find
local pairs = pairs
local strgsub = string.gsub
local strgmatch = string.gmatch
local strformat = string.format

local UnitName, UnitIsDeadOrGhost, LOCALIZED_CLASS_NAMES_MALE = UnitName, UnitIsDeadOrGhost, LOCALIZED_CLASS_NAMES_MALE
local UnitClass, UnitRace = UnitClass, UnitRace
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitPower, UnitPowerMax = UnitPower, UnitPowerMax

local Tags = GladiusMoP:NewModule("Tags", false, false, {
   tagsTexts = {
      ["HealthBar Left Text"] = {
         attachTo = "HealthBar",
         position = "LEFT",
         offsetX = 2,
         offsetY = 0,
         
         size = 11,
         color = { r = 1, g = 1, b = 1, a = 1 },
         
         text = "[name:status]",
      },
      ["HealthBar Right Text"] = {
         attachTo = "HealthBar",
         position = "RIGHT",
         offsetX = -2,
         offsetY = 0,
         
         size = 11,
         color = { r = 1, g = 1, b = 1, a = 1 },
         
         text = "[health:percentage]",
      },
      ["PowerBar Left Text"] = {
         attachTo = "PowerBar",
         position = "LEFT",
         offsetX = 2,
         offsetY = 0,
         
         size = 11,
         color = { r = 1, g = 1, b = 1, a = 1 },
         
         text = "[spec:short] [class:short]",
      },
      ["PowerBar Right Text"] = {
         attachTo = "PowerBar",
         position = "RIGHT",
         offsetX = -2,
         offsetY = 0,
         
         size = 11,
         color = { r = 1, g = 1, b = 1, a = 1 },
         
         text = "[power:short]/[maxpower:short]",
      },
       ["TargetBar Left Text"] = {
         attachTo = "TargetBar",
         position = "LEFT",
         offsetX = 2,
         offsetY = 0,
         
         size = 11,
         color = { r = 1, g = 1, b = 1, a = 1 },
         
         text = "[name:status]",
      },
      ["TargetBar Right Text"] = {
         attachTo = "TargetBar",
         position = "RIGHT",
         offsetX = -2,
         offsetY = 0,
         
         size = 11,
         color = { r = 1, g = 1, b = 1, a = 1 },
         
         text = "[health:short] / [maxhealth:short] ([health:percentage])",
      },
   },
})

function Tags:OnEnable()   
   LSM = GladiusMoP.LSM   
   
   self.version = 1
      
   -- frame
   if (not self.frame) then
      self.frame = {}
   end
   
   -- tags
   if (not GladiusMoP.db.tags or GladiusMoP.db.tagsVersion == nil or self.version > GladiusMoP.db.tagsVersion) then
      GladiusMoP.db.tags = self:GetTags()
      GladiusMoP.db.tagEvents = self:GetTagsEvents()
   end
   
   -- cached functions
   self.func = {}
   
   -- gather events
   self.events = {}
   
   for k,v in pairs(GladiusMoP.db.tagsTexts) do
      -- get tags
      for tag in v.text:gmatch("%[(.-)%]") do
         -- get events
         if (GladiusMoP.db.tagEvents[tag]) then         
            for event in GladiusMoP.db.tagEvents[tag]:gmatch("%S+") do
               if (not self.events[event]) then
                  self.events[event] = {}
               end
               
               self.events[event][k] = true
            end
         end
      end
   end
   
   -- register events
   for event in pairs(self.events) do
      if (strfind(event, "GLADIUSMOP")) then
         self:RegisterMessage(event, "OnMessage")
      else
         self:RegisterEvent(event, "OnEvent")
      end
   end
   
   GladiusMoP.db.tagsVersion = self.version
end

function Tags:OnDisable()
   self:UnregisterAllEvents()
   
   for unit in pairs(self.frame) do
      for text in pairs(self.frame[unit]) do
         self.frame[unit][text]:SetAlpha(0)
      end
   end
end

function Tags:GetAttachTo()
   return ""
end

function Tags:GetFrame(unit)
   return ""
end

function Tags:OnMessage(unit, event)
   if (not strfind(unit, "arena") or strfind(unit, "pet")) then return end
   
   if (self.events[event]) then
      -- update texts
      for text, _ in pairs(self.events[event]) do
         self:UpdateText(unit, text)
      end
   end
end

function Tags:OnEvent(event, unit)
   if (not strfind(unit, "arena") or strfind(unit, "pet")) then return end
   
   if (self.events[event]) then
      -- update texts
      for text, _ in pairs(self.events[event]) do
         self:UpdateText(unit, text)
      end
   end
end

function Tags:CreateFrame(unit, text)
   local button = GladiusMoP.buttons[unit]
   if (not button) then return end       
   
   -- create frame
   self.frame[unit][text] = button:CreateFontString("GladiusMoP" .. self.name .. unit .. text, "OVERLAY")
end

function Tags:UpdateText(unit, text)
   if (not self.frame[unit]) then return end   
   if (not self.frame[unit][text]) then return end

   -- tags
   if (not GladiusMoP.dbi.profile.tags) then
      GladiusMoP.dbi.profile.tags = self:GetTags()
      GladiusMoP.dbi.profile.tagEvents = self:GetTagsEvents()
   end
   
   -- set unit
   local unitParameter = unit
   
   local parent = self.frame[unit][text]:GetParent()
   if (parent and parent.unit) then
      unitParameter = parent.unit
   end

   -- update tag
   local tagText = GladiusMoP.db.tagsTexts[text].text
   
   for tag in strgmatch(GladiusMoP.db.tagsTexts[text].text, "%[(.-)%]") do
      if (GladiusMoP.db.tags[tag]) then
         local escapedText
         
         -- clear the tag, if unit does not exist
         if (not GladiusMoP.test and not UnitName(unitParameter)) then
            escapedText = ""
         else
            -- create function
            if (not self.func[tag]) then
               local func, error = loadstring("local strformat = string.format; return " .. GladiusMoP.db.tags[tag])
               self.func[tag] = func
            end
            
            -- escape return string
            local funcText = self.func[tag]()
            if (funcText) then            
               escapedText = strgsub(funcText(unitParameter) or "", "%%", "%%%%")
            else
               escapedText = ""
            end
         end   
         
         -- replace tag
         tagText = strgsub(tagText, "%[" .. tag .. "%]", escapedText)
      end
   end

   self.frame[unit][text]:SetText(tagText or "")
end

function Tags:Update(unit) 
   if (not self.frame[unit]) then
      self.frame[unit] = {}
   end
   
   for text, _ in pairs(GladiusMoP.db.tagsTexts) do
      local module = GladiusMoP:GetModule(GladiusMoP.db.tagsTexts[text].attachTo)
   
      if (module and module.IsEnabled and module.frame and module.frame[unit]) then   
         -- create frame
         if (not self.frame[unit][text]) then 
            self:CreateFrame(unit, text)
         end
         
         -- update frame   
         self.frame[unit][text]:ClearAllPoints()
         self.frame[unit][text]:SetPoint(GladiusMoP.db.tagsTexts[text].position, module.frame[unit], GladiusMoP.db.tagsTexts[text].position, 
            GladiusMoP.db.tagsTexts[text].offsetX, GladiusMoP.db.tagsTexts[text].offsetY)
            
         self.frame[unit][text]:SetParent(module.frame[unit])
         
         self.frame[unit][text]:SetFont(LSM:Fetch(LSM.MediaType.FONT, GladiusMoP.db.globalFont), (GladiusMoP.db.useGlobalFontSize and GladiusMoP.db.globalFontSize or GladiusMoP.db.tagsTexts[text].size))
         self.frame[unit][text]:SetTextColor(GladiusMoP.db.tagsTexts[text].color.r, GladiusMoP.db.tagsTexts[text].color.g, GladiusMoP.db.tagsTexts[text].color.b, GladiusMoP.db.tagsTexts[text].color.a)
         
         self.frame[unit][text]:SetShadowOffset(1, -1)
         self.frame[unit][text]:SetShadowColor(0, 0, 0, 1)
         
         -- update text
         self:UpdateText(unit, text)
         
         -- hide
         self.frame[unit][text]:SetAlpha(0)
      end
   end
end

function Tags:Show(unit)
   if (not self.frame[unit]) then
      self.frame[unit] = {}
   end
   
   -- update text
   for text, _ in pairs(GladiusMoP.db.tagsTexts) do      
      self:UpdateText(unit, text)
   end
   
   -- show
   for _, text in pairs(self.frame[unit]) do
      text:SetAlpha(1)
   end
end

function Tags:Reset(unit)   
	if (not self.frame[unit]) then
      self.frame[unit] = {}
   end
    
   -- hide
   for _, text in pairs(self.frame[unit]) do
      text:SetAlpha(0)
   end
end

function Tags:Test(unit)   
   -- test
end

local function getOption(info)
   local key = info[#info - 2]
   return GladiusMoP.dbi.profile.tagsTexts[key][info[#info]]
end

local function setOption(info, value)
   local key = info[#info - 2]
   GladiusMoP.dbi.profile.tagsTexts[key][info[#info]] = value
   GladiusMoP:UpdateFrame()
end

local function getColorOption(info)
   local key = info[#info - 2]
   return GladiusMoP.dbi.profile.tagsTexts[key][info[#info]].r, GladiusMoP.dbi.profile.tagsTexts[key][info[#info]].g, 
      GladiusMoP.dbi.profile.tagsTexts[key][info[#info]].b, GladiusMoP.dbi.profile.tagsTexts[key][info[#info]].a
end

local function setColorOption(info, r, g, b, a) 
   local key = info[#info - 2]
   GladiusMoP.dbi.profile.tagsTexts[key][info[#info]].r, GladiusMoP.dbi.profile.tagsTexts[key][info[#info]].g, 
   GladiusMoP.dbi.profile.tagsTexts[key][info[#info]].b, GladiusMoP.dbi.profile.tagsTexts[key][info[#info]].a = r, g, b, a
   GladiusMoP:UpdateFrame()
end

function Tags:GetOptions()
   -- tags
   if (not GladiusMoP.dbi.profile.tags) then
      GladiusMoP.dbi.profile.tags = self:GetTags()
      GladiusMoP.dbi.profile.tagEvents = self:GetTagsEvents()
   end

   -- add text values
   self.addTextAttachTo = "HealthBar"
   self.addTextName = ""
   
   -- add tag values
   self.addTagName = ""

   local options = {
      textList = {  
         type="group",
         name=L["Texts"],
         order=1,
         args = {
            add = {  
               type="group",
               name=L["Add text"],
               inline=true,
               order=1,
               args = {
                  name = {
                     type="input",
                     name=L["Name"],
                     desc=L["Name of the text element"],
                     get=function(info)
                        return self.addTextName
                     end,
                     set=function(info, value)
                        self.addTextName = value
                     end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  attachTo = {
                     type="select",
                     name=L["Text Attach To"],
                     desc=L["Attach text to module bar"],
                     values=function()
                        local t = {}
                        
                        for moduleName, module in pairs(GladiusMoP.modules) do
                           if (module.isBarOption) then
                              t[moduleName] = moduleName
                           end
                        end
                        
                        return t
                     end,
                     get=function(info)
                        return self.addTextAttachTo
                     end,
                     set=function(info, value)
                        self.addTextAttachTo = value
                     end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=10,
                  },
                  add = {
                     type="execute",
                     name=L["Add Text"],
                     func=function()
                        local text = self.addTextAttachTo .. " " .. self.addTextName
                        
                        if (self.addTextName ~= "" and not GladiusMoP.db.tagsTexts[text]) then                           
                           -- add to db
                           GladiusMoP.db.tagsTexts[text] = {
                              attachTo = self.addTextAttachTo,
                              position = "LEFT",
                              offsetX = 0,
                              offsetY = 0,
                              
                              size = 11,
                              color = { r = 1, g = 1, b = 1, a = 1 },
                              
                              text = ""
                           }
                           
                           -- add to options
                           GladiusMoP.options.args[self.name].args.textList.args[text] = self:GetTextOptionTable(text, order)
   
                           -- set tags
                           GladiusMoP.options.args[self.name].args.textList.args[text].args.tag.args = self.optionTags
                           
                           -- update
                           GladiusMoP:UpdateFrame()
                        end
                     end,
                     order=15,
                  },
               },
            },      
         },
      },      
      tagList = {  
         type="group",
         name=L["Tags"],
         hidden=function() return not GladiusMoP.db.advancedOptions end,
         order=2,
         args = {
            add = {  
               type="group",
               name=L["Add tag"],
               inline=true,
               order=1,
               args = {
                  name = {
                     type="input",
                     name=L["Name"],
                     desc=L["Name of the tag"],
                     get=function(info)
                        return self.addTagName
                     end,
                     set=function(info, value)
                        self.addTagName = value
                     end,
                     disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                     order=5,
                  },
                  add = {
                     type="execute",
                     name=L["Add Tag"],
                     func=function()
                        if (self.addTagName ~= "" and not GladiusMoP.db.tags[self.addTagName]) then                           
                           -- add to db
                           GladiusMoP.db.tags[self.addTagName] = [[function(unit)
                           end]]
                           GladiusMoP.db.tagEvents[self.addTagName] = ""
                           
                           -- add to options
                           GladiusMoP.options.args[self.name].args.tagList.args[self.addTagName] = self:GetTagOptionTable(self.addTagName, order)
                           
                           -- add to text option tags
                           for text, v in pairs(GladiusMoP.options.args[self.name].args.textList.args) do
                              if (v.args.tag) then
                                 local tag = self.addTagName
                                 local tagName = L[tag .. "Tag"] ~= tag .. "Tag" and L[tag .. "Tag"] or strformat(L["Tag: %s"], tag) 
                              
                                 GladiusMoP.options.args[self.name].args.textList.args[text].args.tag.args[tag] = {
                                    type="toggle",
                                    name=tagName,
                                    get=function(info) 
                                       local key = info[#info - 2]
                                       
                                       -- check if the tag is in the text
                                       if (strfind(GladiusMoP.dbi.profile.tagsTexts[key].text, "%[" .. info[#info] .. "%]")) then
                                          return true
                                       else
                                          return false
                                       end
                                    end,
                                    set=function(info, v) 
                                       local key = info[#info - 2]
                                       
                                       -- add/remove tag to the text               
                                       if (not v) then
                                          GladiusMoP.dbi.profile.tagsTexts[key].text = strgsub(GladiusMoP.dbi.profile.tagsTexts[key].text, "%[" .. info[#info] .. "%]", "")
                                          
                                          -- trim right
                                          GladiusMoP.dbi.profile.tagsTexts[key].text = strgsub(GladiusMoP.dbi.profile.tagsTexts[key].text, "^(.-)%s*$", "%1")
                                       else
                                          GladiusMoP.dbi.profile.tagsTexts[key].text = GladiusMoP.dbi.profile.tagsTexts[key].text .. " [" .. info[#info] .. "]"
                                       end
                                       
                                       -- update
                                       GladiusMoP:UpdateFrame()
                                    end,
                                    order=order,
                                 }
                              end
                           end  
                           
                           -- update
                           GladiusMoP:UpdateFrame()
                        end
                     end,
                     order=10,
                  },
               },
            },
         },
      },
   }

   -- text option tags
   self.optionTags = {
      text = {
         type="input",
         name=L["Text"],
         desc=L["Text to be displayed"],
         disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
         width="double",
         order=1,
      },
   }
   
   local order = 2
   for tag, _ in pairs(GladiusMoP.dbi.profile.tags) do
      local tagName = L[tag .. "Tag"] ~= tag .. "Tag" and L[tag .. "Tag"] or strformat(L["Tag: %s"], tag) 
   
      self.optionTags[tag] = {
         type="toggle",
         name=tagName,
         get=function(info) 
            local key = info[#info - 2]
            
            -- check if the tag is in the text
            if (strfind(GladiusMoP.dbi.profile.tagsTexts[key].text, "%[" .. info[#info] .. "%]")) then
               return true
            else
               return false
            end
         end,
         set=function(info, v) 
            local key = info[#info - 2]
            
            -- add/remove tag to the text               
            if (not v) then
               GladiusMoP.dbi.profile.tagsTexts[key].text = strgsub(GladiusMoP.dbi.profile.tagsTexts[key].text, "%[" .. info[#info] .. "%]", "")
               
               -- trim right
               GladiusMoP.dbi.profile.tagsTexts[key].text = strgsub(GladiusMoP.dbi.profile.tagsTexts[key].text, "^(.-)%s*$", "%1")
            else
               GladiusMoP.dbi.profile.tagsTexts[key].text = GladiusMoP.dbi.profile.tagsTexts[key].text .. " [" .. info[#info] .. "]"
            end
            
            -- update
            GladiusMoP:UpdateFrame()
         end,
         order=order,
      }
      
      order = order + 1      
   end
   
   -- texts
   order = 1
   for text, _ in pairs(GladiusMoP.dbi.profile.tagsTexts) do 
      options.textList.args[text] = self:GetTextOptionTable(text, order)
   
      -- set tags
      options.textList.args[text].args.tag.args = self.optionTags
      
      order = order + 1
   end
   
   -- tags
   order = 1
   for tag, _ in pairs(GladiusMoP.dbi.profile.tags) do 
      options.tagList.args[tag] = self:GetTagOptionTable(tag, order)      
      order = order + 1
   end   

   return options
end

function Tags:GetTextOptionTable(text, order)
   return {  
      type="group",
      name=text,
      childGroups="tree",
      get=getOption,
      set=setOption,
      order=order,
      args = {
         delete = {
            type="execute",
            name=L["Delete Text"],
            func=function()
               -- remove from db
               GladiusMoP.db.tagsTexts[text] = nil
               
               -- remove from options
               GladiusMoP.options.args[self.name].args.textList.args[text] = nil
               
               -- update
               GladiusMoP:UpdateFrame()
            end,
            order=1,
         },
         tag = {  
            type="group",
            name=L["Tag"],
            desc=L["Tag settings"],  
            inline=true,                
            order=2,
            args = {},
         },
         text = {  
            type="group",
            name=L["Text"],
            desc=L["Text settings"],  
            inline=true,                
            order=3,
            args = {
               color = {
                  type="color",
                  name=L["Text Color"],
                  desc=L["Text color of the text"],
                  hasAlpha=true,
                  get=getColorOption,
                  set=setColorOption,
                  disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                  order=5,
               },
               size = {
                  type="range",
                  name=L["Text Size"],
                  desc=L["Text size of the text"],
                  min=1, max=20, step=1,
                  disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] or GladiusMoP.db.useGlobalFontSize end,
                  order=10,
               },                  
            },
         },
         position = {  
            type="group",
            name=L["Position"],
            desc=L["Position settings"],  
            inline=true,             
            order=4,
            args = {
               position = {
                  type="select",
                  name=L["Text Align"],
                  desc=L["Text align of the text"],
                  values={ ["LEFT"] = L["LEFT"], ["CENTER"] = L["CENTER"], ["RIGHT"] = L["RIGHT"] },
                  disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                  width="double",
                  order=5,
               },
              offsetX = {
                  type="range",
                  name=L["Text Offset X"],
                  desc=L["X offset of the text"],
                  min=-100, max=100, step=1,
                  disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                  hidden=function() return not GladiusMoP.db.advancedOptions end,
                  order=10,
               },
               offsetY = {
                  type="range",
                  name=L["Text Offset Y"],
                  desc=L["Y offset of the text"],
                  disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                  hidden=function() return not GladiusMoP.db.advancedOptions end,
                  min=-100, max=100, step=1,
                  order=15,
               },
            },
         },
      },
   }  
end

function Tags:GetTagOptionTable(tag, order)
   local tagName = L[tag .. "Tag"] ~= tag .. "Tag" and L[tag .. "Tag"] or strformat(L["Tag: %s"], tag) 

   return {  
      type="group",
      name=tagName,
      childGroups="tree",
      order=order,
      args = {
         delete = {
            type="execute",
            name=L["Delete Tag"],
            func=function()
               -- remove from db
               GladiusMoP.db.tags[tag] = nil
               GladiusMoP.db.tagEvents[tag] = nil
               
               -- remove from options
               GladiusMoP.options.args[self.name].args.tagList.args[tag] = nil
               
               -- remove from text option tags
               for text, v in pairs(GladiusMoP.options.args[self.name].args.textList.args) do
                  if (v.args.tag and v.args.tag.args[tag]) then
                     GladiusMoP.options.args[self.name].args.textList.args[text].args.tag.args[tag] = nil
                  end
               end               
               
               -- update
               GladiusMoP:UpdateFrame()
            end,
            order=1,
         },
         tag = {  
            type="group",
            name=L["Tag"],
            desc=L["Tag settings"],  
            inline=true,                
            order=2,
            args = {
               name = {
                  type="input",
                  name=L["Name"],
                  desc=L["Name of the tag"],
                  get=function(info)
                     local key = info[#info - 2]
                     return key
                  end,
                  set=function(info, value)
                     local key = info[#info - 2]
                     
                     -- db
                     GladiusMoP.db.tags[value] = GladiusMoP.db.tags[key]
                     GladiusMoP.db.tagEvents[value] = GladiusMoP.db.tagEvents[key]
                                          
                     GladiusMoP.db.tags[key] = nil
                     GladiusMoP.db.tagEvents[key] = nil
                     
                     -- options
                     GladiusMoP.options.args[self.name].args.tagList.args[key] = nil                     
                     GladiusMoP.options.args[self.name].args.tagList.args[value] = self:GetTagOptionTable(value, order) 
                     
                     -- update
                     GladiusMoP:UpdateFrame()                   
                  end,
                  disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                  width="double",
                  order=5,
               },
               events = {
                  type="input",
                  name=L["Events"],
                  desc=L["Events which update the tag"],
                  get=function(info)
                     local key = info[#info - 2]
                     return GladiusMoP.db.tagEvents[key]
                  end,
                  set=function(info, value)
                     local key = info[#info - 2]
                     GladiusMoP.db.tagEvents[key] = value
                     
                     -- update
                     GladiusMoP:UpdateFrame() 
                  end,
                  disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                  width="double",
                  order=10,
               },
               func = {
                  type="input",
                  name=L["Function"],
                  get=function(info)
                     local key = info[#info - 2]                     
                     return GladiusMoP.db.tags[key]
                  end,
                  set=function(info, value)
                     local key = info[#info - 2]
                     GladiusMoP.db.tags[key] = value
                     
                     -- delete cached function
                     self.func[key] = nil
                     
                     -- update
                     GladiusMoP:UpdateFrame() 
                  end,
                  disabled=function() return not GladiusMoP.dbi.profile.modules[self.name] end,
                  width="double",
                  multiline=true,
                  order=15,
               },
            },
         },
      },
   }  
end

function Tags:GetTags()
   return {
      ["name"] = [[function(unit)
         return UnitName(unit) or unit
      end]],
      ["name:status"] = [[function(unit)
         return UnitIsDeadOrGhost(unit) and GladiusMoP.L["DEAD"] or (UnitName(unit) or unit)
      end]],
      ["class"] = [[function(unit)
         return not GladiusMoP.test and UnitClass(unit) or LOCALIZED_CLASS_NAMES_MALE[GladiusMoP.testing[unit].unitClass]
      end]],
      ["class:short"] = [[function(unit)
         return not GladiusMoP.test and GladiusMoP.L[UnitClass(unit) .. ":short"] or GladiusMoP.L[LOCALIZED_CLASS_NAMES_MALE[GladiusMoP.testing[unit].unitClass] .. ":short"]
      end]],
      ["race"] = [[function(unit)
         return not GladiusMoP.test and UnitRace(unit) or GladiusMoP.testing[unit].unitRace
      end]],
      ["spec"] = [[function(unit)
         return GladiusMoP.test and GladiusMoP.testing[unit].unitSpec or GladiusMoP.buttons[unit].spec
      end]],
      ["spec:short"] = [[function(unit)
         local spec = GladiusMoP.test and GladiusMoP.testing[unit].unitSpec or GladiusMoP.buttons[unit].spec
         if (spec == nil or spec == "") then 
            return "" 
         end
         
         return GladiusMoP.L[spec .. ":short"]
      end]],
           
      ["health"] = [[function(unit)
         return not GladiusMoP.test and UnitHealth(unit) or GladiusMoP.testing[unit].health
      end]],
      ["maxhealth"] = [[function(unit)
         return not GladiusMoP.test and UnitHealthMax(unit) or GladiusMoP.testing[unit].maxHealth
      end]],
      ["health:short"] = [[function(unit)
         local health = not GladiusMoP.test and UnitHealth(unit) or GladiusMoP.testing[unit].health
      
         if (health > 999) then
            return strformat("%.1fk", (health / 1000))
         else
            return health
         end
      end]],
      ["maxhealth:short"] = [[function(unit)
         local health = not GladiusMoP.test and UnitHealthMax(unit) or GladiusMoP.testing[unit].maxHealth
      
         if (health > 999) then
            return strformat("%.1fk", (health / 1000))
         else
            return health
         end
      end]],
      ["health:percentage"] = [[function(unit)
         local health = not GladiusMoP.test and UnitHealth(unit) or GladiusMoP.testing[unit].health
         local maxHealth = not GladiusMoP.test and UnitHealthMax(unit) or GladiusMoP.testing[unit].maxHealth
         
         return strformat("%.1f%%", (health / maxHealth * 100))
      end]],
      
      ["power"] = [[function(unit)
         return not GladiusMoP.test and UnitPower(unit) or GladiusMoP.testing[unit].power
      end]],
      ["maxpower"] = [[function(unit)
         return not GladiusMoP.test and UnitPowerMax(unit) or GladiusMoP.testing[unit].maxPower
      end]],
      ["power:short"] = [[function(unit)
         local power = not GladiusMoP.test and UnitPower(unit) or GladiusMoP.testing[unit].power
      
         if (power > 999) then
            return strformat("%.1fk", (power / 1000))
         else
            return power
         end
      end]],
      ["maxpower:short"] = [[function(unit)
         local power = not GladiusMoP.test and UnitPowerMax(unit) or GladiusMoP.testing[unit].maxPower
      
         if (power > 999) then
            return strformat("%.1fk", (power / 1000))
         else
            return power
         end
      end]],
      ["power:percentage"] = [[function(unit)
         local power = not GladiusMoP.test and UnitPower(unit) or GladiusMoP.testing[unit].power
         local maxPower = not GladiusMoP.test and UnitPowerMax(unit) or GladiusMoP.testing[unit].maxPower
         
         return strformat("%.1f%%", (power / maxPower * 100))
      end]],
   }
end

function Tags:GetTagsEvents()
   return {
      ["name"] = "UNIT_NAME_UPDATE",
      ["name:status"] = "UNIT_NAME_UPDATE UNIT_HEALTH",
      ["class"] = "UNIT_NAME_UPDATE",
      ["class:short"] = "UNIT_NAME_UPDATE", 
      ["race"] = "UNIT_NAME_UPDATE", 
      ["spec"] = "UNIT_NAME_UPDATE GLADIUSMOP_SPEC_UPDATE", 
      ["spec:short"] = "UNIT_NAME_UPDATE GLADIUSMOP_SPEC_UPDATE", 
           
      ["health"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE",
      ["maxhealth"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE",
      ["health:short"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE",
      ["maxhealth:short"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE",
      ["health:percentage"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_NAME_UPDATE",
      
      ["power"] = "UNIT_POWER UNIT_DISPLAYPOWER UNIT_NAME_UPDATE",
      ["maxpower"] = "UNIT_MAXPOWER UNIT_DISPLAYPOWER UNIT_NAME_UPDATE",
      ["power:short"] = "UNIT_POWER UNIT_DISPLAYPOWER UNIT_NAME_UPDATE",
      ["maxpower:short"] = "UNIT_MAXPOWER UNIT_DISPLAYPOWER UNIT_NAME_UPDATE",
      ["power:percentage"] = "UNIT_POWER UNIT_MAXPOWER UNIT_DISPLAYPOWER UNIT_NAME_UPDATE",
   }
end
