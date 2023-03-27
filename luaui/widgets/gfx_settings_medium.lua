function widget:GetInfo()
	return {
		name	= "GFX Settings : Medium",
		desc	= "Changes to a medium-detail graphics settings profile",
		author	= "raaar",
		date	= "2022",
		license	= "PD",
		layer	= math.huge,
		enabled	= false
	}
end

VFS.Include("lualibs/util.lua")

function widget:Initialize()
	-- disable other gfx settings widgets
	disableWidget("GFX Settings : Low")
	disableWidget("GFX Settings : High")

	-- disable other widgets
	disableWidget("Bloom Shader")
	disableWidget("Contrast Adaptive Sharpen")
	disableWidget("Outline")

	Spring.SendCommands("water 1")
	Spring.SendCommands("shadows 2")
	Spring.SetConfigInt("ShadowMapSize",2048,false)
	Spring.SendCommands("softparticles 1")
	Spring.SetConfigInt("MaxParticles",30000,false)
	Spring.SetConfigInt("MaxNanoParticles",15000,false)
	Spring.SendCommands("grounddetail 140")	
	Spring.SetConfigInt("GroundDecals",4,false)
	Spring.SetConfigInt("GroundScarAlphaFade",1,false)
 	Spring.SetConfigFloat("snd_airAbsorption",0.1,false)
 	Spring.SetConfigInt("UseSDLAudio",1,false)
 	Spring.SetConfigInt("UseEFX",1,false)
 	Spring.SetConfigInt("DynamicSky",0,false)
 	Spring.SetConfigInt("GrassDetail",5,false)
 	Spring.SetConfigInt("3DTrees",1,false)
 	Spring.SetConfigInt("AdvMapShading",1,false)
 	--Spring.SetConfigInt("AdvSky",1,false)
 	Spring.SetConfigInt("AdvUnitShading",1,false)
 	Spring.SetConfigInt("CompressTextures",0,false)
 	Spring.SetConfigInt("HighResInfoTexture",1,false)
 	Spring.SetConfigInt("LuaShaders",1,false)
 	Spring.SetConfigInt("ROAM",1,false)
 	Spring.SetConfigInt("MSAALevel",2,false)

	WG.gfxProfile = GFX_MEDIUM

	Spring.Echo("----------------------------------")
	Spring.Echo("Loaded graphics settings profile : medium")
	Spring.Echo("NOTE: restart recommended on first run or if settings changed")	
end

