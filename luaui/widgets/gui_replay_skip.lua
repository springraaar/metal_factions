function widget:GetInfo()
	return {
		name    = "Replay Setup Skip",
		desc    = "Skips starting setup and position selection delay when viewing replays",
		author  = "raaar",
		date    = "2022",
		license = "PD",
		layer   = 0,
		enabled = true
	}
end

local isReplay = Spring.IsReplay()
local skipped = false
local canSkip = false 

----------------------------- CALLINS

function widget:AddConsoleLine(msg,priority)
	if (isReplay and (not canSkip) and (not skipped)) then
		if (msg:find("^Player" ) ~= nil and string.find(msg,"finished loading and")) then
			--Spring.Echo("MSG="..msg)
			canSkip = true
		end
	end
end

function widget:Update()
	if (isReplay) then
		if (canSkip and not skipped) then
			Spring.SendCommands("skip 1")
			skipped = true
		end
	end
end