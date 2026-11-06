-- MUI-owned Forever player/target aura backend. Blizzard owns live aura values.
-- Deliberately separate from the legacy combat-log TimerBars backend.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, _, _, L = MayronUI:GetCoreComponents();
if (not tk:IsForever()) then return end

local holders = {};
local running = false;
local unpack = _G.unpack;

local function UpdateVisibility(_, event)
  for _, holder in _G.ipairs(holders) do
    if (not running) then
      holder:Hide();
    elseif (holder.unitID == "target") then
      -- A visible target container also needs a refresh when its unit changes.
      if (event == "PLAYER_TARGET_CHANGED" and holder.container) then
        holder.container:UpdateAllAuras();
      end
      local exists = _G.UnitExists("target");
      local dead = _G.UnitIsDeadOrGhost("target");
      -- Never branch on a protected value if this client restricts unit state.
      if (not (_G.issecretvalue and (_G.issecretvalue(exists) or _G.issecretvalue(dead)))) then
        holder:SetShown(exists and not dead);
      end
    else
      holder:Show();
    end
  end
end

local targetEvents = _G.CreateFrame("Frame");
targetEvents:RegisterEvent("PLAYER_TARGET_CHANGED");
targetEvents:RegisterUnitEvent("UNIT_HEALTH", "target");
targetEvents:RegisterUnitEvent("UNIT_FLAGS", "target");
targetEvents:SetScript("OnEvent", UpdateVisibility);

local function HideFields()
  running = false;
  for _, holder in _G.ipairs(holders) do holder:Hide(); end
end

local function CreateRow(button, field, shared, isDebuff)
  local width, height = field.bar.width, field.bar.height;
  button:SetSize(width, height);
  local inset = shared.border.show and shared.border.size or 0;
  local iconWidth = field.showIcons and height or 0;
  local slider = _G.CreateFrame("StatusBar", nil, button);
  slider:SetPoint("TOPLEFT", button, "TOPLEFT", iconWidth + inset, -inset);
  slider:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset);
  slider:SetStatusBarTexture(tk.Constants.LSM:Fetch("statusbar", shared.statusBarTexture));
  slider:SetStatusBarColor(unpack(isDebuff and shared.colors.basicDebuff or shared.colors.basicBuff));
  tk:SetBackground(slider, unpack(shared.colors.background));

  if (field.showIcons) then
    local icon = button:CreateTexture(nil, "ARTWORK");
    icon:SetSize(height - 2 * inset, height - 2 * inset);
    icon:SetPoint("LEFT", button, "LEFT", inset, 0);
    icon:SetTexCoord(0.1, 0.92, 0.08, 0.92);
    button:SetIcon(icon);
  end

  local textParent = _G.CreateFrame("Frame", nil, button);
  textParent:SetAllPoints(button);
  textParent:SetFrameLevel(slider:GetFrameLevel() + 1);
  if (field.auraName.show) then
    local name = textParent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    name:SetPoint("LEFT", slider, "LEFT", 4, 0);
    name:SetPoint("RIGHT", slider, "RIGHT", field.timeRemaining.show and -48 or -4, 0);
    name:SetJustifyH("LEFT");
    name:SetWordWrap(false);
    tk:SetFont(name, field.auraName.font, field.auraName.fontSize);
    button:SetSpellName(name);
  end
  if (field.timeRemaining.show) then
    local remaining = textParent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    remaining:SetPoint("RIGHT", slider, "RIGHT", -4, 0);
    remaining:SetJustifyH("RIGHT");
    tk:SetFont(remaining, field.timeRemaining.font, field.timeRemaining.fontSize);
    button:SetDurationText(remaining, {});
  end
  if (field.spellCount.show) then
    local count = textParent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    count:SetPoint("LEFT", slider, "LEFT", field.spellCount.xOffset, 0);
    tk:SetFont(count, field.spellCount.font, field.spellCount.fontSize);
    button:SetApplicationCount(count, {});
  end
  button:SetDurationBar(slider, { direction = _G.Enum.StatusBarTimerDirection.RemainingTime });
end

