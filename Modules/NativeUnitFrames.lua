-- Built-in MUI unit frames for WoW Forever, Retail, and supported Classic clients.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db = MayronUI:GetCoreComponents();
local _, _, _, interfaceVersion = _G.GetBuildInfo();
local isMists = _G.WOW_PROJECT_MISTS_CLASSIC and _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MISTS_CLASSIC;
if (not isMists and not tk:IsClassic() and not tk:IsBCClassic() and not tk:IsForever() and (not tk:IsRetail() or (tonumber(interfaceVersion) or 0) < 120100)) then return end

local german = _G.GetLocale() == "deDE";
local title = german and "MUI-Einheitenrahmen" or "MUI Unit Frames";
local C_NativeUnitFrames = MayronUI:RegisterModule("NativeUnitFrames", title, true);

db:AddToDefaults("profile.nativeUnitFrames", {
  player = { enabled = true; zoom = 1 };
  target = { enabled = true; zoom = 1 };
  healthColor = { r = 0.29; g = 0.33; b = 0.37; a = 1 };
  raid = { classColoredHealth = false; showBuffs = true; showDebuffs = true; debuffFilter = "all"; width = 110; height = 40; point = "BOTTOMLEFT"; x = 20; y = 20 };
  party = { width = 210; height = 40; raidPreviewColumns = 5; classColoredHealth = false; showBuffs = true; showDebuffs = true; debuffFilter = "all"; showFullNames = false; customPosition = true; point = "BOTTOMLEFT"; x = 0; y = 0 };
});

local addons = _G.C_AddOns;
local sufName = "ShadowedUnitFrames";
local nativeLabel = german and "MUI (eigene Einheitenrahmen)" or "MUI (built-in unit frames)";

local function SwitchUnitFrames(mode)
  if (_G.InCombatLockdown()) then
    tk:Print(german and "Einheitenrahmen können nur außerhalb des Kampfes gewechselt werden."
      or "Unit frames can only be switched out of combat.");
    return;
  end
  local character = _G.UnitName("player");
  if (not character) then return end

  if (mode == "suf") then
    if (not addons.GetAddOnInfo(sufName)) then
      tk:Print(german and "Shadowed Unit Frames ist nicht installiert." or "Shadowed Unit Frames is not installed.");
      return;
    end
    addons.EnableAddOn(sufName, character);
  elseif (mode == "mui") then
    if (addons.GetAddOnInfo(sufName)) then addons.DisableAddOn(sufName, character); end
  else
    tk:Print("/muiunitframes mui | /muiunitframes suf");
    return;
  end
  _G.ReloadUI();
end

_G.SLASH_MUIUNITFRAMES1 = "/muiunitframes";
_G.SlashCmdList.MUIUNITFRAMES = function(message)
  SwitchUnitFrames(_G.strtrim(message or ""):lower());
end;

local queuePartyPosition, refreshPartySkin, refreshRaidAuras;
local unitHealthBars = {};

local function UpdateUnitHealthColor(color)
  for _, bar in pairs(unitHealthBars) do
    bar:SetStatusBarColor(color.r, color.g, color.b);
  end
end
local previewMode, ShowGroupPreview = "off", nil;
local partyRowGap = 3;
local groupAnchorOptions = {
  { german and "Links oben" or "Top left", "TOPLEFT" };
  { german and "Links mittig" or "Middle left", "LEFT" };
  { german and "Links unten" or "Bottom left", "BOTTOMLEFT" };
  { german and "Mitte oben" or "Top center", "TOP" };
  { german and "Mitte" or "Center", "CENTER" };
  { german and "Mitte unten" or "Bottom center", "BOTTOM" };
  { german and "Rechts oben" or "Top right", "TOPRIGHT" };
  { german and "Rechts mittig" or "Middle right", "RIGHT" };
  { german and "Rechts unten" or "Bottom right", "BOTTOMRIGHT" };
};

local function GetGroupRowSize(group)
  local settings = db.profile.nativeUnitFrames[group];
  local minWidth, maxWidth = 90, 360;
  local minHeight, maxHeight = 24, group == "party" and 48 or 72;
  return math.max(minWidth, math.min(maxWidth, settings.width)),
    math.max(minHeight, math.min(maxHeight, settings.height));
end

local function GroupSizeSlider(label, group, dimension, min, max)
  return {
    name = label;
    type = "slider";
    min = min;
    max = max;
    step = 1;
    dbPath = "profile.nativeUnitFrames."..group.."."..dimension;
    OnValueChanged = function()
      if (group == "party" and refreshPartySkin) then refreshPartySkin(); end
      if (previewMode ~= "off") then ShowGroupPreview(previewMode); end
    end;
  };
end
local function UpdatePartyPosition()
  if (queuePartyPosition) then queuePartyPosition(); end
  if (refreshPartySkin) then refreshPartySkin(); end
  if (previewMode == "party") then ShowGroupPreview("party"); end
end

local function UpdateRaidPreviewPosition()
  if (previewMode == "raid") then
    ShowGroupPreview(previewMode);
  end
end

local function PreviewCheck(mode, label)
  return {
    name = label;
    type = "check";
    GetValue = function() return previewMode == mode end;
    OnLoad = function(_, checkbox)
      checkbox:HookScript("OnHide", function(self)
        if (previewMode == mode) then ShowGroupPreview("off"); end
        self:SetChecked(false);
      end);
    end;
    SetValue = function(_, checked)
      if (checked) then
        ShowGroupPreview(mode);
      elseif (previewMode == mode) then
        ShowGroupPreview("off");
      end
    end;
  };
end

