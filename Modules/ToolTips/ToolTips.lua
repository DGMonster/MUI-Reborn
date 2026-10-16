-- luacheck: ignore MayronUI self 143
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, em, gui, obj, L = MayronUI:GetCoreComponents();
local C_ToolTipsModule = MayronUI:RegisterModule("Tooltips", L["Tooltips"]);

local tooltipStyle = _G.GAME_TOOLTIP_BACKDROP_STYLE_DEFAULT or _G.TOOLTIP_BACKDROP_STYLE_DEFAULT;
local gameTooltip = _G.GameTooltip--[[@as BackdropTemplate|GameTooltip|MayronUI.GridTextureMixin]];
local healthBar, powerBar = _G.GameTooltipStatusBar, nil;
local IsInGroup, IsInRaid, After = _G.IsInGroup, _G.IsInRaid, _G.C_Timer.After;
local TooltipDataProcessor, UnitIsDeadOrGhost = _G.TooltipDataProcessor, _G.UnitIsDeadOrGhost;
local NotifyInspect, UnitInVehicle = _G.NotifyInspect, _G.UnitInVehicle;

if (not UnitInVehicle) then
  -- for Classic Era
  UnitInVehicle = function() return false; end
end

local originalHealthBarSetStatusBarColor = healthBar.SetStatusBarColor--[[@as function]];

local function IsEditModeActive()
  return _G.EditModeManagerFrame and _G.EditModeManagerFrame:IsShown()
end

local function IsForbiddenTooltip(tooltip)
  return tooltip and tooltip.IsForbidden and tooltip:IsForbidden()
end

local function IsWorldCursorTooltip(tooltip)
  if not tooltip or not tooltip.GetOwner then
    return false
  end

  local owner = tooltip:GetOwner()
  return UnitExists("mouseover") and (not owner or not owner.unit)
end

-- Do NOT touch tooltips in these secure contexts:
local function TooltipSafe(tooltip)
  if not tooltip then return false end
  if IsForbiddenTooltip(tooltip) then return false end
  if InCombatLockdown and InCombatLockdown() then return false end
  if IsEditModeActive() then return false end
  if IsWorldCursorTooltip(tooltip) then return false end
  return true
end


local function SetHealthBarColor(r, g, b, a)
  originalHealthBarSetStatusBarColor(healthBar, r, g, b, a);
end

healthBar.SetStatusBarColor = tk.Constants.DUMMY_FUNC;

if (not obj:IsFunction(gameTooltip.SetBackdrop)) then
  _G.Mixin(gameTooltip, _G.BackdropTemplateMixin);
end

local select, IsAddOnLoaded, strformat, ipairs, UnitAura, unpack,
  UnitName, UnitHealthMax, UnitHealth, hooksecurefunc, UnitExists, UnitIsPlayer,
  GetGuildInfo, UnitRace, UnitCreatureFamily, UnitCreatureType, UnitReaction =
  _G.select, _G.IsAddOnLoaded, _G.string.format, _G.ipairs, _G.UnitAura, _G.unpack,
  _G.UnitName, _G.UnitHealthMax, _G.UnitHealth, _G.hooksecurefunc, _G.UnitExists, _G.UnitIsPlayer,
  _G.GetGuildInfo, _G.UnitRace, _G.UnitCreatureFamily, _G.UnitCreatureType, _G.UnitReaction;
local UnitPowerType, UnitPower, UnitPowerMax, min = _G.UnitPowerType, _G.UnitPower, _G.UnitPowerMax, _G.math.min;
local UnitLevel, CanInspect, UnitGUID, CheckInteractDistance =
  _G.UnitLevel, _G.CanInspect, _G.UnitGUID, _G.CheckInteractDistance;
local tostring, InCombatLockdown = _G.tostring, _G.InCombatLockdown;
local IsPlayerMoving = _G.IsPlayerMoving;
local ClearInspectPlayer, GetTime = _G.ClearInspectPlayer, _G.GetTime;

---@class MayronUI.TooltipCacheEntry
---@field itemLevel number
---@field specName string
---@field createdAt number

---@type table<string, MayronUI.TooltipCacheEntry>
local guidCache = {};

-- Constants
local HARMFUL = "HARMFUL";
local HELPFUL = "HELPFUL";
local ITEM_LEVEL_LABEL = "Item Level:";
local SPEC_LABEL = strformat("%s:", _G.SPECIALIZATION);
local TARGET_LABEL = "Target:";
local AURA_SPACING = 2;

local tooltipsToReskin =  {
	"GameTooltip",
	"ShoppingTooltip1",
	"ShoppingTooltip2",
	"ItemRefTooltip",
	"ItemRefShoppingTooltip1",
	"ItemRefShoppingTooltip2",
	"AtlasLootTooltip",
	"QuestHelperTooltip",
	"QuestGuru_QuestWatchTooltip",
  "WorldMapCompareTooltip1",
  "WorldMapCompareTooltip2",
  "AdventureMap_MissionPinTooltip",
  "FriendsTooltip",
  "LibDBIconTooltip"
};

