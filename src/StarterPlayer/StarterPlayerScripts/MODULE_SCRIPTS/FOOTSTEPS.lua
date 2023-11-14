local FOOTSTEPS = {}

--// Services
local S_RUN = game:GetService('RunService')
local S_REPLICATED = game:GetService('ReplicatedStorage')
local S_PLAYERS = game:GetService('Players')

--// Constants
local PLAYER = S_PLAYERS.LocalPlayer
local PARTICLE = S_REPLICATED:WaitForChild('EXTRA'):WaitForChild('PARTICLES'):WaitForChild('WALK_PARTICLE')

--// Variables
local was_walking = false
local character = nil
local current_particles = {}
local raycast_length = 0


--[[ PRIVATE ]]--

--// Returns a raycast result of the part below the character's humanoidrootpart
local function get_part_below(ignore: {}): RaycastResult
	
	local raycast_params = RaycastParams.new()
	raycast_params.FilterType = Enum.RaycastFilterType.Blacklist
	raycast_params.FilterDescendantsInstances = {character, ignore}
	
	local hrp = character.HumanoidRootPart	
	
	return workspace:Raycast(hrp.Position, Vector3.new(0, -raycast_length, 0), raycast_params)
end



--// Changes the colour of the particle emitters to that of the colour of the part below
local function update_particle_colours()
	
	local raycast_result = get_part_below()
	if not raycast_result then return end
	
	local current_below = raycast_result.Instance
	
	local ignore = {}
	
	while 
		-- Conditions for parts to ignore
		current_below.Parent == workspace.IGNORE
		or current_below.Parent == workspace.DROPPED
	do
		table.insert(ignore, current_below)

		raycast_result = get_part_below(ignore)

		if not raycast_result then
			return
		end

		current_below = raycast_result.Instance
	end
	
	
	for _, PARTICLE in current_particles do
		PARTICLE.Color = ColorSequence.new(raycast_result.Instance.Color)
	end
end



--// Deletes all footstep particle effects
local function end_particle()
	
	coroutine.wrap(function()
		local to_delete = table.clone(current_particles)
		
		for _, PARTICLE in to_delete do
			PARTICLE.Rate = 0
		end
		
		task.wait(.5)
		
		for _, PARTICLE in to_delete do
			PARTICLE:Destroy()
		end

	end)()
	
	table.clear(current_particles)
end




--// Creates 2 particle emitters, parented to the character's feet
local function start_particle()
	
	local particle_1 = PARTICLE:Clone()
	local particle_2 = PARTICLE:Clone()
	particle_1.Parent = character:FindFirstChild('LeftFoot')
	particle_2.Parent = character:FindFirstChild('RightFoot')
	
	table.insert(current_particles, particle_1)
	table.insert(current_particles, particle_2)
end







--// Initalizes variables
local function init()
	
	while not PLAYER.Character do
		wait()
	end
	
	character = PLAYER.Character
	
	local humanoid = character.Humanoid
	raycast_length = character:GetExtentsSize().Y / 2 + 1
	
	S_RUN.Heartbeat:Connect(function()
		
		local state = humanoid:GetState() == Enum.HumanoidStateType.Running
		local moving = humanoid.MoveDirection.Magnitude > 0
		
		if not was_walking and state and moving then
			start_particle()
			was_walking = not was_walking
			
		elseif was_walking and not moving or was_walking and not state then
			end_particle()
			was_walking = not was_walking
		elseif was_walking then
			update_particle_colours()
		end
	end)
end



init()

PLAYER.CharacterAppearanceLoaded:Connect(init)



return FOOTSTEPS