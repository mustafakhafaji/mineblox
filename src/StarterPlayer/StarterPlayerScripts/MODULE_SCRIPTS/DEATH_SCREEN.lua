local DEATH_SCREEN = {}

--// Services
local S_SP = game:GetService('StarterPlayer')
local S_PLAYERS = game:GetService('Players')

--// Modules
local MODULE_SCRIPTS = S_SP.StarterPlayerScripts.MODULE_SCRIPTS
local M_HEALTH = require(MODULE_SCRIPTS.HEALTH)

--// Constants
local PLAYER = S_PLAYERS.LocalPlayer

--// Variables
local character
local humanoid


--[[ PRIVATE ]]--

local function reset_player()
	
end



local function start_death_screen()
	-- set player's camera to current camera cframe, scriptable
	-- set position to something crazy
	-- when player clicks respawn
	-- then reset_player
end


--[[ PUBLIC ]]--

function DEATH_SCREEN.init()
	
	while not PLAYER.Character do
		task.wait()
	end
	
	character = PLAYER.Character
	humanoid = PLAYER.Character:WaitForChild('Humanoid')
end


humanoid.Died:Connect(start_death_screen)


return DEATH_SCREEN