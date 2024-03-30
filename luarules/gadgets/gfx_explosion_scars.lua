

function gadget:GetInfo()
	return {
		name      = "Explosion Scars Handler",
		desc      = "Updates explosion scars on map surface",
		author    = "raaar",
		version   = "v1",
		date      = "2024",
		license   = "PD",
		layer     = 0,
		enabled   = true
	}
end

------------------------------------------------------------
-- Config
------------------------------------------------------------

local spGetGroundHeight = Spring.GetGroundHeight
local spGetGameFrame = Spring.GetGameFrame
local spGetProjectileDefID = Spring.GetProjectileDefID
local spGetProjectilePosition = Spring.GetProjectilePosition

local spCreateGroundDecal = Spring.CreateGroundDecal
local spDestroyGroundDecal = Spring.DestroyGroundDecal
local spSetGroundDecalPosAndDims = Spring.SetGroundDecalPosAndDims
local spSetGroundDecalRotation = Spring.SetGroundDecalRotation
local spSetGroundDecalTexture = Spring.SetGroundDecalTexture
local spSetGroundDecalAlpha = Spring.SetGroundDecalAlpha

local min = math.min
local max = math.max
local floor = math.floor
local abs = math.abs
local sqrt = math.sqrt
local pow = math.pow
local random = math.random
local HALF_PI = 0.5*math.pi

include("lualibs/util.lua")

-- TODO scar color and heat colors aren't used, only alpha changes
-- engine decals API doesn't allow this as of march 2024  
local scarTypes = {
	["1w"] = {												-- L dmg wide explosion
		refDamage = 120,
		texture = "explosion_scar1w.tga",
		startDelayFrames = 5,
		durationFrames = 10 * 30,
		heatDurationFrames = 0, -- no heat
		heatColor = {0.8,0.4,0,0.9},
		heatColor2 = {0.6,0.2,0,0.7},
		color = {0.0,0.0,0.0,0.8} 
	},
	["1wburn"] = {											-- L dmg wide explosion, fire AOE
		refDamage = 120,
		texture = "explosion_scar1w_burn.tga",
		noRotate = false,
		startDelayFrames = 5,
		noFadeFrames = 20 * 30,
		durationFrames = 40 * 30,
		heatDurationFrames = 0, -- no heat
		heatColor = {0.8,0.4,0,0.9},
		heatColor2 = {0.6,0.2,0,0.7},
		color = {0.0,0.0,0.0,0.8} 
	},
	["1n"] = {												-- L dmg narrow explosion
		refDamage = 120,
		texture = "explosion_scar1n.tga",
		startDelayFrames = 5,
		durationFrames = 10 * 30,
		heatDurationFrames = 0, -- no heat
		heatColor = {0.8,0.4,0,0.9},
		heatColor2 = {0.6,0.2,0,0.7},
		color = {0.0,0.0,0.0,0.8} 
	},
	["2w"] = {												-- M dmg wide explosion
		refDamage = 300,
		texture = "explosion_scar2w.tga",
		startDelayFrames = 5,
		durationFrames = 20 * 30,
		heatDurationFrames = 10, 
		heatColor = {0.8,0.4,0,0.6},
		heatColor2 = {0.6,0.2,0,0.4},
		color = {0.0,0.0,0.0,0.8} 
	},
	["2n"] = {												-- M dmg narrow explosion
		refDamage = 300,
		texture = "explosion_scar2n.tga",
		startDelayFrames = 5,
		durationFrames = 20 * 30,
		heatDurationFrames = 10, 
		heatColor = {0.8,0.4,0,0.6},
		heatColor2 = {0.6,0.2,0,0.4},
		color = {0.0,0.0,0.0,0.8} 
	},

	["3w"] = {												-- H dmg wide explosion
		refDamage = 300,
		texture = "explosion_scar3w.tga",
		startDelayFrames = 5,
		durationFrames = 30 * 30,
		heatDurationFrames = 18, 
		heatColor = {0.8,0.4,0,0.9},
		heatColor2 = {0.6,0.2,0,0.7},
		color = {0.0,0.0,0.0,0.9} 
	},
	["3n"] = {												-- H dmg narrow explosion
		refDamage = 300,
		texture = "explosion_scar3n.tga",
		startDelayFrames = 5,
		durationFrames = 30 * 30,
		heatDurationFrames = 18, 
		heatColor = {0.8,0.4,0,0.9},
		heatColor2 = {0.6,0.2,0,0.7},
		color = {0.0,0.0,0.0,0.9} 
	}

}


