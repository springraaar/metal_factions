-----------------------------------------
-- Engine tree model replacements, made by Beherith
-- copied from ZK in April, 2019
-- license probably GPL
-----------------------------------------

local objects = {
	"behepine_regular_2.s3o",
	"behepine_regular_3.s3o",
	"behepine_regular_1.s3o",

	"behepine_brown_1.s3o",
	"behepine_brown_2.s3o",
	"behepine_brown_3.s3o",
}

local treeDefs = {}
local function CreateTreeDef(i)
	treeDefs["treetype" .. i] = {
		description = [[Tree]],
		blocking    = true,
		burnable    = true,
		reclaimable = true,
		energy      = 250,
		damage      = 50,
		metal       = 0,
		reclaimTime = 1000,
		mass        = 50,
		object = objects[(i % #objects) + 1] ,
		footprintX  = 2,
		footprintZ  = 2,
		collisionVolumeScales = [[20 42 20]],
		collisionVolumeType = [[cylY]],

		customParams = {
			mod = true,
			scale = 1.6,
		},
	}
end

for i=0,20 do
  CreateTreeDef(i)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return lowerkeys( treeDefs )

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------