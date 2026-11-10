-- Visual skin for Forever's NPC quest dialog.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, gui = MayronUI:GetCoreComponents();
if (not tk:IsForever()) then return end

local plates, surfaces, buttonSkins = {}, {}, {};
local buttonTexture = tk:GetAssetFilePath("Textures\\Widgets\\Button");
local questButtons = {
  "QuestFrameAcceptButton", "QuestFrameDeclineButton", "QuestFrameCompleteButton",
  "QuestFrameCompleteQuestButton", "QuestFrameGoodbyeButton", "QuestFrameGreetingGoodbyeButton",
};
local tints, textColors = {}, {};
local panels = { "QuestFrameDetailPanel", "QuestFrameProgressPanel", "QuestFrameRewardPanel", "QuestFrameGreetingPanel" };
local paper = { "Bg", "MaterialTopLeft", "MaterialTopRight", "MaterialBotLeft", "MaterialBotRight", "SealMaterialBG" };
local labels = {
  "QuestInfoTitleHeader", "QuestInfoDescriptionHeader", "QuestInfoDescriptionText",
  "QuestInfoObjectivesHeader", "QuestInfoObjectivesText", "QuestInfoGroupSize",
  "QuestInfoRewardText", "QuestInfoTimerText", "QuestInfoSpellObjectiveLearnLabel",
  "QuestProgressTitleText", "QuestProgressText", "QuestProgressRequiredItemsText",
  "QuestProgressRequiredMoneyText", "GreetingText", "CurrentQuestsText", "AvailableQuestsText",
};

local function Tint(texture, r, g, b, originals, alpha)
  if (not texture) then return end
  originals = originals or tints;
  originals[texture] = originals[texture] or { texture:GetVertexColor() };
  texture:SetVertexColor(r, g, b, alpha or originals[texture][4]);
end

local function Lighten(text, originals)
  if (not text) then return end
  originals = originals or textColors;
  originals[text] = originals[text] or { text:GetTextColor() };
  text:SetTextColor(0.93, 0.94, 0.98, originals[text][4]);
end

local function IsInDialog(region, frame)
  while (region) do
    if (region == frame) then return true end
    region = region:GetParent();
  end
  return false;
end

local function RestoreText()
  for text, color in _G.pairs(textColors) do text:SetTextColor(_G.unpack(color)); end
  textColors = {};
end

local function HideArt(container, originals)
  if (not container) then return end
  for _, region in _G.ipairs({ container:GetRegions() }) do
    if (region:IsObjectType("Texture")) then Tint(region, 1, 1, 1, originals, 0); end
  end
end

local function StyleButton(button, shown, close)
  if (not button) then return end
  local skin = buttonSkins[button];
  if (not skin) then
    if (not shown) then return end
    local background = button:CreateTexture(nil, "BACKGROUND", nil, 4);
    background:SetTexture(buttonTexture);
    background:SetAllPoints(button);
    local overlay;
    if (close) then
      overlay = _G.CreateFrame("Frame", nil, button);
      overlay:EnableMouse(false);
      overlay:SetAllPoints(button);
      gui:CreateIconTexture("cross", overlay, false);
    end
    skin = { background = background; overlay = overlay; originals = {} };
    buttonSkins[button] = skin;
  end

  local red, green, blue = tk:GetClassColor();
  skin.background:SetVertexColor(red * 0.85, green * 0.85, blue * 0.85, 1);
  skin.background:SetShown(shown);
  if (skin.overlay) then skin.overlay:SetShown(shown); end
  for _, getter in _G.ipairs({ "GetNormalTexture", "GetPushedTexture" }) do
    local texture = button[getter](button);
    if (texture) then
      if (shown) then
        skin.originals[texture] = skin.originals[texture] or texture:GetAlpha();
        texture:SetAlpha(0);
      elseif (skin.originals[texture] ~= nil) then
        texture:SetAlpha(skin.originals[texture]);
        skin.originals[texture] = nil;
      end
    end
  end
end

local function HideWindow(frame)
  if (plates[frame]) then plates[frame]:SetShown(false); end
  if (surfaces[frame]) then surfaces[frame]:Hide(); end
  StyleButton(frame.CloseButton, false);
end

