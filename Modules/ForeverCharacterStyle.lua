-- Style Forever's character sheet and annotate the native equipment buttons.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, gui = MayronUI:GetCoreComponents();
if (not tk:IsForever()) then return end

db:AddToDefaults("global.foreverCharacterStyle", true);

local slots = {
  "Head", "Neck", "Shoulder", "Back", "Chest", "Shirt", "Tabard", "Wrist",
  "Hands", "Waist", "Legs", "Feet", "Finger0", "Finger1", "Trinket0", "Trinket1",
  "MainHand", "SecondaryHand", "Ranged",
};
local character, setChrome;
local badges, stats, statsHooks, art = {}, {}, {}, {};
local isSecret = _G.issecretvalue;

local function CreateBadgeText(button, point, x, y)
  local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall", 7);
  text:SetPoint(point, button, point, x, y);
  text:SetShadowColor(0, 0, 0, 1);
  text:SetShadowOffset(1, -1);
  return text;
end

local function HideArt(region)
  if (not region or art[region] ~= nil) then return end
  local alpha = region:GetAlpha();
  if (isSecret and isSecret(alpha)) then return end
  art[region] = alpha;
  region:SetAlpha(0);
end

local function HidePaneTextures(pane)
  if (not pane or not pane.GetRegions) then return end
  for _, region in _G.ipairs({ pane:GetRegions() }) do
    if (region:IsObjectType("Texture")) then HideArt(region); end
  end
end