function C_NativeUnitFrames:GetConfigTable()
  local healthColorPath = "profile.nativeUnitFrames.healthColor";
  local healthColorSwatch;
  local partyOptions = {
    name = german and "Gruppe" or "Party";
    type = "submenu";
    children = {
      PreviewCheck("party", german and "Gruppenvorschau (5)" or "Party preview (5)");
      {
        name = german and "Klassenfarben für Lebensbalken" or "Class-colored health bars";
        type = "check";
        dbPath = "profile.nativeUnitFrames.party.classColoredHealth";
        OnValueChanged = function()
          if (refreshPartySkin) then refreshPartySkin(); end
          if (previewMode ~= "off") then ShowGroupPreview(previewMode); end
        end;
      };
      { type = "divider" };
      {
        name = german and "Buffs anzeigen" or "Show buffs";
        type = "check";
        dbPath = "profile.nativeUnitFrames.party.showBuffs";
        OnValueChanged = function()
          if (refreshPartySkin) then refreshPartySkin(); end
        end;
      }; {
        name = german and "Debuffs anzeigen" or "Show debuffs";
        type = "check";
        dbPath = "profile.nativeUnitFrames.party.showDebuffs";
        OnValueChanged = function()
          if (refreshPartySkin) then refreshPartySkin(); end
        end;
      };
      {
        name = german and "Debuff-Filter" or "Debuff filter";
        type = "dropdown";
        options = {
          [german and "Alle Debuffs" or "All debuffs"] = "all";
          [german and "Von mir bannbar" or "Dispellable by me"] = "mine";
          [german and "Alle bannbaren" or "All dispellable"] = "dispellable";
        };
        dbPath = "profile.nativeUnitFrames.party.debuffFilter";
        OnValueChanged = function()
          if (refreshPartySkin) then refreshPartySkin(); end
        end;
      };
      GroupSizeSlider(german and "Breite der Gruppenrahmen" or "Party frame width", "party", "width", 90, 360);
      GroupSizeSlider(german and "Höhe der Gruppenrahmen" or "Party frame height", "party", "height", 24, 48);
      {
        name = german and "Eigene Gruppenposition verwenden" or "Use custom party position";
        type = "check";
        dbPath = "profile.nativeUnitFrames.party.customPosition";
        requiresReload = true;
      }; {
        name = german and "Ankerpunkt" or "Anchor point";
        type = "dropdown";
        options = groupAnchorOptions; disableSorting = true;
        dbPath = "profile.nativeUnitFrames.party.point";
        OnValueChanged = UpdatePartyPosition;
      }; {
        name = german and "X-Versatz" or "X offset";
        type = "slider";
        min = -2000;
        max = 2000;
        step = 0.1;
        dbPath = "profile.nativeUnitFrames.party.x";
        OnValueChanged = UpdatePartyPosition;
      }; {
        name = german and "Y-Versatz" or "Y offset";
        type = "slider";
        min = -2000;
        max = 2000;
        step = 0.1;
        dbPath = "profile.nativeUnitFrames.party.y";
        OnValueChanged = UpdatePartyPosition;
      };
    };
  };
  if (tk:IsForever()) then
    table.insert(partyOptions.children, 2, {
      name = german and "Vor- und Nachnamen anzeigen" or "Show first and last names";
      type = "check";
      dbPath = "profile.nativeUnitFrames.party.showFullNames";
      OnValueChanged = function()
        if (refreshPartySkin) then refreshPartySkin(); end
      end;
    });
  end
  return {
    module = "NativeUnitFrames";
    children = {
      { type = "title"; name = title };
      {
        name = german and "Einheitenrahmen verwenden" or "Unit frame provider";
        type = "dropdown";
        width = 250;
        options = { [nativeLabel] = "mui"; ["Shadowed Unit Frames"] = "suf" };
        tooltip = german and "Wechselt die Einheitenrahmen für diesen Charakter und lädt das Interface neu."
          or "Switches unit frames for this character and reloads the interface.";
        GetValue = function()
          return addons.IsAddOnLoaded(sufName) and "suf" or "mui";
        end;
        SetValue = function(_, value)
          SwitchUnitFrames(value);
        end;
      };
      { type = "divider" };
      {
        name = german and "Spielerrahmen anzeigen" or "Show player frame";
        type = "check";
        dbPath = "profile.nativeUnitFrames.player.enabled";
        requiresReload = true;
      }; {
        name = german and "Spielerporträt-Zoom" or "Player portrait zoom";
        type = "slider";
        valueType = "number";
        min = 0;
        max = 1;
        step = 0.05;
        dbPath = "profile.nativeUnitFrames.player.zoom";
        requiresReload = true;
      }; {
        name = german and "Zielrahmen anzeigen" or "Show target frame";
        type = "check";
        dbPath = "profile.nativeUnitFrames.target.enabled";
        requiresReload = true;
      }; {
        name = german and "Zielporträt-Zoom" or "Target portrait zoom";
        type = "slider";
        valueType = "number";
        min = 0;
        max = 1;
        step = 0.05;
        dbPath = "profile.nativeUnitFrames.target.zoom";
        requiresReload = true;
      }; {
        name = german and "Lebensbalkenfarbe (Spieler und Ziel)" or "Health bar color (player and target)";
        type = "color";
        dbPath = healthColorPath;
        OnValueChanged = UpdateUnitHealthColor;
        OnLoad = function(_, swatch)
          healthColorSwatch = swatch;
        end;
      }; {
        type = "button";
        texture = tk:GetAssetFilePath("Textures\\refresh");
        width = 18;
        height = 18;
        texWidth = 14;
        texHeight = 14;
        point = "CENTER";
        OnLoad = function(_, container)
          local button = container:GetChildren();
          tk:ApplyThemeColor(button:GetNormalTexture());
          tk:SetBasicTooltip(button, german and "Auf Standard zurücksetzen" or "Reset to default", "ANCHOR_TOP");
        end;
        OnClick = function()
          local default = db:GetDefault(healthColorPath);
          local color = { r = default.r; g = default.g; b = default.b; a = default.a };
          db:SetPathValue(healthColorPath, color);
          UpdateUnitHealthColor(color);
          if (healthColorSwatch) then
            healthColorSwatch.value = color;
            healthColorSwatch:ApplyThemeColor(color.r, color.g, color.b, color.a);
          end
        end;
      };
      { type = "divider" };
      partyOptions;
      {
        name = german and "Schlachtzug" or "Raid";
        type = "submenu";
        children = {
          PreviewCheck("raid", german and "Schlachtzugsvorschau (40)" or "Raid preview (40)");
          {
            name = german and "Klassenfarben für Lebensbalken" or "Class-colored health bars";
            type = "check";
            dbPath = "profile.nativeUnitFrames.raid.classColoredHealth";
            OnValueChanged = UpdateRaidPreviewPosition;
          };
          {
            name = german and "Buffs anzeigen" or "Show buffs";
            type = "check";
            dbPath = "profile.nativeUnitFrames.raid.showBuffs";
            OnValueChanged = function()
              if (refreshRaidAuras) then refreshRaidAuras(); end
            end;
          }; {
            name = german and "Debuffs anzeigen" or "Show debuffs";
            type = "check";
            dbPath = "profile.nativeUnitFrames.raid.showDebuffs";
            OnValueChanged = function()
              if (refreshRaidAuras) then refreshRaidAuras(); end
            end;
          };
          {
            name = german and "Debuff-Filter" or "Debuff filter";
            type = "dropdown";
            options = {
              [german and "Alle Debuffs" or "All debuffs"] = "all";
              [german and "Von mir bannbar" or "Dispellable by me"] = "mine";
              [german and "Alle bannbaren" or "All dispellable"] = "dispellable";
            };
            dbPath = "profile.nativeUnitFrames.raid.debuffFilter";
            OnValueChanged = function()
              if (refreshRaidAuras) then refreshRaidAuras(); end
            end;
          };
          GroupSizeSlider(german and "Breite der Schlachtzugsrahmen" or "Raid frame width", "raid", "width", 90, 360);
          GroupSizeSlider(german and "Höhe der Schlachtzugsrahmen" or "Raid frame height", "raid", "height", 24, 72);
          {
            name = german and "Schlachtzug-Spalten (Plätze pro Reihe)" or "Raid columns (members per row)";
            type = "slider";
            min = 0;
            max = 40;
            step = 1;
            dbPath = "profile.nativeUnitFrames.party.raidPreviewColumns";
            tooltip = german and "0 verwendet den Standard mit fünf Spalten. Gilt für die Schlachtzugsvorschau."
              or "0 uses the default of five columns. Applies to the raid preview.";
            OnValueChanged = function()
              if (previewMode == "raid") then ShowGroupPreview(previewMode); end
            end;
          };
          {
            name = german and "Ankerpunkt" or "Anchor point";
            type = "dropdown";
            options = groupAnchorOptions; disableSorting = true;
            dbPath = "profile.nativeUnitFrames.raid.point";
            OnValueChanged = UpdateRaidPreviewPosition;
          }; {
            name = german and "X-Versatz" or "X offset";
            type = "slider";
            min = -2000;
            max = 2000;
            step = 0.1;
            dbPath = "profile.nativeUnitFrames.raid.x";
            OnValueChanged = UpdateRaidPreviewPosition;
          }; {
            name = german and "Y-Versatz" or "Y offset";
            type = "slider";
            min = -2000;
            max = 2000;
            step = 0.1;
            dbPath = "profile.nativeUnitFrames.raid.y";
            OnValueChanged = UpdateRaidPreviewPosition;
          };
        };
      };
    };
  };
end

local function CreateBar(parent, height, red, green, blue)
  local bar = _G.CreateFrame("StatusBar", nil, parent);
  bar:SetHeight(height);
  bar:SetStatusBarTexture(tk:GetAssetFilePath("Textures\\Widgets\\Button"));
  bar:SetStatusBarColor(red, green, blue);
  local background = bar:CreateTexture(nil, "BACKGROUND");
  background:SetAllPoints();
  background:SetColorTexture(0.025, 0.025, 0.035, 0.92);
  return bar;
end

local function ColorGroupName(label, color, group)
  if (color and not db.profile.nativeUnitFrames[group].classColoredHealth) then
    label:SetTextColor(color.r, color.g, color.b);
  else
    label:SetTextColor(1, 1, 1);
  end
  label:SetShadowColor(0, 0, 0, 1);
  label:SetShadowOffset(1, -1);
end

local function ColorGroupHealth(bar, color, group)
  if (color and db.profile.nativeUnitFrames[group].classColoredHealth) then
    bar:SetStatusBarColor(color.r, color.g, color.b);
  else
    bar:SetStatusBarColor(0.075, 0.075, 0.085);
  end
end

local preview;
local previewClasses = { "WARRIOR", "MAGE", "DRUID", "PRIEST", "ROGUE", "WARLOCK", "HUNTER", "SHAMAN", "PALADIN" };
local function CreatePartyStatusIndicators(life, showPrediction)
  local incomingHeal, damageShield;
  if (showPrediction) then
    life:SetClipsChildren(true);
    incomingHeal = _G.CreateFrame("StatusBar", nil, life);
    incomingHeal:SetPoint("TOP");
    incomingHeal:SetPoint("BOTTOM");
    incomingHeal:SetPoint("LEFT", life:GetStatusBarTexture(), "RIGHT");
    incomingHeal:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");
    incomingHeal:SetStatusBarColor(0.2, 0.85, 0.39, 0.72);
    life:HookScript("OnSizeChanged", function(_, width) incomingHeal:SetWidth(width); end);

    damageShield = _G.CreateFrame("StatusBar", nil, life);
    damageShield:SetPoint("TOPLEFT");
    damageShield:SetPoint("TOPRIGHT");
    damageShield:SetHeight(3);
    damageShield:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8");
    damageShield:SetStatusBarColor(0.38, 0.8, 1);
  end

  local aggro = life:CreateTexture(nil, "OVERLAY");
  aggro:SetPoint("TOPLEFT", 0, 0);
  aggro:SetPoint("BOTTOMLEFT", 0, 0);
  aggro:SetWidth(2);
  aggro:SetColorTexture(1, 0.18, 0.12);
  aggro:Hide();
  return incomingHeal, damageShield, aggro;
end

