   function gadget:GetInfo()
      return {
        name      = "Sound Defs Loader",
        desc      = "Loads sound defs",
        author    = "raaar",
        date      = "2022",
        license   = "PD",
        layer     = math.huge,
        enabled   = true,
      }
    end


if (not gadgetHandler:IsSyncedCode()) then
  return
end

function gadget:Initialize()
	Spring.LoadSoundDef("LuaRules/Configs/sound_defs.lua")
end
