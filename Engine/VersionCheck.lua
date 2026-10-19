-- MUI Reborn peer-to-peer version check.
-- WoW addons cannot contact CurseForge or GitHub directly, so clients share
-- their installed version through Blizzard's hidden addon-message channel.

local addonName = ...;
local PREFIX = "MUIRebornVer";

local GetAddOnMetadata = _G.GetAddOnMetadata;
local currentVersion = GetAddOnMetadata and GetAddOnMetadata(addonName, "Version") or "0.0.0";
local L = _G.LibStub("AceLocale-3.0"):GetLocale("MayronUI");
local chatInfo = _G.C_ChatInfo;
local registerPrefix = chatInfo and chatInfo.RegisterAddonMessagePrefix or _G.RegisterAddonMessagePrefix;
local sendAddonMessage = chatInfo and chatInfo.SendAddonMessage or _G.SendAddonMessage;

if (not registerPrefix or not sendAddonMessage) then
  return;
end

local function ParseVersion(version)
  if (type(version) ~= "string") then
    return;
  end

  local major, minor, patch, suffix = version:match("^v?(%d+)%.(%d+)%.(%d+)(.*)$");
  if (not major) then
    return;
  end

  local rank, build = 4, 0; -- A release is newer than every prerelease.
  if (suffix and suffix ~= "") then
    local stage, number = suffix:lower():match("^[-%.]?(%a+)[-%.]?(%d*)$");
    local ranks = { alpha = 1; beta = 2; rc = 3; };
    rank = ranks[stage] or 0;
    build = tonumber(number) or 0;
  end

  return tonumber(major), tonumber(minor), tonumber(patch), rank, build;
end

local function IsNewerVersion(candidate, installed)
  local candidateParts = { ParseVersion(candidate) };
  local installedParts = { ParseVersion(installed) };

  if (#candidateParts == 0 or #installedParts == 0) then
    return false;
  end

  for index = 1, 5 do
    if (candidateParts[index] ~= installedParts[index]) then
      return candidateParts[index] > installedParts[index];
    end
  end

  return false;
end

local function SendVersion(channel)
  pcall(sendAddonMessage, PREFIX, currentVersion, channel);
end

local function BroadcastVersion()
  if (_G.IsInGuild and _G.IsInGuild()) then
    SendVersion("GUILD");
  end

  local instanceCategory = _G.LE_PARTY_CATEGORY_INSTANCE;
  if (_G.IsInGroup and instanceCategory and _G.IsInGroup(instanceCategory)) then
    SendVersion("INSTANCE_CHAT");
  elseif (_G.IsInRaid and _G.IsInRaid()) then
    SendVersion("RAID");
  elseif (_G.IsInGroup and _G.IsInGroup()) then
    SendVersion("PARTY");
  end
end

local newestReportedVersion;
local broadcastQueued;
local lastBroadcast = -10;
local lastReply = -10;

local function QueueBroadcast(delay)
  if (broadcastQueued) then
    return;
  end

  broadcastQueued = true;
  local function Run()
    broadcastQueued = false;

    local now = _G.GetTime and _G.GetTime() or 0;
    if (now - lastBroadcast < 10) then
      return;
    end

    lastBroadcast = now;
    BroadcastVersion();
  end

  if (_G.C_Timer and _G.C_Timer.After) then
    _G.C_Timer.After(delay or 0, Run);
  else
    Run();
  end
end

local function ShowUpdateMessage(version)
  if (newestReportedVersion and not IsNewerVersion(version, newestReportedVersion)) then
    return;
  end

  newestReportedVersion = version;
  local message = L["MUI_REBORN_NEW_VERSION_AVAILABLE"]:format(currentVersion, version);

  if (_G.MayronUI and _G.MayronUI.GetCoreComponents) then
    local tk = _G.MayronUI:GetCoreComponents();
    if (tk and tk.Print) then
      tk:Print(message);
      return;
    end
  end

  if (_G.DEFAULT_CHAT_FRAME) then
    _G.DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffMUI Reborn:|r " .. message);
  end
end

pcall(registerPrefix, PREFIX);

local eventFrame = _G.CreateFrame("Frame");
eventFrame:RegisterEvent("CHAT_MSG_ADDON");
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE");
eventFrame:SetScript("OnEvent", function(_, event, prefix, message, channel)
  if (event == "CHAT_MSG_ADDON") then
    if (prefix == PREFIX and IsNewerVersion(message, currentVersion)) then
      ShowUpdateMessage(message);
    elseif (prefix == PREFIX and IsNewerVersion(currentVersion, message)) then
      -- Answer older clients so they can discover a newer version even when
      -- this client was already online before they joined the guild or group.
      local now = _G.GetTime and _G.GetTime() or 0;
      if (now - lastReply >= 10 and channel) then
        lastReply = now;
        SendVersion(channel);
      end
    end
    return;
  end

  QueueBroadcast(event == "PLAYER_ENTERING_WORLD" and 5 or 2);
end);

