local WORLD_GENERATION = {}

--// Services
local S_RUN = game:GetService('RunService')
local S_RS = game:GetService('ReplicatedStorage')
local S_PLAYERS = game:GetService('Players')
local S_LIGHTING = game:GetService('Lighting')
local S_SP = game:GetService('StarterPlayer')

--// Modules
local MODULES = S_SP.StarterPlayerScripts.MODULE_SCRIPTS
local M_CHUNK_SETTINGS = require(S_RS.MODULE_SCRIPTS.CHUNK_SETTINGS)
local M_ITEM_DATA = require(S_RS.MODULE_SCRIPTS.ITEM_DATA)
local M_CHUNKS_UTIL = require(S_RS.MODULE_SCRIPTS.CHUNKS_UTIL)
local M_TERRAIN_GENERATION = require(script.TERRAIN_GENERATION)
local M_DECORATIVE_GENERATION = require(script.DECORATIVE_GENERATION)
local M_SURFACE_LAYER_GENERATION = require(script.SURFACE_LAYER_GENERATION)

--// Constants
local PLAYER = S_PLAYERS.LocalPlayer

local BLOCK_SIZE = M_CHUNK_SETTINGS['BLOCK_SIZE']

local MAX_HEIGHT = M_CHUNK_SETTINGS['MAX_HEIGHT']
local MIN_HEIGHT = M_CHUNK_SETTINGS['MIN_HEIGHT']

local CHUNK_SIZE = M_CHUNK_SETTINGS['CHUNK_SIZE']
local CHUNK_DISTANCE = M_CHUNK_SETTINGS['CHUNK_DISTANCE']

local LOAD_OFFSET = 2

local BLOCK_NEIGHBOUR_VECTORS = 
	{
		Vector3.new(3, 0, 0),
		Vector3.new(-3, 0, 0),
		Vector3.new(0, 0, 3),
		Vector3.new(0, 0, -3),
		Vector3.new(0, 3, 0),
		Vector3.new(0, -3, 0),
	}


local RELATIVE_POSITION_TO_FACE = 
	{
		[Vector3.new(1, 0, 0)] = 'RIGHT',
		[Vector3.new(-1, 0, 0)] = 'LEFT',
		[Vector3.new(0, 0, 1)] = 'BACK',
		[Vector3.new(0, 0, -1)] = 'FRONT',
		[Vector3.new(0, 1, 0)] = 'TOP',
		[Vector3.new(0, -1, 0)] = 'BOTTOM'
	}

local SEED = S_RS.REMOTES.GetSeed:InvokeServer()

local CHUNKS_TO_RENDER_PER_UPDATE = 1

--// Variables
local preloaded_chunks = {} -- Stores preloaded chunk data (e.x. tree leaves)
local loaded_chunks = require(MODULES.LOADED_CHUNKS) -- Stores what blocks are loaded in each chunk in each position (strings) always be 1 chunk larger than distance
local rendered_chunks = {} -- Stores what blocks are loaded in each chunk in each position (objects)

local chunk_differences = {}

local frames = 0

local last_hrp_cframe = CFrame.new(0, MAX_HEIGHT * BLOCK_SIZE, 0)

--[[ PRIVATE ]]--

function is_tbl_empty(tbl: {}): (boolean)
	for _ in tbl do
		return false
	end
	return true
end



local function floor_divide(n,m)
	return math.floor(n/m)
end



local function generate_block(block_name: string, world_position: Vector3, chunk_folder: Folder)

	local stored_block = S_RS.ITEMS:FindFirstChild(block_name)

	local block = Instance.new('Part')
	block.Color = stored_block.Color
	block.Material = Enum.Material.SmoothPlastic
	block.Transparency = stored_block.Transparency
	block.Size = Vector3.new(3, 3, 3)
	block.Position = world_position
	block.Name = block_name
	block.Anchored = true
	block.CastShadow = false
	block.CanTouch = false

	return block
end






