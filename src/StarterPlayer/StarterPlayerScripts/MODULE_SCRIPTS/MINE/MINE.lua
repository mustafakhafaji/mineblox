local MINE = {}

--// Services
local S_REPLICATED = game:GetService('ReplicatedStorage')
local S_RUN = game:GetService('RunService')
local S_UIS = game:GetService('UserInputService')
local S_TS = game:GetService('TweenService')
local S_SP = game:GetService('StarterPlayer')
local S_RS = game:GetService('ReplicatedStorage')

--// Modules
local MODULE_SCRIPTS = S_SP.StarterPlayerScripts.MODULE_SCRIPTS

local M_SELECTION = require(MODULE_SCRIPTS.SELECTION)
local M_DROP = require(MODULE_SCRIPTS.CHUNK_LOADING.DROPPED_OBJECTS)
local M_EQUIPPED = require(MODULE_SCRIPTS.EQUIPPED)
local M_PLAYER_STATE = require(MODULE_SCRIPTS.PLAYER_STATE)
local M_ITEM_DATA = require(S_REPLICATED.MODULE_SCRIPTS.ITEM_DATA)
local M_FACES = require(script.FACES)
local M_PARTICLES = require(script.PARTICLES)
local M_MODEL = require(MODULE_SCRIPTS.MODEL)
local M_WORLD_GENERATION = require(MODULE_SCRIPTS.CHUNK_LOADING.WORLD_GENERATION)
local M_CHUNK_UTIL = require(S_RS.MODULE_SCRIPTS.CHUNKS_UTIL)

--// Variables
local particle
local block_being_mined = nil
local punched = false
local current_decals = {}

local mining_connection
local left_click_down

--[[ PRIVATE ]]--

