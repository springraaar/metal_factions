--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function gadget:GetInfo()
	return {
		name      = "Rocket Platform Pad Selector",
		desc      = "Handles rocket platform construction points",
		author    = "raaar",
		date      = "2018",
		license   = "PD",
		layer     = 2,
		enabled   = true --  loaded by default?
	}
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitPiecePosDir = Spring.GetUnitPiecePosDir
local spUnitAttach = Spring.UnitAttach
local spGetUnitsInBox = Spring.GetUnitsInBox
local spCallCOBScript = Spring.CallCOBScript

local platformDefIds = {
	[UnitDefNames["aven_long_range_rocket_platform"].id] = true,
	[UnitDefNames["gear_long_range_rocket_platform"].id] = true,
	[UnitDefNames["claw_long_range_rocket_platform"].id] = true,
	[UnitDefNames["sphere_long_range_rocket_platform"].id] = true
}

local missileDefIds = {
	[UnitDefNames["aven_nuclear_rocket"].id] = true,
	[UnitDefNames["aven_dc_rocket"].id] = true,
	[UnitDefNames["gear_nuclear_rocket"].id] = true,
	[UnitDefNames["gear_dc_rocket"].id] = true,
	[UnitDefNames["claw_nuclear_rocket"].id] = true,
	[UnitDefNames["claw_dc_rocket"].id] = true,
	[UnitDefNames["sphere_nuclear_rocket"].id] = true,
	[UnitDefNames["sphere_dc_rocket"].id] = true
}


local missileWeaponIds = {
	[WeaponDefNames["aven_nuclear_rocket"].id]=true,
	[WeaponDefNames["aven_dc_rocket"].id]=true,
	[WeaponDefNames["gear_nuclear_rocket"].id]=true,
	[WeaponDefNames["gear_dc_rocket"].id]=true,
	[WeaponDefNames["claw_nuclear_rocket"].id]=true,
	[WeaponDefNames["claw_dc_rocket"].id]=true,
	[WeaponDefNames["sphere_nuclear_rocket"].id]=true,
	[WeaponDefNames["sphere_dc_rocket"].id]=true
}

local buildPieceNumbers = {
	[1] = 13,	-- silo1
	[2] = 10,	-- silo2
	[3] = 7,	-- silo3
	[4] = 4		-- silo4 
}

local nextAttachPointForPlatformId = {}
local platformAttachmentforMissileId = {}


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:Initialize()
	-- track destructible projectiles
	for id,_ in pairs(missileWeaponIds) do
		Script.SetWatchWeapon(id,true)
	end
end

-- check if the silo has a free pad we can use
function gadget:AllowUnitCreation(udefId, builderId)
	if (missileDefIds[udefId]) then 
	
		-- get the first clear build point, if any
		local point = -1
		local px,py,pz
		local units = {}
		local free 
		nextAttachPointForPlatformId[builderId] = nil
		local piecesWithMissiles = {}
			for mId,info in pairs(platformAttachmentforMissileId) do
			if (info[1] == builderId) then
				piecesWithMissiles[info[2]] = true
			end
		end		
		
		for i=1,4 do
			-- check each pad for obstructions
			if (not piecesWithMissiles[buildPieceNumbers[i]]) then
				px,py,pz,_,_,_ = spGetUnitPiecePosDir(builderId,buildPieceNumbers[i])
				free = true
				units = spGetUnitsInBox(px-10,py-50,pz-10,px+10,py+50,pz+10)
				--Spring.MarkerAddPoint(px,py,pz,"!") --DEBUG
				for uId in ipairs(units) do
					if (uId ~= builderId) then
						free = false
					end
				end
				
				
				if (free) then
					point = i
					nextAttachPointForPlatformId[builderId] = buildPieceNumbers[i]
					break	
				end
			end
		end
		
		if (point > 0) then		
			--Spring.Echo("pad="..point)
			spCallCOBScript(builderId,"SetPad",0,point)
			return true
		end
	
		return false
	end
	
	return true
end


-- attach missile to the platform piece 
function gadget:UnitFromFactory(unitId, unitDefId, unitTeam, factId, factDefId, userOrders)
	if missileDefIds[unitDefId] == true then
		local attachPt = nextAttachPointForPlatformId[factId]
		if (attachPt) then
			spUnitAttach(factId, unitId, attachPt)
			platformAttachmentforMissileId[unitId] = {factId,nextAttachPointForPlatformId[factId]}  
			--Spring.Echo("ATTACHED "..unitId)
		end
	end
end

-- cleanup when missile units are destroyed
function gadget:UnitDestroyed(unitId, unitDefId, unitTeam,attackerId, attackerDefId, attackerTeamId)
	if missileDefIds[unitDefId] then
		if platformAttachmentforMissileId[unitId] then
			platformAttachmentforMissileId[unitId] = nil
		end
	end
end


-- cleanup when missile units "launch themselves"
function gadget:ProjectileCreated(proId, proOwnerId, weaponDefId)
	if missileWeaponIds[weaponDefId] then
		platformAttachmentforMissileId[proOwnerId] = nil
	end
end

end