local function StartFields()
  if (_G.InCombatLockdown()) then
    tk:Print(L["Timer bars must be started outside combat."]);
    return;
  end
  local secrets = _G.C_Secrets;
  if (secrets and secrets.ShouldAurasBeSecret) then
    local restricted = secrets.ShouldAurasBeSecret();
    if ((_G.issecretvalue and _G.issecretvalue(restricted)) or restricted) then
      tk:Print(L["Timer bars cannot be configured while aura data is restricted."]);
      return;
    end
  end
  if (_G.C_AddOns and _G.C_AddOns.LoadAddOn) then
    _G.C_AddOns.LoadAddOn("Blizzard_AuraContainer");
  end
  if (not _G.CustomAuraContainerGroupDefaultOptions or not _G.AnchorUtil or
      not _G.Enum.StatusBarTimerDirection or _G.Enum.StatusBarTimerDirection.RemainingTime == nil) then
    tk:Print(L["Timer bars are unavailable: required Blizzard display interfaces are missing."]);
    return;
  end
  local database = _G.MUI_TimerBars and _G.MUI_TimerBars.db;
  if (not database or not database.profile.enabled) then return end
  -- Once built, reuse native containers rather than rebuilding their restricted children.
  if (#holders > 0) then
    running = true;
    UpdateVisibility();
    return;
  end
  local profile = database.profile;
  local shared = {
    statusBarTexture = profile.statusBarTexture;
    colors = { basicBuff = {}; basicDebuff = {}; background = {} };
    border = { show = profile.border.show; size = profile.border.size };
  };
  for index = 1, 4 do
    shared.colors.basicBuff[index] = profile.colors.basicBuff[index];
    shared.colors.basicDebuff[index] = profile.colors.basicDebuff[index];
    shared.colors.background[index] = profile.colors.background[index];
  end
  for _, fieldName in profile.fieldNames:Iterate() do
    local field = profile.fields[fieldName];
    if (field.enabled and (field.unitID == "player" or field.unitID == "target") and
        (field.filters.showBuffs or field.filters.showDebuffs)) then
      if (field.filters.enableWhiteList or field.filters.enableBlackList) then
        tk:Print(L["Timer bars: fields with active filter lists are not supported on WoW Forever."]);
      else
        local holder = _G.CreateFrame("Frame", nil, _G.UIParent);
        holder.unitID = field.unitID;
        holder:SetSize(field.bar.width, 1);
        local position = field.position;
        holder:SetPoint(position[1], _G[position[2]] or _G.UIParent, position[3], position[4], position[5]);
        local ok, err = _G.pcall(function()
          local container = _G.CreateFrame("AuraContainer", nil, holder, "CustomAuraContainerTemplate");
          holder.container = container;
          container:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT");
          container:SetUnit(field.unitID);
          container:SetFlowLayoutMaximumLineSize(field.bar.width);
          local flow = _G.AnchorUtil.FlowDirection;
          container:SetFlowLayoutGrowthDirection(flow.Right, field.direction == "UP" and flow.Up or flow.Down);
          container:SetFlowLayoutAnchorPoint(field.direction == "UP" and "BOTTOMLEFT" or "TOPLEFT");
          local function AddGroup(isDebuff)
            local onlyPlayer = isDebuff and field.filters.onlyPlayerDebuffs or
              (not isDebuff and field.filters.onlyPlayerBuffs);
            local filter = isDebuff and "HARMFUL" or "HELPFUL";
            if (onlyPlayer) then filter = filter .. "|PLAYER"; end
            container:AddAuraGroup(isDebuff and "MUIDebuffs" or "MUIBuffs", filter, {
              maxFrameCount = field.bar.maxBars;
              sortMethod = profile.sortByExpirationTime and _G.AuraContainerSortMethod.ExpirationOnly or _G.AuraContainerSortMethod.Default;
              sortDirection = _G.AuraContainerSortDirection.Normal;
              layout = { elementSpacing = field.bar.spacing; lineSpacing = field.bar.spacing };
              initializeFrame = function(button) CreateRow(button, field, shared, isDebuff); end;
            });
          end
          if (field.filters.showBuffs) then AddGroup(false); end
          if (field.filters.showDebuffs) then AddGroup(true); end
          container:SetEnabled(true);
        end);
        if (not ok) then
          holder:Hide();
          tk:Print(L["Timer bars could not be created: %s"]:format(_G.tostring(err)));
        else
          holders[#holders + 1] = holder;
        end
      end
    end
  end
  running = true;
  UpdateVisibility();
end

-- Start after the module has initialized its existing database and default fields.
local startupEvents = _G.CreateFrame("Frame");
startupEvents:SetScript("OnEvent", function(self)
  self:UnregisterEvent("PLAYER_REGEN_ENABLED");
  StartFields();
end);
MayronUI:Hook("TimerBars", "OnInitialized", function()
  if (_G.InCombatLockdown()) then
    startupEvents:RegisterEvent("PLAYER_REGEN_ENABLED");
  else
    StartFields();
  end
end);

_G.SLASH_MUIFOREVERTIMERS1 = "/muitimers";
_G.SlashCmdList.MUIFOREVERTIMERS = function(message)
  if (_G.strtrim(message or "") == "off") then
    HideFields();
  else
    StartFields();
  end
end;
