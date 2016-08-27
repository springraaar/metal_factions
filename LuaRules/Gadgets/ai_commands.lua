function gadget:GetInfo()
   return {
      name = "AI interaction gadget",
      desc = "Makes human player's chat starting with 'AI' available to shard AI on the same team.",
      author = "raaar",
      date = "August 2013",
      license = "PD",
      layer = 1,
      enabled = true,
   }
end

--UNSYNCED CODE
if (not gadgetHandler:IsSyncedCode()) then
	function gadget:RecvSkirmishAIMessage(aiTeam,aiMessage)
		Spring.Echo("gadget : data from AI="..aiTeam.." / "..tostring(aiMessage))
		return "TEST RESPONSE"
	end
end


