   function gadget:GetInfo()
      return {
        name      = "Build Effects",
        desc      = "Displays effects as units and features are built or reclaimed",
        author    = "raaar",
        date      = "2022",
        license   = "PD",
        layer     = math.huge,
        enabled   = true,
      }
    end


local spGetUnitCollisionVolumeData = Spring.GetUnitCollisionVolumeData
local spGetUnitPosition = Spring.GetUnitPosition
local spSpawnCEG = Spring.SpawnCEG
local spGetAllUnits = Spring.GetAllUnits
local spGetUnitHealth = Spring.GetUnitHealth

local spGetFeatureResources = Spring.GetFeatureResources
local spGetAllFeatures = Spring.GetAllFeatures
local spGetFeaturePosition = Spring.GetFeaturePosition
local spGetFeatureCollisionVolumeData = Spring.GetFeatureCollisionVolumeData
local spGetFeatureRadius = Spring.GetFeatureRadius
local spGetUnitDefId = Spring.GetUnitDefID
local spPlaySoundFile = Spring.PlaySoundFile
local spGetGameFrame = Spring.GetGameFrame

local oldBpByUnitId = {}
local oldBpByFeatureId = {}
local createCEG = "buildcreated"
local buildCEG = "buildprogress"
local buildWideCEG = "buildwideprogress"
local reclaimCEG = "reclaimprogress"

local eceg = "gplasmaballbloom"
local mceg = "bplasmaballbloom"
local mDestructionCeg = "rockfeatureblastwrapper"
local treeDestructionCeg = "treefeatureblastwrapper"


local random = math.random
local abs = math.abs
local floor = math.floor
local min = math.min
local sqrt = math.sqrt

local xs, ys, zs, xo, yo, zo, vtype, htype, axis, px,py,pz,offsetX, offsetZ, intensity,bp,oldBp,ud

local noCreationEffectDefIds = {
	[UnitDefNames["cs_beacon"].id] = true,
	[UnitDefNames["scoper_beacon"].id] = true
}

if (not gadgetHandler:IsSyncedCode()) then
  return
end

function gadget:UnitCreated(unitId, unitDefId, unitTeam)
	local ud = UnitDefs[unitDefId]
	if (not noCreationEffectDefIds[unitDefId]) and (not (ud.customParams and ud.customParams.isdrone)) then
		oldBpByUnitId[unitId] = -1
		xs, ys, zs, _, _, _, _, _, _, _ = spGetUnitCollisionVolumeData(unitId)
		px,py,pz = spGetUnitPosition(unitId)
		spSpawnCEG(createCEG, px, py+5, pz,0,1,0,xs,xs)
	end
end


function gadget:FeatureCreated(featureId, allyTeam)
	oldBpByFeatureId[featureId] = -1
end


