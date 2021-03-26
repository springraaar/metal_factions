--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
--  file:    config.lua
--  brief:   configfile for handler.lua
--  author:  jK
--
--  Copyright (C) 2011-2013.
--  Licensed under the terms of the GNU GPL, v2 or later.
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--// randomize each run
math.randomseed(os.time())

--// 0: disabled
--// 1: enabled, but can be overriden by widget.GetInfo().unsafe
--// 2: always enabled
SAFEWRAP = 1
SAFEDRAW = false  --// requires SAFEWRAP to work

--//
VFSMODE = VFS.RAW_FIRST

--// when false, the handler will `compress` some output (e.g. list of started widgets)
handler.verbose = false or true


if LUA_NAME == "LuaUI" then
	--// Config & Widget Locations
	ORDER_FILENAME  = LUAUI_DIRNAME .. 'config/' .. Game.modShortName .. '_order.lua'
	CONFIG_FILENAME = LUAUI_DIRNAME .. 'config/' .. Game.modShortName .. '_data.lua'
	KNOWN_FILENAME  = LUAUI_DIRNAME .. 'config/' .. Game.modShortName .. '_known.lua'

	ADDON_DIRS     = {
		LUA_DIRNAME .. 'addons/';
		LUA_DIRNAME .. 'widgets/';
		LUA_DIRNAME .. 'systemaddons/';
		LUA_DIRNAME .. 'systemwidgets/';
		LUA_DIRNAME .. 'chili/';
	}

	--// Create the "LuaUI/Config" directory
	Spring.CreateDir(LUAUI_DIRNAME .. 'config')

	handler:Load(LUAUI_DIRNAME .. "SystemWidgets/BlockUserWidgets.lua" --[[, VFS.ZIP]])
else
	AddonNames = handler.AddonName .. "s/"

	ADDON_DIRS     = {
		LUA_DIRNAME .. 'addons/';
		LUA_DIRNAME .. AddonNames;
		LUA_DIRNAME .. 'systemaddons/';
		LUA_DIRNAME .. 'system' .. AddonNames;
		LUA_DIRNAME .. 'chili/';
	}
end

--// ZK related
--// cache the results of time intensive funcs
include("Utilities/cache.lua", handler.EG)
