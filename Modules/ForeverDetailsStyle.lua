-- Native Details skin integration. No overlay frames and no combat-data access.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db, _, _, _, L = MayronUI:GetCoreComponents();

local plainSkinName = "MUI Reborn";
-- User-approved saved appearance: base 41/255, wallpaper and overlay 77/255.
local backgroundAlpha, wallpaperAlpha = 41 / 255, 77 / 255;
local red, green, blue = tk:GetClassColor();
local skinName = _G.string.format("|cff%02x%02x%02x%s|r",
  _G.math.floor(red * 255 + 0.5), _G.math.floor(green * 255 + 0.5),
  _G.math.floor(blue * 255 + 0.5), plainSkinName);
local function IsMuiSkin(name)
  return _G.type(name) == "string" and
    name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "") == plainSkinName;
end
local ready, registered, elapsedTotal = false, false, 0;
local function Copy(value)
  if (_G.type(value) ~= "table") then return value end
  local result = {};
  for key, child in _G.pairs(value) do result[key] = Copy(child); end
  return result;
end
local function RegisterSkin()
  if (registered) then return true end
  local details = _G.Details;
  if (not ready or not details or not details.InstallSkin or not details.GetAllInstances or not details.skins or
      not details.skins["Minimalistic v2"] or not tk.Constants.LSM) then return false end
  local media = tk.Constants.LSM;
  media:Register("background", "MUI Details Background", "Interface\\Buttons\\WHITE8X8");
  local skin = Copy(details.skins["Minimalistic v2"]);
  skin.author = "Monster";
  skin.site = "https://github.com/DGMonster/MUI-Reborn";
  skin.version = "1.0.8-rc";
  skin.desc = L["MUI styling with class colors, a translucent background and consistent bar spacing."];
  skin.no_cache = true;
  skin.is_cached_skin = nil;
  local red, green, blue = tk:GetClassColor();
  -- These are Details' native skin properties, not a second window on top.
  skin.instance_cprops = {
    titlebar_shown = true; titlebar_height = 22; titlebar_texture = "MayronUI";
    titlebar_texture_color = { red * 0.3, green * 0.3, blue * 0.3, 0.85 };
    toolbar_side = 1; menu_anchor = { 8, 5, side = 2 }; menu_icons_size = 0.9;
    color = { 0.12, 0.12, 0.12, 0 }; color_buttons = { 1, 1, 1, 1 };
    show_sidebars = false; show_statusbar = false; hide_icon = true;
    rounded_corner_enabled = false;
    fullborder_shown = true; fullborder_size = 1;
    fullborder_color = { 0.3, 0.3, 0.3, 1 }; rowareaborder_shown = false;
    backdrop_texture = "MUI Details Background";
    bg_r = 13 / 255; bg_g = 13 / 255; bg_b = 13 / 255; bg_alpha = backgroundAlpha;
    attribute_text = {
      enabled = true; side = 1; text_size = 12; text_face = "MUI_Font";
      shadow = false; anchor = { 6, 6 }; text_color = { 1, 0.82, 0, 1 };
      enable_custom_text = false; show_timer = false;
    };
    row_info = {
      height = 22; space = { left = 6, right = -12, between = 2,
        left_noborder = 6, right_noborder = -12 };
      row_offsets = { left = 0, right = 0, top = -6, bottom = 6 };
      texture = "MayronUI"; texture_file = tk:GetAssetFilePath("Textures\\Widgets\\Button.tga");
      texture_background = "MayronUI"; alpha = 1;
      textL_size = 12; textR_size = 12; font_face = "MUI_Font";
      font_face_file = tk:GetAssetFilePath("Fonts\\MayronUI.ttf");
      no_icon = false; start_after_icon = true; icon_mask = ""; icon_size_offset = -2;
      backdrop = { enabled = false };
      models = { upper_enabled = false, lower_enabled = false };
    };
    wallpaper = {
      enabled = true; texture = tk:GetAssetFilePath("Textures\\DialogBox\\Dialog-Medium.tga");
      anchor = "all"; level = 1; texcoord = { 0.1, 0.9, 0.1, 0.9 };
      overlay = { 128 / 255, 128 / 255, 128 / 255, wallpaperAlpha }; alpha = wallpaperAlpha; width = 256; height = 256;
    };
  };
  -- Details uses the label as its stored key, including color codes (as MID does).
  -- Resolve earlier plain names and names saved with another character's class color.
  for id, name in _G.pairs(details.waitingForSkins or {}) do
    if (IsMuiSkin(name)) then details.waitingForSkins[id] = skinName; end
  end
  for name in _G.pairs(details.skins) do
    if (name ~= skinName and IsMuiSkin(name)) then details.skins[name] = nil; end
  end
  registered = details:InstallSkin(skinName, skin) == true;
  if (registered) then
    -- Saved MUI windows retain their skin choice; only refresh the current class tint.
    for _, instance in _G.pairs(details:GetAllInstances()) do
      if (IsMuiSkin(instance.skin) and instance.baseframe and instance.RefreshTitleBar) then
        instance.skin = skinName;
        instance.titlebar_texture_color = Copy(skin.instance_cprops.titlebar_texture_color);
        -- Upgrade the previous MUI header defaults without resetting the window/rows.
        if (instance.titlebar_height == 26) then instance.titlebar_height = 22; end
        local text = instance.attribute_text;
        if (instance.AttributeMenu and text and text.anchor and text.anchor[1] == 6 and text.anchor[2] == 8) then
          text.anchor[2] = 6; text.shadow = false; text.text_color = { 1, 0.82, 0, 1 };
          instance:AttributeMenu();
        end
        local menu = instance.menu_anchor;
        if (instance.LeftMenuAnchorSide and menu and menu[1] == 8 and menu[2] == 7) then
          menu[2] = 5; instance:LeftMenuAnchorSide();
        end
        instance:RefreshTitleBar();
        -- Upgrade only the previous MUI defaults; retain user-adjusted opacity.
        if (instance.SetBackgroundAlpha and instance.bg_alpha == 0.95) then instance:SetBackgroundAlpha(backgroundAlpha); end
        if (instance.InstanceWallpaper and instance.wallpaper and instance.wallpaper.alpha == 0.9) then
          instance.wallpaper.alpha = wallpaperAlpha;
          instance.wallpaper.overlay = Copy(skin.instance_cprops.wallpaper.overlay);
          instance:InstanceWallpaper(instance.wallpaper.enabled);
        end
      end
    end
  end
  return registered;
