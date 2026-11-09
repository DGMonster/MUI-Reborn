-- Forever error-window presentation only. Blizzard owns text and all actions.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, gui, _, L = MayronUI:GetCoreComponents();
if (not tk:IsRetail()) then return end

local enabled, ready = true, false;
local panel, title;
local originals, buttonVisuals = {}, {};
local elapsedTotal = 0;
local white = "Interface\\Buttons\\WHITE8X8";

local function HideRegion(region)
  if (not region or not region.GetAlpha) then return end
  if (originals[region] == nil) then originals[region] = region:GetAlpha(); end
  region:SetAlpha(0);
end
local function HideBorderRegions(frame)
  if (not frame or not frame.GetRegions) then return end
  for _, region in _G.ipairs({ frame:GetRegions() }) do
    if (region:IsObjectType("Texture")) then
      local layer = region:GetDrawLayer();
      if (layer == "BACKGROUND" or layer == "BORDER") then HideRegion(region); end
    end
  end
end
local function HideOwned()
  if (panel) then panel:Hide(); end
  if (title) then title:Hide(); end
  for _, visual in _G.pairs(buttonVisuals) do visual:Hide(); end
end
local function Restore()
  for region, alpha in _G.pairs(originals) do region:SetAlpha(alpha); end
  originals = {};
  HideOwned();
end
local function Rect(frame)
  local x, y, w, h = frame:GetRect();
  if (_G.issecretvalue and (_G.issecretvalue(x) or _G.issecretvalue(y) or
      _G.issecretvalue(w) or _G.issecretvalue(h))) then return end
  if (not x or not y or not w or not h) then return end
  local scale = frame:GetEffectiveScale() / _G.UIParent:GetEffectiveScale();
  return x * scale, y * scale, w * scale, h * scale;
end
local function Position(visual, native, x, y, w, h, above)
  visual:SetFrameStrata(native:GetFrameStrata());
  visual:SetFrameLevel(_G.math.max(0, native:GetFrameLevel() + (above or -1)));
  visual:ClearAllPoints();
  visual:SetPoint("BOTTOMLEFT", _G.UIParent, "BOTTOMLEFT", x, y);
  visual:SetSize(w, h);
  visual:Show();
end
local function FindCloseButton(frame)
  -- Resolve the text button independently of client-specific parent keys.
  for _, child in _G.ipairs({ frame:GetChildren() }) do
    if (child:IsObjectType("Button") and child.GetText) then
      local text = child:GetText();
      if (not _G.issecretvalue or not _G.issecretvalue(text)) then
        if (text == _G.CLOSE) then return child end
      end
    end
  end
end
local function StyleButton(native, r, g, b)
  if (not native or not native:IsVisible()) then return end
  local x, y, w, h = Rect(native);
  if (not x) then return end
  local visual = buttonVisuals[native];
  if (not visual) then
    visual = _G.CreateFrame("Frame", nil, _G.UIParent, "BackdropTemplate");
    visual:EnableMouse(false);
    visual:SetBackdrop({ edgeFile = white; edgeSize = 1 });
    visual.fill = visual:CreateTexture(nil, "BACKGROUND");
    visual.fill:SetAllPoints();
    visual.fill:SetTexture(tk:GetAssetFilePath("Textures\\Widgets\\Button"));
    buttonVisuals[native] = visual;
  end
  -- Buttons keep their original font strings, scripts, size and click hit area.
  for _, region in _G.ipairs({ native:GetRegions() }) do
    if (region:IsObjectType("Texture")) then HideRegion(region); end
  end
  HideBorderRegions(native.NineSlice);
  visual.fill:SetVertexColor(r * 0.6, g * 0.6, b * 0.6, 1);
  visual:SetBackdropBorderColor(r, g, b, 0.7);
  Position(visual, native, x, y, w, h);
end
local function Refresh()
  if (not ready or not enabled) then return end
  local native = _G.ScriptErrorsFrame;
  if (not native or not native:IsVisible()) then HideOwned(); return end
  if (_G.InCombatLockdown()) then return end
  local x, y, w, h = Rect(native);
  if (not x) then HideOwned(); return end
  local r, g, b = tk:GetThemeColor();
  if (not panel) then
    panel = _G.CreateFrame("Frame", nil, _G.UIParent);
    panel:EnableMouse(false);
    gui:CreateGridTexture(panel,
      tk:GetAssetFilePath("Textures\\DialogBox\\Dialog-Medium"), 10, 0, 674, 674, "BACKGROUND");
    panel:SetGridAlphaType("High");
    title = _G.CreateFrame("Frame", nil, _G.UIParent);
    title:EnableMouse(false);
    title.texture = title:CreateTexture(nil, "BACKGROUND");
    title.texture:SetAllPoints();
    title.texture:SetTexture(tk:GetAssetFilePath("Textures\\DialogBox\\TitleBar"));
    title.text = title:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    title.text:SetPoint("LEFT", 11, 0);
    title.text:SetPoint("RIGHT", -18, 0);
    title.text:SetJustifyH("LEFT");
    title.text:SetWordWrap(false);
    tk:SetMasterFont(title.text, 12);
  end
  local fr, fg, fb = gui:GetMuiFrameColor();
  panel:SetGridColor(fr, fg, fb);
  Position(panel, native, x - 5, y - 5, w + 10, h + 10);
  title.text:SetText(_G.LUA_ERROR or "Lua error");
  title.texture:SetVertexColor(r, g, b);
  Position(title, native, x - 7, y + h - 2, _G.math.min(210, w - 50), 31, 5);
  HideBorderRegions(native);
  HideBorderRegions(native.NineSlice);
  HideBorderRegions(native.Border);
  -- UIPanelDialogTemplate exposes Title and the named TitleBG decoration.
  if (native.Title and native.Title.IsObjectType and native.Title:IsObjectType("FontString")) then
    HideRegion(native.Title);
  end
  local titleBG = _G.ScriptErrorsFrameTitleBG;
  if (titleBG and titleBG.IsObjectType and titleBG:IsObjectType("Texture")) then HideRegion(titleBG); end
  StyleButton(native.Reload, r, g, b);
  StyleButton(FindCloseButton(native), r, g, b);
end

MayronUI:Hook("CoreModule", "OnInitialized", function()
  ready = true;
  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
  watcher:SetScript("OnEvent", Refresh);
  watcher:SetScript("OnUpdate", function(_, elapsed)
    elapsedTotal = elapsedTotal + elapsed;
    if (elapsedTotal >= 0.2) then elapsedTotal = 0; Refresh(); end
  end);
  Refresh();
end);
_G.SLASH_MUIERRORSTYLE1 = "/muierrorstyle";
_G.SlashCmdList.MUIERRORSTYLE = function(message)
  local option = _G.strtrim(message or ""):lower();
  if (option ~= "on" and option ~= "off") then
    tk:Print(L["Error window appearance: /muierrorstyle on or /muierrorstyle off."]);
    return;
  end
  if (_G.InCombatLockdown()) then
    tk:Print(L["Change the error window appearance outside combat."]);
    return;
  end
  enabled = option == "on";
  if (enabled) then Refresh(); else Restore(); end
end;
