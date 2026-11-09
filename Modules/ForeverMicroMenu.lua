-- Forever micro-menu visibility through Bartender's existing visibility driver.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, _, _, L = MayronUI:GetCoreComponents();
if (not tk:IsRetail()) then return end

db:AddToDefaults("global.foreverMicroMenu", { hidden = true });
local ready, lastProfile, elapsedTotal = false, nil, 0;
local function Apply(force)
  if (not ready or _G.InCombatLockdown()) then return false end
  local bt = _G.Bartender4;
  local module = bt and bt.GetModule and bt:GetModule("MicroMenu", true);
  if (not module or not module.bar or not module.db or not module.bar.SetVisibilityOption) then return false end
  local profile = module.db.profile;
  if (force or lastProfile ~= profile) then
    module.bar:SetVisibilityOption("always", db.global.foreverMicroMenu.hidden == true);
    lastProfile = profile;
  end
  return true;
end
MayronUI:Hook("CoreModule", "OnInitialized", function()
  ready = true;
  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED"); watcher:RegisterEvent("ADDON_LOADED");
  watcher:SetScript("OnEvent", function() Apply(false); end);
  watcher:SetScript("OnUpdate", function(_, elapsed)
    elapsedTotal = elapsedTotal + elapsed;
    if (elapsedTotal >= 0.5) then elapsedTotal = 0; Apply(false); end
  end);
  Apply(false);
end);
_G.SLASH_MUIMICROMENU1 = "/muimicro";
_G.SlashCmdList.MUIMICROMENU = function(message)
  local option = _G.strtrim(message or ""):lower();
  if (option ~= "on" and option ~= "off") then
    tk:Print(L["Micro menu: /muimicro on to show, /muimicro off to hide."]); return;
  end
  if (not ready or _G.InCombatLockdown()) then
    tk:Print(L["Change micro-menu visibility outside combat after login."]); return;
  end
  db.global.foreverMicroMenu.hidden = option == "off";
  if (not Apply(true)) then tk:Print(L["The Bartender4 micro-menu module must be enabled."]); end
end;
