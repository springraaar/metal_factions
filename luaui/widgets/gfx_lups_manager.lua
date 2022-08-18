--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  author:  jK
--
--  Copyright (C) 2007,2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- LUPS manager, imported from XTA 9.752 on apr 2017
--- modified by raaar to dynamically adjust aircraft thruster effects based on movement 
--- TODO file needs cleanup to remove zk logic


function widget:GetInfo()
  return {
    name      = "LupsManager",
    desc      = "",
    author    = "jK",
    date      = "Feb, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 10,
    enabled   = true,
    handler   = true,
  }
end

local Echo = Spring.Echo

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function MergeTable(table1,table2)
  local result = {}
  for i,v in pairs(table2) do 
    if (type(v)=='table') then
      result[i] = MergeTable(v,{})
    else
      result[i] = v
    end
  end
  for i,v in pairs(table1) do 
    if (result[i]==nil) then
      if (type(v)=='table') then
        if (type(result[i])~='table') then result[i] = {} end
        result[i] = MergeTable(v,result[i])
      else
        result[i] = v
      end
    end
  end
  return result
end

include("configs/lupsfxs.lua")
include("configs/lupsunitfxs.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function blendColor(c1,c2,mix)
  if (mix>1) then mix=1 end
  local mixInv = 1-mix
  return {
    c1[1]*mixInv + c2[1]*mix,
    c1[2]*mixInv + c2[2]*mix,
    c1[3]*mixInv + c2[3]*mix,
    (c1[4] or 1)*mixInv + (c2[4] or 1)*mix
  }
end


local function blend(a,b,mix)
  if (mix>1) then mix=1 end
  return a*(1-mix) + b*mix
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local UnitEffects = {}
local registeredUnits = {}	-- all finished units - prevents partial unbuild then rebuild from being treated as two UnitFinished events

local function AddFX(unitname,fx)
  local ud = UnitDefNames[unitname]
  --// Seasonal lups stuff

  if ud then
    UnitEffects[ud.id] = fx
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

for i,f in pairs(effectUnitDefs) do
  AddFX(i,f)
end

local currentTime = os.date('*t')


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- for i,f in pairs(effectUnitDefs) do
--   Spring.Echo("   ",i,f)
-- end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local aircraftWithThrusters = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local abs = math.abs
local min = math.min
local max = math.max
local floor = math.floor
local spGetSpectatingState = Spring.GetSpectatingState
local spGetUnitDefID       = Spring.GetUnitDefID
local spGetUnitRulesParam  = Spring.GetUnitRulesParam
local spGetUnitPosition = Spring.GetUnitPosition
local spGetUnitVelocity = Spring.GetUnitVelocity
local spGetUnitDirection = Spring.GetUnitDirection
local spGetGameSpeed = Spring.GetGameSpeed

local copyTable = Spring.Utilities.CopyTable



--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local Lups  -- Lua Particle System
local LupsAddFX
local particleIDs = {}
local initialized = false --// if LUPS isn't started yet, we try it once a gameframe later
local tryloading  = 1     --// try to activate lups if it isn't found

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function ClearFxs(unitID)
  if (particleIDs[unitID]) then
    for i=1,#particleIDs[unitID] do
      local fxID = particleIDs[unitID][i]
      Lups.RemoveParticles(fxID)
    end
    particleIDs[unitID] = nil
  end
end


local function ClearFx(unitID, fxIDtoDel)
  if (particleIDs[unitID]) then
  local newTable = {}
    for i=1,#particleIDs[unitID] do
      local fxID = particleIDs[unitID][i]
      if fxID == fxIDtoDel then 
        Lups.RemoveParticles(fxID)
      else 
        newTable[#newTable+1] = fxID
      end
    end

    if #newTable == 0 then 
      particleIDs[unitID] = nil
    else 
      particleIDs[unitID] = newTable
    end
  end
end


local function AddFxs(unitID,fxID)
  if (not particleIDs[unitID]) then
    particleIDs[unitID] = {}
  end

  local unitFXs = particleIDs[unitID]
  unitFXs[#unitFXs+1] = fxID
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function UnitFinished(_,unitID,unitDefID)
  if registeredUnits[unitID] then
    return
  end
  registeredUnits[unitID] = true

  local effects = UnitEffects[unitDefID]
  if (effects) then
    for i=1,#effects do
      local fx = effects[i]
      if (not fx.options) then
        Spring.Log(widget:GetInfo().name, LOG.ERROR, "LUPS DEBUG GRRR", UnitDefs[unitDefID].name, fx and fx.class)
        return
      end

      if (fx.class=="AirJet") then
        aircraftWithThrusters[unitID] = {fThrust=0,vThrust=0,v=0,effects=effects}
      end
      if (fx.class=="GroundFlash") then
        fx.options.pos = { Spring.GetUnitPosition(unitID) }
      end
      if (fx.options.heightFactor) then
		local pos = fx.options.pos or {0, 0, 0}
        fx.options.pos = { pos[1], Spring.GetUnitHeight(unitID)*fx.options.heightFactor, pos[3] }
      end
	  if (fx.options.radiusFactor) then
		fx.options.size = Spring.GetUnitRadius(unitID)*fx.options.radiusFactor
	  end
      fx.options.unit = unitID
      AddFxs( unitID,LupsAddFX(fx.class,fx.options) )
      fx.options.unit = nil
    end
    
    --local spec, fullSpec = spGetSpectatingState()
    --if (spec and fullSpec) then
--      UnitEnteredLos(_,unitID)  
    --end
  end 
end


local function UnitDestroyed(_,unitID,unitDefID, preEvent)
	if preEvent == false then return end
	
  registeredUnits[unitID] = nil

  aircraftWithThrusters[unitID] = nil
  ClearFxs(unitID)
end


local function UnitEnteredLos(_,unitID)
  -- why shouldn't spectators see the effects?
  local spec, fullSpec = spGetSpectatingState()
  if (spec and fullSpec) then 
    return 
  end
  
  --[[
  if registeredUnits[unitID] then
    return
  end
  registeredUnits[unitID] = true
  ]]

  local unitDefID = spGetUnitDefID(unitID)
  local effects   = UnitEffects[unitDefID]
  if (effects) then
    for i=1,#effects do
      local fx = effects[i]

      if (fx.class=="AirJet") then
        aircraftWithThrusters[unitID] = {fThrust=0,vThrust=0,v=0,effects=effects}
      end
      if (fx.class=="GroundFlash") then
        fx.options.pos = { Spring.GetUnitPosition(unitID) }
      end
    fx.options.unit = unitID
    AddFxs( unitID,LupsAddFX(fx.class,fx.options) )
    fx.options.unit = nil
    end
  end
end


local function UnitLeftLos(_,unitID)
  local spec, fullSpec = spGetSpectatingState()
  if (spec and fullSpec) then return end

  registeredUnits[unitID] = nil
  aircraftWithThrusters[unitID] = nil
  
  ClearFxs(unitID)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local color1 = {0,0,0}
local color2 = {1,0.5,0}
local lastSkipCheckFrame = 0
local lastSkipCount = 0
local lastTotalProcessed = 0
local FTHRUST_UPDATE_RESOLUTION = 4
local VTHRUST_UPDATE_RESOLUTION = 3
local V_UPDATE_RESOLUTION = 3


local function GameFrame(_,n)
	local userSpeedFactor, speedFactor, paused = spGetGameSpeed()
	--Spring.Echo("speedFactor="..speedFactor.." userSpeedFactor="..userSpeedFactor)
  	-- update flight thruster effect according to unit movement
	if ((n%(3*userSpeedFactor))== 0 and (next(aircraftWithThrusters))) then
		--[[
		if (n - lastSkipCheckFrame > 300) then
			local pct = 0
			if lastTotalProcessed > 0 then
				pct = lastSkipCount*100 / lastTotalProcessed
			end
			Spring.Echo(n.." : thruster update skips (last 10s) : "..pct.." %")
			lastTotalProcessed = 0
			lastSkipCount = 0
			lastSkipCheckFrame = n
		end
		]]--
		local ud, unitDefID, vx, vy, vz, v, dx, dy, dz, maxV, xzAlignFactor, fThrust, vThrust, loadFactor, effects, oldVThrust, oldFThrust, oldV
	    for unitID,props in pairs(aircraftWithThrusters) do
			local unitDefID = spGetUnitDefID(unitID)
			if unitDefID then
				ud = UnitDefs[unitDefID]
				if (props) then
					oldVThrust = props.vThrust
					oldFThrust = props.fThrust
					oldV = props.v
					effects = props.effects
					vx, vy, vz, v = spGetUnitVelocity(unitID)
					dx, dy, dz = spGetUnitDirection(unitID)
				
					maxV = ud.speed
					if (vx ~= nil and maxV ~= 0) then
						
						xzAlignFactor = (vx * dx + vz * dz) / v 
						if xzAlignFactor < 0 then
							xzAlignFactor = 0
						end
						
						-- TODO should match acceleration, not velocity
						fThrust = (v / maxV) * xzAlignFactor * 30 
						vThrust = 1 + vy *0.1
						if fThrust < 0.2 then
							fThrust = 0.2
						end
						if vThrust < 0.3 then
							vThrust = 0.3
						end
						
						--  increase thruster intensity for loaded transports
						if (ud.isTransport) then
							loadFactor = spGetUnitRulesParam(unitID, "transport_load_factor")
							if loadFactor then
								loadFactor = tonumber(loadFactor)
								if (loadFactor and loadFactor > 0) then
									fThrust = fThrust * (1 + loadFactor)
									vThrust = vThrust * (1 + loadFactor)
								end 
								if (fThrust > 1) then
									fThrust = 1
								end
								if (vThrust > 1) then
									vThrust = 1
								end
							end
						end
						--lastTotalProcessed = lastTotalProcessed + 1						
						-- only update/replace the lups fx if they changed significantly
						if (floor(fThrust*FTHRUST_UPDATE_RESOLUTION) ~= oldFThrust) or (floor(vThrust*VTHRUST_UPDATE_RESOLUTION) ~= oldVThrust) or (floor(v*V_UPDATE_RESOLUTION) ~= oldV) then
							ClearFxs(unitID)
							for i=1, #effects do
								local fx = effects[i]
								if fx.class == "AirJet" then
									local newFx = copyTable(fx,true)
									local newOptions = newFx.options 
									newOptions.unit = unitID
									if (newOptions.down == true) then
										newOptions.length = fx.options.length * vThrust
									else
										newOptions.length = fx.options.length * fThrust
									end
									AddFxs( unitID, LupsAddFX(newFx.class,newOptions) )
								end
							end
							
							props.vThrust = floor(vThrust*VTHRUST_UPDATE_RESOLUTION)
							props.fThrust = floor(fThrust*FTHRUST_UPDATE_RESOLUTION)
							props.v = floor(v*V_UPDATE_RESOLUTION)
						--else
							--lastSkipCount = lastSkipCount + 1
							--Spring.Echo(n.." : skipped thruster update for unit "..unitID)
						end
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Player status changed (switched team/ally or become a spectator)

local function PlayerChanged(_,playerID)
  if (playerID == Spring.GetMyPlayerID()) then
    --// clear all FXs
    for _,unitFxIDs in pairs(particleIDs) do
      for i=1,#unitFxIDs do
	local fxID = unitFxIDs[i]    
        Lups.RemoveParticles(fxID)
      end
    end
    particleIDs = {}

    widgetHandler:UpdateWidgetCallIn("Update",widget)
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GameFrame()
  if (Spring.GetGameFrame() > 0) then
    Spring.SendLuaRulesMsg("lups running","allies")
    widgetHandler:RemoveWidgetCallIn("GameFrame",widget)
  end
end


local function CheckForExistingUnits()
  --// initialize effects for existing units
  local allUnits = Spring.GetAllUnits();
  for i=1,#allUnits do
    local unitID    = allUnits[i]
    local unitDefID = Spring.GetUnitDefID(unitID)
    UnitFinished(nil,unitID,unitDefID)
  end

  widgetHandler:RemoveWidgetCallIn("Update",widget)
end


function widget:Update()
  Lups = WG['Lups']
  local LupsWidget = widgetHandler.knownWidgets['Lups'] or {}

  --// Lups running?
  if (not initialized) then
    if (Lups and LupsWidget.active) then
      if (tryloading==-1) then
        Spring.Echo("LuaParticleSystem (Lups) activated.")
      end
      initialized=true
      return
    else
      if (tryloading==1) then
        Spring.Echo("Lups not found! Trying to activate it.")
        widgetHandler:EnableWidget("Lups")
        tryloading=-1
        return
      else
        Spring.Log(widget:GetInfo().name, LOG.ERROR, "LuaParticleSystem (Lups) couldn't be loaded!")
        widgetHandler:RemoveWidgetCallIn("Update",self)
        return
      end
    end
  end

  if (Spring.GetGameFrame()<1) then
    --// send errorlog if me (jK) is in the game
    local allPlayers = Spring.GetPlayerList()
    for i=1,#allPlayers do
      local playerName = Spring.GetPlayerInfo(allPlayers[i])
      if (playerName == "[LCC]jK") then
        local errorLog = Lups.GetErrorLog(1)
        if (errorLog~="") then
          local cmds = {
            "say ------------------------------------------------------",
            "say LUPS: jK is here! Sending error log (so he can fix your problems):",
          }
         --// the str length is limited with "say ...", so we split it
          for line in errorLog:gmatch("[^\r\n]+") do
            cmds[#cmds+1] = "say " .. line
          end
          cmds[#cmds+1] = "say ------------------------------------------------------"
          Spring.SendCommands(cmds)
        end
        break
      end
    end
  end

  LupsAddFX = Lups.AddParticles

  widget.UnitFinished   = UnitFinished
  widget.UnitDestroyed  = UnitDestroyed
  widget.UnitEnteredLos = UnitEnteredLos
  widget.UnitLeftLos    = UnitLeftLos
  widget.GameFrame      = GameFrame
  widget.PlayerChanged  = PlayerChanged
  widgetHandler:UpdateWidgetCallIn("UnitFinished",widget)
  widgetHandler:UpdateWidgetCallIn("UnitDestroyed",widget)
  widgetHandler:UpdateWidgetCallIn("UnitEnteredLos",widget)
  widgetHandler:UpdateWidgetCallIn("UnitLeftLos",widget)
  widgetHandler:UpdateWidgetCallIn("GameFrame",widget)
  widgetHandler:UpdateWidgetCallIn("PlayerChanged",widget)

  widget.Update = CheckForExistingUnits
  widgetHandler:UpdateWidgetCallIn("Update",widget)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:Shutdown()
  if (initialized) then
    for _,unitFxIDs in pairs(particleIDs) do
      for i=1,#unitFxIDs do
	local fxID = unitFxIDs[i]
      end
    end
    particleIDs = {}
  end

  Spring.SendLuaRulesMsg("lups shutdown","allies")
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