end
local function Backups(details)
  -- Scope backups by character, Details profile and instance, never share them across characters.
  local global = _G.MayronUIdb.global;
  global.detailsSkinBackups = global.detailsSkinBackups or {};
  local key = tk:GetPlayerKey();
  global.detailsSkinBackups[key] = global.detailsSkinBackups[key] or {};
  local profiles = global.detailsSkinBackups[key];
  local profile = details:GetCurrentProfileName();
  profiles[profile] = profiles[profile] or {};
  return profiles[profile];
end
local controller = {};
function controller:SetEnabled(enabled)
  if (not ready or _G.InCombatLockdown()) then
    tk:Print(L["Details styling can only be changed outside combat after login."]); return false;
  end
  local details = _G.Details;
  if (not RegisterSkin() or not details.GetCurrentProfileName or not details.instance_skin_ignored_values) then
    tk:Print(L["MUI Details skin is unavailable. Load Details first."]); return false;
  end
  local backups = Backups(details);
  local restored = true;
  for _, instance in _G.pairs(details:GetAllInstances()) do
    if (instance.baseframe and instance.ChangeSkin and instance.ExportSkin and instance.ApplySavedSkin) then
      local id = instance.meu_id;
      if (enabled and not IsMuiSkin(instance.skin)) then
        local snapshot = instance:ExportSkin();
        -- Restoring appearance must not undo subsequent movement or behavior changes.
        snapshot.posicao = nil;
        for key in _G.pairs(details.instance_skin_ignored_values) do snapshot[key] = nil; end
        backups[id] = Copy(snapshot);
        instance:ChangeSkin(skinName);
      elseif (not enabled and IsMuiSkin(instance.skin)) then
        local snapshot = backups[id];
        if (snapshot) then
          -- ApplySavedSkin expects a position when Details' position-export option is enabled.
          local saved = Copy(snapshot);
          if (details.profile_save_pos) then saved.posicao = instance.posicao; end
          instance:ApplySavedSkin(saved);
          backups[id] = nil;
        else
          restored = false;
          tk:Print(L["Choose another skin in Details to change this window's appearance."]);
        end
      end
    end
  end
  return restored;
end
MayronUI:AddComponent("ForeverDetailsStyle", controller);
MayronUI:Hook("CoreModule", "OnInitialized", function()
  ready = true;
  local watcher = _G.CreateFrame("Frame");
  watcher:RegisterEvent("PLAYER_REGEN_ENABLED"); watcher:RegisterEvent("ADDON_LOADED");
  watcher:SetScript("OnEvent", function() if (not _G.InCombatLockdown()) then RegisterSkin(); end end);
  watcher:SetScript("OnUpdate", function(_, elapsed)
    if (registered or _G.InCombatLockdown()) then return end
    elapsedTotal = elapsedTotal + elapsed;
    if (elapsedTotal >= 1) then elapsedTotal = 0; RegisterSkin(); end
  end);
  if (not _G.InCombatLockdown()) then RegisterSkin(); end
end);
_G.SLASH_MUIDETAILSSTYLE1 = "/muidetails";
_G.SlashCmdList.MUIDETAILSSTYLE = function(message)
  local option = _G.strtrim(message or ""):lower();
  if (option ~= "on" and option ~= "off") then
    tk:Print(L["Details appearance: /muidetails on or /muidetails off."]); return;
  end
  if (controller:SetEnabled(option == "on")) then
    tk:Print(L[option == "on" and "MUI Details styling enabled (requires Details)." or "MUI Details styling disabled."]);
  end
end;