--// Returns position, block name, and chunk of neighbouring blocks given a coordinate location
local function get_neighbouring_blocks(world_position : Vector3): ({string: {}})

	local neighbouring_blocks_to_load = {}

	for _, offset_vector in BLOCK_NEIGHBOUR_VECTORS do

		local offset_world_position = Vector3.new(
			world_position.X + offset_vector.X,
			world_position.Y + offset_vector.Y,
			world_position.Z + offset_vector.Z
		)

		local position_data = M_CHUNKS_UTIL.world_to_chunk_position(offset_world_position)

		local chunk_x = position_data[1]
		local chunk_z = position_data[2]
		local x = position_data[3]
		local z = position_data[4]
		local y = position_data[5]

		if loaded_chunks[chunk_x] and loaded_chunks[chunk_x][chunk_z] then -- Checks if chunk is loaded

			local block = loaded_chunks[chunk_x][chunk_z][x][z][y]

			table.insert(neighbouring_blocks_to_load, {block, offset_world_position})
		end
	end

	return neighbouring_blocks_to_load
end





local function render_plant(plant_name: string, chunk_folder: Folder, world_position: Vector3): (Model)

	local plant = S_RS.ITEMS:FindFirstChild(plant_name):Clone()

	local plant_size = plant.PrimaryPart.Size

	local width_difference = (BLOCK_SIZE - plant_size.X) / 2 * 100 -- evaluate 2 * 100
	local height_difference = (BLOCK_SIZE - plant_size.Y)

	local plant_cframe = CFrame.new(
		(world_position.X + math.random(-width_difference, width_difference) / 100),
		(world_position.Y - height_difference / 2),-- + height_difference * 3 - height_difference / 2),
		(world_position.Z + math.random(-width_difference, width_difference) / 100)
	)

	plant:PivotTo(plant_cframe)
	plant.Parent = chunk_folder

	return plant
end





--// Creates a block and textures 
local function render_block(block_name: string, chunk_folder: Folder, world_position: Vector3 ): (BasePart | nil)

	local block = nil

	-- Find what sides should be visible
	local neighbouring_blocks = get_neighbouring_blocks(world_position)

	for _, neighbouring_block_data in neighbouring_blocks do

		local neighbouring_block_name = neighbouring_block_data[1]
		local neighbouring_block_world_position = neighbouring_block_data[2]

		if not neighbouring_block_name then continue end

		local neighbouring_block_chunk_position = M_CHUNKS_UTIL.world_to_chunk_position(neighbouring_block_world_position)

		local chunk_x = neighbouring_block_chunk_position[1]
		local chunk_z = neighbouring_block_chunk_position[2]
		local x = neighbouring_block_chunk_position[3]
		local z = neighbouring_block_chunk_position[4]
		local y = neighbouring_block_chunk_position[5]

		if not loaded_chunks[chunk_x] or not loaded_chunks[chunk_x][chunk_z] then continue end

		local neighbouring_block = loaded_chunks[chunk_x][chunk_z][x][z][y] -- Attempt to index nil with number

		if 
			neighbouring_block_name == 'Air'
			or M_ITEM_DATA[neighbouring_block]['TYPE'] == 'PLANT'
			or (block_name ~= 'Oak Leaves' and neighbouring_block_name == 'Oak Leaves')
		then

			if not block then
				block = generate_block(block_name, world_position, chunk_folder)
			end

			local face_vector = (neighbouring_block_world_position - world_position) / 3
			local side_name = RELATIVE_POSITION_TO_FACE[face_vector]

			local side_decal = S_RS.ITEMS.FACES:FindFirstChild(block_name):FindFirstChild(side_name):Clone()
			side_decal.Parent = block
		end
	end

	if block then
		block.Parent = chunk_folder
	end

	return block
end






--// Creates a table (for chunk blocks) made of air
local function create_air_table(): ({})

	local chunk_blocks = {}

	for x = 1, CHUNK_SIZE do
		chunk_blocks[x] = {}

		for z = 1, CHUNK_SIZE do
			chunk_blocks[x][z] = {}

			for y = MIN_HEIGHT, MAX_HEIGHT do
				chunk_blocks[x][z][y] = 'Air'
			end
		end
	end

	return chunk_blocks
end




function create_empty_block_table(tbl: {}, chunk_x: number, chunk_z: number)

	if not tbl[chunk_x] then
		tbl[chunk_x] = {}
	end
	if not tbl[chunk_x][chunk_z] then
		tbl[chunk_x][chunk_z] = {}

		for x = 1, CHUNK_SIZE do
			tbl[chunk_x][chunk_z][x] = {}

			for z = 1, CHUNK_SIZE do
				tbl[chunk_x][chunk_z][x][z] = {}
			end
		end
	end

	return tbl
end





