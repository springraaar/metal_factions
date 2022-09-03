local folder = "sounds/"
local ambientVolume = 1.0

local soundItems = {}
local name = "FEATURECRUSH"
soundItems[name] = {
	name = name,
	file = folder..name..".ogg",
	gain = 1.0,
	pitch = 1.0,
	pitchMod = 0.1,
	gainMod = 0.075,
	priority = -1,
	maxconcurrent = 6, 
	maxdist = 2500, 
	preload = true,
	in3d = true,
	rolloff = 0.1,
	rnd = 1,
	offset = 0,
}
name = "DASHSTART"
soundItems[name] = {
	name = name,
	file = folder..name..".wav",
	gain = 1.0,
	pitch = 1.0,
	pitchMod = 0.1,
	gainMod = 0.075,
	priority = -1,
	maxconcurrent = 4, 
	maxdist = 2500, 
	preload = true,
	in3d = true,
	rolloff = 0.2,
	rnd = 1,
	offset = 0,
}
name = "GENERICCMD"
soundItems[name] = {
	name = name,
	file = folder..name..".wav",
	gain = 1.0,
	pitch = 1.0,
	maxconcurrent = 6, 
	preload = true,
	in3d = false,
}
name = "WARNING1"
soundItems[name] = {
	name = name,
	file = folder..name..".wav",
	gain = 1.0,
	pitch = 1.0,
	maxconcurrent = 6, 
	preload = true,
	in3d = false,
}
return { sounditems = soundItems }, ambientVolume