---@class MayronUI.TooltipDefaults
local tooltipDefaults = {
  enabled = not (select(1, IsAddOnLoaded("TipTac")));
  targetShown = true;
  guildRankShown = true;
  realmShown = true;
  itemLevelShown = true;
  specShown = true;
  font = "MUI_Font";
  flag = "None";
  standardFontSize = 14;
  headerFontSize = 16;
  scale = 0.8;

  useClassColors = true;
  useMuiTexture = true; -- if false, use backdrop

  backdrop = {
    bgFile = "Solid", -- default texture in LSM
    edgeFile = "Solid",
    edgeSize = tk.Constants.BACKDROP_WITH_BACKGROUND.edgeSize,
    insets = { left = 0, right = 0, top = 0, bottom = 0 };
  };

  anchors = {
    screen = {
      point = "BOTTOMRIGHT";
      xOffset = -4;
      yOffset = 4;
    };
    mouse = {
      point = "ANCHOR_CURSOR_RIGHT";
      xOffset = 2;
      yOffset = 4;
    };
  },
  unitFrames = {
    show = true;
    hideInCombat = false;
    anchor = "screen";
  },
  worldUnits = {
    show = true;
    hideInCombat = false;
    anchor = "mouse";
  },
  standard = {
    show = true;
    hideInCombat = false;
    anchor = "screen";
  },
  colors = {
    buff    = { 0, 0, 0 };
    debuff  = { 0.76, 0.2, 0.2 };
    magic   = { 0.2, 0.6, 1 };
    disease = { 0.6, 0.4, 0 };
    poison  = { 0.0, 0.6, 0 };
    curse   = { 0.6, 0.0, 1 };
  };
  healthColors = {
    low = { r = 1, g = 77/255, b = 77/255 },
    medium = { r = 1, g = 1, b = 128/255 },
    high = { r = 86/255, g = 199/255, b = 89/255 }
  };
  powerColors = {
    ["MANA"] = { r = 0.22, g = 0.55, b = 1 };
    ["RAGE"] = { r = 0.45, g = 0, b = 0.02 };
    ["FOCUS"] = { r = 0.61, g = 0.43, b = 0.24 };
    ["ENERGY"] = { r = 1, g = 0.87, b = 0.22 };
    ["HAPPINESS"] = { r = 0.5, g = 0.9, b = 0.7 };
    ["RUNES"] = { r = 0.50, g = 0.50, b = 0.50 };
    ["RUNIC_POWER"] = { r = 0.43, g = 0.60, b = 0.87 };
    ["SOUL_SHARDS"] = { r = 0.58, g = 0.51, b = 0.79 };
    ["LUNAR_POWER"] = { r = 0.30, g = 0.52, b = 0.90 };
    ["HOLY_POWER"] = { r = 0.95, g = 0.90, b = 0.60 };
    ["MAELSTROM"] = { r = 0.00, g = 0.50, b = 1.00 };
    ["INSANITY"] = { r = 0.40, g = 0, b = 0.80 };
    ["COMBO_POINTS"] = { r = 1.00, g = 0.96, b = 0.41 };
    ["CHI"] = { r = 0.71, g = 1.0, b = 0.92 };
    ["ARCANE_CHARGES"] = { r = 0.1, g = 0.1, b = 0.98 };
    ["FURY"] = { r = 0.788, g = 0.259, b = 0.992 };
    ["PAIN"] = { r = 1, g = 0.61, b = 0 };
  };
  healthBar = {
    fontSize = 14;
    texture = "MayronUI";
    flag = "OUTLINE";
    format = "%"; -- or "", "n", "n/n"
    height = 18;
  };
  powerBar = {
    enabled = false;
    fontSize = 14;
    texture = "MayronUI";
    flag = "OUTLINE";
    format = "%"; -- or "", "n", "n/n"
    height = 18;
  };
  auras = {
    buffs = {
      enabled = true;
      onlyYours = false;
      size = 28;
      position = "TOP";
      direction = "rtl";
    };
    debuffs = {
      enabled = true;
      onlyYours = true;
      size = 28;
      position = "BOTTOM";
      direction = "rtl";
      aboveBuffs = true;
      colorByDebuffType = true;
    };
  };
}

db:AddToDefaults("profile.tooltips", tooltipDefaults);

local function SetBackdropStyle(d)
  local settings = d.settings--[[@as MayronUI.TooltipDefaults]]
  local bgFile = tk.Constants.LSM:Fetch(tk.Constants.LSM.MediaType.BACKGROUND, settings.backdrop.bgFile);
  local edgeFile = tk.Constants.LSM:Fetch(tk.Constants.LSM.MediaType.BORDER, settings.backdrop.edgeFile);

  -- It won't update unless it's a completely new table
  if (obj:IsTable(d.tooltipBackdrop)) then
    obj:PushTable(d.tooltipBackdrop);
  end

  d.tooltipBackdrop = {};
  d.tooltipBackdrop.bgFile = bgFile;
  d.tooltipBackdrop.edgeFile = edgeFile;
  d.tooltipBackdrop.edgeSize = settings.backdrop.edgeSize;
  d.tooltipBackdrop.insets = settings.backdrop.insets;

  -- replace backdrop:
  if (tooltipStyle) then
    tooltipStyle.bgFile = d.tooltipBackdrop.bgFile;
    tooltipStyle.insets = d.tooltipBackdrop.insets;
    tooltipStyle.edgeFile = d.tooltipBackdrop.edgeFile;
    tooltipStyle.edgeSize = d.tooltipBackdrop.edgeSize;
  end

  if (settings.useMuiTexture) then
    local closeBtn = _G["ItemRefCloseButton"];

    if (obj:IsWidget(closeBtn)) then
      -- Avoid taint in combat / edit mode UI transitions
      if (not InCombatLockdown()) and (not IsEditModeActive()) then
        gui:ReskinIconButton(closeBtn, "cross");
        local scale = closeBtn:GetParent():GetScale();
        closeBtn:SetSize(28/scale, 24/scale);
        closeBtn:SetPoint("TOPRIGHT", -5, -4);
      end
    end
  end

  for _, tooltipName in ipairs(tooltipsToReskin) do
    local tooltip = _G[tooltipName]--[[@as MayronUI.GridTextureMixin|GameTooltip|table]];

    if (obj:IsTable(tooltip) and obj:IsFunction(tooltip.GetObjectType)) then
      local scale = settings.scale;

      if (tooltip == _G["FriendsTooltip"]) then
        scale = scale + 0.2;
      end

      tooltip:SetScale(scale);

      if (tooltip.NineSlice) then
        tk:KillElement(tooltip.NineSlice);

        if (tooltip ~= gameTooltip) then
          _G.Mixin(tooltip, _G.BackdropTemplateMixin);
        end
      end

      if (settings.useMuiTexture) then
        tooltip:SetBackdrop(nil);

        if (not obj:IsFunction(tooltip.SetGridTextureShown)) then
          gui:AddDialogTexture(tooltip, "High", 10);
          tooltip:SetFrameStrata("TOOLTIP"); -- because AddDialogTexture changes it to Dialog
        end
      end

      if (obj:IsFunction(tooltip.SetGridTextureShown)) then
        tooltip:SetGridTextureShown(settings.useMuiTexture);
      end
    end
  end
end


