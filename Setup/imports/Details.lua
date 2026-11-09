-- Optional preset: apply the registered MUI skin through Details itself.
local _, setup = ...;
local MayronUI = _G.MayronUI;
setup.import["Details"] = function()
  if (MayronUI:GetComponent("ForeverDetailsStyle"):SetEnabled(true)) then return 1 end
end;
