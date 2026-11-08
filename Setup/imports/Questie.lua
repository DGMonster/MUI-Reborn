-- Optional Forever tracker preset; no replacement of Questie profiles.
local _, setup = ...;
local MayronUI = _G.MayronUI;
local tk = MayronUI:GetCoreComponents();
if (not tk:IsForever()) then return end

setup.import["Questie"] = function()
  local questie = _G.Questie;
  if (not questie or not questie.db or not questie.db.profile) then return end
  local profile = questie.db.profile;
  profile.trackerEnabled = true;
  profile.alwaysShowTracker = true;
  profile.hideTrackerInCombat = false;
  profile.hideTrackerInInstances = false;
  profile.hideTrackerInPetBattles = false;
  profile.minimizeTrackerInCombat = false;
  profile.minimizeTrackerInInstances = false;
  -- The installer reloads the UI after applying presets. Questie builds its own tracker.
  MayronUI:GetComponent("ForeverQuestieStyle"):SetEnabled(true);
  return 1;
end;