local function SetFonts(d)
  local font = tk.Constants.LSM:Fetch(tk.Constants.LSM.MediaType.FONT, d.settings.font)
  local flag = d.settings.flag or ""
  local standardSize = d.settings.standardFontSize or 14
  local headerSize = d.settings.headerFontSize or 16

  local function ApplyToTooltip(tooltipName)
    local tooltip = _G[tooltipName]
    if not obj:IsWidget(tooltip) then
      return
    end

    if tooltip.IsForbidden and tooltip:IsForbidden() then
      return
    end

    for i = 1, 30 do
      local left = _G[tooltipName.."TextLeft"..i]
      local right = _G[tooltipName.."TextRight"..i]

      local size = (i == 1) and headerSize or standardSize

      if left and left.SetFont then
        left:SetFont(font, size, flag)
      end

      if right and right.SetFont then
        right:SetFont(font, size, flag)
      end
    end
  end

  for _, tooltipName in ipairs(tooltipsToReskin) do
    ApplyToTooltip(tooltipName)
  end

  -- Shopping tooltips are not in the list on all clients, ensure they are covered:
  ApplyToTooltip("ShoppingTooltip1")
  ApplyToTooltip("ShoppingTooltip2")
end

local function SafePercent(current, max)
  -- max can be secret too, so comparisons must be protected
  local ok, result = pcall(function()
    if not max or max <= 0 then
      return nil
    end
    return current / max
  end)

  if ok and type(result) == "number" then
    return result
  end

  return nil
end

local function GetHealthColor(healthColors, currentHealth, maxHealth)
  local percent = SafePercent(currentHealth, maxHealth)
  if not percent then
    return healthColors.high.r, healthColors.high.g, healthColors.high.b
  end

  if (percent >= 1) then
    return healthColors.high.r, healthColors.high.g, healthColors.high.b
  end

  if (percent == 0) then
    return healthColors.low.r, healthColors.low.g, healthColors.low.b
  end

  local start, stop
  if (percent > 0.5) then
    start = healthColors.high
    stop = healthColors.medium
  else
    start = healthColors.medium
    stop = healthColors.low
  end

  return tk:MixColorsByPercentage(start, stop, percent)
end


local UpdateUnitHealthBarText, UpdateUnitPowerBarText;

local function SafeNumber(x)
  local ok, v = pcall(function() return tonumber(x) end)
  if ok and type(v) == "number" then
    return v
  end
  return nil
end

local function SetFormattedColoredText(fontString, format, percentage, current, max, r, g, b)
  if not fontString then return end

  if tk.Strings:IsNilOrWhiteSpace(format) or type(percentage) ~= "number" or percentage > 100 then
    fontString:SetText("")
    return
  end

  local text = tk.Strings.Empty

  if format == "%" then
    text = strformat("%d%%", percentage)
  else
    local curN = SafeNumber(current)
    local maxN = SafeNumber(max)

    if not curN then
      fontString:SetText("")
      return
    end

    if curN > 1000 then
      curN = strformat("%.1fk", tk.Numbers:ToPrecision(curN / 1000, 1))
    end

    if format == "n" then
      text = tostring(curN)
    elseif format == "n/n" then
      if not maxN then
        fontString:SetText("")
        return
      end

      if maxN > 1000 then
        maxN = strformat("%.1fk", tk.Numbers:ToPrecision(maxN / 1000, 1))
      end

      text = strformat("%s/%s", tostring(curN), tostring(maxN))
    end
  end

  fontString:SetText(tk.Strings:SetTextColorByRGB(text, r, g, b))
end

function UpdateUnitHealthBarText(format, healthColors, unitID)
  local maxHealth = UnitHealthMax(unitID)
  local currentHealth = UnitHealth(unitID)

  local percent = SafePercent(currentHealth, maxHealth)
  if not percent then
    return
  end

  local r, g, b = GetHealthColor(healthColors, currentHealth, maxHealth)
  local percentage = percent * 100

  SetFormattedColoredText(healthBar.HealthText, format, percentage, currentHealth, maxHealth, r, g, b)
end

function UpdateUnitPowerBarText(format, powerColors, unitID)
  if not powerBar then return end

  local powerTypeID = UnitPowerType(unitID)
  if powerTypeID < 0 then return end

  local currentPower = UnitPower(unitID, powerTypeID)
  local maxPower = UnitPowerMax(unitID, powerTypeID)

  local percent = SafePercent(currentPower, maxPower)
  if not percent then
    return
  end

  local maxN = SafeNumber(maxPower) or 0
  local curN = SafeNumber(currentPower) or 0

  powerBar:SetMinMaxValues(0, maxN)
  powerBar:SetValue(curN)

  local powerType = tk.Constants.POWER_TYPES[powerTypeID]
  local powerColor =
    (obj:IsString(powerType) and powerColors[powerType])
    or _G.PowerBarColor[powerTypeID]
    or powerColors["ENERGY"]

  local r, g, b = powerColor.r, powerColor.g, powerColor.b
  local percentage = percent * 100

  r, g, b = min(1, r*1.4), min(1, g*1.4), min(1, b*1.4)

  SetFormattedColoredText(powerBar.PowerText, format, percentage, currentPower, maxPower, r, g, b)
end