function ShowGroupPreview(mode)
  previewMode = mode;
  if (mode == "off") then
    if (preview) then preview:Hide(); end
    return;
  end

  if (not preview) then
    preview = _G.CreateFrame("Frame", nil, _G.UIParent);
    preview:SetFrameStrata("HIGH");
    preview:EnableMouse(false);
    preview:SetClampedToScreen(true);
    local title = preview:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    title:SetPoint("TOPLEFT", preview, "TOPLEFT", 0, -1);
    title:SetText(german and "MUI-Vorschau" or "MUI preview");
    preview.rows = {};
  end

  local party = _G.PartyFrame;
  local uiParent = _G.UIParent;
  local scale = 1;
  preview:ClearAllPoints();
  if (mode ~= "party") then
    local raid = db.profile.nativeUnitFrames.raid;
    preview:SetPoint(raid.point, uiParent, raid.point, raid.x, raid.y);
  elseif (db.profile.nativeUnitFrames.party.customPosition) then
    local settings = db.profile.nativeUnitFrames.party;
    preview:SetPoint(settings.point, uiParent, settings.point, settings.x, settings.y);
    if (party) then scale = party:GetEffectiveScale() / uiParent:GetEffectiveScale(); end
  elseif (party and party:GetNumPoints() > 0) then
    preview:SetPoint("BOTTOMLEFT", party, "BOTTOMLEFT");
    scale = party:GetEffectiveScale() / uiParent:GetEffectiveScale();
  else
    preview:SetPoint("BOTTOMLEFT", uiParent, "BOTTOMLEFT");
  end
  local count = mode == "party" and 5 or 40;
  local width, height = GetGroupRowSize(mode);
  local columns = mode == "party" and 1 or 5;
  if (mode ~= "party") then
    local requested = tonumber(db.profile.nativeUnitFrames.party.raidPreviewColumns) or 0;
    if (requested > 0) then columns = math.min(count, math.max(1, math.floor(requested + 0.5))); end
  end
  local rowsPerColumn = math.floor(count / columns);
  local tallerColumns = count % columns;
  local rows = math.ceil(count / columns);
  local gap, titleHeight = partyRowGap, 17;
  local totalWidth = columns * (width + gap) - gap;
  local totalHeight = rows * (height + gap) - gap + titleHeight;
  preview:SetSize(totalWidth, totalHeight);
  if (mode ~= "party") then
    scale = math.min(scale, uiParent:GetWidth() / totalWidth, uiParent:GetHeight() / totalHeight);
  end
  preview:SetScale(scale);
  local column, slot = 0, 0;
  for index = 1, count do
    local row = preview.rows[index];
    if (not row) then
      row = _G.CreateFrame("Frame", nil, preview);
      row:EnableMouse(false);
      local life = CreateBar(row, 32, 0.075, 0.075, 0.085);
      life:SetPoint("TOPLEFT", 1, -1);
      life:SetPoint("TOPRIGHT", -1, -1);
      local resource = CreateBar(row, 5, 0.22, 0.49, 0.86);
      resource:SetPoint("BOTTOMLEFT", 1, 1);
      resource:SetPoint("BOTTOMRIGHT", -1, 1);
      local labels = _G.CreateFrame("Frame", nil, life);
      labels:SetAllPoints();
      labels:SetFrameLevel(life:GetFrameLevel() + 2);
      local name = labels:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
      local font, size = name:GetFont();
      name:SetFont(font, size + 1, "OUTLINE");
      name:SetPoint("LEFT", 4, -2);
      local percent = labels:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
      percent:SetPoint("RIGHT", -4, -2);
      percent:SetTextColor(0.48, 1, 0.32);
      local health = 100 - ((index - 1) % 5) * 12;
      life:SetMinMaxValues(0, 100);
      life:SetValue(health);
      resource:SetMinMaxValues(0, 100);
      resource:SetValue(100 - ((index - 1) % 5) * 8);
      row.life = life;
      row.label = name;
      row.percent = percent;
      row.sampleHealth = health;
      preview.rows[index] = row;
    end

    row:ClearAllPoints();
    local fromTop = mode == "party" and db.profile.nativeUnitFrames.party.customPosition
      and not db.profile.nativeUnitFrames.party.point:find("BOTTOM");
    if (fromTop) then
      row:SetPoint("TOPLEFT", preview, "TOPLEFT", column * (width + gap), -titleHeight - slot * (height + gap));
    else
      row:SetPoint("BOTTOMLEFT", preview, "BOTTOMLEFT", column * (width + gap), slot * (height + gap));
    end
    slot = slot + 1;
    if (slot == rowsPerColumn + (column < tallerColumns and 1 or 0)) then
      column = column + 1;
      slot = 0;
    end
    row:SetSize(width, height);
    row.life:SetHeight(height - 8);
    local class = previewClasses[(index - 1) % #previewClasses + 1];
    local color = _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class];
    ColorGroupName(row.label, color, mode);
    ColorGroupHealth(row.life, color, mode);
    local partySample = mode == "party";
    if (partySample and not row.aggro) then
      row.incomingHeal, row.damageShield, row.aggro = CreatePartyStatusIndicators(row.life, true);
      row.incomingHeal:SetMinMaxValues(0, 100);
      row.damageShield:SetMinMaxValues(0, 100);
    end
    if (row.aggro) then
      row.aggro:SetShown(partySample and index == 1);
      row.incomingHeal:SetValue(partySample and index == 2 and 24 or 0);
      row.damageShield:SetValue(partySample and index == 3 and 40 or 0);
    end
    local sampleName = partySample and (
      german and ({ "Aggro", "Heilung", "Schutzschild", "Offline", "Bereit" })[index]
        or ({ "Aggro", "Incoming heal", "Shield", "Offline", "Ready" })[index])
      or (german and "Beispiel " or "Sample ")..index;
    row.label:SetText(sampleName);
    if (partySample and index == 4) then
      row.percent:SetText(_G.PLAYER_OFFLINE or "Offline");
      row.percent:SetTextColor(0.8, 0.8, 0.8);
    else
      row.percent:SetFormattedText("%d%%", row.sampleHealth);
      row.percent:SetTextColor(0.48, 1, 0.32);
    end
    row:Show();
  end
  for index = count + 1, #preview.rows do preview.rows[index]:Hide(); end
  preview:Show();
end

local function CreateUnitDisplay(panel, name, unit)
  local settings = db.profile.nativeUnitFrames[unit];
  if (not panel or not settings.enabled) then return end

  local frame = _G.CreateFrame("Frame", name, panel);
  frame:SetPoint("TOPLEFT", panel, "TOPLEFT", 22, -10);
  frame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -22, -10);
  frame:SetHeight(60);
  frame:SetFrameLevel(panel:GetFrameLevel() + 2);
  frame:EnableMouse(false);

  local outline = frame:CreateTexture(nil, "BACKGROUND", nil, -2);
  outline:SetPoint("TOPLEFT", -1, 1);
  outline:SetPoint("BOTTOMRIGHT", 1, -1);
  outline:SetColorTexture(0.02, 0.02, 0.025, 1);

  local portraitBand = _G.CreateFrame("Frame", nil, frame);
  portraitBand:SetPoint("TOPLEFT");
  portraitBand:SetPoint("TOPRIGHT");
  portraitBand:SetHeight(29);
  frame.castAnchor = portraitBand;
  local portraitBackground = portraitBand:CreateTexture(nil, "BACKGROUND");
  portraitBackground:SetAllPoints();
  portraitBackground:SetColorTexture(1, 1, 1, 1);
  local r, g, b = tk:GetThemeColor();
  tk:SetGradient(portraitBackground, "VERTICAL", 0.015, 0.015, 0.02, 1, r * 0.35, g * 0.35, b * 0.35, 1);

  local model = _G.CreateFrame("PlayerModel", nil, portraitBand);
  model:SetAllPoints();
  model:EnableMouse(false);
  model:Hide();

  local portrait = portraitBand:CreateTexture(nil, "ARTWORK");
  portrait:SetAllPoints();
  local function CropPortrait(_, width, height)
    if (width <= 0 or height <= 0) then return end
    local horizontal = math.min(1, width / height) * 0.5;
    local vertical = math.min(1, height / width) * 0.5;
    portrait:SetTexCoord(0.5 - horizontal, 0.5 + horizontal, 0.5 - vertical, 0.5 + vertical);
  end
  local portraitFallback, portraitFade;
  if (unit == "target") then
    portrait:ClearAllPoints();
    portrait:SetPoint("LEFT", portraitBand, "LEFT", 2, 0);
    portrait:SetSize(44, 29);
    CropPortrait(portraitBand, 44, 29);
    portraitFallback = portraitBand:CreateTexture(nil, "BORDER");
    portraitFallback:SetAllPoints(portrait);
    portraitFallback:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
    portraitFallback:Hide();
    portraitFade = portraitBand:CreateTexture(nil, "OVERLAY");
    portraitFade:SetPoint("TOPRIGHT", portrait, "TOPRIGHT");
    portraitFade:SetPoint("BOTTOMRIGHT", portrait, "BOTTOMRIGHT");
    portraitFade:SetWidth(12);
    portraitFade:SetColorTexture(1, 1, 1, 1);
    tk:SetGradient(portraitFade, "HORIZONTAL", r * 0.22, g * 0.22, b * 0.22, 0,
      r * 0.22, g * 0.22, b * 0.22, 0.95);
    portraitFade:Hide();
  else
    portraitBand:SetScript("OnSizeChanged", CropPortrait);
    CropPortrait(portraitBand, portraitBand:GetSize());
  end

  local function ShowTexturePortrait()
    model:Hide();
    portrait:SetTexture(nil);
    local ok = pcall(_G.SetPortraitTexture, portrait, unit);
    portrait:SetShown(ok);
    if (portraitFallback) then portraitFallback:Show(); end
    if (portraitFade) then portraitFade:SetShown(ok); end
    frame.portraitMode = "2D";
  end

  local function UpdatePortrait(event)
    if (unit == "target" and _G.IsInInstance() and _G.issecretvalue
        and _G.issecretvalue(_G.UnitGUID(unit))) then
      ShowTexturePortrait();
      model:ClearModel();
      frame.portraitError = nil;
      return;
    end

    if (event == "UNIT_PORTRAIT_UPDATE" and frame.portraitMode == "3D") then
      return;
    end

    if (unit == "target") then
      model:ClearAllPoints();
      model:SetAllPoints();
      ShowTexturePortrait();
      if (event == "PLAYER_TARGET_CHANGED") then model:ClearModel(); end
    end

    model:Show();
    local ok, loaded = pcall(model.SetUnit, model, unit, false);
    if (ok and not (_G.issecretvalue and _G.issecretvalue(loaded)) and loaded ~= false) then
      model:SetPortraitZoom(settings.zoom);
      model:SetPosition(0, 0, 0);
      model:SetAnimation(0);
      portrait:Hide();
      if (portraitFallback) then portraitFallback:Hide(); end
      if (portraitFade) then portraitFade:Hide(); end
      frame.portraitMode = "3D";
      frame.portraitError = nil;
    else
      if (unit == "target") then model:Hide(); else ShowTexturePortrait(); end
      frame.portraitError = ok and "SetUnit did not confirm the model" or tostring(loaded);
    end
  end

  local color = db.profile.nativeUnitFrames.healthColor;
  local health = CreateBar(frame, 20, color.r, color.g, color.b);
  unitHealthBars[unit] = health;
  health:SetPoint("TOPLEFT", portraitBand, "BOTTOMLEFT", 0, -1);
  health:SetPoint("TOPRIGHT", portraitBand, "BOTTOMRIGHT", 0, -1);

  local function CreateHealthLabel(point, x)
    local text = health:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    text:SetPoint(point, x, 0);
    text:SetTextColor(0.32, 1, 0.15);
    text:SetShadowColor(0, 0, 0, 1);
    text:SetShadowOffset(1, -1);
    return text;
  end

  local healthText = CreateHealthLabel("LEFT", 5);
  local percentText = CreateHealthLabel("RIGHT", -5);
  tk:SetFontSize(percentText, 14);
  local scaleTo100 = _G.CurveConstants and _G.CurveConstants.ScaleTo100;

  local power = CreateBar(frame, 9, 0.22, 0.49, 0.86);
  power:SetPoint("BOTTOMLEFT");
  power:SetPoint("BOTTOMRIGHT");
  if (unit == "player") then
    local function ApplyLayoutBarHeights()
      local healer = db.profile.layout == "Healer";
      health:SetHeight(healer and 14.5 or 20);
      power:SetHeight(healer and 14.5 or 9);
    end
    ApplyLayoutBarHeights();
    _G.hooksecurefunc(MayronUI, "SwitchLayouts", ApplyLayoutBarHeights);
  end
  local isTarget = unit == "target";

  local function Refresh(_, event)
    if (isTarget and not _G.UnitExists(unit)) then
      frame:Hide();
      return;
    end

    frame:Show();
    if (not event or event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_TARGET_CHANGED"
        or event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED"
        or event == "UNIT_PORTRAIT_UPDATE" or event == "UNIT_MODEL_CHANGED") then
      UpdatePortrait(event);
    end

    local powerType, powerToken = _G.UnitPowerType(unit);
    local powerColors = _G.PowerBarColor;
    local isSecret = _G.issecretvalue;
    local powerColor;
    if (powerColors) then
      if (not (isSecret and isSecret(powerToken)) and powerToken) then
        powerColor = powerColors[powerToken];
      end
      if (not powerColor and not (isSecret and isSecret(powerType)) and powerType) then
        powerColor = powerColors[powerType];
      end
    end
    if (powerColor) then
      power:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b);
    else
      power:SetStatusBarColor(0.22, 0.49, 0.86);
    end

    -- The widgets accept protected values directly.
    local currentHealth, maxHealth = _G.UnitHealth(unit), _G.UnitHealthMax(unit);
    health:SetMinMaxValues(0, maxHealth);
    health:SetValue(currentHealth);
    healthText:SetFormattedText("%d", currentHealth);
    if (scaleTo100 and _G.UnitHealthPercent) then
      percentText:SetFormattedText("%.0f%%", _G.UnitHealthPercent(unit, false, scaleTo100));
    elseif (not (_G.issecretvalue and (_G.issecretvalue(currentHealth) or _G.issecretvalue(maxHealth)))
        and maxHealth > 0) then
      percentText:SetFormattedText("%.0f%%", currentHealth / maxHealth * 100);
    else
      percentText:SetText("");
    end
    power:SetMinMaxValues(0, _G.UnitPowerMax(unit));
    power:SetValue(_G.UnitPower(unit));
  end

  frame:RegisterEvent("PLAYER_ENTERING_WORLD");
  if (unit == "target") then
    frame:RegisterEvent("PLAYER_TARGET_CHANGED");
    frame:RegisterEvent("PLAYER_REGEN_DISABLED");
    frame:RegisterEvent("PLAYER_REGEN_ENABLED");
  end
  frame:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", unit);
  frame:RegisterUnitEvent("UNIT_MODEL_CHANGED", unit);
  frame:RegisterUnitEvent("UNIT_HEALTH", unit);
  frame:RegisterUnitEvent("UNIT_MAXHEALTH", unit);
  frame:RegisterUnitEvent("UNIT_POWER_UPDATE", unit);
  frame:RegisterUnitEvent("UNIT_MAXPOWER", unit);
  frame:RegisterUnitEvent("UNIT_DISPLAYPOWER", unit);
  frame:SetScript("OnEvent", Refresh);
  Refresh();
  return frame;
