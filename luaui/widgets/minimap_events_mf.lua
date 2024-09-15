function widget:GetInfo()
  return {
    name      = "Minimap Events (MF version)",
    desc      = "Display indicators on map/minimap for units under attack and long range rocket impacts",
    author    = "raaar, based on widget by trepan",
    date      = "2019",
    license   = "PD",
    layer     = 999999,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local GL_LINE_LOOP           = GL.LINE_LOOP
local GL_ONE                 = GL.ONE
local GL_ONE_MINUS_SRC_ALPHA = GL.ONE_MINUS_SRC_ALPHA
local GL_POINTS              = GL.POINTS
local GL_QUADS               = GL.QUADS
local GL_SRC_ALPHA           = GL.SRC_ALPHA
local GL_TRIANGLE_FAN        = GL.TRIANGLE_FAN
local glBeginEnd             = gl.BeginEnd
local glBlending             = gl.Blending
local glCallList             = gl.CallList
local glColor                = gl.Color
local glCreateList           = gl.CreateList
local glDeleteList           = gl.DeleteList
local glLineWidth            = gl.LineWidth
local glLoadIdentity         = gl.LoadIdentity
local glPopMatrix            = gl.PopMatrix
local glPushMatrix           = gl.PushMatrix
local glRotate               = gl.Rotate
local glScale                = gl.Scale
local glSmoothing            = gl.Smoothing
local glTexCoord             = gl.TexCoord
local glTranslate            = gl.Translate
local glVertex               = gl.Vertex
local spGetFrameTimeOffset   = Spring.GetFrameTimeOffset
local spGetGameSeconds       = Spring.GetGameSeconds
local spGetUnitPosition      = Spring.GetUnitPosition
local spGetUnitViewPosition  = Spring.GetUnitViewPosition
local spIsUnitAllied         = Spring.IsUnitAllied
local spGetGameFrame         = Spring.GetGameFrame
local spGetVisibleProjectiles = Spring.GetVisibleProjectiles
local spGetMyAllyTeamID = Spring.GetMyAllyTeamID
local spGetProjectileDefID = Spring.GetProjectileDefID
local spGetProjectileTarget = Spring.GetProjectileTarget
local spGetProjectilePosition = Spring.GetProjectilePosition
local spGetProjectileOwnerID = Spring.GetProjectileOwnerID
local spGetUnitRulesParam = Spring.GetUnitRulesParam

local floor = math.floor

VFS.Include("lualibs/util.lua")

local vsx, vsy = gl.GetViewSizes()
local scaleFactor = 1
if (vsy > 1080) then
	scaleFactor = vsy / 1080
end	

local LINE_WIDTH = 2
local MINIMAP_LINE_WIDTH = 1
local alpha = 0.3
local warningColor1    = { 1.0, 0.0, 0.0, 0.2 }
local warningColor2    = { 1.0, 1.0, 0.0, 0.2 }

local impactColor1    = { 1.0, 1.0, 0.0, 0.3 }
local impactColor2    = { 1.0, 0.5, 0.0, 0.3 }


local EVENT_DURATION_FRAMES = 45
local damageEvents = {}
local lastDamageEventZones = {}
local REDUNDANT_EVENT_FRAMES = 90
local zx = 0
local zz = 0

local lRRocketsInFlight = {}		-- map {proId,{wdId,maxSQDist,targetPos,aoe,active}}


----------------------------------------------- auxiliary functions

VFS.Include("lualibs/circles.lua")

local function updateCirclesToDraw()
	circlesToDraw = {}			-- x,y,z,radius,color
	minimapCirclesToDraw = {}	-- x,z,radius,color

	-- update circles for damage events
	local currentFrame = spGetGameFrame()
	local px,pz,f,scale
	for i,ev in pairs(damageEvents) do
	    px = ev.px
	    pz = ev.pz
	    f = ev.f
    
		scale = 20 * (1 - (currentFrame - f) / EVENT_DURATION_FRAMES) 
    
		if (scale > 1) then
    		--Spring.Echo("px="..px.." pz="..pz.." scale="..tonumber(scale))
    		minimapCirclesToDraw[#minimapCirclesToDraw+1] = {px,pz,scale*20,warningColor1}
    		minimapCirclesToDraw[#minimapCirclesToDraw+1] = {px,pz,scale*20+100,warningColor2}
		else
			damageEvents[i] = nil
		end
	end
	
	-- update circles for long range rocket impacts
	for proId,props in pairs(lRRocketsInFlight) do
		local maxDist = props.maxSQDist
		local maxRadius = props.aoe
		local x,y,z = spGetProjectilePosition(proId)
		local targetPos = props.targetPos 
		local tx = targetPos[1]
		local ty = targetPos[2]
		local tz = targetPos[3]
		if y and maxDist > 0 then
			local curDist =  sqDistance3D(x,tx,y,ty,z,tz)
			local drawRadius = maxRadius * min(sqrt(curDist/maxDist),1)
			addCircle(tx,ty,tz,drawRadius,impactColor1,true)
			addCircle(tx,ty,tz,maxRadius,impactColor2,true)
		else
			lRRocketsInFlight[proId] = nil
		end
	end
end



----------------------------------------------- engine callins

function widget:Initialize()
	initCircleDLists()
end

function widget:Shutdown()
	removeCircleDLists()
end


function widget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer)
	if (not spIsUnitAllied(unitID)) then
		return
	end
	if (damage <= 0) then
		return
	end
	
	local ud = UnitDefs[unitDefID]
	if (ud == nil) then
		return
	end

	local px,py,pz = spGetUnitPosition(unitID)
	if (px) then
		local f = spGetGameFrame()
		zx=floor(px/256)
		zz=floor(pz/256)
		
		local idx = zx.."_"..zz
		local oldFrame = lastDamageEventZones[idx]
		
		-- roughly filter out redundant events
		if (not oldFrame or f - oldFrame > REDUNDANT_EVENT_FRAMES) then
			table.insert(damageEvents,{px=px,pz=pz,f=f})
			lastDamageEventZones[idx] = f
		end
	end
end

function widget:Update(dt)
	timeSinceLastCircleUpdate = timeSinceLastCircleUpdate + dt
	-- limit circles update rate to ~17x per second 
	if timeSinceLastCircleUpdate > 0.06 then
		updateCirclesToDraw()
		timeSinceLastCircleUpdate = 0
	end
end

function widget:DrawInMiniMap(xSize, ySize)
	glPushMatrix()
	glCallList(minimapTransformDList)
	
	glLineWidth(MINIMAP_LINE_WIDTH)
	for _,circle in ipairs(minimapCirclesToDraw) do
		drawMinimapCircle(circle[1],circle[2],circle[3],circle[4])
	end
	glPopMatrix()
	glColor(1,1,1,1)
end

function widget:DrawWorld()
	glLineWidth(LINE_WIDTH)
	for _,circle in ipairs(circlesToDraw) do
		drawGroundCircle(circle[1],circle[2],circle[3],circle[4],circle[5])
	end
	glColor(1,1,1,1)
end

function widget:GameFrame(f)
	-- every few seconds, remove expired per-zone damage event entries
	if (f%176 == 0) then
		for idx,ef in pairs(lastDamageEventZones) do
			if (f - ef > REDUNDANT_EVENT_FRAMES) then
				--Spring.Echo("expired dmg event at "..idx)
				lastDamageEventZones[idx] = nil
			end
		end
	end
	-- check allied projectiles for long range rockets in flight, track them 
	if (f%30 == 0) then
		local allyId = spGetMyAllyTeamID() 
		local projectiles = spGetVisibleProjectiles(allyId)
		
		for _,proId in pairs(projectiles) do
			if not lRRocketsInFlight[proId] then
				local wdId = spGetProjectileDefID(proId)
				local wd = WeaponDefs[wdId]
				if wd and wd.customParams and tonumber(wd.customParams.drawimpactindicator) == 1 then
					local sx,sy,sz = spGetProjectilePosition(proId)
					
					local ownerUnitId = spGetProjectileOwnerID(proId)
					
					local originalTargetStr = spGetUnitRulesParam(ownerUnitId,"originalTargetPos")
					if originalTargetStr then
						local components = splitString(originalTargetStr,"|")
						tx = tonumber(components[1]) 
						ty = tonumber(components[2])
						tz = tonumber(components[3])
						
						if (sy and ty) then
							local maxSQDist = sqDistance3D(sx,tx,sy,ty,sz,tz)			
							lRRocketsInFlight[proId] = {wdId,maxSQDist=maxSQDist,targetPos={tx,ty,tz},aoe=wd.damageAreaOfEffect }
						end 
					end
				end
			end
		end
	end
end 
