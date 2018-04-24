function gadget:GetInfo()
  return {
    name      = "Shockwaves",
    desc      = "",
    author    = "jK",
    date      = "Jan. 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 10,
    enabled   = true
  }
end

-------------------------------------------------------------------------------
-- Synced
-------------------------------------------------------------------------------
if (gadgetHandler:IsSyncedCode()) then
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

  local hasShockwave = {} -- other gadgets can do Script.SetWatchWeapon and it is a global setting
  local wantedList = {}

  --// find weapons which cause a shockwave
  for i=1,#WeaponDefs do
    local wd = WeaponDefs[i]
    local customParams = wd.customParams or {}
    if ( customParams.shockwave == "1") then
      local strength = 1
      local growth = 25
      local life = 3
      
      Script.SetWatchWeapon(wd.id,true)
      hasShockwave[wd.id] = {growth = growth, life = life, strength = strength}
      wantedList[#wantedList + 1] = wd.id
    end
  end
  
  function gadget:Explosion_GetWantedWeaponDef()
	return wantedList
  end

  function gadget:Explosion(weaponID, px, py, pz, ownerID)
	local shockwave = hasShockwave[weaponID]
	if shockwave then
        SendToUnsynced("lups_shockwave", px, py, pz, shockwave.growth, shockwave.life, shockwave.strength)
	end
    return false
  end

-------------------------------------------------------------------------------
-- Unsynced
-------------------------------------------------------------------------------
else
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

  local function SpawnShockwave(_,px,py,pz, growth, life, strength)
    local Lups = GG['Lups']
      Lups.AddParticles('SphereDistortion',{pos={px,py,pz}, life=life, strength=strength, growth=growth})
      --Lups.AddParticles('ShockWave',{pos={px,py,pz}, growth=growth, life=life})
    
  end

  function gadget:Initialize()
    gadgetHandler:AddSyncAction("lups_shockwave", SpawnShockwave)
  end

  function gadget:Shutdown()
    gadgetHandler.RemoveSyncAction("lups_shockwave")
  end

end