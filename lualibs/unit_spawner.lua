

spGetGameFrame = Spring.GetGameFrame
spGetUnitPosition = Spring.GetUnitPosition
spGetUnitRadius = Spring.GetUnitRadius
spGetUnitHeight = Spring.GetUnitHeight
spSpawnCEG = Spring.SpawnCEG
spPlaySoundFile = Spring.PlaySoundFile
spSetUnitRulesParam = Spring.SetUnitRulesParam
spGetUnitCollisionVolumeData = Spring.GetUnitCollisionVolumeData

local UNIT_RP_PUBLIC_TBL = {public = true}


-- mark unit for teleported overlay, trigger teleport CEG and sound
function showTeleportedUnitFx(unitId)
	local x,y,z = spGetUnitPosition(unitId)
	if x then
		spSetUnitRulesParam(unitId,"teleported_fx_frames",30,UNIT_RP_PUBLIC_TBL)
		
		local sx,sy,sz,_,_,_,_,_,_,_ = spGetUnitCollisionVolumeData(unitId)
		local width = math.max(sx,sz)
		local cegScale = math.max(width,sy)
		local cegName = "teleportshort"
		if sy > 1.0*width then
			cegName = "teleporttall"
		elseif sy > 0.5*width then
			cegName = "teleportmed"
		end
		--Spring.Echo("unitId="..unitId.." sx="..sx.." sy="..sy.." sz="..sz.." width="..width.." CEG="..cegName)
		spSpawnCEG(cegName, x, y, z,0,1,0,cegScale,cegScale)
		spPlaySoundFile("Sounds/TELEPORT.wav", 1, x, y, z)
	end
end