end

local function EnableUnitMenu(display, unit, buttonName)
  if (not display) then return end

  local uiParent = _G.UIParent;
  local watchTarget = unit == "target";
  local button, queued;
  local function QueuePosition()
    if (queued) then return end
    queued = true;
    _G.C_Timer.After(0, function()
      queued = false;
      if (_G.InCombatLockdown()) then return end
      if (not watchTarget and not display:IsVisible()) then
        if (button) then button:Hide(); end
        return;
      end

      local left, bottom, width, height = display:GetRect();
      if (not left or not bottom or not width or not height or width <= 0 or height <= 0) then return end
      local scale = display:GetEffectiveScale() / uiParent:GetEffectiveScale();

      -- The secure click area follows the layout without anchoring to its frames.
      if (not button) then
        button = _G.CreateFrame("Button", buttonName, uiParent, "SecureUnitButtonTemplate");
        button:SetFrameStrata("LOW");
        button:EnableMouse(true);
        button:RegisterForClicks("RightButtonUp");
        if (button.SetPassThroughButtons) then button:SetPassThroughButtons("LeftButton"); end
        button:SetAttribute("unit", unit);
        button:SetAttribute("useOnKeyDown", false);
        button:SetAttribute("*type2", "togglemenu");
        if (watchTarget) then
          button:Hide();
          _G.RegisterUnitWatch(button);
        end
      end

      button:ClearAllPoints();
      button:SetPoint("BOTTOMLEFT", uiParent, "BOTTOMLEFT",
        left * scale - (uiParent:GetLeft() or 0), bottom * scale - (uiParent:GetBottom() or 0));
      button:SetSize(width * scale, height * scale);
      if (not watchTarget) then button:Show(); end
    end);
  end

  display:HookScript("OnShow", QueuePosition);
  display:HookScript("OnHide", QueuePosition);
  display:HookScript("OnSizeChanged", QueuePosition);
  _G.hooksecurefunc(display:GetParent(), "SetPoint", QueuePosition);
  local bottomContainer = _G.MUI_BottomContainer;
  if (bottomContainer) then
    _G.hooksecurefunc(bottomContainer, "SetPoint", QueuePosition);
    bottomContainer:HookScript("OnSizeChanged", QueuePosition);
  end
  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
  watcher:RegisterEvent("UI_SCALE_CHANGED");
  watcher:RegisterEvent("DISPLAY_SIZE_CHANGED");
  watcher:SetScript("OnEvent", QueuePosition);
  QueuePosition();
end

local function CreateCompactHealthText(bar)
  local text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
  text:SetPoint("RIGHT", -3, 0);
  text:SetTextColor(0.55, 1, 0.4);
  text:SetShadowOffset(1, -1);
  return text;
end

local function UpdateCompactHealth(bar, text, unit)
  local current, maximum = _G.UnitHealth(unit), _G.UnitHealthMax(unit);
  bar:SetMinMaxValues(0, maximum);
  bar:SetValue(current);

  local scale = _G.CurveConstants and _G.CurveConstants.ScaleTo100;
  local isSecret = _G.issecretvalue;
  if (scale and _G.UnitHealthPercent) then
    local percent = _G.UnitHealthPercent(unit, false, scale);
    if ((isSecret and isSecret(percent)) or type(percent) == "number") then
      text:SetFormattedText("%.0f%%", percent);
      return;
    end
  end
  if (not (isSecret and (isSecret(current) or isSecret(maximum))) and maximum > 0) then
    text:SetFormattedText("%.0f%%", current / maximum * 100);
  else
    text:SetText("");
  end
end

