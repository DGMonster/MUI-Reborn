-- Movable Forever windows keep Blizzard's panel and drag handlers.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, _, _, L = MayronUI:GetCoreComponents();
if (not tk:IsRetail()) then return end

db:AddToDefaults("global.foreverMovable", { enabled = true; clampToScreen = true; positions = {} });
local enabled, ready = false, false;
local entries = {};
local names = { "CharacterFrame", "SpellBookFrame", "PlayerSpellsFrame", "CommunitiesFrame" };
local active;
local elapsedTotal = 0;
local white = "Interface\\Buttons\\WHITE8X8";
local preview = _G.CreateFrame("Frame", nil, _G.UIParent, "BackdropTemplate");
preview:SetFrameStrata("DIALOG");
preview:SetMovable(true);
preview:EnableMouse(false);
preview:SetBackdrop({ bgFile = white; edgeFile = white; edgeSize = 2 });
preview:SetBackdropColor(0, 0, 0, 0.3);
preview:Hide();

local function SafeRect(frame)
  local x, y, w, h = frame:GetRect();
  if (_G.issecretvalue and (_G.issecretvalue(x) or _G.issecretvalue(y) or
      _G.issecretvalue(w) or _G.issecretvalue(h))) then return end
  if (not x or not y or not w or not h) then return end
  local scale = frame:GetEffectiveScale() / _G.UIParent:GetEffectiveScale();
  return x * scale, y * scale, w * scale, h * scale;
end

local function Capture(entry)
  if (entry.original) then return end
  entry.original = {};
  for i = 1, entry.frame:GetNumPoints() do
    entry.original[i] = { entry.frame:GetPoint(i) };
  end
end

local function Finish(commit)
  if (not active) then return end
  local entry = active;
  active = nil;
  preview:StopMovingOrSizing();
  if (commit and enabled and not _G.InCombatLockdown() and entry.frame:IsShown()) then
    local x, y = SafeRect(preview);
    if (x and y) then
      Capture(entry);
      entry.frame:ClearAllPoints();
      entry.frame:SetPoint("BOTTOMLEFT", _G.UIParent, "BOTTOMLEFT", x, y);
      db.global.foreverMovable.positions[entry.name] = { x = x; y = y };
    end
  end
  preview:Hide();
end