local function ShowDialogSurface(frame, backingInset)
  local surface = surfaces[frame];
  if (not surface) then
    surface = gui:CreateWindowSkinSurface(frame, frame, frame, 3, -4, -3, 3);
    local backing = surface:CreateTexture(nil, "BACKGROUND", nil, -1);
    local inset = backingInset or 0;
    backing:SetPoint("TOPLEFT", surface, "TOPLEFT", inset, -inset);
    backing:SetPoint("BOTTOMRIGHT", surface, "BOTTOMRIGHT", -inset, inset);
    backing:SetColorTexture(0.035, 0.035, 0.045, 0.96);
    surface:SetGridAlphaType("Low");
    surfaces[frame] = surface;
  end
  surface:Show();
end

local function StyleWindow(frame, originals, originalTextColors, backingInset)
  local title = frame.TitleContainer;
  if (title) then
    local plate = plates[frame];
    if (not plate) then
      plate = gui:CreateWindowSkinTitle(title, 186);
      plates[frame] = plate;
    end
    local red, green, blue = tk:GetClassColor();
    plate.texture:SetVertexColor(red * 0.85, green * 0.85, blue * 0.85);
    Lighten(title.TitleText, originalTextColors);
    plate:SetShown(true);
  end

  ShowDialogSurface(frame, backingInset);
  HideArt(frame.NineSlice, originals);
  if (frame.Inset) then
    HideArt(frame.Inset.NineSlice, originals);
    if (frame.Inset.Bg and frame.Inset.Bg:IsObjectType("Texture")) then
      Tint(frame.Inset.Bg, 1, 1, 1, originals, 0);
    end
  end
  if (frame.Bg and frame.Bg:IsObjectType("Texture")) then Tint(frame.Bg, 1, 1, 1, originals, 0); end
  StyleButton(frame.CloseButton, true, true);
end

local scrollLayouts = {};
local function SetScrollInset(scrollBox, enabled, extraWidth)
  if (not scrollBox) then return end
  if (enabled and not scrollLayouts[scrollBox]) then
    if (scrollBox:GetNumPoints() ~= 1) then return end
    local point, relative, relativePoint, x, y = scrollBox:GetPoint(1);
    local width = scrollBox:GetWidth();
    if (point ~= "TOPLEFT" or width <= 8) then return end
    scrollLayouts[scrollBox] = { point, relative, relativePoint, x, y, width };
    scrollBox:SetPoint(point, relative, relativePoint, x + 8, y);
    scrollBox:SetWidth(width - 8 + (extraWidth or 0));
  elseif (not enabled and scrollLayouts[scrollBox]) then
    local layout = scrollLayouts[scrollBox];
    scrollLayouts[scrollBox] = nil;
    scrollBox:SetPoint(_G.unpack(layout, 1, 5));
    scrollBox:SetWidth(layout[6]);
  end
end

local questScrolls = {
  "QuestDetailScrollFrame", "QuestProgressScrollFrame", "QuestRewardScrollFrame", "QuestGreetingScrollFrame",
};

local dialogWidths = {};
local dialogExtraWidth = 20;
local function SetDialogWidth(frame, enabled)
  local width = dialogWidths[frame];
  if (enabled and not width) then
    width = frame:GetWidth();
    dialogWidths[frame] = width;
    frame:SetWidth(width + dialogExtraWidth);
  elseif (not enabled and width) then
    dialogWidths[frame] = nil;
    frame:SetWidth(width);
  end
end

local function LightenDialogButton(button, colors, labels)
  local label = button:GetFontString();
  Lighten(label, colors);

  local text = button:GetText();
  if (_G.issecretvalue and _G.issecretvalue(text)) then return end
  if (type(text) ~= "string") then return end
  local original = labels[button];
  if (original and original.styled == text) then return end
  labels[button] = nil;

  -- Quest titles can carry an inline color that overrides the font string.
  local contents = text:match("^|c%x%x%x%x%x%x%x%x(.*)|r$") or text:match("^|cn[%w_]+:(.*)|r$");
  if (contents) then
    local styled = "|cffedefef" .. contents .. "|r";
    labels[button] = { original = text; styled = styled };
    button:SetText(styled);
  end
end

