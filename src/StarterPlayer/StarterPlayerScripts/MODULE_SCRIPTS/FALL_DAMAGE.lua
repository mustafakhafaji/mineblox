local FALL_DAMAGE = {}

--// Services
local S_RUN = game:GetService('RunService')
local S_PLAYERS = game:GetService('Players')
local S_SP = game:GetService('StarterPlayer')

--// Modules
local M_HEALTH = require(S_SP.StarterPlayerScripts.MODULE_SCRIPTS.HEALTH)

--// Constants
local CAMERA = workspace.Camera
local PLAYER = S_PLAYERS.LocalPlayer

--// Variables
local last_y = nil


--[[ PRIVATE ]]--

local function shake_camera(damage: number)
	
	S_RUN:UnbindFromRenderStep('CameraRotation')
	
	local MAX_ROTATION = damage * 4
	local i	= 0
	
	S_RUN:BindToRenderStep('CameraRotation', Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
		
		if i >= MAX_ROTATION then
			S_RUN:UnbindFromRenderStep('CameraRotation')
			return
		end
		
		CAMERA.CFrame = CAMERA.CFrame * CFrame.fromOrientation(0, 0, math.rad(MAX_ROTATION - i))
		
		i += damage / 2
	end)
end



--// Formula returning how many hearts a player should lose, by calculating fall distance
local function calculate_fall_damage()
	
	local hrp = PLAYER.Character:WaitForChild('HumanoidRootPart')
	local hrp_position = hrp.Position
	
	local y_difference = math.abs(last_y - hrp_position.Y)

	local block_height = math.ceil(y_difference / 3)

	if block_height < 3 then return 0
	else
		return (block_height - 3) / 2
	end
end





local function register_y_position()
	
	local hrp = PLAYER.Character:WaitForChild('HumanoidRootPart')
	
	last_y = hrp.Position.Y
end



local function check_fall_damage()
	
	local damage = calculate_fall_damage()
	if damage == 0 then return end

	-- raycast particle effect on ground 
	
	shake_camera(damage)
	M_HEALTH.take_damage(damage)
end




--// Init detecting player falling
function init(character: Model)
	
	last_y = nil
	local humanoid = character:WaitForChild('Humanoid')
	
	task.wait(.5)
	
	humanoid.StateChanged:Connect(function(old_state, new_state)

		if new_state == Enum.HumanoidStateType.Freefall then
			register_y_position()

		elseif last_y and old_state == Enum.HumanoidStateType.Freefall and new_state == Enum.HumanoidStateType.Landed then
			check_fall_damage()
		end
	end)
end


--add landed particles? in 

--[[ EVENTS ]]--
PLAYER.CharacterAdded:Connect(init)

--// Initalize
if PLAYER.Character then
	init(PLAYER.Character)
end



return FALL_DAMAGE