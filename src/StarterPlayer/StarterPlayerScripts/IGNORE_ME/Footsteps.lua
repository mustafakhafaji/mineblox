local Footsteps = {}

local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local PARTICLE = ReplicatedStorage:WaitForChild('EXTRA'):WaitForChild('PARTICLES'):WaitForChild('WALK_PARTICLE')

local wasWalking = false
local character = nil
local currentParticles = {}
local raycastLength = 0


-- PRIVATE

-- Returns a raycast result of the part below the character's humanoidrootpart
function getPartBelow(ignore: {}): (RaycastResult)
	
	local raycast_params = RaycastParams.new()
	raycast_params.FilterType = Enum.RaycastFilterType.Exclude
	raycast_params.FilterDescendantsInstances = {character, ignore}
	
	local hrp = character.HumanoidRootPart	
	
	return workspace:Raycast(hrp.Position, Vector3.new(0, -raycastLength, 0), raycast_params)
end


-- Changes the colour of the particle emitters to that of the colour of the part below
function updateParticleColours(): ()
	
	local raycastResult = getPartBelow()
	if not raycastResult then
		return 
	end
	
	local currentBelow = raycastResult.Instance
	
	local ignore = {}
	
	while 
		-- Conditions for parts to ignore
		currentBelow.Parent == workspace.IGNORE
		or currentBelow.Parent == workspace.DROPPED
	do
		table.insert(ignore, currentBelow)

		raycastResult = getPartBelow(ignore)

		if not raycastResult then
			return
		end

		currentBelow = raycastResult.Instance
	end
	
	
	for _, PARTICLE in currentParticles do
		PARTICLE.Color = ColorSequence.new(raycastResult.Instance.Color)
	end
end


-- Deletes all footstep particle effects
function endParticle(): ()
	
	coroutine.wrap(function()
		local to_delete = table.clone(currentParticles)
		
		for _, PARTICLE in to_delete do
			PARTICLE.Rate = 0
		end
		
		task.wait(.5)
		
		for _, PARTICLE in to_delete do
			PARTICLE:Destroy()
		end

	end)()
	
	table.clear(currentParticles)
end


-- Creates 2 particle emitters, parented to the character's feet
function startParticle(): ()
	
	local particle_1 = PARTICLE:Clone()
	local particle_2 = PARTICLE:Clone()
	particle_1.Parent = character:FindFirstChild('LeftFoot')
	particle_2.Parent = character:FindFirstChild('RightFoot')
	
	table.insert(currentParticles, particle_1)
	table.insert(currentParticles, particle_2)
end


function updateFootSteps(): ()

	local humanoid = character.Humanoid

	local state = humanoid:GetState() == Enum.HumanoidStateType.Running
	local moving = humanoid.MoveDirection.Magnitude > 0
	
	if 
		not wasWalking
		and state 
		and moving 
	then
		startParticle()
		wasWalking = not wasWalking
		
	elseif 
		(wasWalking 
		and not moving) 
		or (wasWalking 
		and not state) 
	then
		endParticle()
		wasWalking = not wasWalking
	
	elseif wasWalking then
		updateParticleColours()
	end
end


-- Initalizes variables
function init(): ()
	
	while not Player.Character do
		task.wait()
	end
	
	raycastLength = character:GetExtentsSize().Y / 2 + 1
end


-- EVENTS
Player.CharacterAppearanceLoaded:Connect(init)
RunService.Heartbeat:Connect(updateFootSteps)

-- Init
init()


return Footsteps