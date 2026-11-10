-- luacheck: ignore self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, em, gui, obj, L = MayronUI:GetCoreComponents(); -- luacheck: ignore

if (tk:IsForever()) then
  local heading, accent, surface, originalAlpha, hookedTracker, hookedQuestie, hookedSidebar;
  local originalX, appliedX, appliedPoint, appliedRelative, appliedRelativePoint, appliedY;
  local refreshQueued, moving;

  local function MoveAwayFromSidebar(tracker, sidebar)
    if (tracker:GetNumPoints() ~= 1) then
      appliedX = nil;
      return;
    end

    local point, relative, relativePoint, x, y = tracker:GetPoint();
    if (not point) then return end
    if (x ~= appliedX or point ~= appliedPoint or relative ~= appliedRelative
        or relativePoint ~= appliedRelativePoint or y ~= appliedY) then
      originalX = x;
    end

    local offset = 0;
    local right = tracker:GetRight();
    local left = sidebar and sidebar:GetLeft();
    if (right and left and sidebar:IsVisible() and sidebar:GetWidth() > 1) then
      local scale = tracker:GetEffectiveScale();
      local originalRight = (right + originalX - x) * scale;
      offset = math.max(0, (originalRight - left * sidebar:GetEffectiveScale()) / scale + 20);
    end

    local nextX = originalX - offset;
    appliedX, appliedPoint, appliedRelative, appliedRelativePoint, appliedY =
      nextX, point, relative, relativePoint, y;
    if (math.abs(nextX - x) > 0.01) then
      moving = true;
      tracker:SetPoint(point, relative, relativePoint, nextX, y);
      moving = false;
    end
  end

  local RefreshForeverTracker;

  local function QueueRefresh()
    if (refreshQueued or moving) then return end
    refreshQueued = true;
    _G.C_Timer.After(0, function()
      refreshQueued = false;
      RefreshForeverTracker();
    end);
  end

  RefreshForeverTracker = function()
    if (_G.InCombatLockdown()) then return end

    local tracker = _G.ObjectiveTrackerFrame;
    local header = tracker and tracker.Header;
    local background = header and header.Background;
    if (not background) then return end

    if (hookedTracker ~= tracker) then
      tracker:HookScript("OnShow", QueueRefresh);
      _G.hooksecurefunc(tracker, "SetPoint", QueueRefresh);
      _G.hooksecurefunc(tracker, "Update", QueueRefresh);
      hookedTracker = tracker;
    end

    local sidebar = _G.MUI_SideBar;
    if (sidebar and hookedSidebar ~= sidebar) then
      sidebar:HookScript("OnSizeChanged", QueueRefresh);
      sidebar:HookScript("OnShow", QueueRefresh);
      sidebar:HookScript("OnHide", QueueRefresh);
      hookedSidebar = sidebar;
    end

    local questie = _G.Questie_BaseFrame;
    if (questie and hookedQuestie ~= questie) then
      questie:HookScript("OnShow", QueueRefresh);
      questie:HookScript("OnHide", QueueRefresh);
      hookedQuestie = questie;
    end

    local useNativeStyle = not (questie and questie:IsVisible());
    local editMode = _G.EditModeManagerFrame;
    if (not (editMode and editMode:IsEditModeActive())) then
      MoveAwayFromSidebar(tracker, useNativeStyle and sidebar or nil);
    end

    if (not useNativeStyle or db.global.foreverWindowStyle ~= true) then
      if (surface) then surface:Hide(); end
      if (heading) then heading:Hide(); accent:Hide(); end
      if (originalAlpha ~= nil) then
        background:SetAlpha(originalAlpha);
        originalAlpha = nil;
      end
      return;
    end

    local contents = tracker.NineSlice;
    if (not surface) then
      surface = gui:CreateWindowSkinSurface(tracker, header, header, -22, 3, 16, -4);
      surface:SetGridAlphaType("Low");
      heading = header:CreateTexture(nil, "BACKGROUND", nil, 1);
      heading:SetPoint("TOPLEFT", surface.c, "TOPLEFT");
      heading:SetPoint("TOPRIGHT", surface.c, "TOPRIGHT");
      heading:SetPoint("BOTTOM", header, "BOTTOM");
      heading:SetTexture(tk:GetAssetFilePath("Textures\\Widgets\\Button"));
      accent = header:CreateTexture(nil, "BORDER");
      accent:SetPoint("TOPLEFT", surface.c, "TOPLEFT");
      accent:SetPoint("TOPRIGHT", surface.c, "TOPRIGHT");
      accent:SetHeight(2);
    end

    surface:ClearAllPoints();
    surface:SetPoint("TOPLEFT", header, "TOPLEFT", -22, 3);
    surface:SetPoint("TOPRIGHT", header, "TOPRIGHT", 16, 3);
    surface:SetPoint("BOTTOM", contents and contents:IsShown() and contents or header, "BOTTOM", 0, -4);

    local fr, fg, fb = gui:GetMuiFrameColor();
    surface:SetGridColor(fr, fg, fb);
    local red, green, blue = tk:GetThemeColor();
    heading:SetVertexColor(red * 0.4, green * 0.4, blue * 0.4, 0.65);
    accent:SetColorTexture(red, green, blue, 0.85);
    originalAlpha = originalAlpha or background:GetAlpha();
    background:SetAlpha(0);
    surface:Show();
    heading:Show();
    accent:Show();
  end;

  MayronUI:Hook("CoreModule", "OnInitialized", function()
    local watcher = _G.CreateFrame("Frame");
    watcher:RegisterEvent("ADDON_LOADED");
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
    watcher:SetScript("OnEvent", QueueRefresh);
    QueueRefresh();
  end);
  return;
