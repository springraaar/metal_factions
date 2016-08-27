
if addon.InGetInfo then
	return {
		name    = "Music",
		desc    = "plays music",
		author  = "jK",
		date    = "2012,2013",
		license = "GPL2",
		layer   = 0,
		depend  = {"LoadProgress"},
		enabled = true,
	}
end

------------------------------------------

Spring.SetSoundStreamVolume(0)
local musicfiles = VFS.DirList(LUA_DIRNAME .. "music", "*.ogg")
local musicSetting = Spring.GetConfigInt('snd_intromusic') or 0
if musicSetting ~= 1 then musicSetting = 0 end -- prevent users from inputtting weird data
Spring.SetConfigInt('snd_intromusic', musicSetting)

if (#musicfiles > 0) and musicSetting == 1 then
	Spring.PlaySoundStream(musicfiles[ math.random(#musicfiles) ], 1)
	Spring.SetSoundStreamVolume(0)
	Spring.Echo("Music files: ", #musicfiles)
end


function addon.DrawLoadScreen()
	local loadProgress = SG.GetLoadProgress()

	-- fade in & out music with progress
	if (loadProgress < 0.9) then
		Spring.SetSoundStreamVolume(0.9)
	else
		Spring.SetSoundStreamVolume(0.9 + ((0.9 - loadProgress) * 9))
	end
end


function addon.Shutdown()
	Spring.StopSoundStream()
	Spring.SetSoundStreamVolume(1)
end
