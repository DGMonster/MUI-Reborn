-- Optional Forever preset: apply the registered MUI skin through Details itself.
local _, setup = ...;
local MayronUI = _G.MayronUI;
local tk = MayronUI:GetCoreComponents();
if (not tk:IsForever()) then return end
setup.import["Details"] = function()
  if (MayronUI:GetComponent("ForeverDetailsStyle"):SetEnabled(true)) then return 1 end
end;
