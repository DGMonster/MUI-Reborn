-- luacheck: ignore MayronUI self 143
local _G = _G;
local MayronUI, table = _G.MayronUI, _G.table;
local tk, _, em, _, _, L = MayronUI:GetCoreComponents();
local obj = _G.MayronObjects:GetFramework();
local SHOW_TALENT_LEVEL = _G.SHOW_TALENT_LEVEL or 10;
local isMistsClassic = _G.math.floor(_G.select(4, _G.GetBuildInfo()) / 10000) == 5;

---@class ChatFrame
local _, C_ChatModule = MayronUI:ImportModule("ChatModule");
local C_ChatFrame = obj:Import("MayronUI.ChatModule.ChatFrame");

local LoadAddOn, IsTrialAccount, IsInGuild, UnitLevel, UnitInBattleground =
_G.LoadAddOn, _G.IsTrialAccount, _G.IsInGuild, _G.UnitLevel,
_G.UnitInBattleground;

local InCombatLockdown, ipairs = _G.InCombatLockdown, _G.ipairs;
local ToggleGuildFrame;

if (tk:IsRetail()) then
  ToggleGuildFrame = _G.ToggleGuildFrame;
else
  local ToggleFriendsFrame = _G.ToggleFriendsFrame;
  ToggleGuildFrame = function()
    ToggleFriendsFrame(2)
  end
end

-- GLOBALS:
--[[ luacheck: ignore
ToggleCharacter ContainerFrame1 ToggleBackpack OpenAllBags ToggleFrame SpellBookFrame PlayerTalentFrame MacroFrame
ToggleFriendsFrame ToggleHelpFrame TogglePVPUI ToggleAchievementFrame ToggleCalendar ToggleQuestLog
ToggleLFDParentFrame ToggleRaidFrame ToggleEncounterJournal ToggleCollectionsJournal ToggleWorldMap
ToggleWorldStateScoreFrame TalentFrame ToggleLFGParentFrame
]]

local buttonKeys = {
  Character = L["Character"];
  Bags = L["Bags"];
  Friends = L["Friends"];
  Guild = L["Guild"];
  HelpMenu = L["Help Menu"];
  SpellBook = L["Spell Book"];
  Talents = L["Talents"];
  Raid = L["Raid"];
  Macros = L["Macros"];
  WorldMap = L["World Map"];
  QuestLog = L["Quest Log"];
  Reputation = L["Reputation"];
  PVPScore = L["PVP Score"];
};