local function UpdateUnitStatusBars(d, tooltip, unitID)
  if (not TooltipSafe(tooltip)) then return end

  local settings = d.settings--[[@as MayronUI.TooltipDefaults]];

  -- Status bar colors (health)
  local r, g, b;

  if (UnitIsPlayer(unitID)) then
    r, g, b = tk:GetClassColor(unitID);
  else
    local reaction = UnitReaction(unitID, "player");

    if (reaction) then
      r = tk.Constants.FACTION_BAR_COLORS[reaction].r;
      g = tk.Constants.FACTION_BAR_COLORS[reaction].g;
      b = tk.Constants.FACTION_BAR_COLORS[reaction].b;
    else
      local maxHealth = UnitHealthMax(unitID);
      local currentHealth = UnitHealth(unitID);

      if (type(currentHealth) == "number" and type(maxHealth) == "number" and maxHealth > 0) then
        r, g, b = GetHealthColor(settings.healthColors, currentHealth, maxHealth);
      else
        r = settings.healthColors.high.r;
        g = settings.healthColors.high.g;
        b = settings.healthColors.high.b;
      end
    end
  end

  SetHealthBarColor(r, g, b, 1);

  if healthBar.bgTex then
    healthBar.bgTex:SetColorTexture(r * 0.4, g * 0.4, b * 0.4, 0.8);
  end

  UpdateUnitHealthBarText(settings.healthBar.format, settings.healthColors, unitID);

  -- Power bar (optional)
  if (not (powerBar and powerBar.PowerText)) then
    return
  end

  local powerTypeID = UnitPowerType(unitID);
  local show = settings.powerBar.enabled and powerTypeID and powerTypeID >= 0;
  powerBar:SetShown(show);

  if (not show) then
    return
  end

  UpdateUnitPowerBarText(settings.powerBar.format, settings.powerColors, unitID);

  local powerType = tk.Constants.POWER_TYPES[powerTypeID];
  local powerColor = (obj:IsString(powerType) and settings.powerColors[powerType])
    or _G.PowerBarColor[powerTypeID]
    or settings.powerColors["ENERGY"];

  local pr, pg, pb = powerColor.r, powerColor.g, powerColor.b;
  powerBar:SetStatusBarColor(pr, pg, pb, 1);

  if powerBar.bgTex then
    powerBar.bgTex:SetColorTexture(pr * 0.4, pg * 0.4, pb * 0.4, 0.8);
  end
end


  if not TooltipSafe(tooltip) then return end
  local settings = d.settings--[[@as MayronUI.TooltipDefaults]];

  if (UnitIsPlayer(unitID)) then
    local r, g, b = tk:GetClassColor(unitID);
    SetHealthBarColor(r, g, b, 1);
    if healthBar.bgTex then healthBar.bgTex:SetColorTexture(r * 0.4, g * 0.4, b * 0.4, 0.8); end
  else
    local reaction = UnitReaction(unitID, "player");
    local r, g, b;

    if (reaction) then
      r = tk.Constants.FACTION_BAR_COLORS[reaction].r;
      g = tk.Constants.FACTION_BAR_COLORS[reaction].g;
      b = tk.Constants.FACTION_BAR_COLORS[reaction].b;
   else
  local maxHealth = UnitHealthMax(unitID)
  local currentHealth = UnitHealth(unitID)

  if type(currentHealth) == "number"
    and type(maxHealth) == "number"
    and maxHealth > 0 then
    r, g, b = GetHealthColor(settings.healthColors, currentHealth, maxHealth)
  else
    r, g, b =
      settings.healthColors.high.r,
      settings.healthColors.high.g,
      settings.healthColors.high.b
  end
end

    SetHealthBarColor(r, g, b, 1);
    if healthBar.bgTex then healthBar.bgTex:SetColorTexture(r * 0.4, g * 0.4, b * 0.4, 0.8); end
  end

  UpdateUnitHealthBarText(settings.healthBar.format, settings.healthColors, unitID);

  if (not (powerBar and powerBar.PowerText)) then
    return
  end

  local powerTypeID = UnitPowerType(unitID);

  local show = settings.powerBar.enabled and powerTypeID >= 0;
  powerBar:SetShown(show);

  if (not show) then
    return
  end

  UpdateUnitPowerBarText(settings.powerBar.format, settings.powerColors, unitID);

  local powerType = tk.Constants.POWER_TYPES[powerTypeID];
  local powerColor = (obj:IsString(powerType) and settings.powerColors[powerType])
    or _G.PowerBarColor[powerTypeID] or settings.powerColors["ENERGY"];

  local r, g, b = powerColor.r, powerColor.g, powerColor.b;
  powerBar:SetStatusBarColor(r, g, b, 1);
  if powerBar and powerBar.bgTex then powerBar.bgTex:SetColorTexture(r*0.4, g*0.4, b*0.4, 0.8); end


local function HideAllAuras(data)
  if (obj:IsTable(data.buffs)) then
    for _, f in ipairs(data.buffs) do
      f:ClearAllPoints();
      f:Hide();
    end
  end

  if (obj:IsTable(data.debuffs)) then
    for _, f in ipairs(data.debuffs) do
      f:ClearAllPoints();
      f:Hide();
    end
  end
end

local function AddAuras(data, filter, anchor, unitID)
  local id = 1;
  local previousFrame;
  local totalWidth = 0;
  local previousFirstRow = anchor;
  local maxWidth = gameTooltip:GetWidth();
  local maxAuras, auraFrames, settings;

  if (filter == HELPFUL) then
    maxAuras = _G.BUFF_MAX_DISPLAY;
    auraFrames = data.buffs;
    settings = data.settings.auras.buffs;
  else
    maxAuras = _G.DEBUFF_MAX_DISPLAY;
    auraFrames = data.debuffs;
    settings = data.settings.auras.debuffs;
  end

  for index = 1, maxAuras do
    local auraName, iconTexture, _, auraType, duration, endTime, source = UnitAura(unitID, index, filter);
    local show = true;

    if (settings.onlyYours and source ~= "player") then
      show = false;
    end

    if (auraName and iconTexture and show) then
      local frame = auraFrames[id];

      if (not frame) then
        auraFrames[id] = tk:CreateBackdropFrame("Frame", gameTooltip);
        frame = auraFrames[id];

        frame:SetBackdrop(data.auraBackdrop);
        local edge = tk.Constants.BACKDROP.edgeSize;

        frame.iconTexture = frame:CreateTexture(nil, "ARTWORK");
        frame.iconTexture:SetTexCoord(0.1, 0.9, 0.1, 0.9);
        frame.iconTexture:SetPoint("TOPLEFT", edge, -edge);
        frame.iconTexture:SetPoint("BOTTOMRIGHT", -edge, edge);

        frame.cooldown = tk:CreateFrame("Cooldown", frame, nil, _G.BackdropTemplateMixin and "CooldownFrameTemplate");
        frame.cooldown:SetReverse(1);
        frame.cooldown:SetPoint("TOPLEFT", edge, -edge);
        frame.cooldown:SetPoint("BOTTOMRIGHT", -edge, edge);
        frame.cooldown:SetFrameLevel(frame:GetFrameLevel() + 1);
      end

      frame:SetSize(settings.size, settings.size);

      if (duration and duration > 0 and endTime and endTime > 0) then
				frame.cooldown:SetCooldown(endTime - duration, duration);
			else
				frame.cooldown:Hide();
			end

      frame:ClearAllPoints();

      if (filter == HARMFUL) then
        local auraColor =  data.settings.colors.debuff;

        if (settings.colorByDebuffType and auraType) then
          auraColor = data.settings.colors[auraType:lower()] or auraColor;
        end

        frame:SetBackdropBorderColor(unpack(auraColor));
      else
        frame:SetBackdropBorderColor(unpack(data.settings.colors.buff));
      end

      local newTotalWidth = totalWidth + frame:GetWidth() + AURA_SPACING;
      if (previousFrame and newTotalWidth <= maxWidth) then
        local point, relativePoint = "LEFT", "RIGHT";
        local xOffset = AURA_SPACING;

        if (settings.direction == "rtl") then
          point, relativePoint = "RIGHT", "LEFT";
          xOffset = -xOffset;
        end

        frame:SetPoint(point, previousFrame, relativePoint, xOffset, 0);
        totalWidth = newTotalWidth;
      else
        -- main anchor!
        local xOffset = previousFirstRow == gameTooltip and -1 or 0;
        local yOffset = id == 1 and 5 or AURA_SPACING;
        local horizontal = "LEFT";
        local verticlePoint, verticleRelativePoint = "BOTTOM", "TOP";

        if (settings.direction == "rtl") then
          horizontal = "RIGHT";
          xOffset = -xOffset;
        end

        if (settings.position == "BOTTOM") then
          verticlePoint, verticleRelativePoint = "TOP", "BOTTOM";
          yOffset = -yOffset;
        end

        local point = verticlePoint..horizontal;
        local relativePoint = verticleRelativePoint..horizontal;

        frame:SetPoint(point, previousFirstRow, relativePoint, xOffset, yOffset);
        previousFirstRow = frame;
        totalWidth = frame:GetWidth();
      end

      frame.iconTexture:SetTexture(iconTexture);
      frame:Show();

      previousFrame = frame;
      id = id + 1;
    end
  end

  return previousFirstRow;
