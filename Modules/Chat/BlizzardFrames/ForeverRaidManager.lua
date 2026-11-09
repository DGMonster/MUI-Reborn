-- First restoration step: appearance only; Blizzard retains all manager controls.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, gui, _, L = MayronUI:GetCoreComponents();
if (not tk:IsRetail()) then return end

local enabled = tk:IsForever();
local initialized = false;
local background;
local originals = {};
local elapsedSinceRefresh = 0;
local lastState = "idle";
local toggleStyles = {};

local function StyleToggleButton(button, expanded)
  if (not button or not button.IsObjectType or not button:IsObjectType("Button") or _G.InCombatLockdown()) then return end
  local toggleStyle = toggleStyles[button];
  if (not toggleStyle) then
    local width, height = button:GetSize();
    toggleStyle = { button = button; width = width; height = height; textures = {} };
    toggleStyles[button] = toggleStyle;
    -- Snapshot native artwork before creating MUI textures on the same button.
    for _, region in _G.ipairs({ button:GetRegions() }) do
      if (region:IsObjectType("Texture")) then
        toggleStyle.textures[#toggleStyle.textures + 1] = region;
      end
    end
    toggleStyle.panel = button:CreateTexture(nil, "ARTWORK");
    toggleStyle.panel:SetAllPoints();
    toggleStyle.panel:SetTexture(tk:GetAssetFilePath("Textures\\SideBar\\SideButton"));
    toggleStyle.panel:SetTexCoord(1, 0, 0, 1);
    toggleStyle.arrow = button:CreateTexture(nil, "OVERLAY");
    toggleStyle.arrow:SetSize(12, 8);
    toggleStyle.arrow:SetPoint("CENTER");
    toggleStyle.arrow:SetTexture(tk:GetAssetFilePath("Icons\\arrow"));
  end
  for _, region in _G.ipairs(toggleStyle.textures) do
    if (originals[region] == nil) then originals[region] = region:GetAlpha(); end
    region:SetAlpha(0);
  end
  -- Keep the native click action, only match its hit area to the existing MUI tab.
  button:SetSize(15, 100);
  local r, g, b = tk:GetThemeColor();
  toggleStyle.arrow:SetVertexColor(r, g, b);
  toggleStyle.arrow:SetRotation(_G.math.rad(expanded and 90 or -90));
  toggleStyle.panel:Show();
  toggleStyle.arrow:Show();
end

local function StyleToggle(manager)
  -- The current manager has separate expand and collapse buttons.
  StyleToggleButton(manager.toggleButtonForward, false);
  StyleToggleButton(manager.toggleButtonBack, true);
end

local function HideNativeBackground(frame)
  if (not frame or not frame.GetRegions) then return end
  for _, region in _G.ipairs({ frame:GetRegions() }) do
    if (region:IsObjectType("Texture")) then
      local layer = region:GetDrawLayer();
      local atlas = region.GetAtlas and region:GetAtlas();
      -- Only the two native divider atlases are additionally removed from ARTWORK.
      local divider = atlas == "GM-bgOpen-divider-horizontal" or atlas == "GM-bgOpen-divider-vertical";
      if (layer == "BACKGROUND" or layer == "BORDER" or divider) then
        if (originals[region] == nil) then originals[region] = region:GetAlpha(); end
        region:SetAlpha(0);
      end
    end
  end
end

local function Restore()
  for region, alpha in _G.pairs(originals) do region:SetAlpha(alpha); end
  originals = {};
  if (background) then background:Hide(); end
  for button, style in _G.pairs(toggleStyles) do
    style.panel:Hide();
    style.arrow:Hide();
    button:SetSize(style.width, style.height);
  end
end

local function Refresh()
  if (not enabled or not initialized) then return end
  local manager = _G.CompactRaidFrameManager;
  local display = manager and (manager.displayFrame or _G.CompactRaidFrameManagerDisplayFrame);
  if (manager and not _G.InCombatLockdown()) then
    StyleToggle(manager);
    -- The closed manager also draws Background; remove it before display-hidden return.
    local nativeBackground = manager.Background;
    if (nativeBackground and nativeBackground.IsObjectType and nativeBackground:IsObjectType("Texture")) then
      if (originals[nativeBackground] == nil) then originals[nativeBackground] = nativeBackground:GetAlpha(); end
      nativeBackground:SetAlpha(0);
    end
    -- Pooled divider artwork can remain after collapsing the display frame.
    HideNativeBackground(manager);
  end
  if (not display or not display:IsVisible()) then
    lastState = not manager and "manager missing" or (not display and "display missing" or "display hidden");
    if (background) then background:Hide(); end
    return;
  end
  -- Never alter native regions or read/compute native geometry during combat.
  if (_G.InCombatLockdown()) then lastState = "combat"; return end
  local left, bottom, width, height = display:GetRect();
  if (_G.issecretvalue and (_G.issecretvalue(left) or _G.issecretvalue(bottom) or
      _G.issecretvalue(width) or _G.issecretvalue(height))) then lastState = "secret geometry"; return end
  if (not left or not bottom or not width or not height) then lastState = "geometry unavailable"; return end
  if (not background) then
    background = _G.CreateFrame("Frame", "MUI_ForeverRaidManagerBackground", _G.UIParent);
    background:EnableMouse(false);
    gui:CreateGridTexture(background,
      tk:GetAssetFilePath("Textures\\DialogBox\\Dialog-Medium"), 10, 0, 674, 674, "BACKGROUND");
    background:SetGridAlphaType("High");
  end
  -- Independent screen coordinates: no new protected anchor/parent dependency.
  local scale = display:GetEffectiveScale() / _G.UIParent:GetEffectiveScale();
  background:ClearAllPoints();
  background:SetPoint("BOTTOMLEFT", _G.UIParent, "BOTTOMLEFT", left * scale - 4, bottom * scale - 4);
  background:SetSize(width * scale + 8, height * scale + 8);
  background:SetFrameStrata(display:GetFrameStrata());
  background:SetFrameLevel(_G.math.max(0, display:GetFrameLevel() - 1));
  local r, g, b = gui:GetMuiFrameColor();
  background:SetGridColor(r, g, b);

  HideNativeBackground(display);
  HideNativeBackground(manager.NineSlice);
  HideNativeBackground(display.NineSlice);
  background:Show();
  lastState = "drawn";
end

MayronUI:Hook("CoreModule", "OnInitialized", function()
  initialized = true;
  Refresh();
end);

local events = _G.CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:RegisterEvent("PLAYER_REGEN_ENABLED");
events:RegisterEvent("PLAYER_ENTERING_WORLD");
events:RegisterEvent("GROUP_ROSTER_UPDATE");
events:SetScript("OnEvent", Refresh);
-- Observe native expansion/animation without replacing any native method/script.
events:SetScript("OnUpdate", function(_, elapsed)
  if (not enabled) then return end
  elapsedSinceRefresh = elapsedSinceRefresh + elapsed;
  if (elapsedSinceRefresh >= 0.2) then
    elapsedSinceRefresh = 0;
    Refresh();
  end
end);

local function PrintStatus()
  local count = 0;
  for _ in _G.pairs(originals) do count = count + 1; end
  local buttons = 0;
  for _ in _G.pairs(toggleStyles) do buttons = buttons + 1; end
  tk:Print(L["Raid manager styled toggle buttons: %d"]:format(buttons));
  tk:Print(L["Raid manager test status: enabled=%s; state=%s; hidden textures=%d; background=%s"]:format(
    _G.tostring(enabled), lastState, count,
    _G.tostring(background and background:IsShown() or false)));
  local manager = _G.CompactRaidFrameManager;
  local display = manager and (manager.displayFrame or _G.CompactRaidFrameManagerDisplayFrame);
  if (display) then
    local name = display:GetName() or "anonymous";
    tk:Print(L["Raid manager frame: %s; strata=%s; level=%s"]:format(
      name, display:GetFrameStrata(), _G.tostring(display:GetFrameLevel())));
    -- Only frame artwork metadata, no protected unit/combat data.
    for _, region in _G.ipairs({ display:GetRegions() }) do
      if (region:IsObjectType("Texture")) then
        tk:Print(L["Raid manager texture: %s; layer=%s"]:format(
          region:GetName() or "anonymous", region:GetDrawLayer()));
      end
    end
  end
end

_G.SLASH_MUIRAIDSTYLE1 = "/muiraidstyle";
_G.SlashCmdList.MUIRAIDSTYLE = function(message)
  local option = _G.strtrim(message or ""):lower();
  if (option == "status") then
    if (_G.InCombatLockdown()) then
      tk:Print(L["Change the raid manager appearance outside combat."]);
      return;
    end
    PrintStatus();
    return;
  end
  if (option ~= "on" and option ~= "off") then
    tk:Print(L["Raid manager test: /muiraidstyle on or /muiraidstyle off."]);
    return;
  end
  if (_G.InCombatLockdown()) then
    tk:Print(L["Change the raid manager appearance outside combat."]);
    return;
  end
  enabled = option == "on";
  if (enabled) then Refresh(); else Restore(); lastState = "off"; end
  PrintStatus();
end;
