-- luacheck: ignore MayronUI self 143 631
local _G = _G;
local MayronUI = _G.MayronUI;

---@class MayronUI.GUIBuilder
local gui = MayronUI:GetComponent("GUIBuilder");

local ipairs, Mixin = _G.ipairs, _G.Mixin;
local regionsByRow = {
  {"tl", "t", "tr"},
  {"l", "c", "r"},
  {"bl", "b", "br"},
}

---@alias MayronUI.GridTextureType "ExtraLarge"|"Large"|"Medium"|"Small"|"ExtraSmall"
---@alias MayronUI.GridAlphaType "High"|"Regular"|"Low"|"None"

---@class MayronUI.GridTextureMixin : Frame,table
---@field textureType MayronUI.GridTextureType
local GridTextureMixin = {};

function GridTextureMixin:SetGridColor(r, g, b, a)
  for _, row in ipairs(regionsByRow) do
    for column = 1, 3 do
      local texture = self[row[column]]--[[@as Texture]];
      local alpha = a;

      if (alpha == nil) then
        alpha = texture:GetAlpha();
      end

      self[row[column]]:SetVertexColor(r, g, b, alpha or 1);
    end
  end
end

function GridTextureMixin:SetGridBlendMode(mode)
  for _, row in ipairs(regionsByRow) do
    for column = 1, 3 do
      self[row[column]]:SetBlendMode(mode);
    end
  end
end

---@param alphaType MayronUI.GridAlphaType
function GridTextureMixin:SetGridAlphaType(alphaType)
  local alpha;

  if (alphaType == "High") then
    alpha = 1;
  elseif (alphaType == "Regular") then
    alpha = 0.85;
  elseif (alphaType == "Low") then
    alpha = 0.6;
  elseif (alphaType == "None") then
    alpha = 0;
  end

  local r, g, b = self:GetGridColor();
  self.c:SetVertexColor(r, g, b, alpha); -- only reduce middle (not the borders)
end

---@return MayronUI.GridAlphaType
function GridTextureMixin:GetGridAlphaType()
  local _, _, _, alpha = self:GetGridColor();

  if (alpha >= 0.8) then
    return "High";
  elseif (alpha <= 0.6 and alpha > 0) then
    return "Low";
  elseif (alpha == 0) then
    return "None";
  end

  return "Regular";
end

function GridTextureMixin:GetGridColor()
  local r, g, b, a = self.c:GetVertexColor();
  return r, g, b, a;
end

function GridTextureMixin:SetGridTexture(texture)
  for _, row in ipairs(regionsByRow) do
    for column = 1, 3 do
      self[row[column]]:SetTexture(texture);
    end
  end
end

function GridTextureMixin:SetGridTextureShown(shown)
  for _, row in ipairs(regionsByRow) do
    for column = 1, 3 do
      self[row[column]]:SetShown(shown);
    end
  end
end

function GridTextureMixin:SetGridCornerSize(cornerSize)
  for _, row in ipairs(regionsByRow) do
    for column = 1, 3 do
      self[row[column]]:SetSize(cornerSize, cornerSize);
    end
  end
end

-- Places the borders of a texture into their own sections to ensure they do not stretch when the frame is resized.
---@param frame Frame|table
---@param textureFilePath string
---@param cornerSize number
---@param padding number
---@param originalTextureWidth number
---@param originalTextureHeight number
---@param layer DrawLayer?
---@return Frame|MayronUI.GridTextureMixin|table
function gui:CreateGridTexture(frame, textureFilePath, cornerSize, padding, originalTextureWidth, originalTextureHeight, layer)
  padding = padding or 0;

  for _, row in ipairs(regionsByRow) do
    for column = 1, 3 do
      frame[row[column]] = frame:CreateTexture(nil, layer or "BACKGROUND");
      frame[row[column]]:SetTexture(textureFilePath);
      frame[row[column]]:SetSize(cornerSize, cornerSize);
    end
  end

  -- All are a square of cornerSize in width and height
  frame.tl:SetPoint("TOPLEFT", -padding, padding)
  frame.tr:SetPoint("TOPRIGHT", padding, padding);
  frame.bl:SetPoint("BOTTOMLEFT", -padding, -padding);
  frame.br:SetPoint("BOTTOMRIGHT", padding, -padding);

  frame.t:SetPoint("TOPLEFT", frame.tl, "TOPRIGHT");
  frame.t:SetPoint("BOTTOMRIGHT", frame.tr, "BOTTOMLEFT");

  frame.r:SetPoint("TOPLEFT", frame.tr, "BOTTOMLEFT");
  frame.r:SetPoint("BOTTOMRIGHT", frame.br, "TOPRIGHT");

  frame.b:SetPoint("TOPLEFT", frame.bl, "TOPRIGHT");
  frame.b:SetPoint("BOTTOMRIGHT", frame.br, "BOTTOMLEFT");

  frame.l:SetPoint("TOPLEFT", frame.tl, "BOTTOMLEFT");
  frame.l:SetPoint("BOTTOMRIGHT", frame.bl, "TOPRIGHT");

  frame.c:SetPoint("TOPLEFT", frame.tl, "BOTTOMRIGHT");
  frame.c:SetPoint("BOTTOMRIGHT", frame.br, "TOPLEFT");

  -- Text Coords:
  local edgeViewBoxWidth = cornerSize / originalTextureWidth;
  local edgeViewBoxHeight = cornerSize / originalTextureHeight;

  local h1, h2, h3, h4 = 0, edgeViewBoxWidth, 1 - edgeViewBoxWidth, 1; -- horizontalBreakpoints
  local v1, v2, v3, v4 = 0, edgeViewBoxHeight, 1 - edgeViewBoxHeight, 1; -- verticalBreakpoints

  for r, row in ipairs(regionsByRow) do
    local c1, c2, c3 = row[1], row[2], row[3];
    local vMin = select(r, v1, v2, v3, v4);
    local vMax = select(r + 1, v1, v2, v3, v4);
    frame[c1]:SetTexCoord(h1, h2, vMin, vMax);
    frame[c2]:SetTexCoord(h2, h3, vMin, vMax);
    frame[c3]:SetTexCoord(h3, h4, vMin, vMax);
  end

  return Mixin(frame, GridTextureMixin);