end

local function UnitInPlayerGroup(unitGuid)
  if (UnitGUID("player") == unitGuid) then
    return true;

  elseif (IsInGroup()) then
    if (IsInRaid()) then
      for userIndex = 1, 40 do
        local unitID = ("raid%d"):format(userIndex);

        if (UnitExists(unitID) and UnitGUID(unitID) == unitGuid) then
          return true;
        end
      end
    else
      for userIndex = 1, 5 do
        local unitID = ("party%d"):format(userIndex);

        if (UnitExists(unitID) and UnitGUID(unitID) == unitGuid) then
          return true;
        end
      end
    end
  end

  return false;
end

local function UpdateUnitAuras(data, unitID)
  if (not data.auraBackdrop) then
    data.auraBackdrop = obj:PopTable();
    data.auraBackdrop.edgeFile = tk.Constants.LSM:Fetch("border", "Solid");
    data.auraBackdrop.edgeSize = tk.Constants.BACKDROP.edgeSize;
  end

  HideAllAuras(data);

  local relativeFrame = gameTooltip;
  local buffsEnabled = data.settings.auras.buffs.enabled;
  local debuffsEnabled = data.settings.auras.debuffs.enabled;
  local samePositions = (data.settings.auras.buffs.position == data.settings.auras.debuffs.position);

  local debuffsFirst = true;

  if (samePositions) then
    if (data.settings.auras.debuffs.aboveBuffs) then
      if (data.settings.auras.buffs.position == "TOP") then
        debuffsFirst = false; -- if top, then debuffs need to go last to appear above buffs
      end
    else
      if (data.settings.auras.buffs.position == "BOTTOM") then
        debuffsFirst = false; -- if bottom, then debuffs need to go last to appear below buffs
      end
    end
  end

  data.buffs = buffsEnabled and (data.buffs or obj:PopTable());
  data.debuffs = debuffsEnabled and (data.debuffs or obj:PopTable());

  if (debuffsEnabled and debuffsFirst) then
    local nextRelativeFrame = AddAuras(data, HARMFUL, relativeFrame, unitID);

    if (samePositions) then
      relativeFrame = nextRelativeFrame;
    end

    if (buffsEnabled) then
      AddAuras(data, HELPFUL, relativeFrame, unitID);
    end
  else
    if (buffsEnabled) then
      local nextRelativeFrame = AddAuras(data, HELPFUL, relativeFrame, unitID);

      if (samePositions) then
        relativeFrame = nextRelativeFrame;
      end
    end

    if (debuffsEnabled) then
      AddAuras(data, HARMFUL, relativeFrame, unitID);
    end
  end
end

local function RefreshPadding(data)
  local space = data.settings.healthBar.height + 4; -- spacing between bar and text

  if (data.settings.powerBar.enabled and powerBar and powerBar:IsShown()) then
    space = space + data.settings.powerBar.height + 4; -- spacing between bars
  end

  if (healthBar:IsShown()) then
    gameTooltip:SetPadding(0, space);
  else
    gameTooltip:SetPadding(0, 0);
  end
end

local function SetDoubleLine(data, label, rightText)
  local totalLines = gameTooltip:NumLines();

	for i = totalLines, 1, -1  do
		local line1 = _G["GameTooltipTextLeft"..i];
		local line2 = _G["GameTooltipTextRight"..i];
    local text = line1:GetText();

    if (text == label) then
      if (rightText) then
        line2:SetText(rightText);
      else
        line1:SetText("");
        line2:SetText("");
      end

      return

    -- Prevents Classic Bug:
    elseif (rightText == line2:GetText()) then
      line2:SetText("");
    end
  end

  if (rightText) then
    gameTooltip:AddDoubleLine(label, rightText);
  end

  RefreshPadding(data);
end

local function UpdateTargetText(d, unitID)
  local settings = d.settings--[[@as MayronUI.TooltipDefaults]];

  if (not settings.targetShown) then
    SetDoubleLine(d, TARGET_LABEL, nil);
    return
  end

  local targetUnitId = unitID.."Target";
  local targetName = UnitName(targetUnitId);

  if (targetName) then
    if (UnitName("player") == targetName) then
      targetName = tk.Strings:SetTextColorByKey("YOU", "YELLOW");
    else
      targetName = tk.Strings:GetUnitNameText(targetUnitId);
    end
  end

  SetDoubleLine(d, TARGET_LABEL, targetName);