if gadgetHandler:IsSyncedCode() then --------------------- SYNCED - track weapons that leave scars, send explosion data to unsynced

local explosionScarByWeaponDefId = {}    -- { type, radius, intensity }


----------------------------- CALLINS


function gadget:Initialize()
	-- find weapons which cause an explosion scar
	for i=1,#WeaponDefs do
		local wd = WeaponDefs[i]
		local customParams = wd.customParams or {}
		if ( not customParams.noscar and wd.customParams.hitpower) then
      		Script.SetWatchWeapon(wd.id,true)
			
			-- assign a type automatically
			local type = ""..wd.customParams.hitpower
			local isNarrowScar = false
			if wd.damageAreaOfEffect >= 16 then
				type = type.."w"
			else
				type = type.."n"
				isNarrowScar = true
			end
			if customParams.scar then
				if scarTypes[customParams.scar] then
					type = customParams.scar
				else
					Spring.Echo("WARNING : "..wd.name.." has invalid scar type '"..customParams.scar.."'")
				end
			end
			sType = scarTypes[type]			
			local intensity = wd.damages[0] / sType.refDamage
			local radius = max(12,isNarrowScar and wd.damageAreaOfEffect*(0.5+0.5*sqrt(intensity)) or (5+pow(wd.damageAreaOfEffect,0.97)))
			-- sharply reduce scar intensity for beam lasers because they trigger explosion for every beamtime frame
			if wd.type == "BeamLaser" then
				intensity = intensity * 0.33
				radius = radius * 0.8
			end
			
			explosionScarByWeaponDefId[wd.id] = {type = type, radius = radius, intensity = intensity }
		end
	end
end

function gadget:Explosion(weaponID, px, py, pz, ownerID)
	local scarInfo = explosionScarByWeaponDefId[weaponID]
	if scarInfo then
		local h = spGetGroundHeight(px,pz)
		
		-- add scar if exploded close enough to the ground
		if px and abs(py - h) < scarInfo.radius then
			local intensityHeightMod = 1 - abs(py - h) / max(scarInfo.radius,1)
			 
			--Spring.Echo("explosion "..proID.." with scar happened!")
			SendToUnsynced("explosionScarEvent", px, py, pz, scarInfo.type, scarInfo.radius, h, scarInfo.intensity * intensityHeightMod )
		end
	end
	 
end

else ------------------------------- UNSYNCED - get explosion events from synced, add/remove/update scars

local spGetAllGroundDecals = Spring.GetAllGroundDecals

local scars = {}

local tooManyScarsDurationMod = 1

local function updateAllScars(f)
	local colorA = 1
	local colorWeight = 0		-- 0 to 1 along start delay, then down to zero in durationFrames (alpha only)
	for idx,scar in pairs(scars) do
		if (f > scar.endFrame) then
			local destroyed = spDestroyGroundDecal(scar.decalID)
			--Spring.Echo("Decal "..scar.decalID.." destroyed? : "..tostring(destroyed))
			scars[idx] = nil
		elseif (f >= scar.startFrame) then
			
			if f < scar.startDelayFrame then
				-- fadein
				colorWeight = (f - scar.startFrame)/(scar.startDelayFrame - scar.startFrame)
			else
				if (f < scar.noFadeFrame) then
					colorWeight = 1
				else
					-- fadeout
					colorWeight = 1 - (f-scar.startDelayFrame)/scar.durationFrames
				end
			end

			colorA = colorWeight*scar.color[4]			
			spSetGroundDecalAlpha(scar.decalID,colorA)
		end
	end
end

