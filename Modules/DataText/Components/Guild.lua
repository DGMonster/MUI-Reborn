-- luacheck: ignore MayronUI self 143 631
local _G = _G
local MayronUI = _G.MayronUI
local tk, db, em, _, obj, L = MayronUI:GetCoreComponents()

local strsplit, unpack = _G.strsplit, _G.unpack
local ChatFrame1EditBox, ChatMenu_SetChatType, ChatFrame1 =
  _G.ChatFrame1EditBox, _G.ChatMenu_SetChatType, _G.ChatFrame1

local IsInGuild = _G.IsInGuild
local GetNumGuildMembers = _G.GetNumGuildMembers
local GetGuildRosterInfo = _G.GetGuildRosterInfo
local IsTrialAccount = _G.IsTrialAccount
local string = _G.string
local math = _G.math

-- Guild frame toggle handling
local LocalToggleGuildFrame = _G.ToggleGuildFrame

if tk:IsBCClassic() or tk:IsWrathClassic() then
  LocalToggleGuildFrame = function() _G.ToggleFriendsFrame(3) end
elseif tk:IsClassic() then
  LocalToggleGuildFrame = function() _G.ToggleFriendsFrame(1) end
end

-- Retail / Classic safe GuildRoster
local GuildRoster =
  _G.GuildRoster or
  (_G.C_GuildInfo and _G.C_GuildInfo.GuildRoster)

-- =====================================================
-- Module
-- =====================================================
local Guild = obj:CreateClass("Guild")

db:AddToDefaults("profile.datatext.guild", {
  showSelf = true,
  showTooltips = true
})

-- =====================================================
-- Tooltip
-- =====================================================
local function ButtonOnEnter(self)
  if not IsInGuild() then
    GameTooltip:Hide()
    return
  end

  local r, g, b = tk:GetThemeColor()
  GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 2)
  GameTooltip:SetText(L["Commands"] .. ":")

  GameTooltip:AddDoubleLine(
    tk.Strings:SetTextColorByTheme(L["Left Click:"]),
    L["Show Guild Members"],
    r, g, b, 1, 1, 1
  )

  GameTooltip:AddDoubleLine(
    tk.Strings:SetTextColorByTheme(L["Right Click:"]),
    L["Toggle Guild Pane"],
    r, g, b, 1, 1, 1
  )

  GameTooltip:Show()
end

-- =====================================================
-- Label creation (menu)
-- =====================================================
local CreateLabel
do
  local onLabelClickFunc

  local function OpenWhisper(target)
    ChatFrame1EditBox:SetAttribute("tellTarget", target)

    if ChatMenu_SetChatType then
      ChatMenu_SetChatType(ChatFrame1, "SMART_WHISPER")
    elseif _G.ChatFrameUtil and _G.ChatFrameUtil.SendTell then
      _G.ChatFrameUtil.SendTell(target, ChatFrame1)
    elseif _G.ChatFrame_SendTell then
      _G.ChatFrame_SendTell(target, ChatFrame1)
    elseif _G.ChatFrame_OpenChat then
      _G.ChatFrame_OpenChat("/w " .. target .. " ", ChatFrame1)
    else
      ChatFrame1EditBox:Show()
      ChatFrame1EditBox:SetFocus()
    end
  end

  local function LabelOnEnter(self)
    if not self.guildRosterInfo then return end

    local fullName, rank, _, _, _, zone, note, _, _, _, classFile, achievementPoints =
      unpack(self.guildRosterInfo)

    if not fullName then return end

    fullName = strsplit("-", fullName)

    GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 2)
    GameTooltip:AddLine(
      tk.Strings:SetTextColorByClassFileName(fullName, classFile)
    )

    if zone then
      GameTooltip:AddDoubleLine(L["Zone"] .. ":", zone, 1, 1, 1)
    end

    if rank then
      GameTooltip:AddDoubleLine(L["Rank"] .. ":", rank, 1, 1, 1)
    end

    if note and #note > 0 then
      GameTooltip:AddDoubleLine(L["Notes"] .. ":", note, 1, 1, 1)
    end

    if tk:IsRetail() and achievementPoints then
      GameTooltip:AddDoubleLine(
        L["Achievement Points"] .. ":",
        achievementPoints,
        1, 1, 1
      )
    end

    GameTooltip:Show()
  end

  function CreateLabel(parent, width, slideController, showTooltips)
    local label = tk:CreateFrame("Button", parent)

    label.name = label:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label.name:SetPoint("LEFT", 6, 0)
    label.name:SetWidth(width - 10)
    label.name:SetJustifyH("LEFT")
    label.name:SetWordWrap(false)

    if showTooltips then
      label:SetScript("OnEnter", LabelOnEnter)
      label:SetScript("OnLeave", tk.HandleTooltipOnLeave)
    end

    if not onLabelClickFunc then
      onLabelClickFunc = function(self)
        if not self.id then return end
        OpenWhisper(self.id)
        slideController:Start(slideController.Static.FORCE_RETRACT)
      end
    end

    label:SetScript("OnClick", onLabelClickFunc)
    return label
  end