end

local function CanInspectUnit(unitID)
  if (InCombatLockdown() or UnitIsDeadOrGhost("player")) then
    return false;
  end

  local unitGuid = UnitGUID(unitID);

  if (not UnitExists(unitID)) then
    return false;
  end

  if (IsPlayerMoving() and not IsGUIDInGroup(unitGuid)) then
    return false;
  end

  local shouldInspect =
    UnitIsPlayer(unitID) and
    (not UnitInVehicle(unitID)) and
    CheckInteractDistance(unitID, 1) and
    CanInspect(unitID, false) and
    UnitLevel(unitID) >= 10 and
    (not (_G.InspectFrame and _G.InspectFrame:IsVisible()));

  return shouldInspect;
end

local function CheckInspectionState(d, unitID, updateTooltip)
  local settings = d.settings--[[@as MayronUI.TooltipDefaults]];
  local runScript = (settings.specShown or settings.itemLevelShown) and UnitExists(unitID);

  if (not runScript) then
    return false;
  end

  local unitGuid = UnitGUID(unitID);

  if (not unitGuid) then
    return false;
  end

  if (unitGuid == UnitGUID("player")) then
    local specName = tk:GetPlayerSpecialization(nil, "player");
    local itemLevel = tk:GetInspectItemLevel("player");

    if (settings.specShown) then
      SetDoubleLine(d, SPEC_LABEL, specName or L["No Spec"]);
    end

    if (settings.itemLevelShown) then
      SetDoubleLine(d, ITEM_LEVEL_LABEL, itemLevel);
    end

    return
  end

  local entry = guidCache[unitGuid];

  if (entry) then
    if (settings.specShown and entry.specName) then
      SetDoubleLine(d, SPEC_LABEL, entry.specName);
    end

    if (settings.itemLevelShown and entry.itemLevel) then
      SetDoubleLine(d, ITEM_LEVEL_LABEL, entry.itemLevel);
    end
  end

  if (updateTooltip and not CanInspectUnit(unitID)) then
    return false;
  end

  if (updateTooltip and (settings.specShown)) then
    local loadingText = entry and entry.specName or "loading...";
    SetDoubleLine(d, SPEC_LABEL, loadingText);
  end

  if (updateTooltip and (settings.itemLevelShown)) then
    local loadingText = entry and entry.itemLevel or "loading...";
    SetDoubleLine(d, ITEM_LEVEL_LABEL, loadingText);
  end

  After(0.2, function()
    if (UnitGUID(unitID) == unitGuid) then
      d.inspecting = nil;
      ClearInspectPlayer();
      NotifyInspect(unitID);
    end
  end);

  return true;
end

local function CreatePowerBar(data)
  powerBar = tk:CreateFrame("StatusBar", healthBar, "GameTooltipPowerBar");
  powerBar:SetHeight(data.settings.powerBar.height);

  local statusBarTexture = tk.Constants.LSM:Fetch("statusbar", data.settings.powerBar.texture);
  powerBar:SetStatusBarTexture(statusBarTexture);
  powerBar:SetFrameLevel(10);

  -- Create a SAFE background (no BackdropTemplate / NineSlice):
  powerBar.bg = powerBar.bg or _G.CreateFrame("Frame", nil, powerBar);
  powerBar.bg:SetAllPoints();
  powerBar.bg:SetFrameLevel(powerBar:GetFrameLevel() - 1);

  powerBar.bgTex = powerBar.bgTex or powerBar.bg:CreateTexture(nil, "BACKGROUND");
  powerBar.bgTex:SetAllPoints(true);
  powerBar.bgTex:SetColorTexture(0, 0, 0, 0.8);

  local powerText = powerBar:CreateFontString(nil, "OVERLAY");
  local font = tk.Constants.LSM:Fetch(tk.Constants.LSM.MediaType.FONT, data.settings.font);

  powerText:SetFont(font, data.settings.powerBar.fontSize, data.settings.powerBar.flag);
  powerText:SetPoint("CENTER");
  powerBar.PowerText = powerText;
end

local function ApplyHealthBarChanges(data)
  local r, g, b = tk:GetThemeColor();

  local statusBarTexture = tk.Constants.LSM:Fetch("statusbar", data.settings.healthBar.texture);
  healthBar:SetStatusBarTexture(statusBarTexture);
  SetHealthBarColor(r, g, b);
  healthBar:SetFrameLevel(10);

-- Create a SAFE background (no BackdropTemplate / NineSlice):
healthBar.bg = healthBar.bg or _G.CreateFrame("Frame", nil, healthBar);
healthBar.bg:SetAllPoints();
healthBar.bg:SetFrameLevel(healthBar:GetFrameLevel() - 1);

healthBar.bgTex = healthBar.bgTex or healthBar.bg:CreateTexture(nil, "BACKGROUND");
healthBar.bgTex:SetAllPoints(true);
healthBar.bgTex:SetColorTexture(0, 0, 0, 0.8);

local healthText = healthBar:CreateFontString(nil, "OVERLAY");
  healthText:SetPoint("CENTER");
  healthBar.HealthText = healthText;
end

local function PositionStatusBars(data)
  if (powerBar and data.settings.powerBar.enabled) then
    powerBar:ClearAllPoints();
    healthBar:ClearAllPoints();

    healthBar:SetPoint("BOTTOMLEFT", 7, 7 + data.settings.powerBar.height + 4);
    healthBar:SetPoint("BOTTOMRIGHT", -7, 7 + data.settings.powerBar.height + 4);

    powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -4);
    powerBar:SetPoint("TOPRIGHT", healthBar, "BOTTOMRIGHT", 0, -4);
  else
    healthBar:ClearAllPoints();
    healthBar:SetPoint("BOTTOMLEFT", 7, 7);
    healthBar:SetPoint("BOTTOMRIGHT", -7, 7);
  end
end

