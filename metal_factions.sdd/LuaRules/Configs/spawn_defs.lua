--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local hardModifier   = 0.75
spawnSquare          = 150       -- size of the chicken spawn square centered on the burrow
spawnSquareIncrement = 1         -- square size increase for each unit spawned
burrowName           = "roost"   -- burrow unit name
playerMalus          = .95         -- how much harder it becomes for each additional player
maxChicken           = Spring.GetModOptions().mo_maxchicken*1
lagTrigger           = 5       -- average cpu usage after which lag prevention mode triggers
triggerTolerance     = 0.5      -- increase if lag prevention mode switches on and off too fast
maxAge               = 5*60      -- chicken die at this age, seconds
queenName            = "fleagoth"
waveRatio            = 0.6       -- waves are composed by two types of chicken, waveRatio% of one and (1-waveRatio)% of the other
defenderChance       = 0.7       -- amount of turrets spawned per wave, <1 is the probability of spawning a single turret
maxBurrows           = Spring.GetModOptions().mo_maxburrows*1
queenSpawnMult       = 3         -- how many times bigger is a queen hatch than a normal burrow hatch
alwaysVisible        = true     -- chicken are always visible
burrowSpawnRate      = 50       -- higher in games with many players, seconds
upgradeTime		   = 10*60
chickenSpawnRate     = 100
minBaseDistance      = 1000      
maxBaseDistance      = 5000
gracePeriod          = 180       -- no chicken spawn in this period, seconds
--burrowEggs           = Spring.GetModOptions().mo_burroweggs*1        -- number of eggs each burrow spawns
queenTime            = Spring.GetModOptions().mo_queentime*60 -- time at which the queen appears, seconds

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function Copy(original)   -- Warning: circular table references lead to
  local copy = {}               -- an infinite loop.
  for k, v in pairs(original) do
    if (type(v) == "table") then
      copy[k] = Copy(v)
    else
      copy[k] = v
    end
  end
  return copy
end


local function TimeModifier(d, mod)
  for chicken, t in pairs(d) do
    t.time = t.time*mod
    if (t.obsolete) then
      t.obsolete = t.obsolete*mod
    end
  end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- times in minutes
local easychickenTypes = {
  armflea      =  {time =  0,  squadSize = 3,  obsolete = 20},
  armfleaa      =  {time =  10,  squadSize = 1, obsolete = 25},
  armfly     =  {time =  15,  squadSize = 2,  obsolete = 30},
  order_deathray      =  {time =  20,  squadSize = 0.65,  obsolete = 40},
  mflea     =  {time = 25,  squadSize = 0.8},
  order_drill      =  {time =  30,  squadSize = 0.5},
  armflyk	=  {time = 40,  squadSize = 2},
  order_fork	=  {time = 50,  squadSize = 0.01,  obsolete = 61},
}

local chickenTypes = {
  armflea      =  {time =  0,  squadSize = 3,  obsolete = 18},
  armfleaa      =  {time =  10,  squadSize = 1.5, obsolete = 30},
  armfly     =  {time =  11,  squadSize = 3,  obsolete = 25},
  order_deathray      =  {time =  20,  squadSize = 0.65,  obsolete = 40},
  mflea     =  {time = 25,  squadSize = 0.8,  obsolete = 40},
  order_drill      =  {time =  25,  squadSize = 0.25,  obsolete = 35},
  armflyk	=  {time = 40,  squadSize = 3,  obsolete = 77},
  order_fork	=  {time = 45,  squadSize = 0.1,  obsolete = 61},
  minigoth	=  {time = 50,  squadSize = 0.05},
}


local chickenCruelTypes = {
  armflea      =  {time =  0,  squadSize = 3,  obsolete = 10},
  armfleaa      =  {time =  8,  squadSize = 1, obsolete = 25},
  armfly     =  {time =  9,  squadSize = 2,  obsolete = 15},
  order_deathray      =  {time =  15,  squadSize = 0.65,  obsolete = 30},
  mflea     =  {time = 20,  squadSize = 0.8,  obsolete = 55},
  order_drill      =  {time =  25,  squadSize = 0.25,  obsolete = 37},
  armflyk	=  {time = 32,  squadSize = 3,  obsolete = 91},
  order_fork	=  {time = 37,  squadSize = 0.5,  obsolete = 61},
  minigoth	=  {time = 40,  squadSize = 1},
}

