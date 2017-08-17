   function gadget:GetInfo()
      return {
        name      = "Reclaim flash",
        desc      = "Nice tree reclaim effect",
        author    = "Jools, based on gadget with same name by beherith, modified by raaar",
        date      = "Aug 2017",
        license   = "PD",
        layer     = 3,
        enabled   = true,
      }
    end

     
if (not gadgetHandler:IsSyncedCode()) then
  return
end

local eceg = "gplasmaballbloom"
local mceg = "bplasmaballbloom"
local dceg = "featureblastwrapper"
function gadget:FeatureDestroyed(featureID,allyteam)
	fx,fy,fz=Spring.GetFeaturePosition(featureID)
	--Spring.Echo(allyteam)
	if (fx ~= nil) then
		rm, mm, re, me, rl = Spring.GetFeatureResources(featureID)
		if (rm ~= nil) then
			if me > mm and rl == 0 then
				local radius = tonumber(Spring.GetFeatureRadius(featureID))
				Spring.SpawnCEG(eceg, fx, fy, fz,0,1,0,radius,radius)
				Spring.PlaySoundFile('Sounds/RECLAIM1.wav', 1, fx, fy, fz)
			elseif mm >= me and rl == 0 then
				local radius = tonumber(Spring.GetFeatureRadius(featureID))
				Spring.SpawnCEG(mceg, fx, fy, fz,0,1,0,radius,radius)
				Spring.PlaySoundFile('Sounds/RECLAIM1.wav', 1, fx, fy, fz)
			else
				local radius = tonumber(Spring.GetFeatureRadius(featureID))
				Spring.SpawnCEG(dceg, fx, fy, fz, 0, 1, 0,radius ,radius)
				Spring.PlaySoundFile('Sounds/DEBRIS5.wav', 4, fx, fy, fz)
			end
		end
	end
end