local function CreateScreenAnchor(data)
  data.screenAnchor = tk:CreateFrame("Frame");
  data.screenAnchor:SetFrameStrata("TOOLTIP");
  tk:MakeMovable(data.screenAnchor);
  data.screenAnchor:SetSize(240, 150);

  data.screenAnchor:SetPoint(data.settings.anchors.screen.point,
    data.settings.anchors.screen.xOffset,
    data.settings.anchors.screen.yOffset);

  data.screenAnchor.bg = tk:SetBackground(data.screenAnchor, 0, 0, 0, 0.8);
  data.screenAnchor.bg:SetAllPoints(true);

  data.screenAnchor.bg.text = data.screenAnchor:CreateFontString(nil, "BACKGROUND", "GameFontHighlight");
  data.screenAnchor.bg.text:SetText("Tool-tip screen anchor point (Drag me!)");
  data.screenAnchor.bg.text:SetWidth(200);
  data.screenAnchor.bg.text:SetPoint("CENTER");

  function data.screenAnchor:Unlock()
    data.screenAnchor:ClearAllPoints();
    data.screenAnchor:SetPoint(
      data.settings.anchors.screen.point,
      data.settings.anchors.screen.xOffset,
      data.settings.anchors.screen.yOffset);

    data.screenAnchor.bg:SetAlpha(0.8);
    data.screenAnchor.bg.text:SetAlpha(1);
    data.screenAnchor:EnableMouse(true);
    data.screenAnchor:SetMovable(true);
  end

  function data.screenAnchor:Lock(dontSave)
    data.screenAnchor.bg:SetAlpha(0);
    data.screenAnchor.bg.text:SetAlpha(0);
    data.screenAnchor:EnableMouse(false);
    data.screenAnchor:SetMovable(false);

    -- save changes:
    if (not dontSave) then
      local positions = tk.Tables:GetFramePosition(data.screenAnchor);

      if (obj:IsTable(positions)) then
        db:SetPathValue("profile.tooltips.anchors.screen", {
          point = positions[1];
          xOffset = positions[4] or 0;
          yOffset = positions[5] or 0
        });
      end

      return positions;
    end
  end

  data.screenAnchor:Lock(true);


-- ---------------------------------------------------------------------------
-- Safety helpers (Retail secure tooltips: forbidden/world-cursor/edit-mode)
-- ---------------------------------------------------------------------------
end


local function ShouldBeHidden(data, tooltip)
  local _, unitID = tooltip:GetUnit();
  local inCombat = InCombatLockdown();

  if (unitID) then
    if ((inCombat and data.settings.unitFrames.hideInCombat) or not data.settings.unitFrames.show) then
      if (unitID ~= "mouseover") then
        tooltip:Hide();
        return true;
      end
    end

    if ((inCombat and data.settings.worldUnits.hideInCombat) or not data.settings.worldUnits.show) then
      if (unitID == "mouseover") then
        tooltip:Hide();
        return true;
      end
    end

  elseif ((inCombat and data.settings.standard.hideInCombat) or not data.settings.standard.show) then
    tooltip:Hide();
    return true;
  end

  return false;
end

-------------------------------
--- C_ToolTipsModule
-------------------------------
function C_ToolTipsModule:OnInitialize(data)
  local function SetFontsWrapper()
    SetFonts(data);
  end

  local function SetBackdropStyleWrapper()
    SetBackdropStyle(data);
  end

	self:RegisterUpdateFunctions(db.profile.tooltips, {
    font = SetFontsWrapper;--"MUI_Font";
    flag = SetFontsWrapper;
    standardFontSize = SetFontsWrapper; --14;
    headerFontSize = SetFontsWrapper; --16;
    scale = SetBackdropStyleWrapper; --0.8
    useMuiTexture = SetBackdropStyleWrapper; -- if true, does not use backdrop
    backdrop = SetBackdropStyleWrapper;
    healthBar = {
      fontSize = function(value)
        if (healthBar.HealthText) then
          local font = tk.Constants.LSM:Fetch(tk.Constants.LSM.MediaType.FONT, data.settings.font);
          healthBar.HealthText:SetFont(font, value, data.settings.healthBar.flag);
        end
      end;
      flag = function(value)
        if (healthBar.HealthText) then
          local font = tk.Constants.LSM:Fetch(tk.Constants.LSM.MediaType.FONT, data.settings.font);
          healthBar.HealthText:SetFont(font, data.settings.healthBar.fontSize, value);
        end
      end;
      texture = function(value)
        local statusBarTexture = tk.Constants.LSM:Fetch("statusbar", value);
        healthBar:SetStatusBarTexture(statusBarTexture);
      end;
      height = function(value)
        healthBar:SetHeight(value);
        PositionStatusBars(data);
      end;
    };
    anchors = {
      screen = function()
        data.screenAnchor:ClearAllPoints();
        data.screenAnchor:SetPoint(
          data.settings.anchors.screen.point,
          data.settings.anchors.screen.xOffset,
          data.settings.anchors.screen.yOffset);
      end;
    };
    powerBar = {
      enabled = function(value)
        if (value and not powerBar) then
          CreatePowerBar(data);
        end

        PositionStatusBars(data);
      end;
      fontSize = function(value)
        if (powerBar and powerBar.PowerText) then
          local font = tk.Constants.LSM:Fetch(tk.Constants.LSM.MediaType.FONT, data.settings.font);
          powerBar.PowerText:SetFont(font, value, data.settings.powerBar.flag);
        end
      end;
      flag = function(value)
        if (powerBar and powerBar.PowerText) then
          local font = tk.Constants.LSM:Fetch(tk.Constants.LSM.MediaType.FONT, data.settings.font);
          powerBar.PowerText:SetFont(font, data.settings.powerBar.fontSize, value);
        end
      end;
      texture = function(value)
        if (not powerBar) then return end
        local statusBarTexture = tk.Constants.LSM:Fetch("statusbar", value);
        powerBar:SetStatusBarTexture(statusBarTexture);
      end;
      height = function(value)
        if (not powerBar) then return end
        powerBar:SetHeight(value);
        PositionStatusBars(data);
      end;
    };
  });
end

function C_ToolTipsModule:OnInitialized(data)
  if (data.settings.enabled and not IsAddOnLoaded("TipTac")) then
    self:SetEnabled(true);
  end
end