if (not tk:IsRetail()) then
  C_ChatModule.Static.ButtonNames = {
    L["Character"]; L["Bags"]; L["Friends"]; L["Guild"]; L["Help Menu"];
    L["Spell Book"]; L["Talents"]; L["Raid"]; L["Macros"]; L["World Map"];
    L["Quest Log"]; L["Reputation"]; L["PVP Score"]; L["Skills"];
  };

  if (isMistsClassic) then
    C_ChatModule.Static.ButtonNames[#C_ChatModule.Static.ButtonNames] = L["LFD"];
    buttonKeys.LFD = L["LFD"];
  else
    buttonKeys.Skills = L["Skills"];
  end

  if (tk:IsWrathClassic()) then
    table.insert(C_ChatModule.Static.ButtonNames, 8, L["Achievements"]);
    table.insert(C_ChatModule.Static.ButtonNames, 9, L["Glyphs"]);
    table.insert(C_ChatModule.Static.ButtonNames, 10, L["Calendar"]);
    table.insert(C_ChatModule.Static.ButtonNames, 11, L["Currency"]);
    table.insert(C_ChatModule.Static.ButtonNames, 12, L["LFG"]);

    buttonKeys.Currency = L["Currency"];
    buttonKeys.Achievements = L["Achievements"];
    buttonKeys.Glyphs = L["Glyphs"];
    buttonKeys.Calendar = L["Calendar"];
    buttonKeys.LFG = L["LFG"];
  end
else
  C_ChatModule.Static.ButtonNames = {
    L["Character"]; L["Bags"]; L["Friends"]; L["Guild"]; L["Help Menu"];
    L["PVP"]; L["Spell Book"]; L["Talents"]; L["Achievements"];
    L["Calendar"]; L["LFD"]; L["Raid"]; L["Encounter Journal"];
    L["Collections Journal"]; L["Macros"]; L["World Map"]; L["Quest Log"];
    L["Reputation"]; L["PVP Score"]; L["Currency"];
  };

  buttonKeys.PVP = L["PVP"];
  buttonKeys.Achievements = L["Achievements"];
  buttonKeys.Calendar = L["Calendar"];
  buttonKeys.LFD = L["LFD"];
  buttonKeys.Currency = L["Currency"];
  buttonKeys.EncounterJournal = L["Encounter Journal"];
  buttonKeys.CollectionsJournal = L["Collections Journal"];
end

local clickHandlers = {};
local foreverSecureButtons = setmetatable({}, { __mode = "k" });

local function SetForeverSecureAction(button)
  if (not tk:IsForever()) then
    return;
  end

  local buttonText = button:GetText();
  button:SetAttribute("type", nil);
  button:SetAttribute("clickbutton", nil);
  button:SetAttribute("macrotext", nil);
  -- Forever's protected menu bindings fire on key/button down. Triggering the
  -- secure proxy on release is silently ignored by the protected Blizzard UI.
  button:RegisterForClicks("AnyDown");

  if (buttonText == buttonKeys.Character) then
    button:SetAttribute("type", "macro");
    button:SetAttribute("macrotext", "/click CharacterMicroButton");
  elseif (buttonText == buttonKeys.Reputation) then
    button:SetAttribute("type", "macro");
    button:SetAttribute("macrotext", "/click CharacterMicroButton\n/click CharacterFrameModeTab2");
  elseif (buttonText == buttonKeys.LFD) then
    button:SetAttribute("type", "macro");
    button:SetAttribute("macrotext", "/click LFDMicroButton");
  end
end

local function RefreshForeverSecureActions()
  if (not tk:IsForever() or InCombatLockdown()) then
    return;
  end

  for button in pairs(foreverSecureButtons) do
    SetForeverSecureAction(button);
  end
end

if (tk:IsForever()) then
  local refreshFrame = _G.CreateFrame("Frame");
  refreshFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
  refreshFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
  refreshFrame:SetScript("OnEvent", function()
    if (_G.C_Timer and obj:IsFunction(_G.C_Timer.After)) then
      _G.C_Timer.After(0, RefreshForeverSecureActions);
    else
      RefreshForeverSecureActions();
    end
  end);
end

local function ToggleRetailPlayerSpells(tabName, fallbackTab)
  if (obj:IsFunction(_G.TogglePlayerSpellsFrame)) then
    local frameTabs = _G.PlayerSpellsUtil and _G.PlayerSpellsUtil.FrameTabs;
    local tab = frameTabs and frameTabs[tabName] or fallbackTab;
    _G.TogglePlayerSpellsFrame(tab);
    return true;
  end

  return false;
end

-- Character
clickHandlers[buttonKeys.Character] = function()
  ToggleCharacter("PaperDollFrame");
end

-- Bags
clickHandlers[buttonKeys.Bags] = function()
  local frame = _G.ContainerFrame1;

  if (obj:IsFunction(_G.ToggleAllBags)) then
    _G.ToggleAllBags();
  else
    if (obj:IsWidget(frame) and frame:IsVisible()) then
      (_G.CloseAllBags or _G.ToggleBackpack)();
    else
      _G.OpenAllBags();
    end
  end
end

-- Friends
clickHandlers[buttonKeys.Friends] = function()
  ToggleFriendsFrame(_G.FRIEND_TAB_FRIENDS);
end

-- Guild
clickHandlers[buttonKeys.Guild] = function()
  if (IsTrialAccount()) then
    tk:Print(L["Starter Edition accounts cannot perform this action."]);
  elseif (IsInGuild()) then
    ToggleGuildFrame();
  else
    tk:Print("You need to be in a guild to perform this action.");
  end
end

-- Help Menu
clickHandlers[buttonKeys.HelpMenu] = ToggleHelpFrame;

if (tk:IsRetail()) then
  -- PVP
  clickHandlers[buttonKeys.PVP] = function()
    local playerLevel = UnitLevel("player") or 0;
    if (playerLevel < 10) then
      tk:Print(L["Requires level 10+ to view the PVP window."]);
    else
      TogglePVPUI();
    end
  end
end

-- Spell Book
clickHandlers[buttonKeys.SpellBook] = function()
  if (tk:IsRetail()) then
    if (ToggleRetailPlayerSpells("SpellBook", 3)) then
      return;
    end
  end

  if (obj:IsWidget(_G.SpellBookFrame)) then
    ToggleFrame(_G.SpellBookFrame);
  end
end

-- Talents
clickHandlers[buttonKeys.Talents] = function()
  local playerLevel = UnitLevel("player") or 0;
  if (playerLevel < SHOW_TALENT_LEVEL) then
    tk:Print(L["Must be level 10 or higher to use Talents."]);
  else
    if (tk:IsRetail()) then
      if (ToggleRetailPlayerSpells("ClassTalents", 2)) then
        return;
      end
    end

    if (obj:IsFunction(_G.ToggleTalentFrame)) then
      _G.ToggleTalentFrame();
    end
  end
end

-- Raid
clickHandlers[buttonKeys.Raid] = ToggleRaidFrame;

if (tk:IsRetail() or tk:IsWrathClassic()) then
  -- Achievements
  clickHandlers[buttonKeys.Achievements] = ToggleAchievementFrame;

  -- Calendar
  clickHandlers[buttonKeys.Calendar] = ToggleCalendar;
end

if (tk:IsWrathClassic() and obj:IsNumber(SHOW_INSCRIPTION_LEVEL) and obj:IsFunction(ToggleGlyphFrame)) then
  -- Glyphs
  clickHandlers[buttonKeys.Glyphs] = function()
    if (UnitLevel("player") < SHOW_INSCRIPTION_LEVEL) then
      tk:Print(L["Must be level 10 or higher to use Talents."]);
    else
      ToggleGlyphFrame();
    end
  end
end

if (tk:IsWrathClassic()) then
  clickHandlers[buttonKeys.LFG] = function()
    ToggleLFGParentFrame();
  end;
end

if (isMistsClassic) then
  clickHandlers[buttonKeys.LFD] = function()
    if (obj:IsFunction(_G.ToggleLFDParentFrame)) then
      _G.ToggleLFDParentFrame();
    end
  end;
end

if (tk:IsRetail()) then
  -- LFD
  clickHandlers[buttonKeys.LFD] = ToggleLFDParentFrame;

  -- Encounter Journal
  clickHandlers[buttonKeys.EncounterJournal] = ToggleEncounterJournal;

  -- Collections Journal
  clickHandlers[buttonKeys.CollectionsJournal] = function()
    ToggleCollectionsJournal();
  end
end

if (tk:IsWrathClassic() or tk:IsRetail()) then
  -- Currency
  if (buttonKeys.Currency) then
    clickHandlers[buttonKeys.Currency] = function()
      ToggleCharacter("TokenFrame");
    end
  end
end

-- -- Macros
clickHandlers[buttonKeys.Macros] = function()
  if (not obj:IsWidget(MacroFrame)) then
    LoadAddOn("Blizzard_MacroUI");
  end

  ToggleFrame(MacroFrame);
end

-- World Map
clickHandlers[buttonKeys.WorldMap] = ToggleWorldMap;

-- Quest Log
clickHandlers[buttonKeys.QuestLog] = ToggleQuestLog;

-- Repuation
clickHandlers[buttonKeys.Reputation] = function()
  ToggleCharacter("ReputationFrame");
end

-- PVP Score
clickHandlers[buttonKeys.PVPScore] = function()
  if (not UnitInBattleground("player")) then
    tk:Print(L["Requires being inside a Battle Ground."]);
  else
    ToggleWorldStateScoreFrame();
  end
end

-- Skill
if (buttonKeys.Skills) then
  clickHandlers[buttonKeys.Skills] = function()
    ToggleCharacter("SkillFrame");
  end
end

local function ChatButton_OnClick(self)
  if (InCombatLockdown()) then
    tk:Print(L["Cannot toggle menu while in combat."]);
    return;
  end

	local handler = clickHandlers[self:GetText()];
	if (obj:IsFunction(handler)) then
		handler();
	end
end

local function ChatButton_PostClick(self)
  if (tk:IsForever()) then
    local buttonText = self:GetText();

    -- SecureActionButtonTemplate already ran the matching Blizzard action.
    if ((buttonText == buttonKeys.Character or buttonText == buttonKeys.LFD) and
        self:GetAttribute("macrotext")) then
      return;
    end

    if (buttonText == buttonKeys.Reputation and self:GetAttribute("macrotext")) then
      -- The character window is not fully visible until the secure click has
      -- completed. Select its reputation mode on the following frame.
      if (_G.C_Timer and obj:IsFunction(_G.C_Timer.After)) then
        _G.C_Timer.After(0, function()
          local reputationTab = _G.CharacterFrameModeTab2;
          if (reputationTab and obj:IsFunction(reputationTab.OnMouseUp) and
              _G.CharacterFrame and _G.CharacterFrame:IsShown()) then
            reputationTab:OnMouseUp("LeftButton", true);
          end
        end);
      end
      return;
    end
  end

  ChatButton_OnClick(self);
end

local function ChatFrame_OnModifierStateChanged(_, _, data)
  -- Protected button attributes cannot be changed during combat in Forever.
  if (tk:IsForever() and InCombatLockdown()) then
    return;
  end

  if (data.chatModuleSettings.swapInCombat or not InCombatLockdown()) then
    for _, buttonStateData in ipairs(data.settings.buttons) do
      if (not buttonStateData.key or tk:IsModComboActive(buttonStateData.key)) then
        for index = 1, 3 do
          local text = buttonStateData[index];
          -- Preserve saved bindings while replacing the obsolete MoP skills tab.
          if (isMistsClassic and text == L["Skills"]) then
            text = L["LFD"];
          end
          data.buttons[index]:SetText(text);
        end

        SetForeverSecureAction(data.buttons[1]);
        SetForeverSecureAction(data.buttons[2]);
        SetForeverSecureAction(data.buttons[3]);
      end
    end

  end
end

obj:DefineParams("table")
function C_ChatFrame:SetUpButtonHandler(data, buttonSettings)
  data.settings.buttons = buttonSettings;

  local listenerID = data.anchorName .. "_OnModifierStateChanged";
  local listener = em:GetEventListenerByID(listenerID);

  if (not listener) then
    listener = em:CreateEventListenerWithID(listenerID,
               ChatFrame_OnModifierStateChanged)
  end

  listener:SetCallbackArgs(data);
  listener:RegisterEvent("MODIFIER_STATE_CHANGED");
  em:TriggerEventListenerByID(listenerID);

  if (tk:IsForever()) then
    foreverSecureButtons[data.buttons[1]] = true;
    foreverSecureButtons[data.buttons[2]] = true;
    foreverSecureButtons[data.buttons[3]] = true;

    data.buttons[1]:SetScript("PostClick", ChatButton_PostClick);
    data.buttons[2]:SetScript("PostClick", ChatButton_PostClick);
    data.buttons[3]:SetScript("PostClick", ChatButton_PostClick);

    RefreshForeverSecureActions();
    if (_G.C_Timer and obj:IsFunction(_G.C_Timer.After)) then
      _G.C_Timer.After(0, RefreshForeverSecureActions);
      _G.C_Timer.After(1, RefreshForeverSecureActions);
    end
  else
    data.buttons[1]:SetScript("OnClick", ChatButton_OnClick);
    data.buttons[2]:SetScript("OnClick", ChatButton_OnClick);
    data.buttons[3]:SetScript("OnClick", ChatButton_OnClick);
  end
end