local function CreateSlotBorder(button)
  local edges = {};
  for _, side in _G.ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
    local edge = button:CreateTexture(nil, "OVERLAY", nil, 1);
    local horizontal = side == "TOP" or side == "BOTTOM";
    if (horizontal) then
      edge:SetPoint(side.."LEFT");
      edge:SetPoint(side.."RIGHT");
      edge:SetHeight(1);
    else
      edge:SetPoint("TOP"..side);
      edge:SetPoint("BOTTOM"..side);
      edge:SetWidth(1);
    end
    edges[#edges + 1] = edge;
  end
  return edges;
end

local function RefreshSlots(enabled)
  for _, slot in _G.ipairs(slots) do
    local button = _G["Character" .. slot .. "Slot"];
    if (button and (enabled or badges[button])) then
      local badge = badges[button];
      if (not badge) then
        badge = {
          border = CreateSlotBorder(button);
          level = CreateBadgeText(button, "BOTTOMRIGHT", -2, 2);
          durability = CreateBadgeText(button, "TOPRIGHT", -2, -2);
        };
        badges[button] = badge;
      end
      if (enabled) then
        HideArt(button.BorderFrame);
        HideArt(_G["Character" .. slot .. "SlotNormalTexture"]);
      end
      local quality = enabled and _G.GetInventoryItemQuality("player", button:GetID());
      local color;
      if (not (isSecret and isSecret(quality)) and _G.type(quality) == "number") then
        color = _G.ITEM_QUALITY_COLORS[quality];
      end
      for _, edge in _G.ipairs(badge.border) do
        if (color) then edge:SetColorTexture(color.r, color.g, color.b, 0.75);
        else edge:SetColorTexture(0.36, 0.36, 0.42, 0.65); end
        edge:SetShown(enabled);
      end
      local level, durability;
      local slotID = _G.GetInventorySlotInfo(slot .. "Slot");
      if (enabled and slot ~= "Shirt" and slot ~= "Tabard" and slotID and _G.ItemLocation and _G.C_Item
          and _G.C_Item.DoesItemExist and _G.C_Item.GetCurrentItemLevel) then
        local location = _G.ItemLocation:CreateFromEquipmentSlot(slotID);
        local exists = _G.C_Item.DoesItemExist(location);
        if (not (isSecret and isSecret(exists)) and exists) then
          level = _G.C_Item.GetCurrentItemLevel(location);
          local current, maximum = _G.GetInventoryItemDurability(slotID);
          if (not (isSecret and (isSecret(current) or isSecret(maximum)))
              and current and maximum and maximum > 0 and current < maximum) then
            durability = _G.math.floor(current / maximum * 100 + 0.5);
          end
        end
      end
      if (not (isSecret and isSecret(level)) and _G.type(level) == "number" and level > 0) then
        badge.level:SetFormattedText("%d", level);
      else
        badge.level:SetText("");
      end
      if (durability) then
        badge.durability:SetFormattedText("%d%%", durability);
        if (durability <= 25) then badge.durability:SetTextColor(1, 0.35, 0.22);
        else badge.durability:SetTextColor(1, 0.78, 0.30); end
      else
        badge.durability:SetText("");
      end
    end
  end
end

local function StyleStatRow(row)
  if (not db.global.foreverCharacterStyle or _G.InCombatLockdown()
      or not row or (not row.Title and not row.Label)) then return end
  local skin = stats[row];
  if (not skin) then
    local texture = row:CreateTexture(nil, "ARTWORK", nil, -2);
    if (row.Title) then
      texture:SetPoint("BOTTOMLEFT", row, "LEFT", 8, -11);
      texture:SetPoint("BOTTOMRIGHT", row, "RIGHT", -8, -11);
      texture:SetHeight(1);
    else
      texture:SetPoint("BOTTOMLEFT", 8, 0);
      texture:SetPoint("BOTTOMRIGHT", -8, 0);
      texture:SetHeight(1);
    end
    skin = { texture = texture };
    stats[row] = skin;
  end
  if (row.Background and skin.alpha == nil) then
    skin.alpha = row.Background:GetAlpha();
    if (isSecret and isSecret(skin.alpha)) then skin.alpha = nil; end
    if (skin.alpha ~= nil) then row.Background:SetAlpha(0); end
  end
  if (row.Title) then
    local r, g, b = tk:GetClassColor();
    skin.texture:SetColorTexture(r, g, b, 0.45);
  else
    skin.texture:SetColorTexture(1, 1, 1, 0.07);
  end
  skin.texture:Show();
end

local function RefreshStats()
  for _, name in _G.ipairs({ "CharacterStatsPaneScrollBox", "CharacterStatsPanePetScrollBox" }) do
    local container = _G[name];
    local box = container and container.ScrollBox;
    if (box and box.ForEachFrame) then
      if (not statsHooks[box] and _G.ScrollUtil and _G.ScrollUtil.AddInitializedFrameCallback) then
        _G.ScrollUtil.AddInitializedFrameCallback(box, function(_, row)
          StyleStatRow(row);
        end, nil, false);
        statsHooks[box] = true;
      end
      box:ForEachFrame(StyleStatRow);
    end
  end
end

local modelBackdropHooks = {};

local function HideModelTexture(region)
  if (not region) then return end
  HideArt(region);
  local alpha = region:GetAlpha();
  if (not (isSecret and isSecret(alpha)) and alpha ~= 0) then region:SetAlpha(0); end
  if (modelBackdropHooks[region]) then return end
  _G.hooksecurefunc(region, "SetAlpha", function(texture, value)
    if (db.global.foreverCharacterStyle and art[texture] ~= nil and not _G.InCombatLockdown() and
        not (isSecret and isSecret(value)) and value ~= 0) then
      texture:SetAlpha(0);
    end
  end);
  modelBackdropHooks[region] = true;
end

local function HideModelBackdrop()
  HideModelTexture(_G.CharacterModelFrameBackgroundTopLeft);
  local scene = _G.CharacterModelScene;
  if (not scene) then return end
  HideModelTexture(scene.BackgroundOverlay);
  for _, region in _G.ipairs({ scene:GetRegions() }) do
    if (region:IsObjectType("Texture") and region:GetDrawLayer() == "BACKGROUND") then
      HideModelTexture(region);
    end
  end
end

local function Refresh()
  if (_G.InCombatLockdown()) then return end
  local enabled = db.global.foreverCharacterStyle;
  if (not enabled) then
    if (setChrome) then setChrome(false); end
    for region, alpha in _G.pairs(art) do region:SetAlpha(alpha); end
    art = {};
    for row, skin in _G.pairs(stats) do
      skin.texture:Hide();
      if (skin.alpha ~= nil) then row.Background:SetAlpha(skin.alpha); skin.alpha = nil; end
    end
    RefreshSlots(false);
    return;
  end
  if (not character or not character:IsShown()) then return end
  if (not setChrome) then setChrome = gui:CreateWindowSkinChrome(character, 195, nil, true); end
  setChrome(true);
  HideArt(character.Background);
  local portrait = character.PortraitContainer or _G.CharacterFramePortrait;
  HideArt(portrait);
  HideModelBackdrop();
  HidePaneTextures(character.LeftPaneHost);
  HidePaneTextures(character.RightPaneHost);
  HidePaneTextures(_G.CharacterStatsPaneScrollBox);
  HidePaneTextures(_G.CharacterStatsPanePetScrollBox);
  HidePaneTextures(_G.PaperDollFrame and _G.PaperDollFrame.TopBackgroundStripHost);
  local inset = character.InsetRight or _G.CharacterFrameInsetRight;
  if (inset) then HideArt(inset.Bg); HideArt(inset.NineSlice); end
  RefreshSlots(true);
  RefreshStats();
end

MayronUI:Hook("CoreModule", "OnInitialized", function()
  local function Attach()
    if (character or not _G.CharacterFrame or _G.InCombatLockdown()) then return end
    character = _G.CharacterFrame;
    character:HookScript("OnShow", Refresh);
    if (_G.PaperDollFrame) then _G.PaperDollFrame:HookScript("OnShow", Refresh); end
  end

  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("ADDON_LOADED");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
  watcher:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
  watcher:RegisterEvent("UPDATE_INVENTORY_DURABILITY");
  watcher:RegisterEvent("GET_ITEM_INFO_RECEIVED");
  watcher:SetScript("OnEvent", function(self, event)
    Attach();
    if (character) then self:UnregisterEvent("ADDON_LOADED"); end
    if (event == "ADDON_LOADED" or event == "PLAYER_REGEN_ENABLED") then
      Refresh();
    elseif (character and character:IsShown() and not _G.InCombatLockdown()) then
      RefreshSlots(db.global.foreverCharacterStyle);
    end
  end);
  Attach();
  Refresh();
end);

_G.SLASH_MUICHARACTERSTYLE1 = "/muicharacterstyle";
_G.SlashCmdList.MUICHARACTERSTYLE = function(message)
  local option = _G.strtrim(message or ""):lower();
  if (option == "on" or option == "off") then
    db.global.foreverCharacterStyle = option == "on";
    Refresh();
  else
    tk:Print("/muicharacterstyle on | /muicharacterstyle off");
  end
end;
