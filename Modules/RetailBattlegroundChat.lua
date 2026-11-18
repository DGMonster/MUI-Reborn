-- Avoid repeated battleground roster summaries in Retail.
-- Individual system messages continue through Blizzard's normal chat handler.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk = MayronUI:GetCoreComponents();
if (not tk:IsRetail() or tk:IsForever()) then return end

local installed;
local pending = false;

local function StopBatching()
  if (_G.InCombatLockdown()) then
    pending = true;
    return;
  end
  local inside, kind = _G.IsInInstance();
  if (not inside or kind ~= "pvp") then pending = false; return; end
  local filter = _G.BattlegroundChatFilters;
  if (not filter or not filter.StopBGChatFilter) then return end
  if (filter:GetScript("OnUpdate")) then
    filter:StopBGChatFilter();
  end
  pending = false;
end

local function Attach()
  local filter = _G.BattlegroundChatFilters;
  if (filter and not installed and type(filter.StartBGChatFilter) == "function") then
    _G.hooksecurefunc(filter, "StartBGChatFilter", function()
      -- Wait until Blizzard has finished starting its collector.
      _G.C_Timer.After(0, StopBatching);
    end);
    installed = true;
  end
  StopBatching();
end

MayronUI:Hook("CoreModule", "OnInitialized", function()
  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("ADDON_LOADED");
  watcher:RegisterEvent("PLAYER_ENTERING_WORLD");
  watcher:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
  watcher:SetScript("OnEvent", function(_, event)
    if (event == "PLAYER_REGEN_ENABLED") then
      if (pending) then Attach(); end
    else
      Attach();
    end
  end);
  Attach();
end);