function gadget:GameFrame(n)
	if (n%3 == 0) then
		-- check units
		for unitId,oldBp in pairs(oldBpByUnitId) do
			_,_,_,_,bp = spGetUnitHealth(unitId)
			ud = UnitDefs[spGetUnitDefId(unitId)]
			
			if oldBp < 0 then 
				oldBp = bp
				oldBpByUnitId[unitId] = bp
			end
			if bp < 1 then
				if bp > oldBp then
					intensity = min(10,(bp - oldBp)*100)
				
					xs, ys, zs, _, _, _, _, _, _, _ = spGetUnitCollisionVolumeData(unitId)
					px,py,pz = spGetUnitPosition(unitId)
					xs = xs*0.95
					ys = ys*0.95
					zs = zs*0.95
					
					-- random offsets
					if xs < 50 then
						spSpawnCEG( buildCEG, px -xs*0.5 +random()*xs, py+ys+3, pz-zs*0.5+random()*zs,0,1,0,xs,intensity)
						spSpawnCEG( buildCEG, px -xs*0.5 +random()*xs, py+ys+3, pz-zs*0.5+random()*zs,0,1,0,xs,intensity)
					else
						xs = xs*0.65
						zs = zs*0.65

						spSpawnCEG( buildWideCEG, px -xs*0.5 +random()*xs, py+ys+10, pz-zs*0.5+random()*zs,0,1,0,xs,intensity)
						spSpawnCEG( buildWideCEG, px -xs*0.5 +random()*xs, py+ys+10, pz-zs*0.5+random()*zs,0,1,0,xs,intensity)
					end
					
					-- offset depends on bp
					--[[
					--offsetX = ((bp*1000)%50) * 0.02
					--offsetZ = floor((bp*100)%50) * 0.02
					--local r = 10 + xs*0.1
					--spSpawnCEG(buildCEG, px -xs*0.5 +offsetX*xs-0.5*r+r*random(), py+ys, pz-zs*0.5+offsetZ*zs-0.5*r+r*random(),0,1,0,xs,intensity)
					--spSpawnCEG(buildCEG, px -xs*0.5 +offsetX*xs-0.5*r+r*random(), py+ys, pz-zs*0.5+offsetZ*zs-0.5*r+r*random(),0,1,0,xs,intensity)
					]]-- 
					
				elseif bp < oldBp then
					intensity = min(20,abs((bp - oldBp))*100)
				
					xs, ys, zs, _, _, _, _, _, _, _ = spGetUnitCollisionVolumeData(unitId)
					px,py,pz = spGetUnitPosition(unitId)
					xs = xs*0.95
					ys = ys*0.95
					zs = zs*0.95
					
					spSpawnCEG(reclaimCEG, px -xs*0.5 +random()*xs, py+ys, pz-zs*0.5+random()*zs,0,1,0,xs,intensity)
					spSpawnCEG(reclaimCEG, px -xs*0.5 +random()*xs, py+ys, pz-zs*0.5+random()*zs,0,1,0,xs,intensity)
				end
			end
			if bp ~= oldBp then
				oldBpByUnitId[unitId] = bp
			end
		end
		
		-- check features
		for fId,oldBp in pairs(oldBpByFeatureId) do
			_,_,_,_,bp = spGetFeatureResources(fId)
			
			if oldBp < 0 then 
				oldBp = bp
				oldBpByFeatureId[fId] = bp
			end
			if bp < 1 then
				if bp > oldBp then		-- never happens?
					intensity = min(10,(bp - oldBp)*100)
					xs, ys, zs, _, _, _, _, _, _, _ = spGetFeatureCollisionVolumeData(fId)
					px,py,pz = spGetFeaturePosition(fId)
					xs = xs*0.95
					ys = ys*0.95
					zs = zs*0.95
					
					spSpawnCEG(buildCEG, px -xs*0.5 +random()*xs, py+ys, pz-zs*0.5+random()*zs,0,1,0,xs,intensity)
					spSpawnCEG(buildCEG, px -xs*0.5 +random()*xs, py+ys, pz-zs*0.5+random()*zs,0,1,0,xs,intensity)
				elseif bp < oldBp then
					intensity = min(20,abs((bp - oldBp))*100)
				
					xs, ys, zs, _, _, _, _, _, _, _ = spGetFeatureCollisionVolumeData(fId)
					px,py,pz = spGetFeaturePosition(fId)
					xs = xs*0.95
					ys = ys*0.95
					zs = zs*0.95
					
					spSpawnCEG(reclaimCEG, px -xs*0.5 +random()*xs, py+ys, pz-zs*0.5+random()*zs,0,1,0,xs,intensity)
					spSpawnCEG(reclaimCEG, px -xs*0.5 +random()*xs, py+ys, pz-zs*0.5+random()*zs,0,1,0,xs,intensity)
				end
			end
			if bp ~= oldBp then
				oldBpByFeatureId[fId] = bp
			end
		end
	end
end


function gadget:UnitDestroyed(unitId, unitDefId, unitTeam,attackerId, attackerDefId, attackerTeamId)
	if (oldBpByUnitId[unitId]) then
		oldBpByUnitId[unitId] = nil
	end
end	


function gadget:FeatureDestroyed(featureId,allyteam)
	if (oldBpByFeatureId[featureId]) then
		oldBpByFeatureId[featureId] = nil
	end

	-- skip the first few frames to avoid triggering during feature setup/cleanup	
	if spGetGameFrame() > 5 then
		local fx,fy,fz=spGetFeaturePosition(featureId)
		if (fx ~= nil) then
			local rm, mm, re, me, rl = spGetFeatureResources(featureId)
			if (rm ~= nil) then
				if me > mm and rl == 0 then
					local radius = tonumber(spGetFeatureRadius(featureId))
					spSpawnCEG(eceg, fx, fy, fz,0,1,0,radius,radius)
					spPlaySoundFile('Sounds/RECLAIM1.wav', 1, fx, fy, fz)
				elseif mm >= me and rl == 0 then
					local radius = tonumber(spGetFeatureRadius(featureId))
					spSpawnCEG(mceg, fx, fy, fz,0,1,0,radius,radius)
					spPlaySoundFile('Sounds/RECLAIM1.wav', 1, fx, fy, fz)
				else
					local radius = tonumber(spGetFeatureRadius(featureId))
					radius = radius* sqrt(1+ (mm*60+me)*0.00005)
					-- no metal means vegetation...probably 
					if mm == 0 then
						spSpawnCEG(treeDestructionCeg, fx, fy, fz, 0, 1, 0,radius ,radius)
						spPlaySoundFile('TREEFEATURECRUSH', 0.7, fx, fy, fz)
					else
						spSpawnCEG(mDestructionCeg, fx, fy, fz, 0, 1, 0,radius ,radius)
						spPlaySoundFile('FEATURECRUSH', 0.7, fx, fy, fz)
					end
				end
			end
		end
	end
end