local function StylePetFrame(pet)
  local visual = _G.CreateFrame("Frame", nil, pet);
  visual:SetPoint("BOTTOM");
  visual:SetSize(104, 18);
  visual:EnableMouse(false);

  local border = visual:CreateTexture(nil, "BACKGROUND", nil, -2);
  border:SetAllPoints();
  border:SetColorTexture(0.02, 0.02, 0.025, 1);

  local background = visual:CreateTexture(nil, "BACKGROUND", nil, -1);
  background:SetPoint("TOPLEFT", 1, -1);
  background:SetPoint("BOTTOMRIGHT", -1, 1);
  background:SetColorTexture(0.075, 0.075, 0.085, 0.98);

  local health = CreateBar(visual, 16, 0.29, 0.52, 0.25);
  health:SetPoint("TOPLEFT", 1, -1);
  health:SetPoint("BOTTOMRIGHT", -1, 1);
  local percent = CreateCompactHealthText(health);

  local buff = _G.CreateFrame("Frame", nil, visual);
  buff:SetSize(14, 14);
  buff:SetPoint("LEFT", 2, 0);
  buff:EnableMouse(true);
  buff:Hide();
  local icon = buff:CreateTexture(nil, "ARTWORK");
  icon:SetAllPoints();

  local name = health:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
  name:SetPoint("LEFT", 4, 0);
  name:SetPoint("RIGHT", -31, 0);
  name:SetJustifyH("CENTER");
  name:SetMaxLines(1);

  local function CanReadPetBuff()
    local secrets = _G.C_Secrets;
    if (secrets and secrets.ShouldAurasBeSecret) then
      local restricted = secrets.ShouldAurasBeSecret();
      if ((_G.issecretvalue and _G.issecretvalue(restricted)) or restricted) then return false end
    end
    return _G.UnitExists("pet") and pet.unit ~= "player";
  end

  local function HideBuffTooltip(self)
    if (_G.GameTooltip:IsOwned(self)) then _G.GameTooltip:Hide(); end
  end

  buff:SetScript("OnEnter", function(self)
    if (not CanReadPetBuff()) then return end
    _G.GameTooltip:SetOwner(self, "ANCHOR_LEFT");
    _G.GameTooltip:SetUnitAura("pet", 1, "HELPFUL");
  end);
  buff:SetScript("OnLeave", HideBuffTooltip);
  buff:SetScript("OnHide", HideBuffTooltip);

  local function Refresh()
    local unit = pet.unit or "pet";
    name:SetText(_G.UnitName(unit));
    UpdateCompactHealth(health, percent, unit);
    local texture;
    local auras = _G.C_UnitAuras;
    if (auras and auras.GetAuraDataByIndex and CanReadPetBuff()) then
      local aura = auras.GetAuraDataByIndex("pet", 1, "HELPFUL");
      if (not (_G.issecretvalue and _G.issecretvalue(aura)) and aura) then
        texture = aura.icon;
      end
    end
    local hasBuff = not (_G.issecretvalue and _G.issecretvalue(texture)) and texture ~= nil;
    icon:SetTexture(hasBuff and texture or nil);
    buff:SetShown(hasBuff);
    name:SetPoint("LEFT", hasBuff and 18 or 4, 0);
  end

  -- Keep Blizzard's protected pet button and replace its artwork.
  pet:SetIgnoreParentAlpha(true);
  for _, key in ipairs({ "PetPortrait", "PetName", "PetFrameTexture", "PetFrameFlash",
      "PetFrameHealthBar", "PetFrameManaBar", "PetHitIndicator" }) do
    local region = _G[key];
    if (region) then region:SetAlpha(0); end
  end
  -- Blizzard animates the attack texture's alpha, so clear its artwork.
  local attackGlow = _G.PetAttackModeTexture;
  if (attackGlow) then attackGlow:SetTexture(nil); end
  if (pet.AuraFrameContainer) then pet.AuraFrameContainer:SetAlpha(0); end
  pet:HookScript("OnEnter", function()
    local tooltip = _G.PartyMemberBuffTooltip;
    if (tooltip) then tooltip:Hide(); end
  end);
  visual:SetScript("OnShow", Refresh);
  visual:RegisterUnitEvent("UNIT_PET", "player");
  visual:RegisterUnitEvent("UNIT_AURA", "pet");
  visual:RegisterUnitEvent("UNIT_HEALTH", "pet", "player");
  visual:RegisterUnitEvent("UNIT_MAXHEALTH", "pet", "player");
  visual:RegisterEvent("PLAYER_REGEN_DISABLED");
  visual:RegisterEvent("PLAYER_REGEN_ENABLED");
  visual:RegisterUnitEvent("UNIT_NAME_UPDATE", "pet", "player");
  visual:SetScript("OnEvent", Refresh);
  Refresh();
end

local function PositionPetFrame()
  local pet, panel = _G.PetFrame, _G.MUI_UnitPanelCenter;
  if (not pet or not panel) then return end
  StylePetFrame(pet);

  local queued, moving;
  local function QueuePosition()
    if (queued or moving) then return end
    queued = true;
    _G.C_Timer.After(0, function()
      queued = false;
      if (_G.InCombatLockdown()) then return end
      local editMode = _G.EditModeManagerFrame;
      if (editMode and editMode:IsEditModeActive()) then return end

      local center, top = panel:GetCenter(), panel:GetTop();
      if (not center or not top) then return end
      local uiParent = _G.UIParent;
      local panelScale, petScale, uiScale = panel:GetEffectiveScale(), pet:GetEffectiveScale(), uiParent:GetEffectiveScale();
      -- The old preset put the pet 12 px above the target-of-target anchor (-40).
      local x = (center * panelScale - uiParent:GetLeft() * uiScale) / petScale;
      local y = ((top - 28) * panelScale - uiParent:GetBottom() * uiScale) / petScale;
      local point, relative, relativePoint, currentX, currentY = pet:GetPoint();
      if (pet:GetNumPoints() == 1 and point == "BOTTOM" and relative == uiParent
          and relativePoint == "BOTTOMLEFT" and math.abs(currentX - x) < 0.1
          and math.abs(currentY - y) < 0.1) then return end

      -- Anchor to UIParent so the protected pet frame does not anchor to MUI.
      moving = true;
      pet:ClearAllPoints();
      pet:SetPoint("BOTTOM", uiParent, "BOTTOMLEFT", x, y);
      moving = false;
    end);
  end

  pet:HookScript("OnShow", QueuePosition);
  _G.hooksecurefunc(pet, "SetPoint", QueuePosition);
  _G.hooksecurefunc(_G.MUI_UnitPanelLeft, "SetPoint", QueuePosition);
  panel:HookScript("OnSizeChanged", QueuePosition);
  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
  watcher:RegisterEvent("UI_SCALE_CHANGED");
  watcher:SetScript("OnEvent", QueuePosition);
  if (_G.EventRegistry and _G.EditModeManagerFrame) then _G.EventRegistry:RegisterCallback("EditMode.Exit", QueuePosition, watcher); end
  QueuePosition();
end

local function CreateTargetOfTargetDisplay(panel)
  if (not panel) then return end

  local unit = "targettarget";
  local frame = _G.CreateFrame("Frame", "MUI_NativeTargetOfTargetFrame", panel);
  frame:SetPoint("TOP", panel, "TOP", 0, -40);
  frame:SetSize(104, 18);
  frame:SetFrameLevel(panel:GetFrameLevel() + 2);

  local border = frame:CreateTexture(nil, "BACKGROUND", nil, -2);
  border:SetAllPoints();
  border:SetColorTexture(0.02, 0.02, 0.025, 1);

  local health = CreateBar(frame, 16, 0.29, 0.52, 0.25);
  health:SetPoint("TOPLEFT", 1, -1);
  health:SetPoint("BOTTOMRIGHT", -1, 1);

  local name = health:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
  name:SetPoint("LEFT", 4, 0);
  name:SetPoint("RIGHT", -31, 0);
  local percent = CreateCompactHealthText(health);
  name:SetJustifyH("CENTER");
  name:SetMaxLines(1);

  local function Refresh()
    if (not _G.UnitExists(unit)) then
      frame:Hide();
      return;
    end

    name:SetText(_G.UnitName(unit));
    UpdateCompactHealth(health, percent, unit);
    frame:Show();
  end

  frame:RegisterEvent("PLAYER_ENTERING_WORLD");
  frame:RegisterEvent("PLAYER_TARGET_CHANGED");
  frame:RegisterUnitEvent("UNIT_TARGET", "target");
  frame:RegisterUnitEvent("UNIT_NAME_UPDATE", unit);
  frame:RegisterUnitEvent("UNIT_HEALTH", unit);
  frame:RegisterUnitEvent("UNIT_MAXHEALTH", unit);
  frame:SetScript("OnEvent", Refresh);
  Refresh();
end

local function SetCustomPartyPosition()
  local party = _G.PartyFrame;
  if (not party) then return end

  local originalClamp = party:IsClampedToScreen();
  local queued, moving;
  local function QueuePosition()
    if (queued or moving) then return end
    queued = true;
    _G.C_Timer.After(0, function()
      queued = false;
      if (_G.InCombatLockdown()) then return end
      local editMode = _G.EditModeManagerFrame;
      if (editMode and editMode:IsEditModeActive()) then
        if (party:IsClampedToScreen() ~= originalClamp) then
          party:SetClampedToScreen(originalClamp);
        end
        return;
      end

      if (not db.profile.nativeUnitFrames.party.customPosition) then return end

      if (party:IsClampedToScreen()) then party:SetClampedToScreen(false); end

      local point, relative, relativePoint, x, y = party:GetPoint();
      local position = db.profile.nativeUnitFrames.party;
      local anchor = position.point;
      if (party:GetNumPoints() == 1 and point == anchor and relative == _G.UIParent
          and relativePoint == anchor and math.abs(x - position.x) < 0.01
          and math.abs(y - position.y) < 0.01) then return end

      moving = true;
      party:ClearAllPoints();
      party:SetPoint(anchor, _G.UIParent, anchor, position.x, position.y);
      moving = false;
    end);
  end

  local layoutEditor = MayronUI:GetComponent("LayoutEditor");
  layoutEditor.ResetPartyPosition = function()
    local path = "profile.nativeUnitFrames.party.";
    db:SetPathValue(path.."customPosition", db:GetDefault(path.."customPosition"));
    db:SetPathValue(path.."point", db:GetDefault(path.."point"));
    db:SetPathValue(path.."x", db:GetDefault(path.."x"));
    db:SetPathValue(path.."y", db:GetDefault(path.."y"));
    UpdatePartyPosition();
  end
  layoutEditor.AddParty = function(add)
    local settings = db.profile.nativeUnitFrames.party;
    local point = settings.point;
    local width, height = GetGroupRowSize("party");
    add(german and "Gruppe" or "Party", width, height, point, _G.UIParent, point, settings.x, settings.y,
      function(_, _, handle)
        local ui = _G.UIParent;
        local dx, dy;
        if (point:find("LEFT")) then
          dx = handle:GetLeft() - ui:GetLeft();
        elseif (point:find("RIGHT")) then
          dx = handle:GetRight() - ui:GetRight();
        else
          dx = (handle:GetLeft() + handle:GetRight() - ui:GetLeft() - ui:GetRight()) / 2;
        end
        if (point:find("BOTTOM")) then
          dy = handle:GetBottom() - ui:GetBottom();
        elseif (point:find("TOP")) then
          dy = handle:GetTop() - ui:GetTop();
        else
          dy = (handle:GetBottom() + handle:GetTop() - ui:GetBottom() - ui:GetTop()) / 2;
        end
        db:SetPathValue("profile.nativeUnitFrames.party.customPosition", true);
        db:SetPathValue("profile.nativeUnitFrames.party.x", dx);
        db:SetPathValue("profile.nativeUnitFrames.party.y", dy);
        UpdatePartyPosition();
      end);
  end

  queuePartyPosition = QueuePosition;
  party:HookScript("OnShow", QueuePosition);
  _G.hooksecurefunc(party, "SetPoint", QueuePosition);
  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
  watcher:SetScript("OnEvent", QueuePosition);
  if (_G.EventRegistry and _G.EditModeManagerFrame) then _G.EventRegistry:RegisterCallback("EditMode.Enter", QueuePosition, watcher); end
  if (_G.EventRegistry and _G.EditModeManagerFrame) then _G.EventRegistry:RegisterCallback("EditMode.Exit", QueuePosition, watcher); end
  QueuePosition();
