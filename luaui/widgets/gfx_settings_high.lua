function widget:GetInfo()
	return {
		name	= "GFX Settings : High",
		desc	= "Changes to a high-detail graphics settings profile",
		author	= "raaar",
		date	= "2022",
		license	= "PD",
		layer	= math.huge,
		enabled	= true
	}
end

VFS.Include("lualibs/util.lua")

function widget:Initialize()
	-- disable other gfx settings widgets
	disableWidget("GFX Settings : Low")
	disableWidget("GFX Settings : Medium")

	-- other widgets
	enableWidget("Bloom Shader")
	
	Spring.SendCommands("water 4")
	Spring.SendCommands("shadows 1")
	Spring.SetConfigInt("ShadowMapSize",4096,false)
	Spring.SendCommands("softparticles 1")
	Spring.SetConfigInt("MaxParticles",30000,false)
	Spring.SetConfigInt("MaxNanoParticles",15000,false)
	Spring.SendCommands("grounddetail 140")	
	Spring.SetConfigInt("GroundDecals",2,false)
	Spring.SetConfigInt("GroundScarAlphaFade",1,false)
 	Spring.SetConfigFloat("snd_airAbsorption",0.1,false)
 	Spring.SetConfigInt("UseSDLAudio",1,false)
 	Spring.SetConfigInt("UseEFX",1,false)
 	Spring.SetConfigInt("DynamicSky",1,false)
 	Spring.SetConfigInt("GrassDetail",0,false)
 	Spring.SetConfigInt("3DTrees",1,false)
 	Spring.SetConfigInt("AdvMapShading",1,false)
 	--Spring.SetConfigInt("AdvSky",1,false)
 	Spring.SetConfigInt("AdvUnitShading",1,false)
 	Spring.SetConfigInt("CompressTextures",0,false)
 	Spring.SetConfigInt("HighResInfoTexture",1,false)
 	Spring.SetConfigInt("LuaShaders",1,false)
 	Spring.SetConfigInt("ROAM",1,false)
 	Spring.SetConfigInt("MSAALevel",4,false)
 	
 	Spring.SetConfigInt("AllowDeferredMapRendering",1,false)
 	Spring.SetConfigInt("AllowDeferredModelRendering",1,false)
 	

	WG.gfxProfile = GFX_HIGH

	Spring.Echo("----------------------------------")
	Spring.Echo("Loaded graphics settings profile : high")	
	Spring.Echo("NOTE: restart recommended on first run or if settings changed")
end

