-- Independent report shortcut; never alter Blizzard's error window or handlers.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, gui, _, L = MayronUI:GetCoreComponents();
if (not tk:IsForever()) then return end

local button;
local elapsedTotal = 0;
local function Refresh()
  local native = _G.ScriptErrorsFrame;
  if (_G.InCombatLockdown() or not native or not native:IsVisible()) then
    if (button) then button:Hide(); end
    return;
  end
  local left, bottom, width, height = native:GetRect();
  if (_G.issecretvalue and (_G.issecretvalue(left) or _G.issecretvalue(bottom) or
      _G.issecretvalue(width) or _G.issecretvalue(height))) then
    if (button) then button:Hide(); end
    return;
  end
  if (not left or not bottom or not width or not height) then
    if (button) then button:Hide(); end
    return;
  end
  if (not button) then
    button = gui:CreateButton(_G.UIParent, L["Open MUI error report"]);
    button:SetFrameStrata("TOOLTIP");
    button:SetHeight(26);
    button:SetClampedToScreen(true);
    tk:SetBasicTooltip(button,
      L["Open the MUI report form. Copy the Lua error from Blizzard's window into the report if needed."],
      "ANCHOR_TOP");
    button:SetScript("OnClick", function()
      if (not _G.InCombatLockdown()) then MayronUI:TriggerCommand("report", true); end
    end);
  end
  local scale = native:GetEffectiveScale() / _G.UIParent:GetEffectiveScale();
  -- Independent coordinates, no parent/anchor dependency on protected Blizzard UI.
  button:ClearAllPoints();
  button:SetPoint("TOPLEFT", _G.UIParent, "BOTTOMLEFT", left * scale, bottom * scale - 6);
  button:Show();
end

MayronUI:Hook("CoreModule", "OnInitialized", function()
  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("PLAYER_REGEN_DISABLED");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
  watcher:SetScript("OnEvent", Refresh);
  watcher:SetScript("OnUpdate", function(_, elapsed)
    elapsedTotal = elapsedTotal + elapsed;
    if (elapsedTotal >= 0.2) then elapsedTotal = 0; Refresh(); end
  end);
  Refresh();
end);
