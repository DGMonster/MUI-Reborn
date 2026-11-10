-- Optional Forever mail decoration. Blizzard owns the mail controls.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, _, _, gui = MayronUI:GetCoreComponents();
if (not tk:IsForever()) then return end

local windows, tints, textColors, controls = {}, {}, {}, {};
local hookedInbox, hookedSend;
local function Tint(texture, r, g, b, alpha)
  if (not texture) then return end
  tints[texture] = tints[texture] or { texture:GetVertexColor() };
  texture:SetVertexColor(r, g, b, alpha or tints[texture][4]);
end

local function TintRegions(frame, r, g, b)
  if (not frame) then return end
  for _, region in _G.ipairs({ frame:GetRegions() }) do
    if (region:IsObjectType("Texture")) then Tint(region, r, g, b); end
  end
end

local function StyleWindow(frame)
  if (not frame) then return end
  windows[frame] = windows[frame] or gui:CreateWindowSkinChrome(frame, 170);
  windows[frame](true);
end

local function StylePaper(body, left, right, textType)
  if (not body or not body.GetTextColor or not body.SetTextColor) then return end
  local original = textColors[body];
  if (not original) then
    local color = textType and { body:GetTextColor(textType) } or { body:GetTextColor() };
    if (not color[1]) then return end
    original = { color = color; textType = textType };
    textColors[body] = original;
  end
  if (textType) then body:SetTextColor(textType, 0.94, 0.95, 1, 1);
  else body:SetTextColor(0.94, 0.95, 1, 1); end
  if (left and right) then
    Tint(left, 1, 1, 1, 0);
    Tint(right, 1, 1, 1, 0);
  end
end

local function StyleControl(button, brightness, red, green, blue, action, rotation)
  if (not button) then return end
  local skin = controls[button];
  if (not skin) then
    local background = button:CreateTexture(nil, "BACKGROUND");
    background:SetPoint("TOPLEFT", 2, -2);
    background:SetPoint("BOTTOMRIGHT", -2, 2);
    background:SetTexture(tk:GetAssetFilePath("Textures\\Widgets\\Button"));
    skin = { background = background };
    if (rotation) then
      skin.arrow = gui:CreateIconTexture("arrow", button, false, rotation);
    end
    controls[button] = skin;
    if (action) then
      local function UpdateAlpha()
        local enabled = button:IsEnabled();
        background:SetAlpha(enabled and 1 or 0.4);
        if (skin.arrow) then skin.arrow:SetAlpha(enabled and 1 or 0.45); end
      end
      button:HookScript("OnEnable", UpdateAlpha);
      button:HookScript("OnDisable", UpdateAlpha);
      UpdateAlpha();
    end
  end

  local highlight = button:GetHighlightTexture();
  for _, region in _G.ipairs({ button:GetRegions() }) do
    if (region ~= skin.background and region ~= skin.arrow and region ~= highlight
        and region:IsObjectType("Texture")) then
      Tint(region, 1, 1, 1, 0);
    end
  end
  skin.background:SetVertexColor(red * brightness, green * brightness, blue * brightness);
  skin.background:Show();
  if (skin.arrow) then skin.arrow:Show(); end
end


local function ToneDownSendDividers(frame)
  local first = _G.SendMailHorizontalBarLeft;
  local texture = first and first:GetTexture();
  if (not frame or not texture) then return end
  for _, region in _G.ipairs({ frame:GetRegions() }) do
    if (region:IsObjectType("Texture") and region:GetTexture() == texture) then
      Tint(region, 0.38, 0.38, 0.44, 0.35);
    end
  end
end


local function Refresh()
  if (_G.InCombatLockdown()) then return end
  if (_G.MayronUIdb.global.foreverMailStyle == false) then
    for _, setShown in _G.pairs(windows) do setShown(false); end
    for _, skin in _G.pairs(controls) do
      skin.background:Hide();
      if (skin.arrow) then skin.arrow:Hide(); end
    end
    for texture, color in _G.pairs(tints) do texture:SetVertexColor(_G.unpack(color)); end
    for body, original in _G.pairs(textColors) do
      if (original.textType) then body:SetTextColor(original.textType, _G.unpack(original.color));
      else body:SetTextColor(_G.unpack(original.color)); end
    end
    tints, textColors = {}, {};
    return;
  end
  if (not _G.MailFrame) then return end
  local r, g, b = tk:GetClassColor();
  StyleWindow(_G.MailFrame);
  StyleWindow(_G.OpenMailFrame);
  Tint(_G.InboxFrameBg, 1, 1, 1, 0);
  for index = 1, 7 do
    -- The row owns the border art. The actual mail icon belongs to its button.
    TintRegions(_G["MailItem" .. index], 0.22, 0.28, 0.45);
  end
  local inbox, send = _G.InboxFrame, _G.SendMailFrame;
  if (inbox and hookedInbox ~= inbox) then
    inbox:HookScript("OnShow", Refresh);
    hookedInbox = inbox;
  end
  if (send and hookedSend ~= send) then
    send:HookScript("OnShow", Refresh);
    hookedSend = send;
  end

  local sending = send and send:IsShown();
  StyleControl(_G.MailFrameTab1, sending and 0.42 or 0.85, r, g, b);
  StyleControl(_G.MailFrameTab2, sending and 0.85 or 0.42, r, g, b);
  StyleControl(_G.OpenAllMail, 0.85, r, g, b, true);
  StyleControl(_G.SendMailCancelButton, 0.85, r, g, b, true);
  StyleControl(_G.SendMailMailButton, 0.85, r, g, b, true);
  StyleControl(inbox and inbox.PrevPageButton, 0.85, r, g, b, true, 90);
  StyleControl(inbox and inbox.NextPageButton, 0.85, r, g, b, true, -90);
  ToneDownSendDividers(send);
  StylePaper(_G.SendMailBodyEditBox, _G.SendStationeryBackgroundLeft, _G.SendStationeryBackgroundRight);
  StylePaper(_G.OpenMailBodyText, _G.OpenStationeryBackgroundLeft, _G.OpenStationeryBackgroundRight, "p");
end

MayronUI:Hook("CoreModule", "OnInitialized", function()
  if (_G.MayronUIdb.global.foreverWindowStyle ~= true) then return end
  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("MAIL_SHOW");
  watcher:RegisterEvent("MAIL_INBOX_UPDATE");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED");
  watcher:SetScript("OnEvent", Refresh);
  Refresh();
end);

_G.SLASH_MUIMAILSTYLE1 = "/muimailstyle";
_G.SlashCmdList.MUIMAILSTYLE = function(message)
  if (_G.MayronUIdb.global.foreverWindowStyle ~= true) then return end
  local option = _G.strtrim(message or ""):lower();
  if (option == "on" or option == "off") then
    _G.MayronUIdb.global.foreverMailStyle = option == "on";
    Refresh();
  else
    tk:Print("/muimailstyle on | /muimailstyle off");
  end
end;