--// Stores preloaded chunk data into chunk_blocks to be stored into loaded data
local function load_preloaded_chunk_data(chunk_blocks: {}, chunk_x: number, chunk_z: number): ({})

	if not preloaded_chunks[chunk_x] or not preloaded_chunks[chunk_x][chunk_z] then return chunk_blocks end

	for x, preloaded_x_blocks in preloaded_chunks[chunk_x][chunk_z] do
		for z, preloaded_z_blocks in preloaded_x_blocks do
			for y, block_name in preloaded_z_blocks do

				chunk_blocks[x][z][y] = block_name
			end
		end
	end

	return chunk_blocks
end







--// Handles the differences applied by preloaded data
local function handle_new_preloaded_data(new_preloaded_data: {})

	for chunk_x, preloaded_chunk_x_blocks in new_preloaded_data do
		for chunk_z, preloaded_chunk_z_blocks in preloaded_chunk_x_blocks do

			for x, preloaded_x_blocks in preloaded_chunk_z_blocks do
				for z, preloaded_z_blocks in preloaded_x_blocks do
					for y, block_name in preloaded_z_blocks do

						-- Prevents preloaded blocks taking over
						if chunk_differences[chunk_x] and chunk_differences[chunk_x][chunk_z] then
							if chunk_differences[chunk_x][chunk_z][x][z][y] ~= nil then continue end
						end

						-- If not preloaded -> Create preloaded data
						if not preloaded_chunks[chunk_x] or not preloaded_chunks[chunk_x][chunk_z] then
							preloaded_chunks = create_empty_block_table(preloaded_chunks, chunk_x, chunk_z)

						else -- If preloaded -> update preloaded data (only update air and leaves)

							local preloaded_block_at_position = preloaded_chunks[chunk_x][chunk_z][x][z][y]

							if preloaded_block_at_position ~= nil and preloaded_block_at_position ~= 'Oak Leaves' then continue end
						end

						-- If chunk is loaded -> update loaded data (only update air and leaves)
						if loaded_chunks[chunk_x] and loaded_chunks[chunk_x][chunk_z] then

							local loaded_block_at_position = loaded_chunks[chunk_x][chunk_z][x][z][y]
							if loaded_block_at_position ~= 'Air' and loaded_block_at_position ~= 'Oak Leaves' then continue end

							loaded_chunks[chunk_x][chunk_z][x][z][y] = block_name
						end

						preloaded_chunks[chunk_x][chunk_z][x][z][y] = block_name
					end
				end
			end
		end
	end
end






--// Given a table of differences, if its location is rendered then it culls neighbours else it stores in loaded
function register_differences(differences: {}): ()

	for _, difference_data in differences do

		local block_name = difference_data[1]
		local world_position = difference_data[2]

		local chunk_position = M_CHUNKS_UTIL.world_to_chunk_position(world_position)

		local chunk_x = chunk_position[1]
		local chunk_z = chunk_position[2]
		local x = chunk_position[3]
		local z = chunk_position[4]
		local y = chunk_position[5]

		chunk_differences = create_empty_block_table(chunk_differences, chunk_x, chunk_z)

		-- Loading
		if -- If chunk is loaded -> register block name
			loaded_chunks[chunk_x] 
			and loaded_chunks[chunk_x][chunk_z] 
		then
			loaded_chunks[chunk_x][chunk_z][x][z][y] = block_name
			chunk_differences[chunk_x][chunk_z][x][z][y] = block_name
		end

		-- Rendering
		if -- If chunk is rendered
			rendered_chunks[chunk_x] 
			and rendered_chunks[chunk_x][chunk_z] 
		then
			-- If air -> erase, else render block
			if block_name == 'Air' then

				-- Delete block at position
				if rendered_chunks[chunk_x][chunk_z][x][z][y] then

					rendered_chunks[chunk_x][chunk_z][x][z][y]:Destroy()
					rendered_chunks[chunk_x][chunk_z][x][z][y] = nil

					-- Update neighbouring blocks (put into function)
					for _, neighbouring_block_data in get_neighbouring_blocks(world_position) do

						local neighbouring_block_name = neighbouring_block_data[1]
						local neighbouring_block_world_position = neighbouring_block_data[2]

						if neighbouring_block_name == 'Air' then continue end
						if M_ITEM_DATA[neighbouring_block_name]['TYPE'] == 'PLANT' then continue end

						local neighbouring_block_chunk_position = M_CHUNKS_UTIL.world_to_chunk_position(neighbouring_block_world_position)

						local chunk_x = neighbouring_block_chunk_position[1]
						local chunk_z = neighbouring_block_chunk_position[2]
						local x = neighbouring_block_chunk_position[3]
						local z = neighbouring_block_chunk_position[4]
						local y = neighbouring_block_chunk_position[5]

						local neighbouring_block = rendered_chunks[chunk_x][chunk_z][x][z][y]

						-- Neighbour block NOT rendered -> render block
						if not neighbouring_block then

							local chunk_folder = workspace.MAP:FindFirstChild(`{chunk_x}x{chunk_z}`)

							neighbouring_block = render_block(neighbouring_block_name, chunk_folder, neighbouring_block_world_position)
							rendered_chunks[chunk_x][chunk_z][x][z][y] = neighbouring_block

						else -- Neighbour block IS rendered -> update textures

							local face_vector = (world_position - neighbouring_block_world_position) / 3
							local side_name = RELATIVE_POSITION_TO_FACE[face_vector]

							local side_decal = S_RS.ITEMS.FACES:FindFirstChild(neighbouring_block_name):FindFirstChild(side_name):Clone()
							side_decal.Parent = neighbouring_block
						end
					end
				end
			else
				-- Creates block twice, this check prevents it
				if rendered_chunks[chunk_x][chunk_z][x][z][y] then continue end

				local chunk_folder = workspace.MAP:FindFirstChild(`{chunk_x}x{chunk_z}`)
				local block = render_block(block_name, chunk_folder, world_position)
				rendered_chunks[chunk_x][chunk_z][x][z][y] = block
			end
		end		
	end
