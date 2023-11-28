local FallDamage = {}

local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local StarterPlayer = game:GetService('StarterPlayer')

local Modules = StarterPlayer.StarterPlayerScripts.Modules
local Health = require(Modules.Health)

local Camera = workspace.Camera
local Player = Players.LocalPlayer

local lastY = nil

-- PRIVATE

function shakeCamera(damage: number): ()
	
	RunService:UnbindFromRenderStep('CameraRotation')
	
	local maxRotation = damage * 4
	local i	= 0
	
	RunService:BindToRenderStep('CameraRotation', Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
		
		if i >= maxRotation then
			RunService:UnbindFromRenderStep('CameraRotation')
			return
		end
		
		Camera.CFrame = Camera.CFrame * CFrame.fromOrientation(0, 0, math.rad(maxRotation - i))
		
		i += damage / 2
	end)
end


-- Formula returning how many hearts a player should lose, by calculating fall distance
function calculateFallDamage(): (number)
	
	local HumanoidRootPart = Player.Character:WaitForChild('HumanoidRootPart')
	
	local yDifference = math.abs(lastY - HumanoidRootPart.Position.Y)
	local blockHeight = math.ceil(yDifference / 3)

	if blockHeight < 3 then
		return 0
	end

	return (blockHeight - 3) / 2
end


function registerPosition(): ()
	
	local hrp = Player.Character:WaitForChild('HumanoidRootPart')
	
	lastY = hrp.Position.Y
end


function checkFallDamage(): ()
	
	local damage = calculateFallDamage()
	
	if damage == 0 then 
		return
	 end

	-- raycast particle effect on ground 
	
	shakeCamera(damage)
	Health.takeDamage(damage)
end


-- Init detecting player falling
function init(character: Model)
	
	lastY = nil
	local humanoid = character:WaitForChild('Humanoid')
	
	task.wait(.5)
	
	humanoid.StateChanged:Connect(function(oldState, newState)

		if newState == Enum.HumanoidStateType.Freefall then
			registerPosition()

		elseif 
			lastY 
			and oldState == Enum.HumanoidStateType.Freefall 
			and newState == Enum.HumanoidStateType.Landed 
		then
			checkFallDamage()
		end
	end)
end


--add landed particles? in 

-- EVENTS
Player.CharacterAdded:Connect(init)

-- Initalize
if Player.Character then
	init(Player.Character)
end


return FallDamage