local retardmadTypes = {
  armflea      =  {time =  0,  squadSize = 4,  obsolete = 10},
  armfleaa      =  {time =  8,  squadSize = 1, obsolete = 24},
  armfly     =  {time =  10,  squadSize = 2,  obsolete = 30},
  order_deathray      =  {time =  14,  squadSize = 0.3,  obsolete = 50},
  mflea     =  {time = 20,  squadSize = 0.5},
  order_drill      =  {time =  25,  squadSize = 0.25,  obsolete = 37},
  armflyk	=  {time = 34,  squadSize = 3},
  order_fork	=  {time = 44,  squadSize = 0.5},
  minigoth	=  {time = 44,  squadSize = 0.5},
}

local fireTypes = {
  order_fire      =  {time =  0,  squadSize = 0.1,  obsolete = 30},
  order_nova      =  {time =  30,  squadSize = 0.1, obsolete = 50},
  order_plasma      =  {time =  60,  squadSize = 0.1, obsolete = 60},
}

local defenders = {
  aven_defender =  {time =  5,  squadSize = 0.5, obsolete = 15},
  aven_flakker =  {time =  15,  squadSize = 0.5, obsolete = 60},
  }
    
    
difficulties = {
  ['FLEAS: Easy'] = {
    chickenSpawnRate = 120, 
    burrowSpawnRate  = 60,
    gracePeriod      = 300,
    firstSpawnSize   = 1,
    timeSpawnBonus   = .01,     -- how much each time level increases spawn size
    chickenTypes     = Copy(easychickenTypes),
    defenders        = Copy(defenders),
  },

  ['FLEAS: Normal'] = {
    chickenSpawnRate = 90, 
    burrowSpawnRate  = 40,
    firstSpawnSize   = 2,
    timeSpawnBonus   = .02,
    chickenTypes     = Copy(chickenTypes),
    defenders        = Copy(defenders),
  },

  ['FLEAS: Hard'] = {
    chickenSpawnRate = 60, 
    burrowSpawnRate  = 30,
    firstSpawnSize   = 2,
    gracePeriod      = 150,
    timeSpawnBonus   = .04,
    chickenTypes     = Copy(chickenTypes),
    defenders        = Copy(defenders),
  },

  ['FLEAS: Cruel'] = {
    chickenSpawnRate = 60, 
    burrowSpawnRate  = 20,
    firstSpawnSize   = 3,
    gracePeriod      = 150,
    timeSpawnBonus   = .05,
    chickenTypes     = Copy(chickenCruelTypes),
    defenders        = Copy(defenders),
  },

  ['Fleas: Impossible Cream'] = {
    chickenSpawnRate = 120, 
    burrowSpawnRate  = 1,
    firstSpawnSize   = 6,
    gracePeriod      = 300,
    timeSpawnBonus   = .1,
    chickenTypes     = Copy(retardmadTypes),
    defenders        = Copy(defenders),
  },
  ['Fire Spirits Edition'] = {
    chickenSpawnRate = 90, 
    burrowSpawnRate  = 1,
    firstSpawnSize   = 2,
    gracePeriod      = 200,
    timeSpawnBonus   = .999,
    chickenTypes     = Copy(fireTypes),
    defenders        = Copy(defenders),
  },
}



-- minutes to seconds
for _, d in pairs(difficulties) do
  d.timeSpawnBonus = d.timeSpawnBonus/60
  TimeModifier(d.chickenTypes, 60)
  TimeModifier(d.defenders, 60)
end


TimeModifier(difficulties['FLEAS: Hard'].chickenTypes, hardModifier)
TimeModifier(difficulties['FLEAS: Hard'].defenders,    hardModifier)


--difficulties['Chicken Eggs: Easy']   = Copy(difficulties['FLEAS: Easy'])
--difficulties['Chicken Eggs: Normal'] = Copy(difficulties['FLEAS: Normal'])
--difficulties['Chicken Eggs: Hard']   = Copy(difficulties['FLEAS: Hard'])

--difficulties['Chicken Eggs: Easy'].eggs   = true
--difficulties['Chicken Eggs: Normal'].eggs = true
--difficulties['Chicken Eggs: Hard'].eggs   = true

defaultDifficulty = 'FLEAS: Normal'

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
