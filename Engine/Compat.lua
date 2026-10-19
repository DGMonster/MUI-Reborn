-- MUI-Reborn/Engine/Compat.lua
-- Central compatibility layer for Retail/Classic API differences.

_G.MUI_COMPAT_ACTIVE = true

-- Keep the runtime addon identifier in one place. The public addon folder and
-- TOC use a hyphen (MUI-Reborn); SavedVariables and localization keys keep
-- their existing underscore names for backwards compatibility.
local addonName = ...
_G.MUI_REBORN_ADDON_NAME = addonName or "MUI-Reborn"


local _G = _G

-- =========================
-- C_AddOns (Retail)
-- =========================
if C_AddOns then
  _G.IsAddOnLoaded       = _G.IsAddOnLoaded       or C_AddOns.IsAddOnLoaded
  _G.LoadAddOn           = _G.LoadAddOn           or C_AddOns.LoadAddOn
  _G.GetAddOnEnableState = _G.GetAddOnEnableState or C_AddOns.GetAddOnEnableState
  _G.EnableAddOn         = _G.EnableAddOn         or C_AddOns.EnableAddOn
  _G.DisableAddOn        = _G.DisableAddOn        or C_AddOns.DisableAddOn

  _G.GetAddOnMetadata    = _G.GetAddOnMetadata    or C_AddOns.GetAddOnMetadata
  _G.GetAddOnInfo        = _G.GetAddOnInfo        or C_AddOns.GetAddOnInfo
  _G.GetNumAddOns        = _G.GetNumAddOns        or C_AddOns.GetNumAddOns
end

-- =========================
-- GetSpellInfo (Retail)
-- =========================
if not _G.GetSpellInfo and C_Spell and C_Spell.GetSpellInfo then
  _G.GetSpellInfo = function(spellID)
    local info = C_Spell.GetSpellInfo(spellID)
    if not info then return nil end
    -- old signature: name, rank, icon, castTime, minRange, maxRange, spellId
    return info.name, nil, info.iconID, nil, nil, nil, info.spellID or spellID
  end
end

-- =========================
-- GetItemInfoInstant (Forever)
-- =========================
-- Forever exposes the modern C_Item method but not the legacy global used by
-- the inventory module.
if not _G.GetItemInfoInstant and C_Item and C_Item.GetItemInfoInstant then
  _G.GetItemInfoInstant = function(itemInfo)
    return C_Item.GetItemInfoInstant(itemInfo)
  end
end

-- =========================
-- FillLocalizedClassList (Retail)
-- =========================
if not _G.FillLocalizedClassList then
  _G.FillLocalizedClassList = function(tbl, female)
    if type(tbl) ~= "table" then return end

    if C_CreatureInfo and C_CreatureInfo.GetClassInfo then
      for classID = 1, 20 do
        local info = C_CreatureInfo.GetClassInfo(classID)
        if info and info.classFile then
          tbl[info.classFile] = info.className
        end
      end
      return
    end

    local src = (female and _G.LOCALIZED_CLASS_NAMES_FEMALE) or _G.LOCALIZED_CLASS_NAMES_MALE
    if type(src) == "table" then
      for classFile, className in pairs(src) do
        tbl[classFile] = className
      end
    end
  end
end
-- =========================
-- Reputation / Watched faction (Retail)
-- =========================
if not _G.GetWatchedFactionInfo then
  _G.GetWatchedFactionInfo = function()
    if not C_Reputation or not C_Reputation.GetWatchedFactionData then
      return nil
    end

    local data = C_Reputation.GetWatchedFactionData()
    if not data then
      return nil
    end

    -- Old GetWatchedFactionInfo signature:
    -- name, standingID, min, max, value, factionID
    local name = data.name
    local standingID = data.reaction
    local min = data.currentReactionThreshold
    local max = data.nextReactionThreshold
    local value = data.currentStanding
    local factionID = data.factionID

    return name, standingID, min, max, value, factionID
  end