end


if (not tk:IsRetail()) then
  return
end

---@class ObjectiveTrackerModule : BaseModule
local C_ObjectiveTracker = MayronUI:RegisterModule(
  "ObjectiveTrackerModule", L["Objective Tracker"], true);

local _, _, _, interfaceVersion = _G.GetBuildInfo();
local objectiveTrackerSupported = (tonumber(interfaceVersion) or 0) < 120100;

MayronUI:Hook("SideActionBars", "OnEnable", function(sideActionBars)
  if (not objectiveTrackerSupported) then
    return
  end

  MayronUI:ImportModule("ObjectiveTrackerModule"):Initialize(sideActionBars);
end);

local ObjectiveTrackerFrame, IsInInstance, hooksecurefunc, ipairs,
      C_PlayerInfo, C_QuestLog, GetInstanceInfo,
      RegisterStateDriver, UnregisterStateDriver, GetDifficultyColor, string,
      tinsert, unpack = _G.ObjectiveTrackerFrame, _G.IsInInstance,
  _G.hooksecurefunc, _G.ipairs, _G.C_PlayerInfo, _G.C_QuestLog,
  _G.GetInstanceInfo, _G.RegisterStateDriver, _G.UnregisterStateDriver,
  _G.GetDifficultyColor, _G.string, _G.table.insert, _G.unpack;

local function SetHeaderColor(headerText, difficultyColor, highlight)
  local r, g, b = difficultyColor.r, difficultyColor.g, difficultyColor.b;

  if (highlight) then
    r = r * 1.2;
    g = g * 1.2;
    b = b * 1.2;
  end

  headerText:SetTextColor(r, g, b);
end

local function UpdateQuestDifficultyColors(block, highlight)
  if (C_QuestLog and C_QuestLog.GetNumQuestLogEntries) then
    for questLogIndex = 1, C_QuestLog:GetNumQuestLogEntries() do
      local questInfo = C_QuestLog.GetInfo(questLogIndex);

      if (questInfo and questInfo.questID == block.id) then
        -- bonus quests do not have HeaderText
        if (block.HeaderText) then
          local difficulty = C_PlayerInfo.GetContentDifficultyQuestForPlayer(questInfo.questID);
          local difficultyColor = GetDifficultyColor(difficulty);

          SetHeaderColor(block.HeaderText, difficultyColor, highlight);
          local headerText = string.format("[%d] %s", questInfo.level, questInfo.title);
          block.HeaderText:SetText(headerText);
          block.HeaderText:SetHeight(block.HeaderText:GetStringHeight())
        end

        break
      end
    end
  end
end

db:AddToDefaults("profile.objectiveTracker", {
  enabled = true;
  hideInInstance = false;
  anchoredToSideBars = true;
  width = 250;
  height = 600;
  yOffset = 0;
  xOffset = -30;
});

