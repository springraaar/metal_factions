function gadget:GetInfo()
   return {
      name = "Lua GC",
      desc = "More aggressive garbage collection to prevent memory issues",
      author = "raaar",
      date = "2022",
      license = "PD",
      layer = 0,
      enabled = true,
   }
end

GC_FRAMES = 11

VFS.Include("luarules/system.lua")

--UNSYNCED CODE
if not gadgetHandler:IsSyncedCode() then


function gadget:GameFrame(n) 
	if (n%GC_FRAMES == 0) then
		if (collectgarbage) then
			--Spring.Echo("LUA collecting garbage")
			collectgarbage("collect")
		end
	end
end


end