function C_ToolTipsModule:OnEnable(data)
  if (not data.screenAnchor) then
    CreateScreenAnchor(data);
  end

	-- Fixes inconsistency with Blizzard code to support backdrop alphas:
  if (tooltipStyle) then
    tooltipStyle.backdropColor.GetRGB = _G.ColorMixin.GetRGBA;
    tooltipStyle.backdropBorderColor.GetRGB = _G.ColorMixin.GetRGBA;
  end

  ApplyHealthBarChanges(data);

  gameTooltip:HookScript("OnShow", function()
    if gameTooltip.IsForbidden and gameTooltip:IsForbidden() then return end

    if (not gameTooltip:GetUnit()) then
      HideAllAuras(data);
      if (gameTooltip.SetGridColor) then
        local r, g, b = gui:GetMuiFrameColor();
        gameTooltip:SetGridColor(r, g, b);
      end
    end

    RefreshPadding(data); -- Needed for DF
  end);

  gameTooltip:HookScript("OnUpdate", function(self, elapsed)
    data.lastUpdated = (data.lastUpdated or 0) + elapsed;

    if not TooltipSafe(self) then return end


    if (data.lastUpdated > 0.2) then
      data.lastUpdated = 0;

      local _, unitID = self:GetUnit();

      if (not unitID) then return end

      local unitGuid = UnitGUID(unitID);

      if (not unitGuid) then return end

      UpdateTargetText(data, unitID);

      if (CanInspectUnit(unitID) and data.inspecting == unitGuid) then
        local entry = guidCache[unitGuid];

        if (not entry) then
          guidCache[unitGuid] = obj:PopTable();
          entry = guidCache[unitGuid];
          entry.itemLevel = 0;
          entry.createdAt = GetTime();
        end

        if (data.settings.itemLevelShown) then
          local itemLevel = tk:GetInspectItemLevel(unitID);
          itemLevel = math.max(itemLevel, entry.itemLevel);
          entry.itemLevel = itemLevel;

          if (entry.itemLevel > 0) then
            SetDoubleLine(data, ITEM_LEVEL_LABEL, entry.itemLevel);
          end
        end

        if (data.settings.specShown) then
          local specName = tk:GetPlayerSpecialization(nil, unitID);

          if (specName) then
            entry.specName = specName;
            SetDoubleLine(data, SPEC_LABEL, entry.specName);
          else
            SetDoubleLine(data, SPEC_LABEL, L["No Spec"]);
          end
        end
      end

      UpdateUnitStatusBars(data, self, unitID);
      UpdateUnitAuras(data, unitID);
    end
  end);

hooksecurefunc("GameTooltip_SetDefaultAnchor", function(self, parent)
    if IsWorldCursorTooltip(self) then return end
   --  niemals anfassen wenn forbidden / combat / edit mode
  if (self and self.IsForbidden and self:IsForbidden()) then return end
  if InCombatLockdown() then return end
  if _G.EditModeManagerFrame and _G.EditModeManagerFrame:IsShown() then return end

  if (not parent) then return end

  --  World cursor / Nameplate / "mouseover in world" -> Blizzard in Ruhe lassen
  local isWorldUnit = UnitExists("mouseover") and not parent.unit
  if isWorldUnit then
    return
  end

  local anchorType = data.settings.standard.anchor:lower()
  local isUnitFrame = parent.unit ~= nil

  if (isUnitFrame) then
    anchorType = data.settings.unitFrames.anchor:lower()
  end

  local anchor = data.settings.anchors[anchorType]
  if not anchor then return end

  self:ClearAllPoints()

  if (anchorType == "mouse") then
    self:SetOwner(parent, anchor.point, anchor.xOffset, anchor.yOffset)
  else
    self:SetOwner(parent, "ANCHOR_NONE")
    self:SetPoint(anchor.point, data.screenAnchor, anchor.point)
  end
end)

  local function OnTooltipSetUnit(self)
  -- HARD SAFETY: niemals in den Secure/WorldCursor/Combat/EditMode Pfad rein
if self and self.IsForbidden and self:IsForbidden() then return end
if InCombatLockdown() then return end
if _G.EditModeManagerFrame and _G.EditModeManagerFrame:IsShown() then return end

-- WorldCursor / Nameplate / "mouseover in world" komplett skippen:
do
  local owner = self.GetOwner and self:GetOwner()
  if UnitExists("mouseover") and (not owner or not owner.unit) then
    return
  end
end

    if not TooltipSafe(self) then return end
    local _, unitID = self:GetUnit();

    if (unitID) then
      UpdateTargetText(data, unitID); -- Do this here and also in OnUpdate so that it shows up on top
      UpdateExistingUnitTooltipLines(data, unitID); -- must be BEFORE padding
      UpdateUnitTexture(data, unitID);
      CheckInspectionState(data, unitID, true); -- Sends an inspect request if required

      -- need to do these here to avoid flickering:
      UpdateUnitStatusBars(data, self, unitID);
      UpdateUnitAuras(data, unitID);
    end

    RefreshPadding(data);
  end

  if (tk:IsRetail() and TooltipDataProcessor) then
    TooltipDataProcessor.AddTooltipPostCall(_G.Enum.TooltipDataType.Unit, function(self)
      if (self == gameTooltip) then
        OnTooltipSetUnit(self);
      end
    end);
  else
    gameTooltip:HookScript("OnTooltipSetUnit", OnTooltipSetUnit);
  end

  local inspectListener = em:CreateEventListener(function(_, _, unitGuid)
    data.inspecting = unitGuid;
  end);

  local f = tk:CreateFrame("Frame");
  f:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = (self.elapsed or 0) + elapsed;

    if (self.elapsed > 60) then
      self.elapsed = 0;

      local now = GetTime();
      local expiredEntries;

      for unitGuid, entry in pairs(guidCache) do
        local timeAgoInSeconds = now - entry.createdAt;

        if (timeAgoInSeconds > 300) then
          local inGroup = UnitInPlayerGroup(unitGuid);

          if (not inGroup) then
            expiredEntries = expiredEntries or obj:PopTable();
            expiredEntries[unitGuid] = entry;
          end
        end
      end

      if (expiredEntries) then
        for key, entry in pairs(expiredEntries) do
          guidCache[key] = nil;
          obj:PushTable(entry);
        end
      end
    end
  end);

  inspectListener:RegisterEvent("INSPECT_READY");
end