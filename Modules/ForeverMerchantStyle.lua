-- MUI decoration for Forever's native merchant and buyback window.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, gui = MayronUI:GetCoreComponents();
if (not tk:IsForever()) then return end

local surface, plate, closeOverlay, closeBackground, originalTitleColor;
local originalAlphas, tabSkins = {}, {};
local moneyAnchor;
local buttonTexture = tk:GetAssetFilePath("Textures\\Widgets\\Button");

local function HideArt(texture)
  if (not texture or not texture:IsObjectType("Texture")) then return end
  if (originalAlphas[texture] == nil) then originalAlphas[texture] = texture:GetAlpha(); end
  texture:SetAlpha(0);
end

local function HideBorder(frame)
  if (not frame) then return end
  for _, region in _G.ipairs({ frame:GetRegions() }) do HideArt(region); end
end

local function StyleTab(tab, selected, red, green, blue)
  if (not tab) then return end
  local background = tabSkins[tab];
  for _, region in _G.ipairs({ tab:GetRegions() }) do
    if (region ~= background) then HideArt(region); end
  end
  if (not background) then
    background = tab:CreateTexture(nil, "BACKGROUND");
    background:SetTexture(buttonTexture);
    background:SetPoint("TOPLEFT", 4, -3);
    background:SetPoint("BOTTOMRIGHT", -4, 4);
    tabSkins[tab] = background;
  end
  local brightness = selected and 0.85 or 0.42;
  background:SetVertexColor(red * brightness, green * brightness, blue * brightness);
  background:Show();
end

local function Refresh()
  local frame = _G.MerchantFrame;
  if (not frame or _G.InCombatLockdown()) then return end
  local money = _G.MerchantMoneyFrame;
  local title = frame.TitleContainer;
  local titleText = title and title.TitleText;
  if (_G.MayronUIdb.global.foreverMerchantStyle == false or not frame:IsVisible()) then
    if (surface) then surface:Hide(); end
    if (money and moneyAnchor) then
      money:SetPoint(_G.unpack(moneyAnchor, 1, 5));
      moneyAnchor = nil;
    end
    for _, background in _G.pairs(tabSkins) do background:Hide(); end
    if (plate) then plate:SetShown(false); end
    if (closeOverlay) then closeOverlay:Hide(); end
    if (originalTitleColor) then
      titleText:SetTextColor(_G.unpack(originalTitleColor));
      originalTitleColor = nil;
    end
    for texture, alpha in _G.pairs(originalAlphas) do texture:SetAlpha(alpha); end
    originalAlphas = {};
    return;
  end

  if (not surface) then
    surface = gui:CreateWindowSkinSurface(frame, frame, frame, -7, -2, 7, -5);
    local backing = surface:CreateTexture(nil, "BACKGROUND", nil, -1);
    backing:SetPoint("TOPLEFT", surface, "TOPLEFT", 8, -8);
    backing:SetPoint("BOTTOMRIGHT", surface, "BOTTOMRIGHT", -8, 8);
    backing:SetColorTexture(0.035, 0.035, 0.045, 0.96);
    surface:SetGridAlphaType("Low");
  end
  surface:Show();
  HideArt(frame.Bg);
  HideBorder(frame.NineSlice);
  if (frame.Inset) then
    HideArt(frame.Inset.Bg);
    HideBorder(frame.Inset.NineSlice);
  end
  HideArt(_G.MerchantFrameBottomLeftBorder);
  HideArt(_G.BuybackBG);
  HideBorder(_G.MerchantMoneyBg);
  if (money and not moneyAnchor and money:GetNumPoints() == 1) then
    local point, relative, relativePoint, x, y = money:GetPoint(1);
    if (point == "BOTTOMRIGHT" and relative == frame and relativePoint == "BOTTOMRIGHT") then
      moneyAnchor = { point, relative, relativePoint, x, y };
      money:SetPoint(point, relative, relativePoint, x - 4, y + 6);
    end
  end
  local moneyInset = _G.MerchantMoneyInset;
  if (moneyInset) then
    HideArt(moneyInset.Bg);
    HideBorder(moneyInset.NineSlice);
  end

  local red, green, blue = tk:GetClassColor();
  local selected = _G.PanelTemplates_GetSelectedTab(frame);
  StyleTab(_G.MerchantFrameTab1, selected == 1, red, green, blue);
  StyleTab(_G.MerchantFrameTab2, selected == 2, red, green, blue);
  if (title) then
    plate = plate or gui:CreateWindowSkinTitle(title, 186);
    plate.texture:SetVertexColor(red * 0.85, green * 0.85, blue * 0.85);
    if (titleText) then
      originalTitleColor = originalTitleColor or { titleText:GetTextColor() };
      titleText:SetTextColor(0.96, 0.96, 1);
    end
    plate:SetShown(true);
  end
  local close = frame.CloseButton;
  if (close) then
    if (not closeOverlay) then
      closeOverlay = _G.CreateFrame("Frame", nil, close);
      closeOverlay:EnableMouse(false);
      closeOverlay:SetAllPoints(close);
      closeBackground = closeOverlay:CreateTexture(nil, "BACKGROUND");
      closeBackground:SetAllPoints();
      closeBackground:SetTexture(buttonTexture);
      gui:CreateIconTexture("cross", closeOverlay, false);
    end
    HideArt(close:GetNormalTexture());
    HideArt(close:GetPushedTexture());
    closeBackground:SetVertexColor(red * 0.85, green * 0.85, blue * 0.85);
    closeOverlay:Show();
  end
end

MayronUI:Hook("CoreModule", "OnInitialized", function()
  if (_G.MayronUIdb.global.foreverWindowStyle ~= true) then return end
  local frame = _G.MerchantFrame;
  if (frame) then
    frame:HookScript("OnShow", Refresh);
    frame:HookScript("OnHide", Refresh);
  end
  if (type(_G.MerchantFrame_Update) == "function") then
    _G.hooksecurefunc("MerchantFrame_Update", Refresh);
  end
  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("MERCHANT_SHOW");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
  watcher:SetScript("OnEvent", Refresh);
  Refresh();
end);

_G.SLASH_MUIMERCHANTSTYLE1 = "/muimerchantstyle";
_G.SlashCmdList.MUIMERCHANTSTYLE = function(message)
  if (_G.MayronUIdb.global.foreverWindowStyle ~= true) then return end
  local option = _G.strtrim(message or ""):lower();
  if (option == "on" or option == "off") then
    _G.MayronUIdb.global.foreverMerchantStyle = option == "on";
    Refresh();
  else
    tk:Print("/muimerchantstyle on | /muimerchantstyle off");
  end
end;
