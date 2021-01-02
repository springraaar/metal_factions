function widget:GetInfo()
  return {
    name      = "UI keys",
    desc      = "Adds actions to some key combinations",
    author    = "raaar",
    date      = "2015",
    license   = "PD",
    layer     = 10,
    enabled   = true
  }
end

include("keysym.h.lua")


-- custom commands
local CMD_UPGRADEMEX = 31244
local CMD_UPGRADEMEX2 = 31245
local CMD_AREAMEX = 31246 

local menuSecond = -1
WG.menuShown = false
WG.customHotkeys = {}
WG.unboundDefKeys = {}
local shouldShowMenu = false
local shouldSelectCom = false

local customKeybindsFile = "LuaUI/Configs/mf_keys.txt"

local function trim(s)
	return string.match(s,"[%s\t\n\v\f\r]*(.-)[%s\t\n\v\f\r]*$")
end

local function removeComments(s)
	local idx = string.find(s, '//', 1, true)
	if idx then
		return string.sub(s,1,idx-1)
	end
	return s
	--return string.sub(s,1,2) == "//"
end

local function unbindKey(key)
	Spring.SendCommands("unbindkeyset "..key)
	Spring.SendCommands("unbindkeyset Shift+"..key)
	WG.unboundDefKeys[key] = true
end

function getArray(str)
	local arr = {}
	for token in string.gmatch(str, "([^,]+)") do
		arr[#arr+1] = token
	end
	return arr
end


--------------------------------------------

function widget:Initialize()
	Spring.SendCommands("unbindaction showmetalmap")
	Spring.SendCommands("unbindaction quitmenu")
   
	-- try to load custom key binds
	if VFS.FileExists(customKeybindsFile) then
		local text = VFS.LoadFile(customKeybindsFile)
		
		-- process the content line by line
		local line = ""
		local key,action,unitArray
		if text then
			text = text:gsub("[\r]", "")
			for _line in text:gmatch("([^\n]*)") do
				line = trim(removeComments(_line))
				if string.len(line) > 0 then
					Spring.Echo("MFKEYS : processing line \""..line.."\"")
					if line == "swap_a_f" then
						unbindKey("a")
						unbindKey("f")
						Spring.SendCommands("bind                  f  attack")
						Spring.SendCommands("bind              Alt+f  areaattack")
						Spring.SendCommands("bind            Shift+f  attack")
						Spring.SendCommands("bind        Alt+Shift+f  areaattack")
						Spring.SendCommands("bind                  a  fight")
						Spring.SendCommands("bind            Shift+a  fight")		
						Spring.Echo("MFKEYS : A and F actions swapped")
						WG.customHotkeys["attack"] = "f"
						WG.customHotkeys["fight"] = "a"
					elseif string.sub(line,1,2) == "MB" then
						-- special MF binding
						local tokens = {}
						-- get tokens
						for token in string.gmatch(line, "[^%s]+") do
			   				tokens[#tokens+1] = token
						end
						
						local key = tokens[2]
						local action = tokens[3]
						
						if ( action == "wall") then
							unbindKey(key)
							local unitArray = {"aven_fortification_wall","gear_fortification_wall","claw_fortification_wall","sphere_fortification_wall"}
							for _,u in pairs(unitArray) do
								Spring.SendCommands("bind "..key.." buildunit_"..u)
								Spring.SendCommands("bind Shift+"..key.." buildunit_"..u)
								WG.customHotkeys["build_"..u] = key
							end
						elseif ( action == "areamex" or action == "areamex2" or action == "areamex2h" ) then
							unbindKey(key)
							Spring.SendCommands("bind "..key.." "..action)
							Spring.SendCommands("bind Shift+"..key.." "..action)
							WG.customHotkeys[action] = key
						elseif ( action == "build") then
							unbindKey(key)
							unitArray = getArray(tokens[4])
							for _,u in pairs(unitArray) do
								Spring.SendCommands("bind "..key.." buildunit_"..u)
								Spring.SendCommands("bind Shift+"..key.." buildunit_"..u)
								WG.customHotkeys["build_"..u] = key
							end
						end
					else
						-- regular binding						
						Spring.SendCommands(line)
					end
				end
			end
		end
	else
		Spring.Echo("no custom keybinds found")
	end
end


function widget:KeyPress(key, mods, isRepeat)
	if (key == KEYSYMS.C) and mods.ctrl then
		-- get team units
		local unitList = Spring.GetTeamUnits(Spring.GetMyTeamID())
		
		-- find and select the commander
		for i=1,#unitList do
			local unitID    = unitList[i]
			local unitDefID = Spring.GetUnitDefID(unitID)
			local unitDef   = UnitDefs[unitDefID or -1]
			local cp 		= unitDef.customParams or nil
			
			if unitDef and cp and cp.iscommander then
				shouldSelectCom = unitID
				local x,y,z = Spring.GetUnitPosition(unitID)
				Spring.SetCameraTarget(x,y,z)
				return false
			end
		end
	elseif (key == KEYSYMS.ESCAPE) then
		if (not WG.menuShown) then
			shouldShowMenu = true
		else 
			WG.menuShown = false
		end
	elseif (key == KEYSYMS.F4) then
		Spring.SendCommands("showmetalmap")
	elseif (key == KEYSYMS.F10) then
		Spring.SendCommands("screenshot png")
	end
end

-- workaround for menu not showing up
function widget:KeyRelease()
	if (shouldShowMenu) then
		Spring.SendCommands("quitmenu")
		WG.menuShown = true
		shouldShowMenu = false
	elseif (shouldSelectCom) then
		Spring.SelectUnitArray({shouldSelectCom})
		shouldSelectCom = false
	end
end