end

local groupDebuffFilters = {
  all = "HARMFUL";
  mine = "HARMFUL|RAID";
  dispellable = "HARMFUL|DISPELLABLE";
};

local function CreateGroupAuras(row, unit, settings, aboveName)
  local flow = _G.AnchorUtil and _G.AnchorUtil.FlowDirection;
  if (not _G.CustomAuraContainerGroupDefaultOptions or not flow
      or not _G.AuraContainerSortMethod or not _G.AuraContainerSortDirection) then return end

  local iconSize, spacing = 12, 2;
  local groupWidth = 4 * (iconSize + spacing);
  local holder = _G.CreateFrame("Frame", nil, row);
  holder:SetSize(2 * groupWidth, iconSize);
  local groups = {};
  local currentDebuffFilter = groupDebuffFilters[settings.debuffFilter] or groupDebuffFilters.all;

  local ok, err = pcall(function()
    for _, filter in ipairs({ "HELPFUL", "HARMFUL" }) do
      local harmful = filter == "HARMFUL";
      local container = _G.CreateFrame("AuraContainer", nil, holder, "CustomAuraContainerTemplate");
      groups[filter] = container;
      container:SetPoint("TOPLEFT", holder, "TOPLEFT");
      container:SetUnit(unit);
      container:SetFlowLayoutMaximumLineSize(groupWidth);
      container:SetFlowLayoutGrowthDirection(flow.Right, flow.Down);
      container:SetFlowLayoutAnchorPoint("TOPLEFT");
      container:AddAuraGroup(filter, harmful and currentDebuffFilter or filter, {
        maxFrameCount = 4;
        sortMethod = _G.AuraContainerSortMethod.Default;
        sortDirection = _G.AuraContainerSortDirection.Normal;
        layout = { elementSpacing = spacing; lineSpacing = spacing };
        initializeFrame = function(button)
          button:SetSize(iconSize, iconSize);
          local border = button:CreateTexture(nil, "BACKGROUND");
          border:SetAllPoints();
          if (harmful) then
            border:SetColorTexture(0.8, 0.15, 0.15, 1);
          else
            border:SetColorTexture(0.08, 0.08, 0.10, 1);
          end
          local icon = button:CreateTexture(nil, "ARTWORK");
          icon:SetPoint("TOPLEFT", 1, -1);
          icon:SetPoint("BOTTOMRIGHT", -1, 1);
          button:SetIcon(icon);
        end;
      });
      container:SetEnabled(true);
    end
  end);
  if (not ok) then
    holder:Hide();
    return nil, err;
  end
  return function(width, height, showBuffs, showDebuffs, debuffFilter, newUnit)
    if (newUnit and newUnit ~= unit) then
      groups.HELPFUL:SetUnit(newUnit);
      groups.HARMFUL:SetUnit(newUnit);
      unit = newUnit;
    end
    local filter = groupDebuffFilters[debuffFilter] or groupDebuffFilters.all;
    if (filter ~= currentDebuffFilter and groups.HARMFUL.SetAuraGroupFilterString) then
      groups.HARMFUL:SetAuraGroupFilterString("HARMFUL", filter);
      currentDebuffFilter = filter;
    end
    local visibleWidth = showBuffs and showDebuffs and 2 * groupWidth or groupWidth;
    if (aboveName) then
      local scale = math.min(1, (width - 68) / visibleWidth, (height - 17) / iconSize);
      holder:SetScale(scale);
      holder:SetPoint("TOPLEFT", row, "TOPLEFT", 30 / scale, -2 / scale);
    else
      local scale = math.min(1, (width - 8) / holder:GetWidth(), (height - 17) / iconSize);
      holder:SetScale(scale);
      holder:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 4 / scale, 7 / scale);
    end
    groups.HELPFUL:SetShown(showBuffs);
    groups.HARMFUL:SetPoint("TOPLEFT", holder, "TOPLEFT", showBuffs and groupWidth or 0, 0);
    groups.HARMFUL:SetShown(showDebuffs);
    holder:SetShown(showBuffs or showDebuffs);
  end;
end