end
-- =========================
-- Error handling (Retail)
-- =========================
-- Provide HandleLuaError if missing.
-- Ensures ScriptErrorsFrame shows text and avoids recursion/stack overflow.
if not _G.HandleLuaError then
  local handling

  local function showScriptError(msg)
    local f = _G.ScriptErrorsFrame
    if not f then return false end

    if f.Show then
      f:Show()
    end

    -- Most reliable on modern Retail:
    if f.DisplayMessage then
      f:DisplayMessage(msg)
      return true
    end

    -- Alternative internal method (some builds):
    if f.DisplayMessageInternal then
      f:DisplayMessageInternal(msg)
      return true
    end

    -- Fallback:
    if f.OnError then
      f:OnError(msg, "", "")
      return true
    end

    return false
  end

  _G.HandleLuaError = function(message, stack)
    -- Prevent recursive error handling
    if handling then return end
    handling = true

    local msg = tostring(message or "")
    if msg == "" then
      msg = "Lua error (no message provided)."
    end

    if stack and stack ~= "" then
      msg = msg .. "\n" .. tostring(stack)
    else
      -- Ensure we always have a stack trace
      if _G.debugstack then
        msg = msg .. "\n" .. _G.debugstack(3, 30, 30)
      end
    end

    local ok = pcall(function()
      showScriptError(msg)
    end)

    handling = false

    -- Absolute last resort (should almost never happen)
    if not ok then
      if _G.DEFAULT_CHAT_FRAME and _G.DEFAULT_CHAT_FRAME.AddMessage then
        _G.DEFAULT_CHAT_FRAME:AddMessage("|cffff3333[MUI Error]|r " .. msg)
      else
        print("[MUI Error] " .. msg)
      end
    end
  end
end
-- =========================
-- Auras (Retail)
-- =========================
-- UnitAura was replaced by C_UnitAuras in modern Retail.
if not _G.UnitAura and C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
_G.UnitAura = function(unit, index, filter)
  -- Guard: UnitAura soll bei ungültigen Units einfach nil liefern (wie früher auch)
  if type(unit) ~= "string" or not UnitExists(unit) then
    return nil
  end

  local aura = C_UnitAuras.GetAuraDataByIndex(unit, index, filter)
  if not aura then return nil end

  return aura.name,
    aura.icon,
    aura.applications or 0,
    aura.dispelName,
    aura.duration or 0,
    aura.expirationTime or 0,
    aura.sourceUnit,
    aura.isStealable,
    aura.nameplateShowPersonal,
    aura.spellId,
    aura.canApplyAura,
    aura.isBossAura,
    aura.isFromPlayerOrPlayerPet,
    aura.nameplateShowAll,
    aura.timeMod
 end
end
if not _G.UnitBuff then _G.UnitBuff = function(unit, index, filter) return _G.UnitAura(unit, index, filter or "HELPFUL") end end
if not _G.UnitDebuff then _G.UnitDebuff = function(unit, index, filter) return _G.UnitAura(unit, index, filter or "HARMFUL") end end
-- ==================================================
-- Toolkit frame helpers fallback (load-order safe)
-- ==================================================
do
  local _G = _G
  local MayronUI = _G.MayronUI
  if MayronUI and MayronUI.GetCoreComponents then
    local tk = MayronUI:GetCoreComponents()

    -- Only define if missing (so Widgets.lua can still override later)
    if tk and not tk.CreateFrame then
      function tk:CreateFrame(frameType, parent, globalName, templates)
        local ftype = frameType or "Frame"
        local par = parent or _G.UIParent

        -- Try normal CreateFrame first:
        local ok, frameOrErr = pcall(_G.CreateFrame, ftype, globalName, par, templates)
        if not ok or not frameOrErr then
          local errMsg = tostring(frameOrErr)

          -- Retry if template doesn't exist (e.g. UIMenuTemplate removed in Retail)
          if type(templates) == "string" and errMsg:find("Couldn't find inherited node") then
            local t = templates:gsub("UIMenuTemplate", "")
            t = t:gsub("%s*,%s*", ",")
            t = t:gsub("^,+", ""):gsub(",+$", "")
            t = t:gsub("^%s+", ""):gsub("%s+$", "")
            if t == "" then t = nil end

            local ok2, frame2 = pcall(_G.CreateFrame, ftype, globalName, par, t)
            if ok2 and frame2 then
              frameOrErr = frame2
            else
              error(frameOrErr)
            end
          else
            error(frameOrErr)
          end
        end

        frameOrErr:ClearAllPoints()
        frameOrErr:Show()
        return frameOrErr
      end
    end

    if tk and not tk.CreateBackdropFrame then
      function tk:CreateBackdropFrame(frameType, parent, globalName, templates)
        if _G.BackdropTemplateMixin then
          if templates then
            templates = templates .. ", BackdropTemplate"
          else
            templates = "BackdropTemplate"
          end
        end

        local frame = tk:CreateFrame(frameType, parent, globalName, templates)
        frame:ClearAllPoints()
        frame:Show()
        return frame
      end
    end
  end
