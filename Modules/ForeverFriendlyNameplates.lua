local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db = MayronUI:GetCoreComponents();
if (not tk:IsForever()) then return end

db:AddToDefaults("profile.friendlyNameplates", {
  muiFont = false;
  guildColorEnabled = false;
  guildColor = { r = 1; g = 0.78; b = 0.25; a = 1 };
  guildStar = false;
  showGuildNames = true;
});

db:AddToDefaults("global.friendlyNameplateCVars", {
  active = false;
  visibility = "";
  nameOnly = "";
});

local nameplates = MayronUI:NewComponent("ForeverFriendlyNameplates");

local nameOnlyCVar = "nameplateShowOnlyNameForFriendlyPlayerUnits";
local visibilityCVar = "nameplateShowFriendlyPlayers";
local playerNameColor = 96 / 255;

local function UpdateNameplateCVars(enabled)
  local saved = db.global.friendlyNameplateCVars;
  if (enabled == saved.active or not _G.GetCVar or not _G.SetCVar) then return end

  local visibility, nameOnly = _G.GetCVar(visibilityCVar), _G.GetCVar(nameOnlyCVar);
  if (enabled) then
    if (not visibility or not nameOnly) then return end
    saved.visibility = visibility;
    saved.nameOnly = nameOnly;
    saved.active = true;
    if (visibility ~= "1") then _G.SetCVar(visibilityCVar, "1"); end
    if (nameOnly ~= "1") then _G.SetCVar(nameOnlyCVar, "1"); end
  else
    if (visibility == "1" and saved.visibility ~= "" and saved.visibility ~= "1") then
      _G.SetCVar(visibilityCVar, saved.visibility);
    end
    if (nameOnly == "1" and saved.nameOnly ~= "" and saved.nameOnly ~= "1") then
      _G.SetCVar(nameOnlyCVar, saved.nameOnly);
    end
    saved.active = false;
    saved.visibility = "";
    saved.nameOnly = "";
  end
end

