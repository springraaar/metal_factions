----------------- Security overrides

Spring.Start = nil
Spring.Restart = nil

function overrides()
	-- use whitelist of allowed files to read/write
	local fileRWWhiteList = {
		["luaui/Config/metal_factions.lua"] = true,
		["luaui/configs/mf_strategies.json"] = true,
		["luaui/configs/mf_keys.txt"] = true,
		["luaui/configs/mf_optional_units.txt"] = true,
		["cmdcolors_mf.txt"] = true,
		["cmdcolors.tmp"] = true,
		["cmdcolors.txt"] = true,
	}

	if os then
		local osRemove = os.remove
		os.remove = function(file)
			if (fileRWWhiteList[file]) then
				return osRemove(file)
			else
				Spring.Echo("WARNING : Attempting to os.remove file "..file.." : BLOCKED")
			end
		end
		os.execute = nil
		os.rename = nil
	end

	if io then
		local ioOpen = io.open
		io.open = function(file,mode)
			if (fileRWWhiteList[file]) then
				return ioOpen(file,mode)
			else
				Spring.Echo("WARNING : Attempting to io.open file "..file.." : BLOCKED")
			end
		end
		
		local ioInput = io.input
		io.input = function(file)
			if (fileRWWhiteList[file]) then
				return ioInput(file)
			else
				Spring.Echo("WARNING : Attempting to io.input file "..file.." : BLOCKED")
			end
		end

		local ioLines = io.lines
		io.lines = function(file)
			if (fileRWWhiteList[file]) then
				return ioLines(file)
			else
				Spring.Echo("WARNING : Attempting to io.lines file "..file.." : BLOCKED")
			end
		end
		
		io.popen = nil
	end
end

overrides()
