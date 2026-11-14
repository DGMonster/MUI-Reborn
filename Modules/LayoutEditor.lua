local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db = MayronUI:GetCoreComponents();
local editor = MayronUI:NewComponent("LayoutEditor");
local german = _G.GetLocale() == "deDE";
local host = _G.CreateFrame("Frame", "MUI_LayoutEditor", _G.UIParent);
host:SetAllPoints();
host:SetFrameStrata("DIALOG");
host:Hide();

local handles = {};
local function AddHandle(label, width, height, point, relative, relativePoint, x, y, save)
  local index = host.handleCount + 1;
  host.handleCount = index;
  local handle = handles[index];
  if (not handle) then
    handle = _G.CreateFrame("Button", nil, host);
    handles[index] = handle;
    handle:SetMovable(true);
    handle:SetClampedToScreen(true);
    handle:RegisterForDrag("LeftButton");
    local background = handle:CreateTexture(nil, "BACKGROUND");
    background:SetAllPoints();
    handle.background = background;
    local text = handle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    text:SetPoint("LEFT", 4, 0);
    text:SetPoint("RIGHT", -4, 0);
    text:SetWordWrap(false);
    handle.label = text;
    handle:SetScript("OnDragStart", function(self)
      if (_G.InCombatLockdown()) then return end
      self.dragging = true;
      self:StartMoving();
    end);
    handle:SetScript("OnDragStop", function(self)
      if (not self.dragging) then return end
      self.dragging = nil;
      self:StopMovingOrSizing();
      if (_G.InCombatLockdown()) then return end
      local centerX, centerY = self:GetCenter();
      if (not centerX or not centerY) then return end
      local ui = _G.UIParent;
      if (self.save(centerX - ui:GetLeft(), centerY - ui:GetBottom(), self)) then
        self:ClearAllPoints();
        self:SetPoint("CENTER", self.relativeBar, "CENTER");
      end
    end);
  end

  local r, g, b = tk:GetThemeColor();
  handle.background:SetColorTexture(r * 0.55, g * 0.55, b * 0.55, 0.83);
  handle.label:SetText(label);
  handle.save = save;
  handle.relativeBar = relative;
  handle:SetSize(width, height);
  handle:ClearAllPoints();
  handle:SetPoint(point, relative, relativePoint, x, y);
  handle:Show();
end

local close = _G.CreateFrame("Button", nil, host, "UIPanelButtonTemplate");
close:SetSize(145, 24);
close:SetPoint("TOP", 0, -45);
close:SetText(german and "Layout fertig" or "Finish layout");
close:SetScript("OnClick", function() host:Hide(); end);

host:SetScript("OnHide", function()
  for _, handle in ipairs(handles) do
    if (handle.dragging) then
      handle.dragging = nil;
      handle:StopMovingOrSizing();
    end
    handle:Hide();
    handle:ClearAllPoints();
    handle.save = nil;
  end
end);
host:RegisterEvent("PLAYER_REGEN_DISABLED");
host:SetScript("OnEvent", function() host:Hide(); end);
table.insert(_G.UISpecialFrames, host:GetName());

local function AddBar(label, bar, path, database, refresh, castBar)
  if (not bar or bar.disabled or not bar:GetPoint()) then return end
  AddHandle(label, 150, 20,
    "CENTER", bar, "CENTER", 0, 0, function(x, y)
      if (castBar) then
        local nativeFrame = castBar == "Player" and _G.MUI_NativePlayerFrame
          or (castBar == "Target" and _G.MUI_NativeTargetFrame);
        local portrait = nativeFrame and nativeFrame.castAnchor;
        if (portrait and portrait:IsVisible()) then
          local ui = _G.UIParent;
          local scale = portrait:GetEffectiveScale() / ui:GetEffectiveScale();
          local screenX, screenY = x + ui:GetLeft(), y + ui:GetBottom();
          local left, bottom, width, height = portrait:GetRect();
          if (left and bottom and width and height
              and screenX >= left * scale and screenX <= (left + width) * scale
              and screenY >= bottom * scale and screenY <= (bottom + height) * scale) then
            database:SetPathValue(path..".anchorToSUF", true);
            if (refresh) then refresh(); end
            return true;
          end
        end
        database:SetPathValue(path..".anchorToSUF", false);
      end
      database:SetPathValue(path..".position", { "CENTER", "UIParent", "BOTTOMLEFT", x, y });
      if (refresh) then refresh(); end
    end);