end

-- =====================================================
-- Registration
-- =====================================================
MayronUI:Hook("DataTextModule", "OnInitialize", function(self)
  self:RegisterComponentClass("guild", Guild)
end)

function Guild:__Construct(data, settings, dataTextModule, slideController)
  data.settings = settings
  data.slideController = slideController

  self.MenuContent = tk:CreateFrame("Frame")
  self.MenuLabels = obj:PopTable()
  self.TotalLabelsShown = 0

  self.HasLeftMenu = true
  self.HasRightMenu = false
  self.Button = dataTextModule:CreateDataTextButton()
end

function Guild:IsEnabled(data)
  return data.enabled
end

function Guild:SetEnabled(data, enabled)
  data.enabled = enabled

  local listenerID = "DataText_GuildMembers_OnChange"

  if enabled then
    if not em:GetEventListenerByID(listenerID) then
      em:CreateEventListenerWithID(listenerID, function()
        if self.Button then
          self:Update()
        end
      end):RegisterEvent("GUILD_ROSTER_UPDATE")
    else
      em:EnableEventListeners(listenerID)
    end

    self.Button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    self.Button:SetScript("OnEnter", ButtonOnEnter)
    self.Button:SetScript("OnLeave", tk.HandleTooltipOnLeave)
  else
    em:DisableEventListeners(listenerID)
  end
end

-- =====================================================
-- UPDATE (Datatext)
-- =====================================================
function Guild:Update(data, refreshSettings)
  if refreshSettings then
    data.settings:Refresh()
  end

  if not IsInGuild() then
    self.Button:SetText(L["No Guild"])
    return
  end

  if GuildRoster then
    GuildRoster() -- Retail-safe refresh
  end

  local total, online, onlineAndMobile = GetNumGuildMembers()
  online = tonumber(online) or 0
  onlineAndMobile = tonumber(onlineAndMobile) or online

  if not data.settings.showSelf then
    onlineAndMobile = math.max(0, onlineAndMobile - 1)
  end

  local label = tk.Strings.Empty
  local hideLabel =
    obj:IsTable(data.settings.labels)
    and obj:IsTable(data.settings.labels.hidden)
    and data.settings.labels.hidden.guild

  if not hideLabel then
    label = data.settings.labels.guild .. ": "
  end

  self.Button:SetText(
    string.format("%s|cffffffff%u|r", label, onlineAndMobile)
  )
end

-- =====================================================
-- CLICK (menu)
-- =====================================================
function Guild:Click(data, button)
  if not IsInGuild() then return true end

  if button == "RightButton" then
    LocalToggleGuildFrame()
    return
  end

  local shown = 0
  local playerName = tk:GetPlayerKey()

  local memberCount = GetNumGuildMembers()
  memberCount = tonumber(memberCount) or 0

  for i = 1, memberCount do
    local fullName, _, _, level, _, _, _, _, online, status, classFile =
      GetGuildRosterInfo(i)

    if online and fullName and (data.settings.showSelf or fullName ~= playerName) then
      shown = shown + 1

      local label =
        self.MenuLabels[shown] or
        CreateLabel(
          self.MenuContent,
          data.settings.popup.width,
          data.slideController,
          data.settings.showTooltips
        )

      self.MenuLabels[shown] = label
      label.id = fullName
      label.guildRosterInfo = { GetGuildRosterInfo(i) }

      fullName = strsplit("-", fullName)

      local state = ""
      if status == 1 then
        state = " |cffffe066[AFK]|r"
      elseif status == 2 then
        state = " |cffff3333[DND]|r"
      end

      label.name:SetText(
        string.format(
          "%s%s %s",
          tk.Strings:SetTextColorByClassFileName(fullName, classFile),
          state,
          level or ""
        )
      )
    end
  end

  self.TotalLabelsShown = shown
end
