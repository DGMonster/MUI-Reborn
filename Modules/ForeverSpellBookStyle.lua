-- Optional decoration for Forever's native spellbook.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, gui = MayronUI:GetCoreComponents();
if (not tk:IsForever()) then return end

local visuals = {};
local hookedFrames = {};
local originalTints = {};
local surfaces = {};
local originalTextColors = {};
local pageTextures = { "BookBGHalved", "BookBGLeft", "BookBGRight" };
local frameNames = { "PlayerSpellsFrame", "SpellBookFrame" };
local buttonTexture = tk:GetAssetFilePath("Textures\\Widgets\\Button");

local function AddButtonVisual(style, button, iconName, rotation)
  if (not button) then return end
  local overlay = _G.CreateFrame("Frame", nil, button);
  overlay:EnableMouse(false);
  overlay:SetAllPoints(button);
  local background = overlay:CreateTexture(nil, "BACKGROUND");
  background:SetAllPoints();
  background:SetTexture(buttonTexture);
  local icon = gui:CreateIconTexture(iconName, overlay, false, rotation);
  style.buttons[#style.buttons + 1] = { overlay = overlay; background = background; icon = icon };
  for _, region in _G.ipairs({ button:GetRegions() }) do
    if (region:IsObjectType("Texture")) then
      style.originals[region] = region:GetAlpha();
    end
  end
end

local function CreateVisuals(frame)
  local style = { originals = {}; buttons = {} };
  local title = frame.TitleContainer;
  if (title) then
    style.heading = title:CreateTexture(nil, "BACKGROUND");
    style.heading:SetAllPoints(title);
    style.heading:SetColorTexture(0.045, 0.045, 0.055, 0.95);

    style.titlePlate = gui:CreateWindowSkinTitle(title, 172);
  end

  local accentParent = title or frame;
  style.accent = accentParent:CreateTexture(nil, "OVERLAY", nil, 7);
  if (title) then
    style.accent:SetPoint("BOTTOMLEFT", title, "BOTTOMLEFT");
    style.accent:SetPoint("BOTTOMRIGHT", title, "BOTTOMRIGHT");
  else
    style.accent:SetPoint("TOPLEFT", frame, "TOPLEFT", 66, -21);
    style.accent:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -67, -21);
  end
  style.accent:SetHeight(2);

  local close = frame.ClosePanelButton or frame.CloseButton or _G[frame:GetName() .. "CloseButton"];
  AddButtonVisual(style, close, "cross");
  local toggle = frame.MaximizeMinimizeButton;
  if (toggle) then
    AddButtonVisual(style, toggle.MaximizeButton, "arrow", -45);
    AddButtonVisual(style, toggle.MinimizeButton, "arrow", 135);
  end

  return style;
end

local function Tint(texture, red, green, blue, alpha)
  if (not texture) then return end
  if (not originalTints[texture]) then originalTints[texture] = { texture:GetVertexColor() }; end
  texture:SetVertexColor(red, green, blue, alpha or originalTints[texture][4]);
end

local function ColorText(text, red, green, blue)
  if (not text) then return end
  if (not originalTextColors[text]) then originalTextColors[text] = { text:GetTextColor() }; end
  text:SetTextColor(red, green, blue, originalTextColors[text][4]);
end

local function ColorLabels(frame, red, green, blue)
  if (not frame) then return end
  for _, region in _G.ipairs({ frame:GetRegions() }) do
    if (region:IsObjectType("FontString")) then ColorText(region, red, green, blue); end
  end
end