local function CreateHandle(name, frame)
  local entry = { name = name; frame = frame };
  local handle = _G.CreateFrame("Button", nil, _G.UIParent);
  entry.handle = handle;
  handle:SetFrameStrata("DIALOG");
  handle:SetHeight(20);
  handle:RegisterForDrag("LeftButton");
  handle:SetHighlightTexture(white);
  handle:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.12);
  entry.dots = {};
  for row = 0, 2 do
    for column = 0, 1 do
      local dot = handle:CreateTexture(nil, "OVERLAY");
      dot:SetSize(2, 2);
      dot:SetPoint("TOPRIGHT", -8 - column * 4, -5 - row * 4);
      dot:SetTexture(white);
      entry.dots[#entry.dots + 1] = dot;
    end
  end
  tk:SetBasicTooltip(handle, L["Hold the left mouse button to move this window. Only available outside combat."], "ANCHOR_CURSOR_RIGHT", 16, 8);
  handle:SetScript("OnDragStart", function()
    if (not enabled or _G.InCombatLockdown() or not frame:IsShown()) then return end
    local x, y, w, h = SafeRect(frame);
    if (not x) then return end
    Finish(false);
    active = entry;
    preview:ClearAllPoints();
    preview:SetPoint("BOTTOMLEFT", _G.UIParent, "BOTTOMLEFT", x, y);
    preview:SetSize(w, h);
    preview:SetClampedToScreen(db.global.foreverMovable.clampToScreen);
    local r, g, b = tk:GetThemeColor();
    preview:SetBackdropBorderColor(r, g, b, 0.9);
    preview:Show();
    preview:StartMoving();
  end);
  handle:SetScript("OnDragStop", function() Finish(true); end);
  handle:Hide();
  return entry;
end

local function HasSavedAnchor(frame, saved)
  if (frame:GetNumPoints() ~= 1) then return false end
  local point, relative, relativePoint, x, y = frame:GetPoint(1);
  if (_G.issecretvalue and (_G.issecretvalue(point) or _G.issecretvalue(relative) or
      _G.issecretvalue(relativePoint) or _G.issecretvalue(x) or _G.issecretvalue(y))) then return true end
  return point == "BOTTOMLEFT" and relative == _G.UIParent and relativePoint == "BOTTOMLEFT" and
    x == saved.x and y == saved.y;
end

local function RestoreSavedPosition(entry)
  -- Blizzard lays out the guild window and its management panel together.
  if (entry.name == "CommunitiesFrame" and tk:IsForever() and
      _G.GuildControlUI and _G.GuildControlUI:IsShown()) then return end
  local saved = db.global.foreverMovable.positions[entry.name];
  if (not saved or _G.type(saved.x) ~= "number" or _G.type(saved.y) ~= "number") then return end
  if (HasSavedAnchor(entry.frame, saved)) then return end

  Capture(entry);
  entry.frame:ClearAllPoints();
  entry.frame:SetPoint("BOTTOMLEFT", _G.UIParent, "BOTTOMLEFT", saved.x, saved.y);
end

local function Refresh()
  if (not enabled or not ready or _G.InCombatLockdown()) then return end
  for _, name in _G.ipairs(names) do
    local frame = _G[name];
    local entry = entries[name];
    if (frame and not entry and (tk:IsForever() or not frame:IsProtected())) then
      entry = CreateHandle(name, frame);
      entries[name] = entry;
      if (name == "CommunitiesFrame" and tk:IsForever()) then
        local function RestoreAfterLayout()
          if (enabled and ready and not _G.InCombatLockdown() and active ~= entry and frame:IsVisible()) then
            RestoreSavedPosition(entry);
          end
        end
        for _, method in _G.ipairs({ "UpdateCommunitiesTabs", "ToggleSubPanel" }) do
          if (type(frame[method]) == "function") then
            _G.hooksecurefunc(frame, method, RestoreAfterLayout);
          end
        end
      end
    end
    if (entry) then
      if (frame:IsVisible()) then
        if (not entry.wasVisible or (name == "CommunitiesFrame" and tk:IsForever() and active ~= entry)) then
          RestoreSavedPosition(entry);
        end
        entry.wasVisible = true;
        local x, y, w, h = SafeRect(frame);
        if (x) then
          entry.handle:ClearAllPoints();
          entry.handle:SetPoint("TOPLEFT", _G.UIParent, "BOTTOMLEFT", x + 65, y + h - 4);
          entry.handle:SetWidth(_G.math.max(40, w - 120));
          local r, g, b = tk:GetThemeColor();
          for _, dot in _G.ipairs(entry.dots) do dot:SetVertexColor(r, g, b, 0.85); end
          entry.handle:Show();
        else
          entry.handle:Hide();
        end
      else
        entry.wasVisible = false;
        entry.handle:Hide();
        if (active == entry) then Finish(false); end
      end
    end
  end
end

local function RestoreAnchors()
  for _, entry in _G.pairs(entries) do
    entry.handle:Hide();
    if (entry.original) then
      entry.frame:ClearAllPoints();
      for _, point in _G.ipairs(entry.original) do entry.frame:SetPoint(_G.unpack(point)); end
      entry.original = nil;
    end
    entry.wasVisible = false;
  end
end

local controller = {};
function controller:SetEnabled(value)
  if (_G.InCombatLockdown() or not ready) then
    tk:Print(L["Window movement can only be changed outside combat after login."]);
    return false;
  end
  Finish(false);
  enabled = value == true;
  db.global.foreverMovable.enabled = enabled;
  if (enabled) then Refresh(); else RestoreAnchors(); end
  return true;
end
function controller:ResetPositions()
  if (_G.InCombatLockdown() or not ready) then
    tk:Print(L["Window movement can only be changed outside combat after login."]);
    return false;
  end
  Finish(false);
  RestoreAnchors();
  db.global.foreverMovable.positions = {};
  Refresh();
  return true;
end
MayronUI:AddComponent("ForeverMovableFrames", controller);

local events = _G.CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:RegisterEvent("PLAYER_REGEN_DISABLED");
events:RegisterEvent("PLAYER_REGEN_ENABLED");
events:SetScript("OnEvent", function(_, event)
  if (event == "PLAYER_REGEN_DISABLED") then
    Finish(false);
    for _, entry in _G.pairs(entries) do entry.handle:Hide(); end
  else
    Refresh();
  end
end);
events:SetScript("OnUpdate", function(_, elapsed)
  if (not enabled or not ready or _G.InCombatLockdown()) then return end
  elapsedTotal = elapsedTotal + elapsed;
  if (elapsedTotal >= 0.15) then elapsedTotal = 0; Refresh(); end
end);
MayronUI:Hook("CoreModule", "OnInitialized", function()
  ready = true;
  enabled = db.global.foreverMovable.enabled == true;
  Refresh();
end);

_G.SLASH_MUIFOREVERMOVE1 = "/muimove";
_G.SlashCmdList.MUIFOREVERMOVE = function(message)
  local option = _G.strtrim(message or ""):lower();
  if (option ~= "on" and option ~= "off") then
    tk:Print(L["Window movement test: /muimove on or /muimove off."]);
    return;
  end
  if (_G.InCombatLockdown() or not ready) then
    tk:Print(L["Window movement can only be changed outside combat after login."]);
    return;
  end
  if (not controller:SetEnabled(option == "on")) then return end
  if (enabled) then
    tk:Print(L["Window movement enabled: drag the dotted title-bar grip on supported windows."]);
  else
    tk:Print(L["Window movement disabled; session anchors restored."]);
  end
end;
