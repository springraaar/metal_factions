--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    LuaRules/Configs/deployment.lua
--  brief:   LuaRules deployment mode configuration
--  author:  Dave Rodgers
--
--  Copyright (C) 2007.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local noCustomBuilds = true


local deployment = {

  maxFrames = 180 * Game.gameSpeed,

  maxUnits  = 600,

  maxMetal  = 3000,
  maxEnergy = 20000,

  maxRadius = 1024,

  maxAutoBuildLevels = 1,

  customBuilds = {

    ['armcom'] = {
      allow = {
        --'armcom',
        'armmav',
      },
      forbid = {},
    },

    ['corcom'] = {
      allow = {
        --'corcom',
        'corpyro',
      },
      forbid = {},
    },
  },
}


if (noCustomBuilds) then
  deployment.customBuilds = {}  -- FIXME --
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return deployment

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
