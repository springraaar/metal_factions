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
VFS.Include("lualibs/custom_cmd.lua")

local menuSecond = -1
WG.customHotkeys = {}
WG.unboundDefKeys = {}
local shouldShowMenu = false
local shouldSelectCom = false

local customKeybindsFile = "luaui/configs/mf_keys.txt"

local keybindsFileTxt = [[
// ---------- mf keybind instructions
// EXAMPLES:
// this is a comment, remove them from the relevant lines below to enable them, or add your own
//swap_a_f		// swaps A and F hotkeys (most games use A for attack-move/fight instead of F)
//MB w wall		// build small wall, any faction
//MB z areamex		// area metal extractor command
//MB x areamex2		// area metal extractor command, level 2
//MB c areamex2h	// area metal extractor command, level 2 (exploiter)
//MB v build aven_nano_tower,gear_nano_tower,claw_nano_tower,sphere_pole		// try to build units from a list, separated by "," (generally one from each faction)
//MB v build aven_light_laser_tower,aven_defender,aven_stasis,aven_sentinel		// alternate between trying to build units from a list, separated by ","
//MB <key> <action>	// supported actions: fight,attack,patrol,repair,guard,reclaim,restore,capture,loadunits,unloadunits,wait,onoff,selfd,priority

MB w wall
MB z areamex
MB x areamex2
MB c areamex2h
MB v build aven_nano_tower,gear_nano_tower,claw_nano_tower,sphere_pole

// ---------- regular keybind instructions
// bind shift+v buildunit_aven_weaver
// bind v buildunit_aven_weaver
// ...
]]

local function trim(s)
	return string.match(s,"[%s\t\n\v\f\r]*(.-)[%s\t\n\v\f\r]*$")
end

local function removeComments(s)
	local idx = string.find(s, '//', 1, true)
	if idx then
		return string.sub(s,1,idx-1)
	end
	return s
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
	--Spring.SendCommands("unbindaction quitmenu")
	Spring.SendCommands("unbind esc quitmenu")
	Spring.SendCommands("bind Shift+esc quitmenu")
   
	-- create a custom keybinds file with default content if it's missing
	if not VFS.FileExists(customKeybindsFile) then
		Spring.Echo("creating mf keybinds file with default content at "..customKeybindsFile)
		Spring.CreateDir("luaui")
		Spring.CreateDir("luaui/configs")
		io.output(customKeybindsFile)
		io.write(keybindsFileTxt)
	else
		keybindsFileTxt = VFS.LoadFile(customKeybindsFile)
	end
   
	-- try to load custom key binds
	if keybindsFileTxt then
		local text = keybindsFileTxt
		
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
						else
							unbindKey(key)
							Spring.SendCommands("bind "..key.." "..action)
							Spring.SendCommands("bind Shift+"..key.." "..action)
							WG.customHotkeys[action] = key
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
	
	-- default key overrides
	if (not WG.unboundDefKeys or not WG.unboundDefKeys["j"]) then
		if (not WG.customHotkeys["jump"]) then
			unbindKey("j")
			Spring.SendCommands("bind j jump")
			Spring.SendCommands("bind Shift+j jump")
			WG.customHotkeys["jump"] = "j"
		end
	end
	if (not WG.unboundDefKeys or not WG.unboundDefKeys["o"]) then
		if (not WG.customHotkeys["onoff"]) then
			unbindKey("o")
			Spring.SendCommands("bind o onoff")
			Spring.SendCommands("bind Shift+o onoff")
			WG.customHotkeys["onoff"] = "o"
		end
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
	elseif (key == KEYSYMS.F4) then
		Spring.SendCommands("showmetalmap")
	elseif (key == KEYSYMS.F10) then
		Spring.SendCommands("screenshot png")
	end
end

-- workaround for menu not showing up
function widget:KeyRelease()
	if (shouldSelectCom) then
		Spring.SelectUnitArray({shouldSelectCom})
		shouldSelectCom = false
	end
end