--// Block jump animation after block is mined
--[[function animate_jump(item_name: string, position: Vector3)


	local dropped_object = S_REPLICATED.ITEMS:FindFirstChild(item_name):Clone()
	dropped_object.Parent = workspace.IGNORE

	-- TODO: fix tweening models
	local to_tween = nil

	if dropped_object:IsA('Model') then

		M_MODEL.start_weld(dropped_object)
		dropped_object:ScaleTo(1/3)
		dropped_object:SetPrimaryPartCFrame(CFrame.new(position))

		to_tween = dropped_object.PrimaryPart
	else
		if M_ITEM_DATA[dropped_object.Name]['TYPE'] == 'ORE' then
			dropped_object.Size = Vector3.new(0.05, 1, 1)
		else
			dropped_object.Size = Vector3.new(.75, .75, .75)
		end

		dropped_object.Position = position
		dropped_object.CanCollide = false

		to_tween = dropped_object
	end

	local x = math.random(-9, 9) / 10
	local y = math.random(8, 16) / 10
	local z = math.random(-9, 9) / 10

	local up_tween = S_TS:Create(to_tween, TweenInfo.new(.25,
		Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{
			CFrame = CFrame.new(
				position.x + x / 2,
				position.y + y,
				position.z + z / 2
			)
		}
	)
	up_tween:Play()

	local down_tween = S_TS:Create(to_tween, TweenInfo.new(.25,
		Enum.EasingStyle.Sine, Enum.EasingDirection.In),
		{
			CFrame = CFrame.new(
				position.x + x,
				position.y,
				position.z + z
			)
		}
	)

	up_tween.Completed:Connect(function()
		down_tween:Play()
	end)

	down_tween.Completed:Connect(function()
		--M_DROP.add(dropped_object)
	end)
end
]]




--// Destroy a block
function destroy_block()

	if not block_being_mined then return end
	
	local block = block_being_mined
	M_PARTICLES.break_particle(block)
	
	M_WORLD_GENERATION.handle_mined_block(block.Name, block.Position)

	local drop = M_ITEM_DATA[block.Name]['DROP']

	if drop then
		handle_block_mined(drop, block.Position)
		--[[animate_jump(drop, block.Position + Vector3.new(
			math.random(-5, 5) / 10,
			math.random(-5, 5) / 10,
			math.random(-5, 5) / 10
			)
		)]]
	end

	--TODO ay
	--if M_ITEM_DATA[block.Name]['TYPE'] == 'BLOCK' then
	
	--block_being_mined:Destroy()
	--else
	--block.Parent:Destroy()
	--end

	block_being_mined = nil
end





--// Returns time it takes to mine an item
function get_mine_time(block_name: string): (number)

	local hardness = M_ITEM_DATA[block_name]['HARDNESS']
	local preferred_tool = M_ITEM_DATA[block_name]['PREFERRED_TOOL']
	local tool_level = nil

	return .03
	--return hardness -- return minetime
end





--// Ends player mine
function end_mining(): ()

	M_PLAYER_STATE['MINING'] = false

	if mining_connection then
		mining_connection:Disconnect()
		mining_connection = nil
	end

	for _, decal in current_decals do
		decal:Destroy()
	end
	table.clear(current_decals)

	M_PARTICLES.end_surface()
end





--// Starts player mine
function start_mining(): ()

	-- One punch breakable object
	block_being_mined = M_SELECTION.get_hovering()
	if not block_being_mined then return end

	local mine_time = get_mine_time(block_being_mined.Name)

	if mine_time == 0 then

		M_EQUIPPED.punch()
		destroy_block()
		return
	end

	local stage = 1
	local stage_interval = mine_time / 9
	local stage_check = os.clock()

	M_PLAYER_STATE['MINING'] = true

	local normal = M_SELECTION.get_normal()
	particle = M_PARTICLES.start_surface(block_being_mined, normal)

	-- mining harder object
	mining_connection = S_RUN.RenderStepped:Connect(function()

		M_EQUIPPED.punch()

		local current_normal = M_SELECTION.get_normal()

		if normal ~= current_normal then

			normal = current_normal
			M_PARTICLES.end_surface()
			particle = M_PARTICLES.start_surface(block_being_mined, normal)
		end

		if M_SELECTION.get_hovering() ~= block_being_mined then
			end_mining()
		end

		if os.clock() > stage_check then

			if not mining_connection then return end

			if stage > 9 then
				end_mining()
				destroy_block()
				return
			end

			for _, decal in current_decals do
				decal:Destroy()
			end
			table.clear(current_decals)

			local current_decal = S_REPLICATED.EXTRA.STAGES[stage]

			for i = 1, 6, 1 do

				local face_decal = current_decal:Clone()	
				face_decal.Face = M_FACES[i]
				face_decal.Parent = block_being_mined

				table.insert(current_decals, face_decal)
			end

			stage += 1
			stage_check = os.clock() + stage_interval
		end
	end)
end



function left_click_start(): ()
	
	left_click_down = S_RUN.Heartbeat:Connect(function()
		
		if mining_connection then return end
		
		local current_target = M_SELECTION.get_hovering()

		if not current_target then -- Punch
			punched = true
			M_EQUIPPED.punch()
			return
		end

		block_being_mined = current_target
		local break_time = get_mine_time(current_target.Name)

		if break_time == 0 then
			M_EQUIPPED.punch()
			destroy_block()
			return
		end

		start_mining(break_time)
	end)
end



function left_click_end(): ()
	
	if left_click_down then
		left_click_down:Disconnect()
		left_click_down = nil
	end

	punched = false
	end_mining()
end


function handle_input_began(input, typing): ()
	if typing then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		left_click_start()
	end
end

function handle_input_ended(input, typing): ()
	if typing then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		left_click_end()
	end
end




function scale_object(object: BasePart): ()

	if object:IsA('Model') then

		local scale_factor = 1 / 3

		-- Calculate using size of model and desired size, use largest side?

		object:ScaleTo(scale_factor)
	else
		object.Size = Vector3.new(.75, .75, .75)
	end
end





function handle_block_mined(object_name: string, world_position: Vector3): ()

	local block = S_RS.ITEMS:FindFirstChild(object_name):Clone()
	scale_object(block)
	
	block.CanCollide = false
	block.Position = world_position + Vector3.new(math.random(-100, 100) / 100, 0, math.random(-100, 100) / 100)
	block.Parent = workspace.DROPPED
	
	local chunk_position = M_CHUNK_UTIL.world_to_chunk_position(world_position)
	local chunk_x = chunk_position[1]
	local chunk_z = chunk_position[2]
	
	block.Parent = workspace.DROPPED:FindFirstChild(`{chunk_x}x{chunk_z}`)
	
	M_DROP.add(block, 1, world_position)
	M_DROP.block_mined(object_name, world_position)
end




--[[ EVENTS ]]--

S_UIS.InputBegan:Connect(handle_input_began)
S_UIS.InputEnded:Connect(handle_input_ended)

S_RS.REMOTES.BlockMined.OnClientEvent:Connect(handle_block_mined)


return MINE