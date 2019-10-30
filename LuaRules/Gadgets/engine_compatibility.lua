function gadget:GetInfo()
   return {
      name = "Engine compatibility",
      desc = "Shows warning if spring engine version is not supported",
      author = "raaar",
      date = "2018",
      license = "PD",
      layer = 999999,
      enabled = true,
   }
end


local showWarningMessage = 0
local currentEngineVersion = "???"
local recommendedEngineVersion = "104.0.1-1429-g1add37c maintenanc"

--SYNCED CODE
if (gadgetHandler:IsSyncedCode()) then

function gadget:Initialize()
	if (Engine and Engine.version) then
		currentEngineVersion = Engine.version
	elseif (Game and Game.version) then
		currentEngineVersion = Game.version
	end
	
	if (not string.find(currentEngineVersion,"104.0.1-1")) or (not string.find(currentEngineVersion,"maintenance"))   then
		showWarningMessage = 1
	end 
end



function gadget:GameFrame(n) 
	if (n%16) == 0 then
		if (showWarningMessage == 1) then
			Spring.Echo("---------------------------------------------\nWARNING : unsupported Spring Engine version detected ("..currentEngineVersion.."). Use Spring "..recommendedEngineVersion.. " or later instead.\nGet the latest recommended engine and game versions by joining the MF rooms on the official server.")
			showWarningMessage = 0
			gadgetHandler:RemoveGadget()
		end	
	end
end

end


