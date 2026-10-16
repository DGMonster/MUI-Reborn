-- luacheck: ignore MayronUI self 143
-- Setup namespaces ------------------
local _G = _G
local MayronUI = _G.MayronUI
local tk, _, _, gui = MayronUI:GetCoreComponents()

local _, C_ChatModule = MayronUI:ImportModule("ChatModule")
local CompactRaidFrameManager, GetNumGroupMembers = _G.CompactRaidFrameManager, _G.GetNumGroupMembers
local IsAddOnLoaded = _G.IsAddOnLoaded
local radians = _G.math.rad
--------------------------------------

local function OnArrowButtonEvent(self)
  if not IsAddOnLoaded("Blizzard_CompactRaidFrames") then
    return
  end

  local inGroup = (GetNumGroupMembers() or 0) > 0
  self:SetShown(inGroup)
end

local function OnArrowButtonClick(self)
  -- toggle compact raid frame manager
  if self.displayFrame and self.displayFrame:IsVisible() then
    self.displayFrame:Hide()
    self.icon:SetRotation(radians(-90))
  elseif self.displayFrame then
    self.displayFrame:Show()
    self.icon:SetRotation(radians(90))
  end

  if self.displayFrame and CompactRaidFrameManager then
    self.displayFrame:SetWidth(CompactRaidFrameManager:GetWidth())
    self.displayFrame:SetHeight(CompactRaidFrameManager:GetHeight())
  end
end

local function OnArrowButtonEnter(self)
  local r, g, b = self.icon:GetVertexColor()
  self.icon:SetVertexColor(r * 1.2, g * 1.2, b * 1.2)

  if self.showOnMouseOver then
    self:SetAlpha(1)
  end
end

local function OnArrowButtonLeave(self)
  tk:ApplyThemeColor(self.icon)
  if self.showOnMouseOver then
    self:SetAlpha(0)
  end
end

-- Helper to safely disable/hide textures/frames that may not exist in newer clients
local function KillTexture(obj)
  if obj and obj.SetTexture then
    obj:SetTexture("")
    obj.SetTexture = tk.Constants.DUMMY_FUNC
  end
end

local function KillShow(obj)
  if obj then
    obj:Hide()
    obj:SetAlpha(0)
    if obj.EnableMouse then obj:EnableMouse(false) end
    -- NICHT: obj.Show = ...
  end
end

function C_ChatModule:SetUpRaidFrameManager(data)
	-- The Retail compact raid manager and its children are protected. Reparenting,
	-- hiding, or reskinning them taints the frame; Blizzard later calls
	-- Frame:RegisterEvent() on it and blocks the action. Leave the manager fully
	-- under Blizzard's control on Retail 12.1. SUF raid frames remain available.
	if tk:IsRetail() then
		data.raidFrameManager = false
		return
	end

  if not CompactRaidFrameManager then
    return
  end

  -- Hide Blizzard Compact Manager visuals (safe guards)
  if CompactRaidFrameManager.DisableDrawLayer then
    CompactRaidFrameManager:DisableDrawLayer("ARTWORK")
  end
  if CompactRaidFrameManager.EnableMouse then
    CompactRaidFrameManager:EnableMouse(false)
  end
  if CompactRaidFrameManager.toggleButton then
    tk:KillElement(CompactRaidFrameManager.toggleButton)
  end

  -- Retail: these globals can be missing or renamed; guard everything:
  KillTexture(_G.CompactRaidFrameManagerDisplayFrameHeaderDelineator)
  KillTexture(_G.CompactRaidFrameManagerDisplayFrameFilterOptionsFooterDelineator)
  KillShow(_G.CompactRaidFrameManagerDisplayFrameHeaderBackground)

  -- Also attempt to find equivalents on the displayFrame (future-proof)
  local df = CompactRaidFrameManager.displayFrame
  if df then
    -- common candidates across versions:
    KillTexture(df.HeaderDelineator)
    KillTexture(df.FilterOptionsFooterDelineator)
    KillShow(df.HeaderBackground)

    -- some versions nest under Header / FilterOptions:
    if df.Header then
      KillTexture(df.Header.Delineator)
      KillShow(df.Header.Background)
    end
    if df.FilterOptions then
      KillTexture(df.FilterOptions.FooterDelineator)
    end
  end

  -- button to toggle compact raid frame manager
  local btn = tk:CreateFrame("Button", nil, "MUI_RaidFrameManagerButton")

  btn:SetSize(15, 100)
  btn:SetPoint("LEFT")
  btn:SetNormalTexture(tk:GetAssetFilePath("Textures\\SideBar\\SideButton"))
  btn:GetNormalTexture():SetTexCoord(1, 0, 0, 1)

  btn.icon = btn:CreateTexture(nil, "OVERLAY")
  btn.icon:SetSize(12, 8)
  btn.icon:SetPoint("CENTER")
  btn.icon:SetTexture(tk:GetAssetFilePath("Icons\\arrow"))
  btn.icon:SetRotation(radians(-90))
  tk:ApplyThemeColor(btn.icon)

  btn:RegisterEvent("ADDON_LOADED")
  btn:RegisterEvent("GROUP_ROSTER_UPDATE")
  btn:RegisterEvent("PLAYER_ENTERING_WORLD")

  btn:SetScript("OnClick", OnArrowButtonClick)
  btn:SetScript("OnEvent", OnArrowButtonEvent)
  btn:SetScript("OnEnter", OnArrowButtonEnter)
  btn:SetScript("OnLeave", OnArrowButtonLeave)

  -- Attach the Blizzard display frame to our button
  btn.displayFrame = df
  if btn.displayFrame then
    btn.displayFrame:SetParent(btn)
    btn.displayFrame:ClearAllPoints()
    btn.displayFrame:SetPoint("TOPLEFT", btn, "TOPRIGHT", 5, 0)

    gui:AddDialogTexture(btn.displayFrame)
    tk:MakeMovable(btn.displayFrame)
  end

  OnArrowButtonEvent(btn)
  data.raidFrameManager = true
end
