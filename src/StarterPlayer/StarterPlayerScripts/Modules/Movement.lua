local Movement = {}

local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local Players = game:GetService('Players')
local StarterPlayer = game:GetService('StarterPlayer')

local Modules = StarterPlayer.StarterPlayerScripts.Modules
local Settings = require(Modules.Settings)

local Player = Players.LocalPlayer

local frozen = false

local fovTween = nil
local camTween = nil

local canSprint = false

local sprinting = false
local crouching = false

local DEFAULT_SPEED = 12.95
local DEFAULT_FOV = Settings['defaultFOV']
local SPRINT_FOV = DEFAULT_FOV + 20

-- PRIVATE

-- Start player sprint speed and effects
function startSprint(): ()
	
	sprinting = true

	if fovTween then
		fovTween:Cancel()
	end

	local humanoid = Player.Character:FindFirstChild('Humanoid')
	
	humanoid.WalkSpeed = DEFAULT_SPEED + DEFAULT_SPEED * .3

	fovTween = TweenService:Create(workspace.CurrentCamera,
		TweenInfo.new(.25, Enum.EasingStyle.Sine),
		{
			FieldOfView = SPRINT_FOV
		}
	)
	fovTween:Play()

	fovTween.Completed:Connect(function()
		fovTween = nil
	end)
end


-- End player sprint speed and effects
function endSprint(): ()
	
	sprinting = false

	if fovTween then
		fovTween:Cancel()
	end
	
	Player.Character:FindFirstChild('Humanoid').WalkSpeed = DEFAULT_SPEED

	fovTween = TweenService:Create(workspace.CurrentCamera,
		TweenInfo.new(.25, Enum.EasingStyle.Sine),
		{
			FieldOfView = DEFAULT_FOV
		}
	)
	fovTween:Play()

	fovTween.Completed:Connect(function()
		fovTween = nil
	end)
end


-- Start player crouching speed and effects
function startCrouch(): ()
	
	crouching = true
	
	local humanoid = Player.Character:FindFirstChild('Humanoid')
	humanoid.WalkSpeed = DEFAULT_SPEED * .3

	if camTween then
		camTween:Cancel()
	end
	
	camTween = TweenService:Create(
		humanoid,
		TweenInfo.new(.15), 
		{
			CameraOffset = Vector3.new(0, -1, 0)
		}
	)
	camTween:Play()

	camTween.Completed:Connect(function()
		camTween = nil
	end)
end


-- End player crouching speed and effects
function endCrouch(): ()
	
	crouching = false
	
	local humanoid = Player.Character:FindFirstChild('Humanoid')
	
	if sprinting then
		humanoid.WalkSpeed = DEFAULT_SPEED + DEFAULT_SPEED * .3
	else
		humanoid.WalkSpeed = DEFAULT_SPEED
	end

	if camTween then
		camTween:Cancel()
	end

	camTween = TweenService:Create(
		humanoid, 
		TweenInfo.new(.15), 
		{
			CameraOffset = Vector3.new(0, 0, 0)
		}
	)
	camTween:Play()

	camTween.Completed:Connect(function()
		camTween = nil
	end)
end


-- PUBLIC

-- Freezes player
function Movement.freezePlayer(): ()
	frozen = true
	
	endSprint()
	endCrouch()
	
	local humanoid = Player.Character:FindFirstChild('Humanoid')
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid.WalkSpeed = 0
end


-- Unfreezes player; able to move 
function Movement.unfreezePlayer(): ()
	frozen = false
	
	local humanoid = Player.Character:FindFirstChild('Humanoid')
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	humanoid.WalkSpeed = DEFAULT_SPEED
end


function handleInputBegan(input: InputObject, typing: boolean): ()

	if 
		not Player.Character 
		or frozen
		or typing
	then 
		return 
	end
	
	if input.UserInputType == Enum.UserInputType.Keyboard then
		
		if input.KeyCode == Enum.KeyCode.LeftShift then
			startCrouch()
		end
		
		if input.KeyCode == Enum.KeyCode.W then
			if not sprinting then 

				if canSprint and not crouching then
					startSprint()
				else
					canSprint = true
					task.wait(.2)
					canSprint = false
				end
			end
		end
		
		if input.KeyCode == Enum.KeyCode.LeftControl then
			
			local isMoving = Player.Character.Humanoid.MoveDirection.Magnitude > 0
			
			if 
				not sprinting 
				and not crouching 
				and isMoving 
			then
				startSprint()
			elseif sprinting then
				endSprint()
			end
		end
	end
end


function handleInputEnded(input: InputObject, typing: boolean): ()

	if 
		not Player.Character 
		or typing 
	then 
		return 
	end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.W then
			if sprinting then
				endSprint()
			end
		end
		
		if input.KeyCode == Enum.KeyCode.LeftShift then
			if crouching then
				endCrouch()
			end
		end
	end
end

-- EVENTS

UserInputService.InputBegan:Connect(handleInputBegan)
UserInputService.InputEnded:Connect(handleInputEnded)

-- Init
workspace.Camera.FieldOfView = DEFAULT_FOV

return Movement