-- Forever loot-window decoration only. Native loot buttons and scripts remain intact.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, gui, _, L = MayronUI:GetCoreComponents();
if (not tk:IsForever()) then return end
local ready, panel, elapsedTotal = false, nil, 0;
local originals = {};
local enabled = true;
local hookedFrames, closeVisuals = {}, {};
local function HideBorders(frame, allLayers)
  if (not frame or not frame.GetRegions) then return end
  for _, region in _G.ipairs({ frame:GetRegions() }) do
    if (region:IsObjectType("Texture")) then
      local layer = region:GetDrawLayer();
      if (allLayers or layer == "BACKGROUND" or layer == "BORDER") then
        if (originals[region] == nil) then originals[region] = region:GetAlpha(); end
        region:SetAlpha(0);
      end
    end
  end
end
local function StyleCloseButton(native, red, green, blue)
  local button = native.ClosePanelButton or native.CloseButton or _G.LootFrameCloseButton;
  if (not button or not button.GetRegions) then return end
  local visual = closeVisuals[button];
  if (not visual) then
    visual = _G.CreateFrame("Frame", nil, button);
    visual:EnableMouse(false); visual:SetAllPoints(button);
    visual.background = visual:CreateTexture(nil, "BACKGROUND");
    visual.background:SetAllPoints();
    visual.background:SetTexture(tk:GetAssetFilePath("Textures\\Widgets\\Button"));
    visual.icon = gui:CreateIconTexture("cross", visual, false);
    closeVisuals[button] = visual;
  end
  HideBorders(button, true);
  visual.background:SetVertexColor(red * 0.65, green * 0.65, blue * 0.65, 1);
  visual.icon:SetVertexColor(red, green, blue, 1);
  visual:Show();
end
local function Refresh()
  if (not ready or not enabled) then return end
  local native = _G.LootFrame;
  if (not native or not native:IsVisible()) then if (panel) then panel:Hide(); end return end
  if (_G.InCombatLockdown()) then return end
  local x, y, width, height = native:GetRect();
  if (_G.issecretvalue and (_G.issecretvalue(x) or _G.issecretvalue(y) or
      _G.issecretvalue(width) or _G.issecretvalue(height))) then return end
  if (not x or not y or not width or not height) then return end
  if (not panel) then
    panel = _G.CreateFrame("Frame", nil, _G.UIParent);
    panel:EnableMouse(false);
    gui:CreateGridTexture(panel,
      tk:GetAssetFilePath("Textures\\DialogBox\\Dialog-Medium"), 10, 0, 674, 674, "BACKGROUND");
    panel:SetGridAlphaType("Low");
    panel.heading = panel:CreateTexture(nil, "BORDER");
    panel.heading:SetTexture(tk:GetAssetFilePath("Textures\\Widgets\\Button"));
    panel.heading:SetPoint("TOPLEFT", 7, -7); panel.heading:SetPoint("TOPRIGHT", -7, -7);
    panel.heading:SetHeight(20);
  end
  local scale = native:GetEffectiveScale() / _G.UIParent:GetEffectiveScale();
  local level = native:GetFrameLevel();
  local strata = native:GetFrameStrata();
  if (level == 0) then
    local below = { DIALOG = "HIGH", HIGH = "MEDIUM", MEDIUM = "LOW", LOW = "BACKGROUND" };
    strata = below[strata] or "BACKGROUND";
  end
  panel:SetFrameStrata(strata); panel:SetFrameLevel(_G.math.max(0, level - 1));
  panel:ClearAllPoints();
  panel:SetPoint("BOTTOMLEFT", _G.UIParent, "BOTTOMLEFT", (x - 4) * scale, (y + 6) * scale);
  panel:SetSize((width + 8) * scale, _G.math.max(1, height - 2) * scale);
  local fr, fg, fb = gui:GetMuiFrameColor(); panel:SetGridColor(fr, fg, fb);
  local red, green, blue = tk:GetClassColor();
  panel.heading:SetVertexColor(red * 0.45, green * 0.45, blue * 0.45, 0.85);
  HideBorders(native); HideBorders(native.NineSlice, true); HideBorders(native.Border, true);
  StyleCloseButton(native, red, green, blue);
  panel:Show();
end
local function BindLootFrame()
  local native = _G.LootFrame;
  if (not native or hookedFrames[native] or _G.InCombatLockdown()) then return end
  -- Style during OnShow, before rendering, rather than waiting for the next poll.
  native:HookScript("OnShow", Refresh);
  native:HookScript("OnHide", function() if (panel) then panel:Hide(); end end);
  native:HookScript("OnSizeChanged", Refresh);
  hookedFrames[native] = true;
  if (enabled) then
    HideBorders(native); HideBorders(native.NineSlice, true); HideBorders(native.Border, true);
  end
end
MayronUI:Hook("CoreModule", "OnInitialized", function()
  ready = true;
  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("LOOT_OPENED"); watcher:RegisterEvent("LOOT_CLOSED");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED"); watcher:RegisterEvent("ADDON_LOADED");
  watcher:SetScript("OnEvent", function() BindLootFrame(); Refresh(); end);
  watcher:SetScript("OnUpdate", function(_, elapsed)
    elapsedTotal = elapsedTotal + elapsed;
    if (elapsedTotal >= 0.2) then elapsedTotal = 0; BindLootFrame(); Refresh(); end
  end);
  BindLootFrame(); Refresh();
end);

_G.SLASH_MUILOOTSTYLE1 = "/muilootstyle";
_G.SlashCmdList.MUILOOTSTYLE = function(message)
  local option = _G.strtrim(message or ""):lower();
  if (option ~= "on" and option ~= "off") then
    tk:Print(L["Loot appearance: /muilootstyle on or /muilootstyle off."]); return;
  end
  if (_G.InCombatLockdown()) then return end
  enabled = option == "on";
  if (enabled) then Refresh(); else
    if (panel) then panel:Hide(); end
    for texture, alpha in _G.pairs(originals) do texture:SetAlpha(alpha); end
    originals = {};
    for _, visual in _G.pairs(closeVisuals) do visual:Hide(); end
  end
end;
