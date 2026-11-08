-- Targeted Forever font restoration. Never edit shared Blizzard Font objects.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db = MayronUI:GetCoreComponents();
if (not tk:IsForever()) then return end

local ready = false;
local elapsedTotal = 0;
local originals = {};
local frameNames = { "CharacterFrame", "SpellBookFrame", "PlayerSpellsFrame" };

local function ReadFont(region)
  local file, size, flags = region:GetFont();
  if (_G.issecretvalue and (_G.issecretvalue(file) or _G.issecretvalue(size) or _G.issecretvalue(flags))) then return end
  if (_G.type(file) ~= "string" or _G.type(size) ~= "number") then return end
  return file, size, flags or "";
end

local function Restore()
  for region, font in _G.pairs(originals) do
    region:SetFont(font[1], font[2], font[3]);
  end
  originals = {};
end

local function ApplyToRegions(frame, masterFont)
  if (not frame or not frame.GetRegions) then return end
  for _, region in _G.ipairs({ frame:GetRegions() }) do
    -- FontString:SetFont gives this string its own font; no SetFont on Font objects.
    if (region:IsObjectType("FontString")) then
      local file, size, flags = ReadFont(region);
      if (file and file ~= masterFont) then
        if (not originals[region]) then originals[region] = { file, size, flags }; end
        region:SetFont(masterFont, size, flags);
      end
    end
  end
end

local function Refresh()
  if (not ready or _G.InCombatLockdown()) then return end
  local settings = db.global.core.fonts;
  if (not settings.useMasterFont) then Restore(); return end
  local masterFont = tk.Constants.LSM:Fetch("font", settings.master, true);
  if (not masterFont) then return end
  for _, name in _G.ipairs(frameNames) do
    local frame = _G[name];
    if (frame and frame:IsVisible()) then
      -- Only headings owned directly by the window and its standard title container.
      -- No recursion into spell buttons, equipment slots, tooltips or unit frames.
      ApplyToRegions(frame, masterFont);
      ApplyToRegions(frame.TitleContainer, masterFont);
    end
  end
end

local events = _G.CreateFrame("Frame");
events:RegisterEvent("ADDON_LOADED");
events:RegisterEvent("PLAYER_REGEN_ENABLED");
events:SetScript("OnEvent", Refresh);
events:SetScript("OnUpdate", function(_, elapsed)
  if (not ready or _G.InCombatLockdown()) then return end
  elapsedTotal = elapsedTotal + elapsed;
  if (elapsedTotal >= 0.25) then elapsedTotal = 0; Refresh(); end
end);
MayronUI:Hook("CoreModule", "OnInitialized", function()
  ready = true;
  Refresh();
end);