local function RestoreButtonLabels(labels)
  for button, label in _G.pairs(labels) do
    local current = button:GetText();
    if (not (_G.issecretvalue and _G.issecretvalue(current)) and current == label.styled) then
      button:SetText(label.original);
    end
    labels[button] = nil;
  end
end

local questButtonLabels = {};

local function Refresh()
  local frame = _G.QuestFrame;
  if (not frame or _G.InCombatLockdown()) then return end
  if (_G.MayronUIdb.global.foreverQuestDialogStyle == false or not frame:IsVisible()) then
    HideWindow(frame);
    if (_G.MayronUIdb.global.foreverQuestDialogStyle == false) then
      SetDialogWidth(frame, false);
      for _, name in _G.ipairs(questScrolls) do SetScrollInset(_G[name], false); end
    end
    for _, name in _G.ipairs(questButtons) do StyleButton(_G[name], false); end
    for texture, color in _G.pairs(tints) do texture:SetVertexColor(_G.unpack(color)); end
    tints = {};
    RestoreText();
    RestoreButtonLabels(questButtonLabels);
    return;
  end

  SetDialogWidth(frame, true);
  StyleWindow(frame, nil, nil, 8);
  for _, name in _G.ipairs(questScrolls) do SetScrollInset(_G[name], true, dialogExtraWidth); end
  for _, name in _G.ipairs(questButtons) do StyleButton(_G[name], true); end
  for _, name in _G.ipairs(panels) do
    local panel = _G[name];
    if (panel) then
      for _, key in _G.ipairs(paper) do Tint(panel[key], 1, 1, 1, nil, 0); end
    end
  end
  for _, name in _G.ipairs(labels) do
    local text = _G[name];
    -- The quest map shares some QuestInfo strings with the NPC dialog.
    if (text and IsInDialog(text, frame)) then Lighten(text); end
  end
  local greeting = _G.QuestFrameGreetingPanel;
  local titleButtons = greeting and greeting:IsShown() and greeting.titleButtonPool;
  if (titleButtons) then
    for button in titleButtons:EnumerateActive() do
      LightenDialogButton(button, textColors, questButtonLabels);
    end
  end
  local rewards = _G.QuestInfoRewardsFrame;
  if (rewards and IsInDialog(rewards, frame)) then
    Lighten(rewards.Header);
    Lighten(rewards.ItemChooseText);
    Lighten(rewards.ItemReceiveText);
    Lighten(rewards.PlayerTitleText);
    Lighten(rewards.QuestSessionBonusReward);
    Lighten(rewards.XPFrame and rewards.XPFrame.ReceiveText);
  end
end

local gossipTints, gossipTextColors, gossipButtonLabels = {}, {}, {};

local function RefreshGossip()
  local frame = _G.GossipFrame;
  if (not frame or _G.InCombatLockdown()) then return end
  if (_G.MayronUIdb.global.foreverQuestDialogStyle == false or not frame:IsVisible()) then
    HideWindow(frame);
    local panel = frame.GreetingPanel;
    StyleButton(panel and panel.GoodbyeButton, false);
    if (_G.MayronUIdb.global.foreverQuestDialogStyle == false) then
      SetDialogWidth(frame, false);
      SetScrollInset(panel and panel.ScrollBox, false);
    end
    for texture, color in _G.pairs(gossipTints) do texture:SetVertexColor(_G.unpack(color)); end
    for text, color in _G.pairs(gossipTextColors) do text:SetTextColor(_G.unpack(color)); end
    RestoreButtonLabels(gossipButtonLabels);
    gossipTints, gossipTextColors, gossipButtonLabels = {}, {}, {};
    return;
  end

  SetDialogWidth(frame, true);
  StyleWindow(frame, gossipTints, gossipTextColors, 8);
  Tint(frame.Background, 1, 1, 1, gossipTints, 0);
  local panel = frame.GreetingPanel;
  if (not panel) then return end
  local scrollBox = panel.ScrollBox;
  if (not scrollBox) then return end
  SetScrollInset(scrollBox, true, dialogExtraWidth);
  StyleButton(panel.GoodbyeButton, true);
  for _, region in _G.ipairs({ panel:GetRegions() }) do
    if (region:IsObjectType("Texture") and region:GetDrawLayer() == "BORDER") then
      Tint(region, 1, 1, 1, gossipTints, 0);
    end
  end
  if (not scrollBox:GetView()) then return end
  for _, row in scrollBox:EnumerateFrames() do
    if (row:IsObjectType("Button")) then
      LightenDialogButton(row, gossipTextColors, gossipButtonLabels);
    else
      for _, region in _G.ipairs({ row:GetRegions() }) do
        if (region:IsObjectType("FontString")) then Lighten(region, gossipTextColors); end
      end
    end
  end
