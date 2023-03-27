function widget:GetInfo()
	return {
		name	= "GFX Settings : Low",
		desc	= "Changes to a low-detail graphics settings profile, for better performance",
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
	disableWidget("GFX Settings : Medium")
	disableWidget("GFX Settings : High")

	-- disable other widgets
	disableWidget("Bloom Shader")
	disableWidget("Contrast Adaptive Sharpen")
	disableWidget("Outline")

	Spring.SendCommands("water 0")
	Spring.SendCommands("shadows 0")
	Spring.SetConfigInt("ShadowMapSize",0,false)
	Spring.SendCommands("softparticles 0")
	Spring.SetConfigInt("MaxParticles",20000,false)
	Spring.SetConfigInt("MaxNanoParticles",10000,false)
	Spring.SendCommands("grounddetail 100")	
	Spring.SetConfigInt("GroundDecals",0,false)
	Spring.SetConfigInt("GroundScarAlphaFade",0,false)
 	Spring.SetConfigFloat("snd_airAbsorption",0.0,false)
 	Spring.SetConfigInt("UseSDLAudio",1,false)
 	Spring.SetConfigInt("UseEFX",0,false)
 	Spring.SetConfigInt("DynamicSky",0,false)
 	Spring.SetConfigInt("GrassDetail",0,false)
 	Spring.SetConfigInt("3DTrees",0,false)
 	Spring.SetConfigInt("AdvMapShading",0,false)
 	--Spring.SetConfigInt("AdvSky",0,false)
 	Spring.SetConfigInt("AdvUnitShading",0,false)
 	Spring.SetConfigInt("CompressTextures",1,false)
 	Spring.SetConfigInt("HighResInfoTexture",0,false)
 	Spring.SetConfigInt("LuaShaders",1,false)
 	Spring.SetConfigInt("ROAM",2,false)
 	Spring.SetConfigInt("MSAALevel",0,false)	

	WG.gfxProfile = GFX_LOW
	
	Spring.Echo("----------------------------------")
	Spring.Echo("Loaded graphics settings profile : low")
	Spring.Echo("NOTE: restart recommended on first run or if settings changed")
end

