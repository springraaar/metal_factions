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
local refMajorStr="2025"
local refMinorStr="06"
local refPatchSetStr="20"
local refMajor=tonumber(refMajorStr)
local refMinor=tonumber(refMinorStr)
local refPatchSet=tonumber(refPatchSetStr)

--UNSYNCED CODE
if not (gadgetHandler:IsSyncedCode()) then

function gadget:Initialize()
	--for k,v in pairs(Engine) do
	--	Spring.Echo("Engine."..k.."="..tostring(v))	
	--end
	
	local curMajor = tonumber(Engine.versionMajor)
	local curMinor = tonumber(Engine.versionMinor)
	local curPatchSet = tonumber(Engine.versionPatchSet)
	
	if (curMajor > refMajor)
		or
		(curMajor == refMajor and curMinor > refMinor)
		or 
		(curMajor == refMajor and curMinor == refMinor and curPatchSet >= refPatchSet)
	then
		-- should work fine
	else
		showWarningMessage = 1
	end 
end



function gadget:GameFrame(n) 
	if (n%16) == 0 then
		if (showWarningMessage == 1) then
			Spring.Echo("---------------------------------------------\nWARNING : unsupported engine version detected ("..Engine.versionFull.."). Use Recoil "..refMajorStr.."."..refMinorStr.."."..refPatchSetStr.. " or later instead.\nGet the latest recommended engine and game versions by joining the MF rooms on the official server.")
			showWarningMessage = 0
			gadgetHandler:RemoveGadget()
		end	
	end
end

end