local function SkinPartyFrames()
  if (_G.C_AddOns and _G.C_AddOns.LoadAddOn) then
    _G.C_AddOns.LoadAddOn("Blizzard_AuraContainer");
  end
  local reportedAuraError;
  local styled = {};
  local scaleTo100 = _G.CurveConstants and _G.CurveConstants.ScaleTo100;

  local selfFrame;
  local function SkinMember(frame, playerRow)
    local container = frame.HealthBarContainer;
    local health = container and container.HealthBar;
    if (not playerRow and (not health or not frame.ManaBar or not frame.Name
        or not frame.UpdateArt or not frame.unitToken)) then return end

    if (not styled[frame]) then
      local left, right, top, bottom = frame:GetHitRectInsets();
      local row = _G.CreateFrame("Frame", nil, frame);
      row:SetPoint("TOPLEFT");
      row:EnableMouse(false);
      local layoutAuras, auraError = CreateGroupAuras(row, frame.unitToken, db.profile.nativeUnitFrames.party, true);
      if (auraError and not reportedAuraError) then
        reportedAuraError = true;
        tk:Print(tostring(auraError));
      end

      local border = row:CreateTexture(nil, "BACKGROUND");
      border:SetAllPoints();
      border:SetColorTexture(0.015, 0.015, 0.02, 1);

      local life = CreateBar(row, 32, 0.075, 0.075, 0.085);
      life:SetPoint("TOPLEFT", 1, -1);
      life:SetPoint("TOPRIGHT", -1, -1);
      local resource = CreateBar(row, 5, 0.22, 0.49, 0.86);
      resource:SetPoint("BOTTOMLEFT", 1, 1);
      resource:SetPoint("BOTTOMRIGHT", -1, 1);

      local prediction;
      if (_G.CreateUnitHealPredictionCalculator and _G.UnitGetDetailedHealPrediction) then
        prediction = _G.CreateUnitHealPredictionCalculator();
      end
      local legacyPrediction = isMists and _G.UnitGetIncomingHeals and _G.UnitGetTotalAbsorbs;
      local incomingHeal, damageShield, aggro = CreatePartyStatusIndicators(life, prediction or legacyPrediction);

      local labels = _G.CreateFrame("Frame", nil, life);
      labels:SetAllPoints(life);
      labels:SetFrameLevel(life:GetFrameLevel() + 2);
      local name = labels:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
      local font, size = name:GetFont();
      name:SetFont(font, size + 1, "OUTLINE");
      name:SetPoint("BOTTOMLEFT", life, "BOTTOMLEFT", 4, 1);
      name:SetPoint("BOTTOMRIGHT", life, "BOTTOMRIGHT", -46, 1);
      name:SetJustifyH("LEFT");
      name:SetMaxLines(1);
      local percent = labels:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
      percent:SetPoint("BOTTOMRIGHT", life, "BOTTOMRIGHT", -4, 1);
      percent:SetTextColor(0.48, 1, 0.32);

      local leaderIcon = life:CreateTexture(nil, "OVERLAY", nil, 7);
      leaderIcon:SetSize(11, 11);
      leaderIcon:SetPoint("TOPLEFT", 3, -1);
      local roleIcon = life:CreateTexture(nil, "OVERLAY", nil, 7);
      roleIcon:SetSize(11, 11);
      roleIcon:SetPoint("LEFT", leaderIcon, "RIGHT", 2, 0);
      leaderIcon:SetTexture("Interface\\GroupFrame\\UI-Group-LeaderIcon");
      local marker = life:CreateTexture(nil, "OVERLAY", nil, 7);
      marker:SetSize(14, 14);
      marker:SetPoint("TOPRIGHT", -3, -1);
      marker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons");
      marker:Hide();

      local isSecret = _G.issecretvalue;
      local function UpdateRange()
        local unit = playerRow and "player" or frame.unit;
        local state = frame.state;
        if (isSecret and (isSecret(unit) or isSecret(state))) then return end
        if (state == "vehicle" or not unit or playerRow or not _G.UnitInRange) then
          row:SetAlpha(1);
          return;
        end

        local inRange, checked = _G.UnitInRange(unit);
        if (isSecret and isSecret(inRange)) then
          if (row.SetAlphaFromBoolean) then
            row:SetAlphaFromBoolean(inRange, 1, 0.55);
          else
            row:SetAlpha(1);
          end
        else
          local rangeKnown = not (isSecret and isSecret(checked)) and checked;
          row:SetAlpha(rangeKnown and inRange == false and 0.55 or 1);
        end
      end

      local function Update()
        local unit = playerRow and "player" or frame.unit;
        local state = frame.state;
        if (isSecret and (isSecret(unit) or isSecret(state))) then return end
        local exists = unit and _G.UnitExists(unit);
        if (state == "vehicle" or not unit or (not (isSecret and isSecret(exists)) and not exists)) then
          name:SetText("");
          percent:SetText("");
          roleIcon:Hide();
          leaderIcon:Hide();
          marker:Hide();
          aggro:Hide();
          if (incomingHeal) then
            incomingHeal:SetValue(0);
            damageShield:SetValue(0);
          end
          row:SetAlpha(1);
          return;
        end

        local unitName, level = _G.UnitName(unit), _G.UnitLevel(unit);
        if (tk:IsForever() and db.profile.nativeUnitFrames.party.showFullNames and _G.GetUnitName) then
          local fullName = _G.GetUnitName(unit, true);
          if (not (isSecret and isSecret(fullName)) and type(fullName) == "string" and fullName ~= "") then
            unitName = fullName;
          end
        end
        if (not (isSecret and (isSecret(unitName) or isSecret(level))) and unitName and level and level > 0) then
          name:SetFormattedText("%s %d", unitName, level);
        else
          name:SetText(unitName);
        end

        local role = _G.UnitGroupRolesAssigned and _G.UnitGroupRolesAssigned(unit);
        local roleAtlas;
        if (not (isSecret and isSecret(role))) then
          if (role == "TANK") then
            roleAtlas = "roleicon-tiny-tank";
          elseif (role == "HEALER") then
            roleAtlas = "roleicon-tiny-healer";
          elseif (role == "DAMAGER") then
            roleAtlas = "roleicon-tiny-dps";
          end
        end
        if (roleAtlas) then roleIcon:SetAtlas(roleAtlas); end
        roleIcon:SetShown(roleAtlas ~= nil);

        local leader = _G.UnitIsGroupLeader(unit);
        if (isSecret and isSecret(leader)) then
          leaderIcon:SetShown(leaderIcon.SetAlphaFromBoolean ~= nil);
          if (leaderIcon.SetAlphaFromBoolean) then leaderIcon:SetAlphaFromBoolean(leader, 1, 0); end
        else
          leaderIcon:SetAlpha(1);
          leaderIcon:SetShown(leader == true);
        end
        local _, class = _G.UnitClass(unit);
        local color;
        if (not (_G.issecretvalue and _G.issecretvalue(class)) and class) then
          color = _G.RAID_CLASS_COLORS and _G.RAID_CLASS_COLORS[class];
        end
        ColorGroupName(name, color, "party");
        ColorGroupHealth(life, color, "party");
        local currentHealth, maxHealth = _G.UnitHealth(unit), _G.UnitHealthMax(unit);
        life:SetMinMaxValues(0, maxHealth);
        life:SetValue(currentHealth);
        resource:SetMinMaxValues(0, _G.UnitPowerMax(unit));
        resource:SetValue(_G.UnitPower(unit));
        local powerType, powerToken = _G.UnitPowerType(unit);
        local colors = _G.PowerBarColor;
        local powerColor;
        if (colors) then
          if (not (isSecret and isSecret(powerToken)) and powerToken) then
            powerColor = colors[powerToken];
          end
          if (not powerColor and not (isSecret and isSecret(powerType)) and powerType) then
            powerColor = colors[powerType];
          end
        end
        if (powerColor) then
          resource:SetStatusBarColor(powerColor.r, powerColor.g, powerColor.b);
        else
          resource:SetStatusBarColor(0.22, 0.49, 0.86);
        end
        local connected = _G.UnitIsConnected(unit);
        local dead = _G.UnitIsDeadOrGhost(unit);
        local offline = not (isSecret and isSecret(connected)) and connected == false;
        local isDead = not (isSecret and isSecret(dead)) and dead == true;
        local inactive = offline or isDead;
        if (incomingHeal) then
          if (inactive) then
            incomingHeal:SetValue(0);
            damageShield:SetValue(0);
          elseif (prediction) then
            _G.UnitGetDetailedHealPrediction(unit, nil, prediction);
            local maximum = prediction:GetMaximumHealth();
            incomingHeal:SetMinMaxValues(0, maximum);
            incomingHeal:SetValue((prediction:GetIncomingHeals()));
            damageShield:SetMinMaxValues(0, maximum);
            damageShield:SetValue((prediction:GetDamageAbsorbs()));
          else
            incomingHeal:SetMinMaxValues(0, maxHealth);
            local incoming = _G.UnitGetIncomingHeals(unit);
            if (isSecret and isSecret(incoming)) then incomingHeal:SetValue(incoming);
            else incomingHeal:SetValue(incoming or 0); end
            damageShield:SetMinMaxValues(0, maxHealth);
            local absorbs = _G.UnitGetTotalAbsorbs(unit);
            if (isSecret and isSecret(absorbs)) then damageShield:SetValue(absorbs);
            else damageShield:SetValue(absorbs or 0); end
          end
        end
        local threat = not inactive and _G.UnitThreatSituation and _G.UnitThreatSituation(unit);
        aggro:SetShown(not (isSecret and isSecret(threat)) and type(threat) == "number" and threat >= 2);

        if (inactive) then
          percent:SetText(offline and (_G.PLAYER_OFFLINE or "Offline") or (_G.DEAD or "Dead"));
          percent:SetTextColor(0.8, 0.8, 0.8);
        else
          percent:SetTextColor(0.48, 1, 0.32);
          if (scaleTo100 and _G.UnitHealthPercent) then
            percent:SetFormattedText("%.0f%%", _G.UnitHealthPercent(unit, false, scaleTo100));
          elseif (not (isSecret and (isSecret(currentHealth) or isSecret(maxHealth))) and maxHealth > 0) then
            percent:SetFormattedText("%.0f%%", currentHealth / maxHealth * 100);
          else
            percent:SetText("");
          end
        end

        local mark = _G.GetRaidTargetIndex(unit);
        local showMarker = not (isSecret and isSecret(mark)) and mark ~= nil and _G.SetRaidTargetIconTexture;
        if (showMarker) then _G.SetRaidTargetIconTexture(marker, mark); end
        marker:SetShown(not not showMarker);
      end

      local readyCheck = not playerRow and frame.ReadyCheck;
      local readyCheckLayout;
      local function LayoutReadyCheck(normal)
        if (not readyCheck) then return end
        if (normal and not readyCheckLayout) then
          readyCheckLayout = { scale = readyCheck:GetScale() };
          for i = 1, readyCheck:GetNumPoints() do
            readyCheckLayout[i] = { readyCheck:GetPoint(i) };
          end
          readyCheck:SetScale(readyCheckLayout.scale * 0.5);
          readyCheck:ClearAllPoints();
          readyCheck:SetPoint("TOPRIGHT", row, "TOPRIGHT", -22, -2);
        elseif (not normal and readyCheckLayout) then
          readyCheck:SetScale(readyCheckLayout.scale);
          readyCheck:ClearAllPoints();
          for _, point in ipairs(readyCheckLayout) do
            readyCheck:SetPoint(unpack(point, 1, 5));
          end
          readyCheckLayout = nil;
        end
      end

      local function ApplyArt()
        if (_G.InCombatLockdown()) then return end
        local normal = frame.state ~= "vehicle";
        local alpha = normal and 0 or 1;
        row:SetShown(normal);
        LayoutReadyCheck(normal);
        if (frame.Texture) then frame.Texture:SetAlpha(alpha); end
        if (frame.Portrait) then frame.Portrait:Hide(); end
        if (not playerRow) then
          frame.Name:SetAlpha(alpha);
          container:SetAlpha(alpha);
          frame.ManaBar:SetAlpha(alpha);
          if (layoutAuras and frame.AuraFrameContainer) then frame.AuraFrameContainer:SetAlpha(alpha); end
          local overlay = frame.PartyMemberOverlay;
          if (overlay) then
            if (overlay.RoleIcon) then overlay.RoleIcon:SetAlpha(alpha); end
            if (overlay.LeaderIcon) then overlay.LeaderIcon:SetAlpha(alpha); end
            if (overlay.GuideIcon) then overlay.GuideIcon:SetAlpha(alpha); end
            if (overlay.Disconnect) then overlay.Disconnect:SetAlpha(alpha); end
          end
        end
        if (normal) then
          local width, height = GetGroupRowSize("party");
          row:SetSize(width, height);
          life:SetHeight(height - 8);
          if (layoutAuras) then
            local settings = db.profile.nativeUnitFrames.party;
            layoutAuras(width, height, settings.showBuffs, settings.showDebuffs, settings.debuffFilter);

          end
          if (playerRow) then
            frame:SetSize(width, height);
          else
            frame:SetHitRectInsets(0, frame:GetWidth() - width, 0, frame:GetHeight() - height);
          end
        else
          frame:SetHitRectInsets(left, right, top, bottom);
        end
        Update();
      end

      styled[frame] = ApplyArt;
      if (playerRow) then
        row:RegisterUnitEvent("UNIT_HEALTH", "player");
        row:RegisterUnitEvent("UNIT_POWER_UPDATE", "player");
      else
        _G.hooksecurefunc(frame, "UpdateArt", ApplyArt);
        health:HookScript("OnValueChanged", Update);
        frame.ManaBar:HookScript("OnValueChanged", Update);
      end
      row:RegisterUnitEvent("UNIT_NAME_UPDATE", frame.unitToken);
      row:RegisterUnitEvent("UNIT_MAXHEALTH", frame.unitToken);
      row:RegisterUnitEvent("UNIT_MAXPOWER", frame.unitToken);
      row:RegisterUnitEvent("UNIT_DISPLAYPOWER", frame.unitToken);
      row:RegisterUnitEvent("UNIT_LEVEL", frame.unitToken);
      row:RegisterUnitEvent("UNIT_CONNECTION", frame.unitToken);
      if (_G.UnitThreatSituation) then
        row:RegisterUnitEvent("UNIT_THREAT_SITUATION_UPDATE", frame.unitToken);
      end
      if (incomingHeal) then
        row:RegisterUnitEvent("UNIT_HEAL_PREDICTION", frame.unitToken);
        row:RegisterUnitEvent("UNIT_ABSORB_AMOUNT_CHANGED", frame.unitToken);
        if (prediction) then row:RegisterUnitEvent("UNIT_HEAL_ABSORB_AMOUNT_CHANGED", frame.unitToken); end
      end
      row:RegisterUnitEvent("UNIT_FLAGS", frame.unitToken);
      row:RegisterEvent("RAID_TARGET_UPDATE");
      row:RegisterEvent("PLAYER_LEVEL_UP");
      row:RegisterEvent("GROUP_ROSTER_UPDATE");
      row:RegisterEvent("PARTY_LEADER_CHANGED");
      row:RegisterEvent("PLAYER_ROLES_ASSIGNED");
      row:SetScript("OnEvent", Update);
      local rangeElapsed = 0;
      row:SetScript("OnUpdate", function(_, elapsed)
        rangeElapsed = rangeElapsed + elapsed;
        if (rangeElapsed < 0.25) then return end
        rangeElapsed = 0;
        UpdateRange();
      end);
      frame:HookScript("OnShow", function()
        Update();
        UpdateRange();
      end);
    end
    styled[frame]();
    return true;
  end

  local function PlacePartyRow(frame, party, anchor, index, count)
    local width, height = GetGroupRowSize("party");
    local step = height + partyRowGap;
    local x = anchor:find("RIGHT") and -width or (anchor:find("LEFT") and 0 or -width / 2);
    local y;
    if (anchor:find("BOTTOM")) then
      y = height + (index - 1) * step;
    elseif (anchor:find("TOP")) then
      y = -(index - 1) * step;
    else
      y = (count * step - partyRowGap) / 2 - (index - 1) * step;
    end
    local point, relative, relativePoint, currentX, currentY = frame:GetPoint();
    if (frame:GetNumPoints() ~= 1 or point ~= "TOPLEFT" or relative ~= party
        or relativePoint ~= anchor or currentX ~= x or currentY ~= y) then
      frame:ClearAllPoints();
      frame:SetPoint("TOPLEFT", party, anchor, x, y);
    end
  end

  local function CollectMembers(parent, members)
    for _, child in ipairs({parent:GetChildren()}) do
      if (child.HealthBarContainer and child.Name) then
        members[#members + 1] = child;
      elseif (child ~= selfFrame) then
        CollectMembers(child, members);
      end
    end
  end

  local function Refresh()
    local party = _G.PartyFrame;
    if (not party or _G.InCombatLockdown()) then return end

    local members = {};
    CollectMembers(party, members);
    local active, hasPlayer = {};
    for _, member in ipairs(members) do
      if (SkinMember(member, false) and member:IsShown()) then
        active[#active + 1] = member;
        if (member.unitToken == "player") then hasPlayer = true; end
      end
    end
    table.sort(active, function(a, b)
      return (a.layoutIndex or 0) < (b.layoutIndex or 0);
    end);
    local first = active[1];
    local editMode = _G.EditModeManagerFrame;
    local editing = editMode and editMode:IsEditModeActive();
    local showPlayer = first and not hasPlayer and _G.IsInGroup() and not _G.IsInRaid() and not editing;
    local settings = db.profile.nativeUnitFrames.party;
    local customPosition = settings.customPosition and not editing;
    local reserved = showPlayer and 1 or 0;
    if (customPosition) then
      for index, member in ipairs(active) do
        PlacePartyRow(member, party, settings.point, index + reserved, #active + reserved);
      end
    end

    if (not showPlayer) then
      if (selfFrame) then selfFrame:Hide(); end
      return;
    end

    if (not selfFrame) then
      selfFrame = _G.CreateFrame("Button", nil, party, "SecureUnitButtonTemplate");
      selfFrame.unitToken = "player";
      selfFrame:EnableMouse(true);
      selfFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp");
      selfFrame:SetAttribute("unit", "player");
      selfFrame:SetAttribute("useOnKeyDown", false);
      selfFrame:SetAttribute("*type1", "target");
      selfFrame:SetAttribute("*type2", "togglemenu");
    end
    SkinMember(selfFrame, true);
    if (customPosition) then
      PlacePartyRow(selfFrame, party, settings.point, 1, #active + 1);
    else
      selfFrame:ClearAllPoints();
      selfFrame:SetPoint("BOTTOMLEFT", first, "TOPLEFT", 0, partyRowGap);
    end
    selfFrame:Show();
  end
  refreshPartySkin = Refresh;

  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
  watcher:RegisterEvent("GROUP_ROSTER_UPDATE");
  watcher:SetScript("OnEvent", Refresh);
  if (_G.EventRegistry and _G.EditModeManagerFrame) then _G.EventRegistry:RegisterCallback("EditMode.Enter", Refresh, watcher); end
  if (_G.EventRegistry and _G.EditModeManagerFrame) then _G.EventRegistry:RegisterCallback("EditMode.Exit", Refresh, watcher); end
  local party = _G.PartyFrame;
  if (party and party.UpdatePaddingAndLayout) then
    _G.hooksecurefunc(party, "UpdatePaddingAndLayout", function()
      _G.C_Timer.After(0, Refresh);
    end);
  end
  Refresh();
end

local function SetupRaidAuras()
  local rows = {};
  local queued, reportedError;

  local function UpdateFrame(frame)
    if (frame:IsForbidden()) then return end
    local unit = frame.unit;
    if ((_G.issecretvalue and _G.issecretvalue(unit)) or type(unit) ~= "string"
        or not unit:match("^raid%d+$") or not frame.healthBar) then return end
    local width, height = frame:GetSize();
    if (width <= 8 or height <= 17) then return end

    local settings = db.profile.nativeUnitFrames.raid;
    local data = rows[frame];
    if (not data) then
      local row = _G.CreateFrame("Frame", nil, frame);
      row:SetAllPoints(frame);
      row:SetFrameLevel(frame:GetFrameLevel() + 2);
      row:EnableMouse(false);
      local layout, err = CreateGroupAuras(row, unit, settings);
      if (not layout) then
        row:Hide();
        if (err and not reportedError) then
          reportedError = true;
          tk:Print(tostring(err));
        end
      end
      data = { row = row; layout = layout };
      rows[frame] = data;
    end
    if (not data.layout) then return end

    data.layout(width, height, settings.showBuffs, settings.showDebuffs, settings.debuffFilter, unit);
    data.unit = unit;
    data.row:Show();
  end

  local function Scan(frame)
    if (frame:IsForbidden() or not frame:IsShown()) then return end
    if (frame.healthBar) then
      UpdateFrame(frame);
      return;
    end
    for _, child in ipairs({ frame:GetChildren() }) do Scan(child); end
  end

  local function Refresh()
    local raid = _G.CompactRaidFrameContainer;
    if (_G.InCombatLockdown() or not raid or not _G.IsInRaid()) then return end
    Scan(raid);
  end
  refreshRaidAuras = Refresh;

  if (_G.CompactUnitFrame_SetUnit) then
    _G.hooksecurefunc("CompactUnitFrame_SetUnit", function(frame)
      local data = rows[frame];
      if (data and not frame:IsForbidden()) then
        local unit = frame.unit;
        if ((_G.issecretvalue and _G.issecretvalue(unit)) or data.unit ~= unit) then
          data.row:Hide();
        end
      end
      if (queued or _G.InCombatLockdown() or not _G.IsInRaid()) then return end
      queued = true;
      _G.C_Timer.After(0, function()
        queued = false;
        Refresh();
      end);
    end);
  end

  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("GROUP_ROSTER_UPDATE");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
  watcher:SetScript("OnEvent", Refresh);
  Refresh();
end

MayronUI:Hook("CoreModule", "OnInitialized", function()
  -- UnitPanels can finish initializing later in the same login event.
  _G.C_Timer.After(0, function()
    if (_G.C_AddOns.IsAddOnLoaded("ShadowedUnitFrames")) then return end
    local player = CreateUnitDisplay(_G.MUI_UnitPanelLeft, "MUI_NativePlayerFrame", "player");
    EnableUnitMenu(player, "player", "MUI_NativePlayerMenuButton");
    local target = CreateUnitDisplay(_G.MUI_UnitPanelRight, "MUI_NativeTargetFrame", "target"); 
    EnableUnitMenu(target, "target", "MUI_NativeTargetMenuButton");
    if (_G.MUI_UnitPanelCenter) then PositionPetFrame(); end
    CreateTargetOfTargetDisplay(_G.MUI_UnitPanelCenter);
    SkinPartyFrames();
    SetupRaidAuras();
    SetCustomPartyPosition();
    if (player and _G.PlayerFrame) then _G.PlayerFrame:SetAlpha(0); end
    if (target and _G.TargetFrame) then _G.TargetFrame:SetAlpha(0); end
  end);
end);
