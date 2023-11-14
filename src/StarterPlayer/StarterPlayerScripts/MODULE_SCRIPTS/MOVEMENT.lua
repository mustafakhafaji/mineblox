local MOVEMENT = {}

--// Services
local S_UIS = game:GetService('UserInputService')
local S_TS = game:GetService('TweenService')
local S_PLAYERS = game:GetService('Players')
local S_SP = game:GetService('StarterPlayer')

--// Modules
local MODULES = S_SP.StarterPlayerScripts.MODULE_SCRIPTS
local M_SETTINGS = require(MODULES.SETTINGS)

--// Constants
local PLAYER = S_PLAYERS.LocalPlayer
local DEFAULT_FOV = M_SETTINGS['default_fov']
local SPRINT_FOV = DEFAULT_FOV + 20

--// Variables
local frozen: boolean = false

local default_speed: number = 12.95
local fov_tween = nil
local cam_tween = nil

local can_sprint = false

local sprinting = false
local crouching = false





--[[ PRIVATE ]]--

--// Start player sprint speed and effects
local function start_sprint()
	
	sprinting = true

	if fov_tween then
		fov_tween:Cancel()
	end
	
	PLAYER.Character:FindFirstChild('Humanoid').WalkSpeed = default_speed + default_speed * .3

	fov_tween = S_TS:Create(workspace.CurrentCamera,
		TweenInfo.new(.25, Enum.EasingStyle.Sine),
		{FieldOfView = SPRINT_FOV}
	)
	fov_tween:Play()

	fov_tween.Completed:Connect(function()
		fov_tween = nil
	end)
end





--// End player sprint speed and effects
local function end_sprint()
	
	sprinting = false

	if fov_tween then
		fov_tween:Cancel()
	end
	
	PLAYER.Character:FindFirstChild('Humanoid').WalkSpeed = default_speed

	fov_tween = S_TS:Create(workspace.CurrentCamera,
		TweenInfo.new(.25, Enum.EasingStyle.Sine),
		{FieldOfView = DEFAULT_FOV}
	)
	fov_tween:Play()

	fov_tween.Completed:Connect(function()
		fov_tween = nil
	end)
end




--// Start player crouching speed and effects
local function start_crouch()
	
	crouching = true
	
	local camera = workspace.CurrentCamera
	local humanoid = PLAYER.Character:FindFirstChild('Humanoid')
	humanoid.WalkSpeed = default_speed * .3

	if cam_tween then
		cam_tween:Cancel()
	end
	
	cam_tween = S_TS:Create(humanoid, TweenInfo.new(.15), {CameraOffset = Vector3.new(0, -1, 0)})
	cam_tween:Play()

	cam_tween.Completed:Connect(function()
		cam_tween = nil
	end)
end





--// End player crouching speed and effects
local function end_crouch()
	
	crouching = false
	
	local camera = workspace.CurrentCamera
	local humanoid = PLAYER.Character:FindFirstChild('Humanoid')
	
	if sprinting then
		humanoid.WalkSpeed = default_speed + default_speed * .3
	else
		humanoid.WalkSpeed = default_speed
	end

	if cam_tween then
		cam_tween:Cancel()
	end

	cam_tween = S_TS:Create(humanoid, TweenInfo.new(.15), {CameraOffset = Vector3.new(0, 0, 0)})
	cam_tween:Play()

	cam_tween.Completed:Connect(function()
		cam_tween = nil
	end)
end





--[[ PUBLIC ]]--

--// Freezes player; unable to move 
function MOVEMENT.freeze_player()
	frozen = true
	
	end_sprint()
	end_crouch()
	
	local humanoid = PLAYER.Character:FindFirstChild('Humanoid')
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid.WalkSpeed = 0
end





--// Unfreezes player; able to move 
function MOVEMENT.unfreeze_player()
	frozen = false
	
	local humanoid = PLAYER.Character:FindFirstChild('Humanoid')
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	humanoid.WalkSpeed = default_speed
end




--// Initalizes movement
	
workspace.Camera.FieldOfView = DEFAULT_FOV

S_UIS.InputBegan:Connect(function(input, typing)
	if not PLAYER.Character then return end
	if frozen or typing then return end
	
	if input.UserInputType == Enum.UserInputType.Keyboard then
		
		if input.KeyCode == Enum.KeyCode.LeftShift then
			start_crouch()
		end
		
		if input.KeyCode == Enum.KeyCode.W then
			if not sprinting then 

				if can_sprint and not crouching then
					start_sprint()
				else
					can_sprint = true
					task.wait(.2)
					can_sprint = false
				end
			end
		end
		
		if input.KeyCode == Enum.KeyCode.LeftControl then
			
			local is_moving = PLAYER.Character.Humanoid.MoveDirection.Magnitude > 0
			
			if not sprinting and not crouching and is_moving then
				start_sprint()
			elseif sprinting then
				end_sprint()
			end
		end
	end
end)

S_UIS.InputEnded:Connect(function(input, typing)
	if not PLAYER.Character or typing then return end
	
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.W then
			if sprinting then
				end_sprint()
			end
		end
		
		if input.KeyCode == Enum.KeyCode.LeftShift then
			if crouching then
				end_crouch()
			end
		end
	end
	
end)




return MOVEMENT