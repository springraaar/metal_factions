------------- ECONOMY / WIND

WIND_INCOME_MULTIPLIER = 1.6					-- because MF wind generators produce +60% relative to the standard
WIND_ALTITUDE_EXTRA_INCOME_FRACTION = 0.4		-- up to extra 40% from being built on relatively high altitude   
WIND_STR_CAP = 40								-- the base wind strength cap on generators
EXCESS_WIND_REDUCTION_MULT = 0.85 		-- to compensate for the fact that the actual average is higher than expected

------------- OPTIONAL UNITS

MAX_OPTIONAL_UNITS_BY_FACTION = 6
optionalUnitsFile = "LuaUI/Config/mf_optional_units.txt"
defaultOptionalUnitsText = [[
aven_lone_trooper
aven_stormtrooper
aven_trooper_hmis
aven_techno
aven_cadence
aven_stormfront
gear_seeker
gear_firefly
gear_igniter_flamer
gear_axle
gear_rhino
gear_ruiner
claw_ringo
claw_trigger
claw_porcupine
claw_blaster
claw_flayer
claw_top
sphere_duron
sphere_boulder
sphere_buster
sphere_nova
sphere_tuber
sphere_rumble
]]


------------- UI colors
-- TODO move to luaUI-specific constants file

UI_SCROLLBAR_BOX_BG = {0.1, 0.1, 0.1, 0.6}
UI_SCROLLBAR_BOX_BORDER = {0.4, 0.4, 0.4, 1}
UI_SCROLLBAR_INNER_BG = {1.0, 1.0, 1.0, 1}
UI_SCROLLBAR_INNER_BORDER = {0.8, 0.8,0.8, 1}

UI_TEXT = {0.9,0.9,0.9,1}
UI_TEXT2 = {0.7,0.7,0.7,1}

UI_BG_NOTEXT = {0.0,0.0,0.0,0.4}
UI_BG_TEXT = {0.0,0.0,0.0,0.6}
UI_BORDER = {0, 0, 0, 1}
UI_BG_SELECTED = {0,0.3,0,0.5}

UI_BTN_BG = {0.1,0.1,0.1,1}
UI_BTN_BORDER = {0, 0, 0, 1}
UI_BTN_BG_OVER = {0.35,0.35,0.35,1}
UI_BTN_BORDER_OVER = {1,1,1,1}
UI_BTN_BG_SELECTED = {0,0.25,0,1}
UI_BTN_BORDER_SELECTED = {0,1,0,1}
UI_BTN_BG_SELECTED_OVER = {0.1,0.4,0.1,1}
UI_BTN_BORDER_SELECTED_OVER = {0.3,1,0.3,1}
UI_BTN_TEXT = {1.0,1.0,1.0,1}
UI_BTN_TEXT_OVER = {0.9,0.9,0.9,1}	-- not used




