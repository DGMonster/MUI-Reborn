-- Optional presentation for Questie. Questie owns content and interaction.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, gui, _, L = MayronUI:GetCoreComponents();

db:AddToDefaults("global.foreverQuestie", { enabled = false });
local ready, panel, tracker = false, nil, nil;
local elapsedTotal = 0;

local function Refresh()
  if (not ready) then return end
  if (not db.global.foreverQuestie.enabled) then
    if (panel) then panel:Hide(); end
    return;
  end
  local native = _G.Questie_BaseFrame;
  if (not native or not native:IsVisible()) then
    if (panel) then panel:Hide(); end
    return;
  end
  -- Never change addon frame hierarchies or presentation during combat.
  if (_G.InCombatLockdown()) then return end
  if (not panel or tracker ~= native) then
    if (panel) then panel:Hide(); end
    tracker = native;
    panel = _G.CreateFrame("Frame", nil, native);
    panel:EnableMouse(false);
    panel:SetPoint("TOPLEFT", native, "TOPLEFT", -4, 4);
    panel:SetPoint("BOTTOMRIGHT", native, "BOTTOMRIGHT", 4, -4);
    gui:CreateGridTexture(panel,
      tk:GetAssetFilePath("Textures\\DialogBox\\Dialog-Medium"), 10, 0, 674, 674, "BACKGROUND");
    panel:SetGridAlphaType("Low");
    panel.accent = panel:CreateTexture(nil, "ARTWORK");
    panel.accent:SetTexture("Interface\\Buttons\\WHITE8X8");
    panel.accent:SetPoint("TOPLEFT", 9, -5);
    panel.accent:SetPoint("TOPRIGHT", -9, -5);
    panel.accent:SetHeight(2);
    panel.heading = panel:CreateTexture(nil, "BORDER");
    panel.heading:SetTexture(tk:GetAssetFilePath("Textures\\Widgets\\Button"));
    panel.heading:SetPoint("TOPLEFT", 7, -7);
    panel.heading:SetPoint("TOPRIGHT", -7, -7);
    panel.heading:SetHeight(20);
  end
  -- Keep the decoration below Questie's header and quest-content child frames.
  panel:SetFrameLevel(native:GetFrameLevel());
  local fr, fg, fb = gui:GetMuiFrameColor();
  panel:SetGridColor(fr, fg, fb);
  local red, green, blue = tk:GetThemeColor();
  panel.accent:SetVertexColor(red, green, blue, 0.85);
  panel.heading:SetVertexColor(red * 0.4, green * 0.4, blue * 0.4, 0.65);
  local header = _G.Questie_HeaderFrame;
  panel.heading:SetShown(header and header:IsShown() or false);
  panel:Show();
end

local controller = {};
function controller:SetEnabled(enabled)
  if (not ready or _G.InCombatLockdown()) then
    tk:Print(L["Questie styling can only be changed outside combat after login."]);
    return false;
  end
  db.global.foreverQuestie.enabled = enabled == true;
  Refresh();
  return true;
end
MayronUI:AddComponent("ForeverQuestieStyle", controller);
MayronUI:Hook("CoreModule", "OnInitialized", function()
  ready = true;
  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
  watcher:RegisterEvent("ADDON_LOADED");
  watcher:SetScript("OnEvent", Refresh);
  watcher:SetScript("OnUpdate", function(_, elapsed)
    if (not db.global.foreverQuestie.enabled) then return end
    elapsedTotal = elapsedTotal + elapsed;
    if (elapsedTotal >= 0.25) then elapsedTotal = 0; Refresh(); end
  end);
  Refresh();
end);
_G.SLASH_MUIQUESTIESTYLE1 = "/muiquestie";
_G.SlashCmdList.MUIQUESTIESTYLE = function(message)
  local option = _G.strtrim(message or ""):lower();
  if (option ~= "on" and option ~= "off") then
    tk:Print(L["Questie appearance: /muiquestie on or /muiquestie off."]);
    return;
  end
  if (controller:SetEnabled(option == "on")) then
    tk:Print(L[option == "on" and "MUI Questie styling enabled (requires Questie)." or "MUI Questie styling disabled."]);
  end
end;