end

function editor.Toggle()
  if (host:IsShown()) then host:Hide(); return end
  if (_G.InCombatLockdown()) then
    tk:Print(german and "Das Layout kann nur außerhalb des Kampfes verschoben werden."
      or "Layout can only be moved out of combat.");
    return;
  end

  host.handleCount = 0;
  if (editor.AddParty) then editor.AddParty(AddHandle); end

  local labels = {
    Player = german and "Spieler-Zauberleiste" or "Player cast bar";
    Target = german and "Ziel-Zauberleiste" or "Target cast bar";
    Focus = german and "Fokus-Zauberleiste" or "Focus cast bar";
    Pet = german and "Begleiter-Zauberleiste" or "Pet cast bar";
    Mirror = german and "Umgebungsleiste" or "Mirror timer";
  };
  for _, name in ipairs({ "Player", "Target", "Focus", "Pet", "Mirror" }) do
    if (db.profile.castBars[name].enabled) then
      local bar, refresh = _G["MUI_"..name.."CastBar"];
      if (name == "Player" and editor.RefreshPlayerCastBar) then
        bar, refresh = _G.PlayerCastingBarFrame, editor.RefreshPlayerCastBar;
      end
      AddBar(labels[name], bar, "profile.castBars."..name, db, refresh, name);
    end
  end

  local timerDB = MayronUI:GetComponent("TimerBarsDatabase");
  if (timerDB.profile.enabled) then
    for _, name in timerDB.profile.fieldNames:Iterate() do
      if (timerDB.profile.fields[name].enabled) then
        local holder = editor.TimerHolders and editor.TimerHolders[name];
        local bar = holder or _G["MUI_"..name.."TimerField"];
        AddBar((german and "Timerleiste: " or "Timer bar: ")..name,
          bar, "profile.fields."..name, timerDB, holder and holder.UpdateLayoutPosition);
      end
    end
  end

  if (host.handleCount > 0) then
    host:Show();
  else
    tk:Print(german and "Keine aktiven Leisten oder Gruppenrahmen zum Verschieben."
      or "No active bars or party frames to move.");
  end
end

function editor.ResetPositions()
  if (_G.InCombatLockdown()) then
    tk:Print(german and "Layoutpositionen können nur außerhalb des Kampfes zurückgesetzt werden."
      or "Layout positions can only be reset out of combat.");
    return;
  end

  local reopen = host:IsShown();
  if (reopen) then host:Hide(); end
  if (editor.ResetPartyPosition) then editor.ResetPartyPosition(); end

  for _, name in ipairs({ "Player", "Target", "Focus", "Pet", "Mirror" }) do
    local path = "profile.castBars."..name;
    local position = db:GetDefault(path..".position") or db:GetDefault("profile.castBars.__templateCastBar.position");
    db:SetPathValue(path..".position", { _G.unpack(position) });
    db:SetPathValue(path..".anchorToSUF", db:GetDefault(path..".anchorToSUF") == true);
  end
  if (editor.RefreshPlayerCastBar) then editor.RefreshPlayerCastBar(); end

  local timerDB = MayronUI:GetComponent("TimerBarsDatabase");
  for _, name in timerDB.profile.fieldNames:Iterate() do
    local position = editor.GetDefaultTimerPosition(name) or timerDB:GetDefault("profile.__templateField.position");
    timerDB:SetPathValue("profile.fields."..name..".position", { _G.unpack(position) });
    local holder = editor.TimerHolders and editor.TimerHolders[name];
    if (holder) then holder.UpdateLayoutPosition(); end
  end

  if (reopen) then editor.Toggle(); end
  tk:Print(german and "Layoutpositionen zurückgesetzt." or "Layout positions reset.");
end

_G.SLASH_MUILAYOUTEDITOR1 = "/muilayout";
_G.SlashCmdList.MUILAYOUTEDITOR = editor.Toggle;