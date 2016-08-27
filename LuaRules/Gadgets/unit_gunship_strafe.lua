
function gadget:GetInfo()
  return {
    name      = "Heavy gunship strafe",
    desc      = "used to override default strafing behaviour for heavy gunships",
    author    = "raaar",
    date      = "09 Jun 2013",
    license   = "PD",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

-- TODO not used, remove?

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local SetGunshipMoveTypeData = Spring.MoveCtrl.SetGunshipMoveTypeData

local SetUnitVelocity = Spring.SetUnitVelocity
local GetUnitPosition = Spring.GetUnitPosition
local GetUnitVelocity = Spring.GetUnitVelocity
local GetUnitDirection = Spring.GetUnitDirection
local GetGameSeconds = Spring.GetGameSeconds
local GetCommandQueue = Spring.GetCommandQueue
local GetUnitWeaponTestRange = Spring.GetUnitWeaponTestRange
local random = math.random
local min = math.min
local cos = math.cos
local sin = math.sin
local sqrt = math.sqrt
local INTENSITY = 4
local FREQ_MOD = 1.5
local MAX_SPEED_COMPONENT = 2
local CMD_ATTACK = 20
local Echo = Spring.Echo



local heavyGunshipsStrafing = {}

-- fix strafe range
function gadget:UnitCreated(unitID, unitDefID, unitTeam)
	if unitDefID == "aven_icarus" then
		Spring.SetUnitWeaponState(unitID,0,{range = 300})
		Spring.SetUnitWeaponState(unitID,1,{range = 300})
	end
end

-- change unit velocity to make it move around a bit if attacking and within range of target
function HeavyGunshipStrafe(unitID, unitDefID, teamID)
  local px, py, pz = GetUnitPosition(unitID)
  if (px == nil) then
    return
  end

  -- only do something if current order is attacking a target
  local cmdTable = Spring.GetCommandQueue(unitID,1) 
  if( cmdTable and table.getn(cmdTable) > 0 and cmdTable[1]["id"] == CMD_ATTACK and cmdTable[1]["params"] ) then
    heavyGunshipsStrafing[unitID] = GetGameSeconds()
  else
    heavyGunshipsStrafing[unitID] = nil
  end
	
  return
end

-- change units movement
function gadget:GameFrame(n)
	--if (n%2 ~= 0) then
		--return
	--end
	
	local tx = 0
	local vxInc = 0
	local vyInc = 0
	local vzInc = 0
	local dx = 0
	local dy = 0
	local dz = 0
	local d = 0
	
	for unitID,data in pairs(heavyGunshipsStrafing) do

		local px, py, pz = GetUnitPosition(unitID)
		if (px == nil) then
			return
		end
	
		-- only do something if current order is attacking a target and within range
		local cmdTable = Spring.GetCommandQueue(unitID,1)

		if( cmdTable and table.getn(cmdTable) > 0 and cmdTable[1]["id"] == CMD_ATTACK and cmdTable[1]["params"] ) then
			tx = cmdTable[1]["params"][1]
			ty = cmdTable[1]["params"][2]
			tz = cmdTable[1]["params"][3]
			vx, vy, vz = GetUnitVelocity(unitID)
		
		    if GetUnitWeaponTestRange(unitID, 1, tx, ty, tz ) and (vx^2 + vy^2 + vz^2) < 10000 then
	
				-- target velocity
				vxInc = 0
				vyInc = 0
				vzInc = 0
		
				-- local dx, dy, dz = GetUnitDirection(unitID)
				dx = (tx - px)
				dy = (ty - py)
				dz = (tz - pz)
				d = sqrt(dx^2+dy^2+dz^2)
		
				-- calculate velocity increments, strafe intensity should be focused sideways
				if ( vx < MAX_SPEED_COMPONENT and vx > -MAX_SPEED_COMPONENT) then
					vxInc = INTENSITY * cos((GetGameSeconds()+unitID)*FREQ_MOD ) * dz/d
				end
				if ( vz < MAX_SPEED_COMPONENT and vz > -MAX_SPEED_COMPONENT) then
					vzInc = INTENSITY * cos((GetGameSeconds()+unitID)*FREQ_MOD ) * (-dx/d)
				end
				-- change unit velocity
				SetUnitVelocity(unitID, min(vx + vxInc,MAX_SPEED_COMPONENT), min(vy + vyInc,MAX_SPEED_COMPONENT), min(vz + vzInc,MAX_SPEED_COMPONENT))
				--SetUnitVelocity(unitID, vxInc, 0, vzInc)
		
				--Spring.Echo("strafing dx="..dx.." dy="..dy.." dz="..dz)
				--Spring.Echo("strafing vxInc="..vxInc.." vyInc="..vyInc.." vzInc="..vzInc)
			end
		end
	end
end



gadgetHandler:RegisterGlobal("HeavyGunshipStrafe", HeavyGunshipStrafe)
