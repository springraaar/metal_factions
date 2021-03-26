
function gadget:GetInfo()
  return {
    name      = "Thrusters",
    desc      = "provides thruster intensity information for aircraft unit scripts",
    author    = "raaar",
    date      = "2017",
    license   = "PD",
    layer     = 5,
    enabled   = false
  }
end

--TODO not used, remove this?

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if (not gadgetHandler:IsSyncedCode()) then
    return
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetUnitDirection = Spring.GetUnitDirection
local spSpawnCEG = Spring.SpawnCEG

local random = math.random
local min = math.min
local cos = math.cos
local sin = math.sin
local sqrt = math.sqrt
local Echo = Spring.Echo


-- get air unit thruster intensity pushing towards front and up
function airThrust(unitID, unitDefID, teamID)
	local vx, vy, vz, v = spGetUnitVelocity(unitID)
	local px, py, pz = spGetUnitPosition(unitID)
	local dx, dy, dz = spGetUnitDirection(unitID)

	local maxV = UnitDefs[unitDefID].speed
	if (vx == nil or maxV == 0) then
		return 0, 0
	end
	
	-- TODO use acceleration, not velocity?
	local fThrust = (v / maxV) * 3000 
	local vThrust = (vy / maxV) * 3000

	local offset = -10
	px = px + offset * dx
	py = py + offset * dy
	pz = pz + offset * dz
	
--	 local LupsApi = GG.Lups
--	 LupsApi.AddParticles('Jet', { unit=unitID, piece="jp1", pos={0,0,0}, life=10, repeatEffect=true, size=50, colormap1={1,0.8,0.5,0.5}, colormap2={1,1,1,0.5} }) 
	 
	--spSpawnCEG("JETSML",px,py,pz,-dx,-dy,-dz,0,fThrust)		
	Echo("ft = "..fThrust.." vt = "..vThrust )
	return fThrust, vThrust 
end

gadgetHandler:RegisterGlobal("airThrust", airThrust)
