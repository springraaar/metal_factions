--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    luaui.lua
--  brief:   entry point for LuaUI
--  author:  Dave Rodgers
--
--  Copyright (C) 2008.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

LUAUI_VERSION = "LuaUI v0.3"
LUAUI_DIRNAME = 'LuaUI/'		-- compatibility with lua files loaded from the engine directory outside base
								-- available only on VFS.RAW which is case-sensitive on linux 
								-- game package uses "luaui" but VFS.GAME is case insensitive so it doesn't matter 
VFS.DEF_MODE = VFS.RAW_FIRST
local STARTUP_FILENAME = LUAUI_DIRNAME .. 'mfmain.lua'

VFS.Include("lualibs/security.lua") -- security overrides

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

do
  -- use a versioned directory name if it exists
  local sansslash = string.sub(LUAUI_DIRNAME, 1, -2)
  local versiondir = sansslash .. '-' .. Engine.version .. '/'
  if (VFS.FileExists(versiondir  .. 'mfmain.lua', VFS.RAW_ONLY)) then
    LUAUI_DIRNAME = versiondir
  end
end

Spring.Echo('Using LUAUI_DIRNAME = ' .. LUAUI_DIRNAME)


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- load the user's UI
--

do
  local text = VFS.LoadFile(STARTUP_FILENAME, VFS.RAW_FIRST)
  if (text == nil) then
    Script.Kill('Failed to load ' .. STARTUP_FILENAME)
  end
  local chunk, err = loadstring(text)
  if (chunk == nil) then
    Script.Kill('Failed to load ' .. STARTUP_FILENAME .. ' (' .. err .. ')')
  else
    chunk()
    return
  end
end


-------------------------------------------------------------------------------- 
-------------------------------------------------------------------------------- 