function C_ObjectiveTracker:OnInitialize(data, sideActionBars)
  data.panel = sideActionBars:GetPanel();
  data.minButtons = obj:PopTable();

  local function SetUpAnchor()
    data.objectiveContainer:ClearAllPoints();

    if (data.settings.anchoredToSideBars) then
      data.objectiveContainer:SetPoint("TOPRIGHT", data.panel, "TOPLEFT",
        data.settings.xOffset, data.settings.yOffset);
    else
      data.objectiveContainer:SetPoint("CENTER", data.settings.xOffset,
        data.settings.yOffset);
    end
  end

  self:RegisterUpdateFunctions(db.profile.objectiveTracker, {
    hideInInstance = function(value)
      if (not value) then
        UnregisterStateDriver(data.autoHideHandler, "autoHideHandler");
        em:DestroyEventListeners("ObjectiveTracker_InInstance");
        return;
      end

      RegisterStateDriver(data.autoHideHandler, "autoHideHandler",
        "[@boss1,exists][@boss2,exists][@boss3,exists][@boss4,exists] 1;0");

      local listener = em:GetEventListenerByID("ObjectiveTracker_InInstance") or
        -- create one:
        em:CreateEventListenerWithID("ObjectiveTracker_InInstance", function()
          local inInstance = IsInInstance();

          if (inInstance) then
            if (not ObjectiveTrackerFrame.collapsed) then
              local _, _, difficultyID = GetInstanceInfo();

              -- ignore keystone dungeons
              if (difficultyID and difficultyID ~= 8) then
                _G.ObjectiveTracker_Collapse();
                data.previouslyCollapsed = true;
              end
            end
          else
            if (ObjectiveTrackerFrame.collapsed and data.previouslyCollapsed) then
              _G.ObjectiveTracker_Expand();
              data:Call("HandleObjectiveTracker_Update");
            end

            data.previouslyCollapsed = nil;
          end
        end);

      listener:RegisterEvent("PLAYER_ENTERING_WORLD");

      if (IsInInstance()) then
        em:TriggerEventListenerByID("ObjectiveTracker_InInstance");
      end
    end;

    width = function(value)
      data.objectiveContainer:SetSize(value, data.settings.height);
    end;

    height = function(value)
      data.objectiveContainer:SetSize(data.settings.width, value);
      local updater = _G.ObjectiveTracker_Update;

      if (obj:IsFunction(updater)) then
       updater(); -- this updates the total quests that can fit into the new visible area
      end
    end;

    anchoredToSideBars = SetUpAnchor;
    yOffset = SetUpAnchor;
    xOffset = SetUpAnchor;
  });

  if (data.settings.enabled) then
    if (not data.objectiveContainer) then
      local success, isMovable = pcall(function()
        ObjectiveTrackerFrame:SetMovable(true); -- required to make user placed

        if (not ObjectiveTrackerFrame:IsMovable()) then
          return false; -- an addon may have tampered with it
        end

        ObjectiveTrackerFrame:SetUserPlaced(true);
        ObjectiveTrackerFrame:SetClampedToScreen(false);
        return true;
      end);

      if (not (success and isMovable)) then
        return
      end
    end

    self:SetEnabled(true);
  end
end

local upButtonTexture = tk:GetAssetFilePath("Icons\\up");
local downButtonTexture = tk:GetAssetFilePath("Icons\\down");

function C_ObjectiveTracker.Private:HandleObjectiveTracker_Update(data)
  for _, pair in ipairs(data.minButtons) do
    local btn, module = unpack(pair);

    if (module.collapsed) then
      btn:SetNormalTexture(downButtonTexture, "BLEND");
      btn:SetPushedTexture(downButtonTexture, "BLEND");
      btn:SetHighlightTexture(downButtonTexture, "ADD");
    else
      btn:SetNormalTexture(upButtonTexture, "BLEND");
      btn:SetPushedTexture(upButtonTexture, "BLEND");
      btn:SetHighlightTexture(upButtonTexture, "ADD");
    end
  end
end

obj:DefineParams("Button", "table")
function C_ObjectiveTracker:ReskinMinifyButton(data, btn, module)
  -- TODO: This is broken
  -- tk:ApplyThemeColor(btn);
  -- btn:SetSize(20, 20);
  -- btn:GetNormalTexture():SetTexCoord(0, 1, 0, 1);
  -- btn:GetPushedTexture():SetTexCoord(0, 1, 0, 1);
  -- btn:GetHighlightTexture():SetTexCoord(0, 1, 0, 1);

  -- btn:GetNormalTexture().SetTexCoord = tk.Constants.DUMMY_FUNC;
  -- btn:GetPushedTexture().SetTexCoord = tk.Constants.DUMMY_FUNC;
  -- btn:GetHighlightTexture().SetTexCoord = tk.Constants.DUMMY_FUNC;

  -- btn:GetNormalTexture().SetRotation = tk.Constants.DUMMY_FUNC;
  -- btn:GetPushedTexture().SetRotation = tk.Constants.DUMMY_FUNC;
  -- btn:GetHighlightTexture().SetRotation = tk.Constants.DUMMY_FUNC;

  local tbl = obj:PopTable(btn, module);
  tinsert(data.minButtons, tbl);
end

function C_ObjectiveTracker:OnObjectiveTrackerInitialized()
  for _, module in ipairs(ObjectiveTrackerFrame.MODULES_UI_ORDER) do
    tk:KillElement(module.Header.Background);
    tk:ApplyThemeColor(module.Header.Text);
    module.Header.Text:SetPoint("LEFT", 0, 0);

    if (module.Header.MinimizeButton) then
      self:ReskinMinifyButton(module.Header.MinimizeButton, module);
    end
  end
end

