Spring.Utilities = Spring.Utilities or {}

------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- bool deep: clone subtables. defaults to false. not safe with circular tables!
function Spring.Utilities.CopyTable(tableToCopy, deep)
	local copy = {}
	for key, value in pairs(tableToCopy) do
		if (deep and type(value) == "table") then
			copy[key] = Spring.Utilities.CopyTable(value, true)
		else
			copy[key] = value
		end
	end
	return copy
end

function Spring.Utilities.MergeTable(primary, secondary, deep)
	local new = Spring.Utilities.CopyTable(primary, deep)
	for i, v in pairs(secondary) do
		-- key not used in primary, assign it the value at same key in secondary
		if not new[i] then
			if (deep and type(v) == "table") then
				new[i] = Spring.Utilities.CopyTable(v, true)
			else
				new[i] = v
			end
		-- values at key in both primary and secondary are tables, merge those
		elseif type(new[i]) == "table" and type(v) == "table"  then
			new[i] = Spring.Utilities.MergeTable(new[i], v, deep)
		end
	end
	return new
end

----------------------------------------------------------------------------
-- GROUNDFLASHES -----------------------------------------------------------
----------------------------------------------------------------------------


----------------------------------------------------------------------------
-- BURSTS ------------------------------------------------------------------
----------------------------------------------------------------------------

----------------------------------------------------------------------------
-- COLORSPHERES ------------------------------------------------------------
----------------------------------------------------------------------------


areaShieldSphere = {
	goodColorMap = {{0.8, 0.8, 1.0, 0.5}},
	badColorMap = {{1, 0.1, 0.1, 0.2}},
	life			= math.huge,
	repeatEffect	= true
}

atomShieldSphere = {
	goodColorMap = {{0.8, 0.8, 0.0, 0.5}},
	badColorMap = {{0.0, 0.0, 0.0, 0.2}},
	life			= math.huge,
	repeatEffect	= true
}



----------------------------------------------------------------------------
-- LIGHT -------------------------------------------------------------------
----------------------------------------------------------------------------

local function InterpolateColors(startColor, endColor, steps)
	local output = { startColor }
	local alpha = startColor[4]
	for i=1,steps do
		output[i+1] = {}
		for j=1,3 do
			local stepSize = (endColor[j] - startColor[j])/steps
			output[i+1][j] = output[i][j] + stepSize
		end
		output[i+1][4] = alpha
	end
	output[#output+1] = endColor
	return output
end


blinkyLightWhite = {
  life        = 60,
  lifeSpread  = 0,
  size        = 20,
  sizeSpread  = 0,
  colormap    = { {1, 1, 1, 0.02}, {0, 0, 0, 0}, {0, 0, 0, 0}, {0, 0, 0, 0} },
  texture     = 'bitmaps/GPL/smallflare.tga',
  count       = 1,
  repeatEffect = true,
}

local blinkyLightColors = {
	Red = {1, 0.1, 0.1, 0.02},
	Blue = {0.1, 0.1, 1, 0.02},
	Green = {0, 1, 0.2, 0.02},
	Orange = {0.8, 0.2, 0., 0.02},
	Violet = {0.5, 0, 0.6, 0.02},
}

for name, color in pairs(blinkyLightColors) do
	local key = "blinkyLight"..name
	widget[key] = Spring.Utilities.CopyTable(blinkyLightWhite, true)
	widget[key]["colormap"][1] = color
end

----------------------------------------------------------------------------
-- SimpleParticles ---------------------------------------------------------
----------------------------------------------------------------------------


sparks = {
  speed        = 0,
  speedSpread  = 0,
  life         = 90,
  lifeSpread   = 10,
  partpos      = "x,0,0 | if(rand()*2>1) then x=0 else x=20 end",
  colormap     = { {0.8, 0.8, 0.8, 0.01}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, },
  rotSpeed     = 0.1,
  rotFactor    = 1.0,
  rotFactorSpread = -2.0,
  rotairdrag   = 0.99,
  rotSpread    = 360,
  size         = 10,
  sizeSpread   = 12,
  sizeGrowth   = 0.4,
  emitVector   = {0,0,0},
  emitRotSpread = 70,
  texture      = 'bitmaps/PD/Lightningball.TGA',
  count        = 6,
  repeatEffect = true,
}
sparks1 = {
  speed        = 0,
  speedSpread  = 0,
  life         = 20,
  lifeSpread   = 20,
  partpos      = "5-rand()*10, 5-rand()*10, 5-rand()*10 ",
  --partpos      = "0,0,0",
  colormap     = { {0.8, 0.8, 0.2, 0.01}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, {0, 0, 0, 0.0}, },
  rotSpeed     = 0.1,
  rotFactor    = 1.0,
  rotFactorSpread = -2.0,
  rotairdrag   = 0.99,
  rotSpread    = 360,
  size         = 10,
  sizeSpread   = 12,
  sizeGrowth   = 0.4,
  emitVector   = {0,0,0},
  emitRotSpread = 70,
  texture      = 'bitmaps/PD/Lightningball.TGA',
  count        = 6,
  repeatEffect = true,
}

