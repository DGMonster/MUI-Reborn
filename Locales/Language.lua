local _, addon = ...;
local _G = _G;
local aceLocale = _G.LibStub("AceLocale-3.0");

addon.muiLanguages = {
  enUS = "English";
  deDE = "Deutsch";
  frFR = "Français";
  itIT = "Italiano";
  esES = "Español (España)";
  zhCN = "简体中文";
  ptBR = "Português (Brasil)";
  ruRU = "Русский";
  koKR = "한국어";
  zhTW = "繁體中文";
  esMX = "Español (Latinoamérica)";
};

function addon.NormalizeMuiLanguage(value)
  return type(value) == "string" and addon.muiLanguages[value] and value or "client";
end

local saved = _G.MayronUIdb;
local global = type(saved) == "table" and saved.global;
local core = type(global) == "table" and global.core;
local selected = addon.NormalizeMuiLanguage(type(core) == "table" and core.language);

local shortcutKeys = {
  Character = true; Bags = true; Friends = true; Guild = true; ["Help Menu"] = true;
  PVP = true; ["Spell Book"] = true; Talents = true; Achievements = true; Calendar = true;
  LFD = true; LFG = true; Raid = true; ["Encounter Journal"] = true;
  ["Collections Journal"] = true; Macros = true; ["World Map"] = true;
  ["Quest Log"] = true; Reputation = true; ["PVP Score"] = true; Currency = true;
  Glyphs = true; Skills = true;
};
local shortcutAliases = {};

function addon.RegisterMuiLocale(locale)
  local destination;
  local manual = selected ~= "client" and selected == locale and locale ~= "enUS";
  if (locale == "enUS" or selected == "client") then
    destination = aceLocale:NewLocale("MayronUI", locale, locale == "enUS");
  elseif (manual) then
    destination = aceLocale:GetLocale("MayronUI");
  end

  return setmetatable({}, {
    __newindex = function(_, key, value)
      if (shortcutKeys[key]) then
        local label = value == true and key or value;
        if (type(label) == "string") then
          local aliases = shortcutAliases[label] or {};
          aliases[key] = true;
          shortcutAliases[label] = aliases;
        end
      end

      if (manual) then
        rawset(destination, key, value == true and key or value);
      elseif (destination) then
        destination[key] = value;
      end
    end;
  });
end

function addon.LocalizeChatShortcut(label, available)
  local aliases = shortcutAliases[label];
  if (not aliases) then return label end

  local translations = aceLocale:GetLocale("MayronUI");
  local translated;
  for key in pairs(aliases) do
    local current = translations[key];
    for _, option in ipairs(available) do
      if (option == label) then return label end
      if (option == current) then translated = current; end
    end
  end
  return translated or label;
end