function C_ObjectiveTracker:OnEnable(data)
  if (not objectiveTrackerSupported) then
    return
  end

  if (data.objectiveContainer) then
    return
  end

  -- holds and controls blizzard objectives tracker frame
  data.objectiveContainer = tk:CreateFrame("Frame", nil, "MUI_ObjectiveContainer");

  -- blizzard objective tracker frame global variable
  local isReanchoring = false;
  local reanchorPending = false;

  local function ReanchorObjectiveTracker()
    reanchorPending = false;

    if (isReanchoring or not data.objectiveContainer) then
      return
    end

    isReanchoring = true;
    ObjectiveTrackerFrame:SetParent(data.objectiveContainer);
    ObjectiveTrackerFrame:ClearAllPoints();
    ObjectiveTrackerFrame:SetAllPoints(data.objectiveContainer);
    isReanchoring = false;
  end

  local function QueueObjectiveTrackerReanchor()
    if (isReanchoring or reanchorPending) then
      return
    end

    reanchorPending = true;
    _G.C_Timer.After(0, ReanchorObjectiveTracker);
  end

  ReanchorObjectiveTracker();
  hooksecurefunc(ObjectiveTrackerFrame, "SetPoint", QueueObjectiveTrackerReanchor);
  hooksecurefunc(ObjectiveTrackerFrame, "SetParent", QueueObjectiveTrackerReanchor);


  data.autoHideHandler = tk:CreateFrame("Frame", data.objectiveContainer, nil, "SecureHandlerStateTemplate");

  data.autoHideHandler:SetAttribute("_onstate-autoHideHandler",
    "if (newstate == 1) then self:Hide() else self:Show() end");

  local triggerInInstanceHandler = function()
    em:TriggerEventListenerByID("ObjectiveTracker_InInstance");
  end
  data.autoHideHandler:SetScript("OnShow", triggerInInstanceHandler);
  data.autoHideHandler:SetScript("OnHide", triggerInInstanceHandler);

  -- Reskinning (kept very minimal):
  local headerMenu = ObjectiveTrackerFrame and ObjectiveTrackerFrame.HeaderMenu

  -- Retail fallback attempts (Blizzard moved these around over time)
  if not headerMenu and ObjectiveTrackerFrame and ObjectiveTrackerFrame.Header then
    headerMenu = ObjectiveTrackerFrame.Header.Menu
      or ObjectiveTrackerFrame.Header.Dropdown
      or ObjectiveTrackerFrame.Header
  end

  if headerMenu and headerMenu.Title then
    tk:ApplyThemeColor(headerMenu.Title)
  end

  local block = _G.ScenarioStageBlock
  if block and block.NormalBG then
    block.NormalBG:Hide()
  end
  if block then
    block:SetHeight(70)

    local box = gui:AddDialogTexture(tk:CreateFrame("Frame", block))
    box:SetPoint("TOPLEFT", 5, -5)
    box:SetPoint("BOTTOMRIGHT", -5, 5)
    box:SetFrameStrata("BACKGROUND")
  end

  -- reskin the "main" minimize button (not per module):
  if headerMenu and headerMenu.MinimizeButton then
    local minButton = headerMenu.MinimizeButton
    self:ReskinMinifyButton(minButton, ObjectiveTrackerFrame)
  end

-- Trigger updates via events (Retail-safe)
local listener = em:GetEventListenerByID("MUI_ObjectiveTracker_Update")
  or em:CreateEventListenerWithID("MUI_ObjectiveTracker_Update", function()
    data:Call("HandleObjectiveTracker_Update")
  end)

listener:RegisterEvent("QUEST_LOG_UPDATE")
listener:RegisterEvent("QUEST_WATCH_LIST_CHANGED")
listener:RegisterEvent("SUPER_TRACKING_CHANGED")
listener:RegisterEvent("ZONE_CHANGED_NEW_AREA")
listener:RegisterEvent("PLAYER_ENTERING_WORLD")

  -- Update difficulty colors (guarded for Retail changes):
  local qtm = _G.QUEST_TRACKER_MODULE
  if qtm and type(qtm) == "table" then
    hooksecurefunc(qtm, "Update", function()
      local blocksFrame = _G.ObjectiveTrackerBlocksFrame
      local firstBlock = blocksFrame and blocksFrame.QuestHeader
        and blocksFrame.QuestHeader.module and blocksFrame.QuestHeader.module.firstBlock

      local block = firstBlock
      while block do
        UpdateQuestDifficultyColors(block)
        block = block.nextBlock
      end
    end)

    hooksecurefunc(qtm, "OnBlockHeaderEnter", function(_, block)
      UpdateQuestDifficultyColors(block, true)
    end)

    hooksecurefunc(qtm, "OnBlockHeaderLeave", function(_, block)
      UpdateQuestDifficultyColors(block)
    end)
  end
end