end
-- ==================================================
-- Legacy UIMenu compatibility (Retail)
-- UIMenuTemplate / UIMenu_Initialize removed in modern Retail.
-- This provides a minimal drop-down style menu MUI can use.
-- ==================================================
do
  if not _G.UIMenu_Initialize then
    local function EnsureBackdrop(frame)
      if frame and frame.SetBackdrop and tk and tk.Constants and tk.Constants.BACKDROP then
        frame:SetBackdrop(tk.Constants.BACKDROP)
        frame:SetBackdropBorderColor(0, 0, 0)
        frame:SetBackdropColor(0, 0, 0, 0.85)
      end
    end

    -- Very small menu builder: expects `initFunc(self, level)` to create buttons
    -- via `_G.UIMenu_AddButton(info, level)`.
    local currentMenu
    local buttonsByLevel = {}

    _G.UIMenu_CreateInfo = _G.UIMenu_CreateInfo or function()
      return {}
    end

    _G.UIMenu_AddButton = _G.UIMenu_AddButton or function(info, level, shortcut, func, nested, value)
      -- MUI's chat sidebar still uses the older positional signature:
      -- UIMenu_AddButton(menu, text, shortcut, func, nested, value).
      if info and info.GetObjectType then
        local menuFrame = info
        local buttonText = level or ""
        local menuButtons = menuFrame.MUICompatButtons

        if not menuButtons then
          menuButtons = {}
          menuFrame.MUICompatButtons = menuButtons
        end

        local btn = CreateFrame("Button", nil, menuFrame, "UIPanelButtonTemplate")
        btn:SetHeight(20)
        btn:SetText(buttonText)
        btn:SetNormalFontObject("GameFontHighlightSmall")
        btn:SetHighlightFontObject("GameFontHighlightSmall")
        btn.value = value

        local previous = menuButtons[#menuButtons]
        btn:ClearAllPoints()
        if previous then
          btn:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -4)
          btn:SetPoint("TOPRIGHT", previous, "BOTTOMRIGHT", 0, -4)
        else
          btn:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 10, -10)
          btn:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", -10, -10)
        end

        btn:SetScript("OnClick", function(self)
          if type(func) == "function" then
            func(self)
          end
          menuFrame:Hide()
        end)

        table.insert(menuButtons, btn)
        btn:Show()
        return btn
      end

      level = level or 1
      if not currentMenu then return end

      local menuFrame = currentMenu

      buttonsByLevel[level] = buttonsByLevel[level] or {}

      local btn = CreateFrame("Button", nil, menuFrame, "UIPanelButtonTemplate")
      btn:SetHeight(18)
      btn:SetText(info.text or "")
      btn:SetNormalFontObject("GameFontHighlightSmall")
      btn:SetHighlightFontObject("GameFontHighlightSmall")

      btn:SetScript("OnClick", function()
        if type(info.func) == "function" then
          info.func(info.arg1, info.arg2, info.checked)
        end
        menuFrame:Hide()
      end)

      table.insert(buttonsByLevel[level], btn)
    end

    _G.UIMenu_Initialize = function(menuFrame, initFunc, displayMode, level)
      level = level or 1
      currentMenu = menuFrame

      -- clear previous
      for _, levelBtns in pairs(buttonsByLevel) do
        for _, b in ipairs(levelBtns) do
          if b and b.Hide then b:Hide() end
        end
      end
      buttonsByLevel = {}

      menuFrame:SetFrameStrata("DIALOG")
      menuFrame:SetFrameLevel(100)
      menuFrame:EnableMouse(true)
      menuFrame:SetClampedToScreen(true)

      EnsureBackdrop(menuFrame)

      -- Let caller add buttons
      if type(initFunc) == "function" then
        initFunc(menuFrame, level)
      end

      -- layout buttons
      local btns = buttonsByLevel[level] or {}
      local width = 140
      local height = 12

      local prev
      for i, b in ipairs(btns) do
        b:ClearAllPoints()
        if not prev then
          b:SetPoint("TOPLEFT", menuFrame, "TOPLEFT", 10, -10)
          b:SetPoint("TOPRIGHT", menuFrame, "TOPRIGHT", -10, -10)
        else
          b:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -4)
          b:SetPoint("TOPRIGHT", prev, "BOTTOMRIGHT", 0, -4)
        end
        b:Show()
        prev = b

        width = math.max(width, (b:GetTextWidth() or 0) + 40)
        height = height + b:GetHeight() + 4
      end

      menuFrame:SetSize(width, height)
      menuFrame:Show()

      currentMenu = nil
    end
  end
