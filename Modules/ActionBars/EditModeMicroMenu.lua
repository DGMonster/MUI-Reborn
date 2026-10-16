-- Keeps Bartender4's MUI micro menu in sync with Blizzard Edit Mode.
-- Bartender4 owns the real micro buttons while it is enabled, whereas the
-- Blizzard settings dialog still edits the hidden Blizzard system frame.

local _G = _G;
local Enum = _G.Enum;
local C_Timer = _G.C_Timer;
local EventRegistry = _G.EventRegistry;
local EditModeManagerFrame = _G.EditModeManagerFrame;
local InCombatLockdown = _G.InCombatLockdown;

if (not Enum or not Enum.EditModeSystem or not Enum.EditModeSystem.MicroMenu) then
  return;
end

local function GetSettingValue(systemInfo, setting)
  if (not systemInfo or not systemInfo.settings) then
    return nil;
  end

  for _, settingInfo in pairs(systemInfo.settings) do
    if (settingInfo.setting == setting) then
      return settingInfo.value;
    end
  end
end

local function GetMicroMenuSystemInfo()
  if (not EditModeManagerFrame or not EditModeManagerFrame.GetActiveLayoutInfo) then
    return nil;
  end

  local layoutInfo = EditModeManagerFrame:GetActiveLayoutInfo();
  if (not layoutInfo or not layoutInfo.systems) then
    return nil;
  end

  for _, systemInfo in pairs(layoutInfo.systems) do
    if (systemInfo.system == Enum.EditModeSystem.MicroMenu) then
      return systemInfo;
    end
  end
end

local function DecodeSliderValue(rawValue, minimum, step, maximumIndex)
  if (type(rawValue) ~= "number") then
    return nil;
  end

  -- Edit Mode stores sliders as a zero-based step index. Accept a percentage
  -- as well in case Blizzard changes the storage format in a later build.
  if (rawValue >= 0 and rawValue <= maximumIndex) then
    return minimum + (rawValue * step);
  end

  return rawValue;
end

local function ApplyMicroMenuSettings()
  if (InCombatLockdown and InCombatLockdown()) then
    return;
  end

  local Bartender4 = _G.Bartender4;
  if (not Bartender4 or not Bartender4.GetModule) then
    return;
  end

  local systemInfo = GetMicroMenuSystemInfo();
  if (not systemInfo) then
    return;
  end

  local microMenuModule = Bartender4:GetModule("MicroMenu", true);
  if (not microMenuModule or not microMenuModule.bar or not microMenuModule.db) then
    return;
  end

  local settingEnum = Enum.EditModeMicroMenuSetting;
  if (not settingEnum) then
    return;
  end

  local orientation = GetSettingValue(systemInfo, settingEnum.Orientation);
  local order = GetSettingValue(systemInfo, settingEnum.Order);
  local sizeValue = GetSettingValue(systemInfo, settingEnum.Size);
  local eyeSizeValue = GetSettingValue(systemInfo, settingEnum.EyeSize);

  local orientationEnum = Enum.MicroMenuOrientation;
  local orderEnum = Enum.MicroMenuOrder;
  local isVertical = orientationEnum and orientation == orientationEnum.Vertical;
  local isReverse = orderEnum and order == orderEnum.Reverse;
  local microMenuBar = microMenuModule.bar;
  local buttonCount = microMenuModule.button_count or
    (microMenuBar.buttons and #microMenuBar.buttons) or 1;

  microMenuModule.db.profile.rows = isVertical and buttonCount or 1;
  microMenuModule.db.profile.position.growHorizontal = isReverse and "LEFT" or "RIGHT";
  microMenuModule.db.profile.position.growVertical = isReverse and "UP" or "DOWN";

  local menuSize = DecodeSliderValue(sizeValue, 70, 5, 26);
  if (menuSize) then
    microMenuBar:SetConfigScale(menuSize / 100);
  end

  microMenuModule:ApplyConfig();

  local queueStatusModule = Bartender4:GetModule("QueueStatusButtonBar", true);
  local eyeSize = DecodeSliderValue(eyeSizeValue, 50, 5, 20);

  if (queueStatusModule and queueStatusModule.bar and eyeSize) then
    queueStatusModule.bar:SetConfigScale(eyeSize / 100);
  end
end

local updateQueued = false;
local function QueueUpdate()
  if (updateQueued or not C_Timer or not C_Timer.After) then
    return;
  end

  updateQueued = true;
  C_Timer.After(0, function()
    updateQueued = false;
    ApplyMicroMenuSettings();
  end);
end

if (EditModeManagerFrame and EditModeManagerFrame.OnSystemSettingChange and _G.hooksecurefunc) then
  _G.hooksecurefunc(EditModeManagerFrame, "OnSystemSettingChange", QueueUpdate);
end

if (EventRegistry and EventRegistry.RegisterCallback) then
  EventRegistry:RegisterCallback("EditMode.Exit", QueueUpdate);
  EventRegistry:RegisterCallback("EditMode.SavedLayouts", QueueUpdate);
end

local eventFrame = _G.CreateFrame("Frame");
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
eventFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED");
eventFrame:SetScript("OnEvent", QueueUpdate);
