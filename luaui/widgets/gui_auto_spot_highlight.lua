function widget:GetInfo()
  return {
    name      = "Auto Show Resource Spots",
    desc      = "Toggles metal/geo highlight view when issuing extractor build commands",
    license   = "PD",
    author    = "raaar",
    layer     = -50,
    enabled   = true
  }
end


-- custom commands
VFS.Include("lualibs/custom_cmd.lua")


local spGetActiveCommand = Spring.GetActiveCommand
local spSendCommands = Spring.SendCommands
local spGetMapDrawMode = Spring.GetMapDrawMode

local resourceViewCommands = {}


function widget:Initialize()
	if Spring.SetAutoShowMetal then
		-- disable automatic showmetal control, check existence so this will
		-- keep working when AutoShowMetal gets removed from future engine version.
		Spring.SetAutoShowMetal(false)
	end

	for uDefID, uDef in pairs(UnitDefs) do
		if uDef.extractsMetal > 0 or uDef.needGeo then
			resourceViewCommands[uDefID] = true
		end
	end

	-- also add area mex commands
	resourceViewCommands[-CMD_UPGRADEMEX] = true
	resourceViewCommands[-CMD_UPGRADEMEX2] = true
	resourceViewCommands[-CMD_AREAMEX] = true
end



local oldCmdID = nil
function widget:DrawWorld()
	local _, cmdID, _ = spGetActiveCommand()
	if cmdID ~= oldCmdID then
		local shouldEnableResourceView = (cmdID and resourceViewCommands[-cmdID]) or false
		local isResourceViewOn = (spGetMapDrawMode() == 'metal')
	
		if shouldEnableResourceView ~= isResourceViewOn then
			spSendCommands("showmetalmap")
		end
		
		oldCmdID = cmdID
	end
end