end
-- ==================================================
-- Legacy UIMenu_AutoSize compatibility (Retail)
-- ==================================================
if not _G.UIMenu_AutoSize then
  _G.UIMenu_AutoSize = function(menuFrame)
    if not menuFrame or not menuFrame.GetChildren then
      return
    end

    local maxWidth = 120
    local totalHeight = 20

    for _, child in ipairs({ menuFrame:GetChildren() }) do
      if child:IsShown() and child.GetText then
        local w = (child.GetTextWidth and child:GetTextWidth()) or 0
        maxWidth = math.max(maxWidth, w + 40)
        totalHeight = totalHeight + (child:GetHeight() or 18) + 4
      end
    end

    menuFrame:SetSize(maxWidth, totalHeight)
  end
end
function _G.MUI_LoadLandingPage()
  if _G.ExpansionLandingPage or _G.GarrisonLandingPage then
    return true
  end

  if _G.C_AddOns and _G.C_AddOns.LoadAddOn then
    _G.C_AddOns.LoadAddOn("Blizzard_ExpansionLandingPage")
    _G.C_AddOns.LoadAddOn("Blizzard_GarrisonUI")
  elseif _G.UIParentLoadAddOn then
    _G.UIParentLoadAddOn("Blizzard_ExpansionLandingPage")
    _G.UIParentLoadAddOn("Blizzard_GarrisonUI")
  end

  return (_G.ExpansionLandingPage or _G.GarrisonLandingPage) ~= nil
end
function _G.MUI_GetMissionMinimapButton()
  return _G.ExpansionLandingPageMinimapButton
      or _G.GarrisonLandingPageMinimapButton
end
function _G.MUI_CanViewMissions()
  if not C_Garrison or not C_Garrison.GetLandingPageGarrisonType then
    return false
  end

  local btn = _G.MUI_GetMissionMinimapButton()
  if not btn then
    return false
  end

  local garrisonType = C_Garrison.GetLandingPageGarrisonType()

  -- Covenant / SL style
  if btn.garrisonMode then
    if not C_Covenants
      or not C_Covenants.GetActiveCovenantID
      or not C_Covenants.GetCovenantData then
      return false
    end

    return C_Covenants.GetCovenantData(
      C_Covenants.GetActiveCovenantID()
    ) ~= nil
  end

  -- Modern Retail (DF / TWW)
  if not _G.MUI_LoadLandingPage() then
    return false
  end

  local page = _G.ExpansionLandingPage or _G.GarrisonLandingPage
  if not page or not page.GetOverlayMinimapDisplayInfo then
    return false
  end

  return page:GetOverlayMinimapDisplayInfo() ~= nil
end





