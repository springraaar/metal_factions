function gadget:GetInfo()
   return {
      name = "Map Feature Checker",
      desc = "Removes unsupported features from the map.",
      author = "raaar",
      date = "2024",
      license = "PD",
      layer = math.huge,
      enabled = true,
   }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

include("lualibs/util.lua")

local spGetFeatureDefID = Spring.GetFeatureDefID
local spDestroyFeature = Spring.DestroyFeature

if (not gadgetHandler:IsSyncedCode()) then
    return
end

------------------------------------- auxiliary functions

local unsupportedFeatureDefIds = {}

------------------------------------- callins

function gadget:Initialize()
	-- check which features have invalid models, mark them as unsupported
	for fdId,fd in pairs(FeatureDefs) do
		if fd.modelpath ~= "" then
			if not VFS.FileExists(fd.modelpath) then
				unsupportedFeatureDefIds[fdId] = true
				--Spring.Echo("featureId="..fdId.." fName="..fd.name.." model="..fd.modelpath .." modelAvailable="..tostring(VFS.FileExists(fd.modelpath)))
			end
		end
	end
end

-- block unsupported features from spawning
function gadget:FeatureCreated(fId, teamID)
	local fdId = spGetFeatureDefID(fId)
	if fdId and unsupportedFeatureDefIds[fdId] then
		spDestroyFeature(fId)
	end
end