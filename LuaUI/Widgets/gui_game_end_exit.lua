--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Game-end-exiter",
    desc      = "Exit automatically some time after the game ends.",
    author    = "raaar",
    date      = "2019",
    license   = "PD",
    layer     = 111,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local spGetGameRulesParam = Spring.GetGameRulesParam
local spGetGameSeconds = Spring.GetGameSeconds
local floor = math.floor

local TIME_TOLERANCE_S = 40
local countDownActive = false
local gameEndSecond = 0
 

function widget:Update()
	local gameEnded = spGetGameRulesParam('game_over') == 1
	if gameEnded and (not countDownActive) then
		countDownActive = true
		gameEndSecond = spGetGameSeconds()
	end
	
	if (countDownActive) then
		local remainingSeconds = floor(TIME_TOLERANCE_S - (spGetGameSeconds() - gameEndSecond))
		if (remainingSeconds <= 30) then
			Spring.Echo("GAME OVER : EXITING IN "..remainingSeconds.."s")
		end		
		if (remainingSeconds < 1) then
			Spring.SendCommands("quitforce")
		end
	end
end