end
-- Decorative inset for native windows. Keep the grid below the native controls.
function gui:CreateWindowSkinSurface(parent, topLeft, bottomRight, left, top, right, bottom)
  local tk = MayronUI:GetCoreComponents();
  local surface = _G.CreateFrame("Frame", nil, parent);
  surface:EnableMouse(false);
  surface:SetFrameLevel(parent:GetFrameLevel());
  surface:SetPoint("TOPLEFT", topLeft, "TOPLEFT", left, top);
  surface:SetPoint("BOTTOMRIGHT", bottomRight, "BOTTOMRIGHT", right, bottom);
  self:CreateGridTexture(surface, tk:GetAssetFilePath("Textures\\DialogBox\\Dialog-Medium"),
    10, 0, 674, 674);
  local red, green, blue = tk:GetClassColor();
  surface:SetGridColor(red, green, blue, 0.9);
  surface.c:SetVertexColor(0.72, 0.72, 0.76, 0.85);
  return surface;
end

function gui:CreateWindowSkinTitle(title, width)
  local tk = MayronUI:GetCoreComponents();
  local texture = title:CreateTexture(nil, "BACKGROUND", nil, 1);
  texture:SetTexture(tk:GetAssetFilePath("Textures\\DialogBox\\TitleBar"));
  texture:SetPoint("LEFT", title, "LEFT", 3, 1);
  texture:SetSize(width, 24);
  texture:Hide();
  local text = title.TitleText;
  local points, justify;
  local style = { texture = texture };

  function style:SetShown(shown)
    if (shown and text and not points) then
      points, justify = {}, text:GetJustifyH();
      for index = 1, text:GetNumPoints() do points[index] = { text:GetPoint(index) }; end
      text:ClearAllPoints();
      text:SetPoint("LEFT", texture, "LEFT", 9, 0);
      text:SetPoint("RIGHT", texture, "RIGHT", -15, 0);
      text:SetJustifyH("LEFT");
    elseif (not shown and points) then
      text:ClearAllPoints();
      for _, point in ipairs(points) do text:SetPoint(_G.unpack(point)); end
      text:SetJustifyH(justify);
      points = nil;
    end
    texture:SetShown(shown);
  end

  return style;
end

-- Applies the inventory-style shell to a native window with its own title.
function gui:CreateWindowSkinChrome(frame, titleWidth, extraLeft)
  local tk = MayronUI:GetCoreComponents();
  local surface = self:CreateWindowSkinSurface(frame, frame, frame, -3 - (extraLeft or 0), -2, 3, -3);
  local backing = surface:CreateTexture(nil, "BACKGROUND", nil, -1);
  backing:SetPoint("TOPLEFT", surface, "TOPLEFT", 8, -8);
  backing:SetPoint("BOTTOMRIGHT", surface, "BOTTOMRIGHT", -8, 8);
  backing:SetColorTexture(0.035, 0.035, 0.045, 0.96);
  surface:SetGridAlphaType("Low");
  surface:Hide();

  local title = frame.TitleContainer;
  local plate = title and self:CreateWindowSkinTitle(title, titleWidth);
  local titleText = title and title.TitleText;
  local close = frame.CloseButton;
  local closeSkin, closeBackground;
  if (close) then
    closeSkin = _G.CreateFrame("Frame", nil, close);
    closeSkin:EnableMouse(false);
    closeSkin:SetAllPoints(close);
    closeBackground = closeSkin:CreateTexture(nil, "BACKGROUND");
    closeBackground:SetAllPoints(closeSkin);
    closeBackground:SetTexture(tk:GetAssetFilePath("Textures\\Widgets\\Button"));
    self:CreateIconTexture("cross", closeSkin, false);
    closeSkin:Hide();
  end

  local originalAlphas, originalTextColor = {};
  local function HideArt(region)
    if (not region) then return end
    if (originalAlphas[region] == nil) then originalAlphas[region] = region:GetAlpha(); end
    region:SetAlpha(0);
  end

  return function(shown)
    surface:SetShown(shown);
    if (plate) then plate:SetShown(shown); end
    if (closeSkin) then closeSkin:SetShown(shown); end
    if (not shown) then
      for region, alpha in _G.pairs(originalAlphas) do region:SetAlpha(alpha); end
      originalAlphas = {};
      if (originalTextColor) then
        titleText:SetTextColor(_G.unpack(originalTextColor));
        originalTextColor = nil;
      end
      return;
    end

    local red, green, blue = tk:GetClassColor();
    HideArt(frame.Bg);
    HideArt(frame.NineSlice);
    if (frame.Inset) then
      HideArt(frame.Inset.Bg);
      HideArt(frame.Inset.NineSlice);
    end
    if (plate) then plate.texture:SetVertexColor(red * 0.85, green * 0.85, blue * 0.85); end
    if (titleText) then
      originalTextColor = originalTextColor or { titleText:GetTextColor() };
      titleText:SetTextColor(0.96, 0.96, 1);
    end
    if (closeSkin) then
      HideArt(close:GetNormalTexture());
      HideArt(close:GetPushedTexture());
      closeBackground:SetVertexColor(red * 0.85, green * 0.85, blue * 0.85);
    end
  end;
end