end





--// If plant above position -> erase plant
local function erase_plant_above(world_position: Vector3): ()

	local chunk_position = M_CHUNKS_UTIL.world_to_chunk_position(world_position)

	local chunk_x = chunk_position[1]
	local chunk_z = chunk_position[2]
	local x = chunk_position[3]
	local z = chunk_position[4]
	local y = chunk_position[5]

	-- Check block above
	local above_block_name = loaded_chunks[chunk_x][chunk_z][x][z][y + 1]

	if above_block_name and above_block_name ~= 'Air' then
		if M_ITEM_DATA[above_block_name]['TYPE'] == 'PLANT' then

			local above_block = rendered_chunks[chunk_x][chunk_z][x][z][y + 1]
			above_block:Destroy()

			loaded_chunks[chunk_x][chunk_z][x][z][y + 1] = 'Air'
			rendered_chunks[chunk_x][chunk_z][x][z][y + 1] = nil

			S_RS.REMOTES.UpdateChunk:FireServer({{'Air', M_CHUNKS_UTIL.chunk_to_world_position(chunk_x, chunk_z, x, z, y + 1)}})
		end
	end
end




--// Teleports player's character to a random location around spawn (chunks 0, 0) or where they last died
function teleport_character_to_spawn(character: Model): ()

	local hrp = character:WaitForChild('HumanoidRootPart')
	hrp.CFrame = last_hrp_cframe
	
	repeat
		task.wait(.1)
	until not is_tbl_empty(rendered_chunks)

	local rendered_chunk_xs = {}
	local rendered_chunk_zs = {}

	for rendered_chunk_x in rendered_chunks do
		table.insert(rendered_chunk_xs, rendered_chunk_x)
	end

	local chunk_x = rendered_chunk_xs[math.random(#rendered_chunk_xs)]

	for rendered_chunk_z in rendered_chunks[chunk_x] do
		table.insert(rendered_chunk_zs, rendered_chunk_z)
	end

	local chunk_z = rendered_chunk_zs[math.random(#rendered_chunk_zs)]

	local x = math.random(CHUNK_SIZE)
	local z = math.random(CHUNK_SIZE)

	--print(loaded_chunks)

	local blocks_at_spawn = loaded_chunks[chunk_x][chunk_z][x][z]

	for y = MAX_HEIGHT, MIN_HEIGHT, -1 do

		local block_name = blocks_at_spawn[y]

		if block_name ~= 'Air' and M_ITEM_DATA[block_name]['TYPE'] ~= 'PLANT' then

			local block = rendered_chunks[chunk_x][chunk_z][x][z][y]

			hrp.CFrame = CFrame.new(block.Position + character:GetExtentsSize() / 2)

			return
		end
	end
end





function register_player_position_upon_death(character: Model)

	local humanoid = character:WaitForChild('Humanoid')
	local hrp = character:WaitForChild('HumanoidRootPart')

	humanoid.Died:Connect(function()
		last_hrp_cframe = hrp.CFrame
	end)
end




function reorder_chunk_priority(chunks: {}): ({})

	local character_position = PLAYER.Character.HumanoidRootPart.Position

	local player_chunk_x = math.floor(character_position.X / (CHUNK_SIZE * BLOCK_SIZE))
	local player_chunk_z = math.floor(character_position.Z / (CHUNK_SIZE * BLOCK_SIZE))

	table.sort(chunks, function(a, b)
		return 
			math.sqrt((a[1] - player_chunk_x) * (a[1] - player_chunk_x) + (a[2] - player_chunk_z) * (a[2] - player_chunk_z))
			< 
			math.sqrt((b[1] - player_chunk_x) * (b[1] - player_chunk_x) + (b[2] - player_chunk_z) * (b[2] - player_chunk_z))
	end)
	return chunks
end




--[[ PUBLIC ]]--

function WORLD_GENERATION.render_chunk(chunk_x: number, chunk_z: number): ()

	local chunk_folder = Instance.new('Folder')
	chunk_folder.Name = `{chunk_x}x{chunk_z}`
	chunk_folder.Parent = workspace.MAP

	local loaded_chunk_blocks = loaded_chunks[chunk_x][chunk_z]
	local rendered_chunk_blocks = {}

	for x = 1, CHUNK_SIZE do
		rendered_chunk_blocks[x] = {}

		for z = 1, CHUNK_SIZE do
			rendered_chunk_blocks[x][z] = {}

			for y = MAX_HEIGHT, MIN_HEIGHT, -1 do
				local block_name = loaded_chunk_blocks[x][z][y]
				if block_name == 'Air' then continue end

				local world_position = M_CHUNKS_UTIL.chunk_to_world_position(chunk_x, chunk_z, x, z, y)

				local block

				if M_ITEM_DATA[block_name]['TYPE'] == 'PLANT' then
					block = render_plant(block_name, chunk_folder, world_position)
				else
					block = render_block(block_name, chunk_folder, world_position)
				end

				if block then
					rendered_chunk_blocks[x][z][y] = block
				end
			end
		end
	end

	if not rendered_chunks[chunk_x] then
		rendered_chunks[chunk_x] = {}
	end

	rendered_chunks[chunk_x][chunk_z] = rendered_chunk_blocks
end








--// Deletes chunk folder
function WORLD_GENERATION.unrender_chunk(chunk_x: number, chunk_z: number): ()

	workspace.MAP:FindFirstChild(`{chunk_x}x{chunk_z}`):Destroy()

	rendered_chunks[chunk_x][chunk_z] = nil

	if is_tbl_empty(rendered_chunks[chunk_x]) then
		rendered_chunks[chunk_x] = nil
	end
end





--// Stores chunk information in loaded_chunks[chunk_x][chunk_z]
function WORLD_GENERATION.load_chunk(chunk_x: number, chunk_z: number): ({})

	local chunk_blocks = {} -- Blocks for each position in chunk x, z, y
	local chunk_surface_y = {} -- Surface level for each position in chunk
	local chunk_preloaded_data = {}

	chunk_blocks = create_air_table()
	chunk_blocks = load_preloaded_chunk_data(chunk_blocks, chunk_x, chunk_z)
	chunk_blocks = M_TERRAIN_GENERATION.generate(chunk_blocks, chunk_x, chunk_z, SEED)
	chunk_blocks, chunk_surface_y = M_SURFACE_LAYER_GENERATION.generate(chunk_blocks, chunk_x, chunk_z, SEED)
	chunk_blocks, chunk_preloaded_data = M_DECORATIVE_GENERATION.generate(chunk_blocks, chunk_surface_y, SEED, chunk_x, chunk_z)

	handle_new_preloaded_data(chunk_preloaded_data)

	if not loaded_chunks[chunk_x] then
		loaded_chunks[chunk_x] = {}
	end
	loaded_chunks[chunk_x][chunk_z] = {}

	loaded_chunks[chunk_x][chunk_z] = chunk_blocks
	S_RS.REMOTES.GetChunkDifferences:FireServer(chunk_x, chunk_z)
end






--// Erases given chunk from loaded_chunks
function WORLD_GENERATION.unload_chunk(chunk_x: number, chunk_z: number): ()
	loaded_chunks[chunk_x][chunk_z] = nil

	if is_tbl_empty(loaded_chunks[chunk_x]) then
		loaded_chunks[chunk_x] = nil
	end

	if chunk_differences[chunk_x] and chunk_differences[chunk_x][chunk_z] then
		chunk_differences[chunk_x][chunk_z] = nil
	end
end




--// Breaking a block chunk loading logic
function WORLD_GENERATION.handle_mined_block(block_name: string, world_position: Vector3)

	erase_plant_above(world_position)

	local chunk_position = M_CHUNKS_UTIL.world_to_chunk_position(world_position)

	local chunk_x = chunk_position[1]
	local chunk_z = chunk_position[2]
	local x = chunk_position[3]
	local z = chunk_position[4]
	local y = chunk_position[5]

	-- Erase existing block
	rendered_chunks[chunk_x][chunk_z][x][z][y]:Destroy()
	rendered_chunks[chunk_x][chunk_z][x][z][y] = nil
	loaded_chunks[chunk_x][chunk_z][x][z][y] = 'Air'

	-- Update neighbouring blocks
	for _, neighbouring_block_data in get_neighbouring_blocks(world_position) do

		local neighbouring_block_name = neighbouring_block_data[1]
		local neighbouring_block_world_position = neighbouring_block_data[2]

		if neighbouring_block_name == 'Air' or M_ITEM_DATA[neighbouring_block_name]['TYPE'] == 'PLANT' then continue end

		local neighbouring_block_chunk_position = M_CHUNKS_UTIL.world_to_chunk_position(neighbouring_block_world_position)

		local chunk_x = neighbouring_block_chunk_position[1]
		local chunk_z = neighbouring_block_chunk_position[2]
		local x = neighbouring_block_chunk_position[3]
		local z = neighbouring_block_chunk_position[4]
		local y = neighbouring_block_chunk_position[5]

		if not rendered_chunks[chunk_x] or not rendered_chunks[chunk_x][chunk_z] then continue end

		local neighbouring_block = rendered_chunks[chunk_x][chunk_z][x][z][y]

		-- Neighbour block NOT rendered -> render block
		if not neighbouring_block then

			local chunk_folder = workspace.MAP:FindFirstChild(`{chunk_x}x{chunk_z}`)

			neighbouring_block = render_block(neighbouring_block_name, chunk_folder, neighbouring_block_world_position)
			rendered_chunks[chunk_x][chunk_z][x][z][y] = neighbouring_block

		else -- Neighbour block IS rendered -> update textures

			local face_vector = (world_position - neighbouring_block_world_position) / 3
			local side_name = RELATIVE_POSITION_TO_FACE[face_vector]


			local side_decal = S_RS.ITEMS.FACES:FindFirstChild(neighbouring_block_name):FindFirstChild(side_name):Clone()
			side_decal.Parent = neighbouring_block
		end
	end

	S_RS.REMOTES.UpdateChunk:FireServer({{'Air', world_position}})
end





function WORLD_GENERATION.handle_block_placed(block_name: string, world_position: Vector3)

	local chunk_position = M_CHUNKS_UTIL.world_to_chunk_position(world_position)

	local chunk_x = chunk_position[1]
	local chunk_z = chunk_position[2]
	local x = chunk_position[3]
	local z = chunk_position[4]
	local y = chunk_position[5]
end





--// Updates fog's range
function WORLD_GENERATION.update_fog()

	S_LIGHTING.FogEnd = CHUNK_DISTANCE * CHUNK_SIZE * BLOCK_SIZE
	S_LIGHTING.FogStart = CHUNK_DISTANCE * CHUNK_SIZE * BLOCK_SIZE - (BLOCK_SIZE * CHUNK_SIZE)
end





--[[ EVENTS ]]--

S_RS.REMOTES.UpdateChunk.OnClientEvent:Connect(register_differences) -- When different player mines block
S_RS.REMOTES.GetChunkDifferences.OnClientEvent:Connect(register_differences) -- When chunk is loaded

PLAYER.CharacterAdded:Connect(teleport_character_to_spawn)
PLAYER.CharacterAdded:Connect(register_player_position_upon_death)

WORLD_GENERATION.update_fog()

--// Initalize

if PLAYER.Character then
	coroutine.wrap(teleport_character_to_spawn)(PLAYER.Character)
end

return WORLD_GENERATION