end

local binderTints = {};
local function RestoreBinderPopup(dialog)
  local originals = binderTints[dialog];
  if (not originals) then return end
  binderTints[dialog] = nil;
  surfaces[dialog]:Hide();
  StyleButton(dialog:GetButton1(), false);
  StyleButton(dialog:GetButton2(), false);
  for texture, color in _G.pairs(originals) do texture:SetVertexColor(_G.unpack(color)); end
end

local function StyleBinderPopup(dialog)
  if (not dialog or dialog.which ~= "CONFIRM_BINDER" or _G.InCombatLockdown() or
      _G.MayronUIdb.global.foreverQuestDialogStyle == false) then return end

  ShowDialogSurface(dialog, 8);
  surfaces[dialog].ignoreInLayout = true;
  local originals = binderTints[dialog] or {};
  binderTints[dialog] = originals;
  HideArt(dialog.NineSlice, originals);
  HideArt(dialog.BG, originals);
  if (dialog.Bg and dialog.Bg:IsObjectType("Texture")) then Tint(dialog.Bg, 1, 1, 1, originals, 0); end
  StyleButton(dialog:GetButton1(), true);
  StyleButton(dialog:GetButton2(), true);
end

MayronUI:Hook("CoreModule", "OnInitialized", function()
  if (_G.MayronUIdb.global.foreverWindowStyle ~= true) then return end
  local frame = _G.QuestFrame;
  if (not frame) then return end
  frame:HookScript("OnShow", Refresh);
  frame:HookScript("OnHide", Refresh);
  local greeting = _G.QuestFrameGreetingPanel;
  if (greeting) then greeting:HookScript("OnShow", Refresh); end
  local watcher = _G.CreateFrame("Frame");
  local popupEvents = _G.PopupEventManager;
  if (popupEvents) then
    popupEvents:RegisterCallback("PopupOpened", function(_, dialog) StyleBinderPopup(dialog); end, watcher);
    popupEvents:RegisterCallback("PopupClosed", function(_, dialog) RestoreBinderPopup(dialog); end, watcher);
  end
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
  watcher:RegisterEvent("QUEST_DETAIL");
  watcher:RegisterEvent("QUEST_PROGRESS");
  watcher:RegisterEvent("QUEST_COMPLETE");
  watcher:RegisterEvent("QUEST_GREETING");
  watcher:RegisterEvent("GOSSIP_SHOW");
  watcher:SetScript("OnEvent", function()
    Refresh();
    RefreshGossip();
  end);
  local gossip = _G.GossipFrame;
  if (gossip) then
    gossip:HookScript("OnShow", RefreshGossip);
    gossip:HookScript("OnHide", RefreshGossip);
    local scrollBox = gossip.GreetingPanel and gossip.GreetingPanel.ScrollBox;
    if (scrollBox) then scrollBox:RegisterCallback("OnUpdate", RefreshGossip, watcher); end
  end
  Refresh();
  RefreshGossip();
end);

_G.SLASH_MUIQUESTDIALOG1 = "/muiquestdialog";
_G.SlashCmdList.MUIQUESTDIALOG = function(message)
  if (_G.MayronUIdb.global.foreverWindowStyle ~= true) then return end
  local option = _G.strtrim(message or ""):lower();
  if (option == "on" or option == "off") then
    _G.MayronUIdb.global.foreverQuestDialogStyle = option == "on";
    Refresh();
    RefreshGossip();
    local dialog = _G.StaticPopup_FindVisible("CONFIRM_BINDER");
    if (dialog and not _G.InCombatLockdown()) then
      if (option == "on") then StyleBinderPopup(dialog); else RestoreBinderPopup(dialog); end
    end
  else
    tk:Print("/muiquestdialog on | /muiquestdialog off");
  end
end;
