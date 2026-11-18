-- Optional Forever skin for Blizzard's guild and communities window.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, gui = MayronUI:GetCoreComponents();
if (not tk:IsForever()) then return end

local setShown, hookedFrame;
local setSettingsShown, hookedSettings;
local originals, decorations = {}, {};
local buttonTexture = tk:GetAssetFilePath("Textures\\Widgets\\Button");

local function HideArt(region)
  if (not region) then return end
  if (originals[region] == nil) then originals[region] = region:GetAlpha(); end
  region:SetAlpha(0);
end

local function StyleInfoPane(pane)
  if (not pane) then return end
  local visual = decorations[pane];
  for _, region in _G.ipairs({ pane:GetRegions() }) do
    if ((not visual or region ~= visual.background) and region:IsObjectType("Texture")) then
      HideArt(region);
    end
  end
  if (not visual) then
    local background = pane:CreateTexture(nil, "BACKGROUND", nil, -1);
    background:SetPoint("TOPLEFT", 4, -3);
    background:SetPoint("BOTTOMRIGHT", -4, 3);
    background:SetColorTexture(0.045, 0.045, 0.058, 0.94);
    visual = { background = background };
    decorations[pane] = visual;
  end
  visual.background:Show();
end

local function StyleButton(button, rotation)
  if (not button) then return end
  local visual = decorations[button];
  if (not visual) then
    local overlay = _G.CreateFrame("Frame", nil, button);
    overlay:EnableMouse(false);
    overlay:SetAllPoints(button);
    local background = (rotation and overlay or button):CreateTexture(nil, "BACKGROUND", nil, 3);
    background:SetTexture(buttonTexture);
    background:SetAllPoints();
    if (rotation) then gui:CreateIconTexture("arrow", overlay, false, rotation); end
    visual = { overlay = overlay; background = background };
    decorations[button] = visual;
  end
  HideArt(button:GetNormalTexture());
  HideArt(button:GetPushedTexture());
  local red, green, blue = tk:GetClassColor();
  visual.background:SetVertexColor(red * 0.85, green * 0.85, blue * 0.85);
  visual.background:Show();
  visual.overlay:Show();
end

local function StyleList(list)
  if (not list) then return end
  HideArt(list.TopFiligree);
  HideArt(list.BottomFiligree);
  HideArt(list.Bg);
  HideArt(list.FilligreeOverlay);
  if (list.InsetFrame) then
    HideArt(list.InsetFrame.Bg);
    HideArt(list.InsetFrame.NineSlice);
  end
  local scroll = list.ScrollBox;
  if (not scroll or not scroll:GetView()) then return end
  local red, green, blue = tk:GetClassColor();
  for _, entry in scroll:EnumerateFrames() do
    if (entry.Background) then
      HideArt(entry.Background);
      local visual = decorations[entry];
      if (not visual) then
        local background = entry:CreateTexture(nil, "BACKGROUND", nil, 2);
        background:SetPoint("TOPLEFT", 6, -2);
        background:SetPoint("BOTTOMRIGHT", -6, 2);
        visual = { background = background };
        decorations[entry] = visual;
      end
      local selected = entry.Selection and entry.Selection:IsShown();
      HideArt(entry.Selection);
      local strength = selected and 0.46 or 0.18;
      visual.background:SetColorTexture(0.035 + red * strength, 0.035 + green * strength,
        0.045 + blue * strength, 0.96);
      visual.background:Show();
    end
  end
end

local function StyleSettings(frame)
  setSettingsShown = setSettingsShown or gui:CreateWindowSkinChrome(frame);
  setSettingsShown(true);

  local top = _G.GuildControlUITopBg;
  if (top) then
    HideArt(top);
    HideArt(_G.GuildControlUIHbar);
    local visual = decorations[frame];
    if (not visual) then
      local background = frame:CreateTexture(nil, "BACKGROUND", nil, 2);
      background:SetAllPoints(top);
      background:SetTexture(buttonTexture);
      visual = { background = background };
      decorations[frame] = visual;
    end
    local red, green, blue = tk:GetClassColor();
    visual.background:SetVertexColor(red * 0.52, green * 0.52, blue * 0.52);
    visual.background:Show();
  end

  local order = frame.orderFrame;
  StyleButton(order and order.newButton);
  StyleButton(order and order.dupButton);
  local discord = frame.discordFrame;
  StyleButton(discord and discord.channelButton);
end

local function Refresh()
  if (_G.InCombatLockdown()) then return end
  local frame = _G.CommunitiesFrame;
  if (not frame) then return end
  local settings = _G.GuildControlUI;
  if (settings and hookedSettings ~= settings) then
    settings:HookScript("OnShow", Refresh);
    hookedSettings = settings;
  end
  local list = frame.CommunitiesList;
  if (hookedFrame ~= frame) then
    frame:HookScript("OnShow", Refresh);
    if (type(frame.UpdateCommunitiesTabs) == "function") then
      _G.hooksecurefunc(frame, "UpdateCommunitiesTabs", Refresh);
    end
    if (list and list.ScrollBox) then list.ScrollBox:RegisterCallback("OnUpdate", Refresh, frame); end
    hookedFrame = frame;
  end

  if (_G.MayronUIdb.global.foreverGuildStyle == false) then
    if (setShown) then setShown(false); end
    if (setSettingsShown) then setSettingsShown(false); end
    for _, visual in _G.pairs(decorations) do
      visual.background:Hide();
      if (visual.overlay) then visual.overlay:Hide(); end
    end
    for region, alpha in _G.pairs(originals) do region:SetAlpha(alpha); end
    originals = {};
    return;
  end

  if (settings and settings:IsVisible()) then StyleSettings(settings); end
  if (frame:IsVisible()) then
    setShown = setShown or gui:CreateWindowSkinChrome(frame, 210, 8);
    setShown(true);
    StyleList(list);
    StyleInfoPane(_G.CommunitiesFrameGuildDetailsFrameInfo);
    StyleInfoPane(_G.CommunitiesFrameGuildDetailsFrameNews);
    local toggle = frame.MaximizeMinimizeFrame;
    if (toggle) then
      StyleButton(toggle.MaximizeButton, -45);
      StyleButton(toggle.MinimizeButton, 135);
    end
    StyleButton(frame.InviteButton);
    StyleButton(frame.GuildLogButton);
    local controls = frame.CommunitiesControlFrame;
    StyleButton(controls and controls.GuildControlButton);
  end
end

MayronUI:Hook("CoreModule", "OnInitialized", function()
  if (_G.MayronUIdb.global.foreverWindowStyle ~= true) then return end
  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("ADDON_LOADED");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
  watcher:SetScript("OnEvent", Refresh);
  Refresh();
end);

_G.SLASH_MUIGUILDSTYLE1 = "/muiguildstyle";
_G.SlashCmdList.MUIGUILDSTYLE = function(message)
  if (_G.MayronUIdb.global.foreverWindowStyle ~= true) then return end
  local option = _G.strtrim(message or ""):lower();
  if (option == "on" or option == "off") then
    _G.MayronUIdb.global.foreverGuildStyle = option == "on";
    Refresh();
  else
    tk:Print("/muiguildstyle on | /muiguildstyle off");
  end
end;