MayronUI:Hook("CoreModule", "OnInitialized", function()
  local enabled = db.profile.friendlyNameplates.muiFont and _G.C_NamePlate ~= nil;
  UpdateNameplateCVars(enabled);
  if (not enabled) then return end

  local names, stars, guildLabels = {}, {}, {};
  local isSecret = _G.issecretvalue;

  local playerLabels = {};

  local function GetDisplayName(original, unit)
    local name = original.name;
    local fullName = _G.GetUnitName and _G.GetUnitName(unit, true);
    local label = playerLabels[original.frame];
    if ((isSecret and isSecret(fullName)) or type(fullName) ~= "string" or fullName == "") then
      if (label) then label:Hide(); end
      if (original.replaced) then name:SetAlpha(original.alpha); end
      original.replaced = nil;
      return name;
    end

    if (not label) then
      label = original.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
      tk:SetMasterFont(label, 15, "");
      label:SetShadowColor(0, 0, 0, 0);
      playerLabels[original.frame] = label;
    end
    label:ClearAllPoints();
    label:SetPoint("CENTER", name, "CENTER");
    label:SetText(fullName);
    label:SetShown(name:IsShown());
    original.replaced = true;
    name:SetAlpha(0);
    return label;
  end

  local function StyleGuildName(frame, unit, name)
    local settings = db.profile.friendlyNameplates;
    local guild;
    if (settings.showGuildNames or settings.guildColorEnabled or settings.guildStar) then
      local value = _G.GetGuildInfo(unit);
      if (not (isSecret and isSecret(value)) and type(value) == "string" and value ~= "") then
        guild = value;
      end
    end

    local member = false;
    if (guild and (settings.guildColorEnabled or settings.guildStar)) then
      local ownGuild = _G.GetGuildInfo("player");
      member = not (isSecret and isSecret(ownGuild)) and ownGuild == guild;
    end

    local label = guildLabels[frame];
    local showGuild = settings.showGuildNames and guild ~= nil and name:IsShown();
    if (showGuild and not label) then
      label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
      label:SetPoint("TOP", name, "BOTTOM", 0, -1);
      tk:SetMasterFont(label, 14, "");
      label:SetShadowColor(0, 0, 0, 0);
      label:SetTextColor(playerNameColor, playerNameColor, 1);
      guildLabels[frame] = label;
    end
    if (label and not label:IsForbidden()) then
      if (showGuild) then
        label:ClearAllPoints();
        label:SetPoint("TOP", name, "BOTTOM", 0, -1);
        label:SetFormattedText("<%s>", guild);
      end
      label:SetShown(showGuild);
    end

    if (member and settings.guildColorEnabled) then
      local color = settings.guildColor;
      name:SetTextColor(color.r, color.g, color.b, 1);
    else
      name:SetTextColor(playerNameColor, playerNameColor, 1, 1);
    end

    local showStar = member and settings.guildStar and name:IsShown();
    local star = stars[frame];
    if (showStar and not star) then
      star = frame:CreateTexture(nil, "OVERLAY");
      star:SetSize(11, 11);
      star:SetPoint("RIGHT", name, "LEFT", -3, 0);
      star:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1");
      stars[frame] = star;
    end
    if (star) then
      if (showStar) then
        star:ClearAllPoints();
        star:SetPoint("RIGHT", name, "LEFT", -3, 0);
      end
      star:SetShown(showStar);
    end
  end

  local function Restore(unit)
    local original = names[unit];
    if (not original) then return end
    names[unit] = nil;
    local star = stars[original.frame];
    if (star and not star:IsForbidden()) then star:Hide(); end
    local label = guildLabels[original.frame];
    if (label and not label:IsForbidden()) then label:Hide(); end
    local playerLabel = playerLabels[original.frame];
    if (playerLabel and not playerLabel:IsForbidden()) then playerLabel:Hide(); end
    local name = original.name;
    if (name:IsForbidden()) then return end
    name:SetFont(original.file, original.size, original.flags);
    if (original.replaced) then name:SetAlpha(original.alpha); end
    name:SetShadowOffset(original.x, original.y);
    name:SetShadowColor(unpack(original.shadow));
    name:SetTextColor(unpack(original.color));
  end

  local function Apply(unit, expectedFrame)
    if ((isSecret and isSecret(unit)) or type(unit) ~= "string" or _G.GetCVar(nameOnlyCVar) ~= "1") then return end

    local plate = _G.C_NamePlate.GetNamePlateForUnit(unit);
    if (not plate or plate:IsForbidden()) then return end
    local frame = plate.UnitFrame;
    if (not frame or frame:IsForbidden() or (expectedFrame and frame ~= expectedFrame)) then return end

    local player, hostile = _G.UnitIsPlayer(unit), _G.UnitCanAttack("player", unit);
    if ((isSecret and (isSecret(player) or isSecret(hostile))) or not player or hostile) then
      Restore(unit);
      return;
    end
    local name = frame.name;
    if (not name or name:IsForbidden()) then return end

    if (not names[unit]) then
      local file, size, flags = name:GetFont();
      if (not file) then return end
      local x, y = name:GetShadowOffset();
      names[unit] = { frame = frame; name = name; file = file; size = size; flags = flags; alpha = name:GetAlpha();
        x = x; y = y; shadow = {name:GetShadowColor()}; color = {name:GetTextColor()} };
    end

    tk:SetMasterFont(name, 15, "");
    StyleGuildName(frame, unit, GetDisplayName(names[unit], unit));
    name:SetShadowOffset(1, -1);
    name:SetShadowColor(0, 0, 0, 0);
  end

  local function Refresh()
    for unit in pairs(names) do Restore(unit); end
    if (_G.GetCVar(nameOnlyCVar) ~= "1") then return end
    for _, plate in ipairs(_G.C_NamePlate.GetNamePlates()) do
      if (not plate:IsForbidden() and plate.namePlateUnitToken) then
        Apply(plate.namePlateUnitToken);
      end
    end
  end

  if (_G.CompactUnitFrame_UpdateName) then
    _G.hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
      if (frame:IsForbidden()) then return end
      local unit = frame.unit;
      if ((isSecret and isSecret(unit)) or type(unit) ~= "string" or not unit:match("^nameplate%d+$")) then return end
      Apply(unit, frame);
    end);
  end

  nameplates.Refresh = Refresh;

  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("NAME_PLATE_UNIT_ADDED");
  watcher:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
  watcher:RegisterEvent("CVAR_UPDATE");
  watcher:RegisterEvent("PLAYER_GUILD_UPDATE");
  watcher:RegisterEvent("PLAYER_TARGET_CHANGED");
  watcher:SetScript("OnEvent", function(_, event, value)
    if (event == "NAME_PLATE_UNIT_REMOVED") then
      Restore(value);
    elseif (event == "NAME_PLATE_UNIT_ADDED") then
      _G.C_Timer.After(0, function()
        if (_G.UnitExists(value) and _G.GetCVar(nameOnlyCVar) == "1") then Apply(value); end
      end);
    elseif (event == "PLAYER_TARGET_CHANGED") then
      local plate = _G.C_NamePlate.GetNamePlateForUnit("target");
      local unit = plate and not plate:IsForbidden() and plate.namePlateUnitToken;
      Apply(unit);
    elseif (event == "PLAYER_GUILD_UPDATE" or value == nameOnlyCVar) then
      _G.C_Timer.After(0, Refresh);
    end
  end);
  Refresh();
end);