local function StylePages(frame, book)
  local paged = book.PagedSpellsFrame;
  if (not paged or not paged.EnumerateFrames or not book.BookBGHalved) then return end

  local surface = surfaces[book];
  if (not surface) then
    surface = gui:CreateWindowSkinSurface(book, book, book, 8, -50, -7, 2);
    surfaces[book] = surface;
  end
  surface:Show();
  for _, key in _G.ipairs(pageTextures) do Tint(book[key], 1, 1, 1, 0); end
  Tint(book.TopBar, 0.22, 0.24, 0.32);
  Tint(book.BookCornerFlipbook, 1, 1, 1, 0);
  Tint(book.Bookmark, 1, 1, 1, 0);
  ColorLabels(frame.TitleContainer, 0.96, 0.96, 1);
  if (frame.NineSlice) then
    for _, region in _G.ipairs({ frame.NineSlice:GetRegions() }) do
      if (region:IsObjectType("Texture")) then Tint(region, 0.27, 0.34, 0.52); end
    end
  end

  for _, row in paged:EnumerateFrames() do
    local text = row.TextContainer;
    if (text) then
      Tint(row.Backplate, 1, 1, 1, 0);
      ColorText(text.Name, 0.95, 0.96, 1);
      ColorText(text.SubName, 0.72, 0.75, 0.82);
      ColorText(text.RequiredLevel, 1, 0.68, 0.48);
    else
      Tint(row.Backplate, 1, 1, 1, 0);
      Tint(row.Border, 1, 1, 1, 0);
      ColorLabels(row, 0.92, 0.93, 0.98);
    end
  end
  ColorLabels(paged.PagingControls, 0.86, 0.88, 0.94);
end

local function RestorePages()
  for texture, color in _G.pairs(originalTints) do texture:SetVertexColor(_G.unpack(color)); end
  for text, color in _G.pairs(originalTextColors) do text:SetTextColor(_G.unpack(color)); end
  originalTints = {};
  originalTextColors = {};
end

local function Refresh()
  if (_G.InCombatLockdown()) then return end
  local enabled = _G.MayronUIdb.global.foreverSpellBookStyle ~= false;
  local visibleFrame, visibleBook;
  for _, name in _G.ipairs(frameNames) do
    local frame = _G[name];
    if (frame) then
      if (not hookedFrames[frame]) then
        frame:HookScript("OnShow", Refresh);
        frame:HookScript("OnHide", Refresh);
        hookedFrames[frame] = true;
      end
      local book = frame.SpellBookFrame or frame;
      if (not visibleFrame and frame:IsVisible() and book:IsVisible()) then
        visibleFrame, visibleBook = frame, book;
      end
    end
  end

  if (enabled and visibleFrame and not visuals[visibleFrame]) then
    visuals[visibleFrame] = CreateVisuals(visibleFrame);
  end

  for book, surface in _G.pairs(surfaces) do surface:SetShown(enabled and book == visibleBook); end
  if (enabled and visibleBook) then
    StylePages(visibleFrame, visibleBook);
  else
    RestorePages();
  end

  local red, green, blue = tk:GetClassColor();
  for frame, style in _G.pairs(visuals) do
    local shown = enabled and frame == visibleFrame;
    style.accent:SetColorTexture(red, green, blue, 1);
    style.accent:SetShown(shown);
    if (style.heading) then
      style.heading:SetShown(shown);
      style.titlePlate.texture:SetVertexColor(red * 0.85, green * 0.85, blue * 0.85, 1);
      style.titlePlate:SetShown(shown);
    end
    for _, button in _G.ipairs(style.buttons) do
      button.background:SetVertexColor(red * 0.65, green * 0.65, blue * 0.65);
      button.icon:SetVertexColor(red, green, blue);
      button.overlay:SetShown(shown);
    end
    for texture, alpha in _G.pairs(style.originals) do
      texture:SetAlpha(shown and 0 or alpha);
    end
  end
end

MayronUI:Hook("CoreModule", "OnInitialized", function()
  if (_G.MayronUIdb.global.foreverWindowStyle ~= true) then return end
  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("ADDON_LOADED");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
  watcher:SetScript("OnEvent", Refresh);
  local registry = _G.EventRegistry;
  registry:RegisterCallback("PlayerSpellsFrame.SpellBookFrame.Show", Refresh, watcher);
  registry:RegisterCallback("PlayerSpellsFrame.SpellBookFrame.Hide", Refresh, watcher);
  registry:RegisterCallback("PlayerSpellsFrame.SpellBookFrame.DisplayedSpellsChanged", Refresh, watcher);
  Refresh();
end);

_G.SLASH_MUISPELLBOOK1 = "/muispellbook";
_G.SlashCmdList.MUISPELLBOOK = function(message)
  if (_G.MayronUIdb.global.foreverWindowStyle ~= true) then return end
  local option = _G.strtrim(message or ""):lower();
  if (option == "on" or option == "off") then
    _G.MayronUIdb.global.foreverSpellBookStyle = option == "on";
    Refresh();
  else
    tk:Print("/muispellbook on | /muispellbook off");
  end
end;
