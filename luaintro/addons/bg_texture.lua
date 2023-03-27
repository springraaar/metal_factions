
if addon.InGetInfo then
	return {
		name    = "LoadTexture",
		desc    = "",
		author  = "jK",
		date    = "2012",
		license = "GPL2",
		layer   = 2,
		depend  = {"LoadProgress"},
		enabled = true,
	}
end

------------------------------------------

local loadscreens = VFS.DirList("bitmaps/loadpictures/")
-- add the first image twice, to make it more likely to show up
loadscreens[#loadscreens+1] = loadscreens[1] 
local backgroundTexture = loadscreens[ math.random(#loadscreens) ]
local aspectRatio

local version = Game.gameVersion
if version == "workbench" or version == "$VERSION" then
	version = "vX.XX"
end

local vsx, vsy = gl.GetViewSizes()
local refFontSize = 32
local refBoxSizeX = 100
local refBoxSizeY = 44
local fontSize = refFontSize
local scaleFactor = 1

-- colors
local cText = {1, 0.8, 0, 1}
local cBorder = {1, 0.8, 0, 1}		
local cBack = {0, 0, 0, 1}

local versionLabel = {}

function updateSizesPositions()
	if (vsy > 1080) then
		scaleFactor = vsy/1080
	else
		scaleFactor = 1
	end
	fontSize = refFontSize * scaleFactor 
	versionLabel.x1 = vsx - 40*scaleFactor - refBoxSizeX*scaleFactor
	versionLabel.x2 = vsx - 40*scaleFactor
	versionLabel.y1 = vsy - 40*scaleFactor - refBoxSizeY*scaleFactor
	versionLabel.y2 = vsy - 40*scaleFactor
	
	--Spring.Echo("vx1="..versionLabel.x1.." vx2="..versionLabel.x2)
end

function addon.Initialize() 
	updateSizesPositions()
end

function addon.ViewResize(viewSizeX, viewSizeY)
	vsx = viewSizeX
	vsy = viewSizeY
	updateSizesPositions()
end


function addon.DrawLoadScreen()
	local loadProgress = SG.GetLoadProgress()

	if not aspectRatio then
		local texInfo = gl.TextureInfo(backgroundTexture)
		if not texInfo then return end
		aspectRatio = texInfo.xsize / texInfo.ysize
	end
	local screenAspectRatio = vsx / vsy

	local xDiv = 0
	local yDiv = 0
	local ratioComp = screenAspectRatio / aspectRatio

	if (ratioComp > 1) then
		xDiv = (1 - (1 / ratioComp)) * 0.5;
	elseif (math.abs(ratioComp - 1) < 0) then
	else
		yDiv = (1 - ratioComp) * 0.5;
	end

	-- background
	gl.Color(1,1,1,1)
	gl.Texture(backgroundTexture)
	gl.TexRect(0+xDiv,0+yDiv,1-xDiv,1-yDiv)
	gl.Texture(false)

	-- also draw game version near the top-right corner
	gl.PushMatrix()
	gl.Scale(1/vsx,1/vsy,1)
	gl.Color(cBack)
	gl.Rect(versionLabel.x1,versionLabel.y1,versionLabel.x2,versionLabel.y2)
	gl.Color(cText)
	gl.Text(version,(versionLabel.x1 + versionLabel.x2) /2, (versionLabel.y1 + versionLabel.y2) / 2-fontSize/3,fontSize,"c")
	gl.Color(cBorder)
	gl.Rect(versionLabel.x1,versionLabel.y1,versionLabel.x1+2,versionLabel.y2)
	gl.Rect(versionLabel.x2-2,versionLabel.y1,versionLabel.x2,versionLabel.y2)
	gl.Rect(versionLabel.x1,versionLabel.y1,versionLabel.x2,versionLabel.y1+2)
	gl.Rect(versionLabel.x1,versionLabel.y2-2,versionLabel.x2,versionLabel.y2)
	gl.Color(1,1,1,1)
	gl.PopMatrix()
end

function addon.Shutdown()
	gl.DeleteTexture(backgroundTexture)
end
