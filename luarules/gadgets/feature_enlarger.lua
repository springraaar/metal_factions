function gadget:GetInfo()
	return {
		name    = "Feature Enlarger",
		desc    = "Scales feature models with 'scale' custom parameter",
		author  = "raaar, based on gadget by Rafal",
		date    = "2019",
		license = "PD",
		layer   = 0,
		enabled = true
	}
end

--------------------------------------------------------------------------------
-- speedups
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------
if not (gadgetHandler:IsSyncedCode()) then


local spSetFeatureLuaDraw = Spring.FeatureRendering.SetFeatureLuaDraw
local spGetFeatureDefID = Spring.GetFeatureDefID
local glScale = gl.Scale
local rand = math.random

local scaleById = {}
local SCALE_SPREAD = 0.16


--------------------------------------------------------------------------------


function gadget:Initialize()
	for i,fId in pairs(Spring.GetAllFeatures()) do
		local fd = FeatureDefs[spGetFeatureDefID(fId)]
		if (fd and fd.customParams.scale) then
			spSetFeatureLuaDraw(fId, true)
			scaleById[fId] = (1 - SCALE_SPREAD/2 + rand()*SCALE_SPREAD) * fd.customParams.scale
		end
	end
end

function gadget:DrawFeature(fId, drawMode)
	local scale = scaleById[fId]

	if (scale and scale ~= 1.0) then
		glScale( scale, scale, scale )
	end

	return false
end

end
