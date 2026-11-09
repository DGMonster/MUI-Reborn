-- Character-owned integration profiles. Existing shared profiles are never removed.
local _G = _G;
local MayronUI = _G.MayronUI;
local tk, db = MayronUI:GetCoreComponents();
local supported = { ShadowUF = true; Bartender4 = true };

local function Copy(value)
  if (type(value) ~= "table") then return value end
  local result = {};
  for key, child in pairs(value) do result[key] = Copy(child); end
  return result;
end
local function Registry(addonName)
  local sv = _G.MayronUIdb;
  sv.global.characterAddonProfiles = sv.global.characterAddonProfiles or {};
  local characters = sv.global.characterAddonProfiles;
  local key = tk:GetPlayerKey();
  characters[key] = characters[key] or {};
  characters[key][addonName] = characters[key][addonName] or {};
  return characters[key][addonName];
end
local function Truncate(text, limit)
  while (limit > 0) do
    local nextByte = text:byte(limit + 1);
    if (not nextByte or nextByte < 128 or nextByte >= 192) then break end
    limit = limit - 1;
  end
  return text:sub(1, limit);
end
local function ProfileName(playerKey, source)
  local full = "MUI-" .. playerKey .. ":" .. source;
  if (#full <= 50) then return full end
  local hash = 5381;
  for index = 1, #full do hash = (hash * 33 + full:byte(index)) % 4294967296; end
  return Truncate(full, 41) .. ":" .. string.format("%08x", hash);
end
local function Exists(database, name)
  for _, candidate in ipairs(database:GetProfiles()) do
    if (candidate == name) then return true end
  end
  return false;
end

local function ResolveCharacterProfile(addonName, database, source)
  if (not db.global.core.setup.profilePerCharacter) then
    return source or database:GetCurrentProfile();
  end
  if (_G.InCombatLockdown()) then error("Character profiles must be selected outside combat."); end
  local mappings = Registry(addonName);
  -- A layout may already contain this character's resolved profile name.
  for _, destination in pairs(mappings) do
    if (destination == source) then return destination end
  end
  local destination = mappings[source];
  if (destination and Exists(database, destination)) then return destination end
  destination = ProfileName(tk:GetPlayerKey(), source);
  local base, suffix = destination, 1;
  while (Exists(database, destination)) do
    suffix = suffix + 1;
    local tail = ":" .. suffix;
    destination = Truncate(base, 50 - #tail) .. tail;
  end
  return destination, mappings;
end

function MayronUI:GetCharacterAddonProfile(addonName, source)
  if (not supported[addonName]) then return source end
  local database = tk.Tables:GetDBObject(addonName);
  if (not database) then return source end
  source = source or database:GetCurrentProfile();
  local destination, mappings = ResolveCharacterProfile(addonName, database, source);
  if (not mappings) then return destination end

  local previous = database:GetCurrentProfile();
  local canCopy = Exists(database, source);
  database:SetProfile(destination);
  local success, message = pcall(function()
    if (canCopy) then database:CopyProfile(source); end
  end);
  if (not success) then
    database:SetProfile(previous);
    error(message);
  end
  mappings[source] = destination;
  return destination;
end

function MayronUI:EnsureCharacterProfiles()
  if (not db.global.core.setup.profilePerCharacter) then return end
  if (_G.InCombatLockdown()) then error("Character profiles require leaving combat first."); end
  local key = tk:GetPlayerKey();
  local current = db:GetCurrentProfile();
  local sv = _G.MayronUIdb;
  if (current ~= key) then
    if (not sv.profiles[key]) then
      sv.profiles[key] = Copy(sv.profiles[current] or {});
      local marker = sv.appended and sv.appended["profile." .. current];
      if (marker) then sv.appended["profile." .. key] = Copy(marker); end
    end
    db:SetProfile(key);
  end
  for addonName in pairs(supported) do
    local database = tk.Tables:GetDBObject(addonName);
    if (database) then
      local destination = self:GetCharacterAddonProfile(addonName);
      if (database:GetCurrentProfile() ~= destination) then database:SetProfile(destination); end
    end
  end
end

-- Installer-only: write the preset into this character's profile tables in place.
-- Preserve global options, other profiles, profileKeys and unloaded namespaces.
function MayronUI:InstallCharacterAddonPreset(addonName, settings)
  local database = tk.Tables:GetDBObject(addonName);
  assert(database and supported[addonName], "Missing character-profile database: " .. addonName);
  local previous = database:GetCurrentProfile();
  local selected;
  local function ApplyPreset(target, source)
    for key, value in pairs(source) do
      if (type(value) == "table" and type(target[key]) == "table") then
        ApplyPreset(target[key], value);
      else
        target[key] = Copy(value);
      end
    end
  end
  local function Fill(target, source, activeDatabase)
    if (activeDatabase) then
      -- Keep AceDB defaults for live addon configs until the installer reloads.
      activeDatabase:ResetProfile(true, true);
    else
      for key in pairs(target) do target[key] = nil; end
    end
    ApplyPreset(target, source);
  end
  for source, preset in pairs(settings.profiles or {}) do
    local destination, mappings = ResolveCharacterProfile(addonName, database, source);
    if (source == "MayronUI") then selected = destination; end
    local active = database:GetCurrentProfile() == destination;
    local profiles = database.profiles;
    -- Stage inactive presets before notifying the addon of a profile change.
    if (not active) then profiles[destination] = profiles[destination] or {}; end
    local target = active and database.profile or profiles[destination];
    Fill(target, preset, active and database);
    for namespace, data in pairs(settings.namespaces or {}) do
      local values = data.profiles and data.profiles[source];
      if (values) then
        database.sv.namespaces = database.sv.namespaces or {};
        local saved = database.sv.namespaces;
        saved[namespace] = saved[namespace] or { profiles = {} };
        saved[namespace].profiles = saved[namespace].profiles or {};
        local profiles = saved[namespace].profiles;
        profiles[destination] = profiles[destination] or {};
        local activeNamespace = active and database:GetNamespace(namespace, true);
        local namespaceProfile = activeNamespace and activeNamespace.profile or profiles[destination];
        Fill(namespaceProfile, values, activeNamespace);
      end
    end
    if (mappings) then mappings[source] = destination; end
  end
  database:SetProfile(selected or previous);
end