local function checkRemoveSmallerScars(radius,idx,idx2,idx3)
	if radius > 96 then
		for otherIdx,scar in pairs(scars) do
			if otherIdx ~= idx and radius >= scar.radius and scar.idx3 == idx3 then
				scar.endFrame = scar.endFrame -0.5*scar.durationFrames
				scar.durationFrames = 0.5*scar.durationFrames 
  				-- scars[otherIdx] = nil
			end
		end
	elseif radius > 32 then
		for otherIdx,scar in pairs(scars) do
			if otherIdx ~= idx and radius >= scar.radius and scar.idx2 == idx2 then
				scar.endFrame = scar.endFrame -0.5*scar.durationFrames
				scar.durationFrames = 0.5*scar.durationFrames 
				--scars[otherIdx] = nil
			end
		end
	else
		-- do nothing?
	end
end

local function addScar(_,px,py,pz,type,radius,h,intensity)
	local f = spGetGameFrame()
	local sType = scarTypes[type]
	local color = {sType.color[1],sType.color[2],sType.color[3],min(sType.color[4]*(0.5+0.5*intensity),sType.color[4])}
	local durationMod = tooManyScarsDurationMod * (0.1+0.9*pow(intensity,0.6))
	local scar = {
		idx = "x"..floor(px*0.25).."z"..floor(pz*0.25),				-- 4*4 no-overlap 
		idx2 = "x"..floor(px*0.015625).."z"..floor(pz*0.015625),	-- 64*64 check index
		idx3 = "x"..floor(px*0.0052083).."z"..floor(pz*0.0052083),	-- 192*192 check index 
		texture=sType.texture,
		px = px,
		py = h,
		pz = pz,
		rotation = sType.noRotate and 0 or HALF_PI*random(0,3), 
		radius = radius,
		color = color,
		startFrame = f,
		startDelayFrame = f + (sType.startDelayFrames * radius/50),
		noFadeFrame = f + (sType.noFadeFrames and sType.noFadeFrames or 0),
		endFrame = f + sType.durationFrames*durationMod,
		durationFrames = sType.durationFrames*durationMod,
		--heatDurationFrames = sType.heatDurationFrames*durationMod,
		--heatColor = sType.heatColor,
		--heatColor2 = sType.heatColor2,
		--drawColor = {0,0,0,0},
		decalID = 0
	}
	
	local oldScar = scars[scar.idx]
	-- allow location overlap, once
	if oldScar then
		-- if there was a replacement there already, remove its decal before refreshing
		local replacementScar = scars[scar.idx.."r"]
		if replacementScar then
			local destroyed = spDestroyGroundDecal(replacementScar.decalID)
			--Spring.Echo("Decal "..replacementScar.decalID.." destroyed? : "..tostring(destroyed))
		end
		scars[scar.idx.."r"] = scar
	else
		scars[scar.idx] = scar
	end
	
	-- add the decal
	local decalID = spCreateGroundDecal()
	spSetGroundDecalPosAndDims(decalID,scar.px,scar.pz,radius,radius)
	spSetGroundDecalRotation(decalID,scar.rotation)
	spSetGroundDecalTexture(decalID,scar.texture,true)
	spSetGroundDecalAlpha(decalID,scar.color[4])
	scar.decalID = decalID
	
	-- thin nearby scars with radius <= itself
	-- bigger radius explosions are more likely to trigger this 
	if (random(0,3)+0.02*radius >  2) then
		checkRemoveSmallerScars(radius,scar.idx,scar.idx2,scar.idx3)
	end 
end


----------------------------- CALLINS


function gadget:Initialize()
	gadgetHandler:AddSyncAction("explosionScarEvent", addScar)
end

function gadget:Shutdown()
	gadgetHandler.RemoveSyncAction("explosionScarEvent")
end

function gadget:GameFrame(f)
	-- reduce scar duration in denser battles, for performance reasons
	if (f % 50 == 0) then
		nScars = tableLength(scars)
		allDecals = spGetAllGroundDecals()
		nDecals = 0
		if allDecals then
			nDecals = tableLength(allDecals)
		end
		
		if (nScars > 1000) then
			tooManyScarsDurationMod = 0.3
		elseif (nScars > 500) then
			tooManyScarsDurationMod = 0.7
		elseif (nScars > 200) then
			tooManyScarsDurationMod = 0.85
		else
			tooManyScarsDurationMod = 1
		end
		if not allDecals then
			allDecals = {}
		end
		--Spring.Echo("#scars : "..nScars.." #decals : "..nDecals.." "..tableToString(allDecals))
	end

	if (f%2 == 0) then
		updateAllScars(f)
	end
end

end