local Generator = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local Lighting = game:GetService('Lighting')
local StarterPlayer = game:GetService('StarterPlayer')

local Modules = StarterPlayer.StarterPlayerScripts.Modules
local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ItemData = require(ReplicatedStorage.Shared.ItemData)
local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)
local M_TERRAIN_GENERATION = require(script.TERRAIN_GENERATION)
local M_DECORATIVE_GENERATION = require(script.DECORATIVE_GENERATION)
local M_SURFACE_LAYER_GENERATION = require(script.SURFACE_LAYER_GENERATION)

local Player = Players.LocalPlayer

local BLOCK_SIZE = ChunkSettings['BLOCK_SIZE']

local MAX_HEIGHT = ChunkSettings['MAX_HEIGHT']
local MIN_HEIGHT = ChunkSettings['MIN_HEIGHT']

local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']
local CHUNK_DISTANCE = ChunkSettings['CHUNK_DISTANCE']

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

local SEED = ReplicatedStorage.Remotes.GetSeed:InvokeServer()

local preloadedChunks = {} -- Stores preloaded chunk data (e.x. tree leaves)
local loadedChunks = require(Modules.LoadedChunks) -- Stores what blocks are loaded in each chunk in each position (strings) always be 1 chunk larger than distance
local renderedChunks = {} -- Stores what blocks are loaded in each chunk in each position (objects)

local chunkDifferences = {}

local lastHumanoidRootPartCFrame = CFrame.new(0, MAX_HEIGHT * BLOCK_SIZE, 0)

-- PRIVATE

function isTblEmpty(tbl: {}): (boolean)
	for _ in tbl do
		return false
	end
	return true
end


function generateBlock(blockName: string, worldPosition: Vector3, chunkFolder: Folder)

	local stored_block = ReplicatedStorage.ITEMS:FindFirstChild(blockName)

	local block = Instance.new('Part')
	block.Color = stored_block.Color
	block.Material = Enum.Material.SmoothPlastic
	block.Transparency = stored_block.Transparency
	block.Size = Vector3.new(3, 3, 3)
	block.Position = worldPosition
	block.Name = blockName
	block.Anchored = true
	block.CastShadow = false
	block.CanTouch = false

	return block
end


-- Returns position, block name, and chunk of neighbouring blocks given a coordinate location
function getNeighbouringBlocks(worldPosition : Vector3): ({string: {}})

	local neighbouringBlocks_to_load = {}

	for _, offset_vector in BLOCK_NEIGHBOUR_VECTORS do

		local offset_world_position = Vector3.new(
			worldPosition.X + offset_vector.X,
			worldPosition.Y + offset_vector.Y,
			worldPosition.Z + offset_vector.Z
		)

		local position_data = ChunksUtil.worldToChunkPosition(offset_world_position)

		local chunkX = position_data[1]
		local chunkZ = position_data[2]
		local x = position_data[3]
		local z = position_data[4]
		local y = position_data[5]

		if loadedChunks[chunkX] and loadedChunks[chunkX][chunkZ] then -- Checks if chunk is loaded

			local block = loadedChunks[chunkX][chunkZ][x][z][y]

			table.insert(neighbouringBlocks_to_load, {block, offset_world_position})
		end
	end

	return neighbouringBlocks_to_load
end


function renderPlant(plant_name: string, chunkFolder: Folder, worldPosition: Vector3): (Model)

	local plant = ReplicatedStorage.ITEMS:FindFirstChild(plant_name):Clone()

	local plant_size = plant.PrimaryPart.Size

	local width_difference = (BLOCK_SIZE - plant_size.X) / 2 * 100 -- evaluate 2 * 100
	local height_difference = (BLOCK_SIZE - plant_size.Y)

	local plant_cframe = CFrame.new(
		(worldPosition.X + math.random(-width_difference, width_difference) / 100),
		(worldPosition.Y - height_difference / 2),-- + height_difference * 3 - height_difference / 2),
		(worldPosition.Z + math.random(-width_difference, width_difference) / 100)
	)

	plant:PivotTo(plant_cframe)
	plant.Parent = chunkFolder

	return plant
end


-- Creates a block and textures 
function renderBlock(blockName: string, chunkFolder: Folder, worldPosition: Vector3 ): (BasePart | nil)

	local block = nil

	-- Find what sides should be visible
	local neighbouringBlocks = getNeighbouringBlocks(worldPosition)

	for _, neighbouringBlockData in neighbouringBlocks do

		local neighbouringBlockName = neighbouringBlockData[1]
		local neighbouringBlockWorldPosition = neighbouringBlockData[2]

		if not neighbouringBlockName then 
			continue 
		end

		local neighbouringBlockChunkPosition = ChunksUtil.worldToChunkPosition(neighbouringBlockWorldPosition)

		local chunkX = neighbouringBlockChunkPosition[1]
		local chunkZ = neighbouringBlockChunkPosition[2]
		local x = neighbouringBlockChunkPosition[3]
		local z = neighbouringBlockChunkPosition[4]
		local y = neighbouringBlockChunkPosition[5]

		if not loadedChunks[chunkX] or not loadedChunks[chunkX][chunkZ] then 
			continue 
		end

		local neighbouringBlock = loadedChunks[chunkX][chunkZ][x][z][y] -- Attempt to index nil with number

		if 
			neighbouringBlockName == 'Air'
			or ItemData[neighbouringBlock]['TYPE'] == 'PLANT'
			or (blockName ~= 'Oak Leaves' and neighbouringBlockName == 'Oak Leaves')
		then

			if not block then
				block = generateBlock(blockName, worldPosition, chunkFolder)
			end

			local faceVector = (neighbouringBlockWorldPosition - worldPosition) / 3
			local sideName = RELATIVE_POSITION_TO_FACE[faceVector]

			local side_decal = ReplicatedStorage.Items.Faces:FindFirstChild(blockName):FindFirstChild(sideName):Clone()
			side_decal.Parent = block
		end
	end

	if block then
		block.Parent = chunkFolder
	end

	return block
end


-- Creates a table (for chunk blocks) made of air
function createAirTable(): ({})

	local chunkBlocks = {}

	for x = 1, CHUNK_SIZE do
		chunkBlocks[x] = {}

		for z = 1, CHUNK_SIZE do
			chunkBlocks[x][z] = {}

			for y = MIN_HEIGHT, MAX_HEIGHT do
				chunkBlocks[x][z][y] = 'Air'
			end
		end
	end

	return chunkBlocks
end


function createEmptyBlockTable(tbl: {}, chunkX: number, chunkZ: number)

	if not tbl[chunkX] then
		tbl[chunkX] = {}
	end
	if not tbl[chunkX][chunkZ] then
		tbl[chunkX][chunkZ] = {}

		for x = 1, CHUNK_SIZE do
			tbl[chunkX][chunkZ][x] = {}

			for z = 1, CHUNK_SIZE do
				tbl[chunkX][chunkZ][x][z] = {}
			end
		end
	end

	return tbl
end


-- Stores preloaded chunk data into chunkBlocks to be stored into loaded data
function loadPreloadedChunkData(chunkBlocks: {}, chunkX: number, chunkZ: number): ({})

	if not preloadedChunks[chunkX] or not preloadedChunks[chunkX][chunkZ] then 
		return chunkBlocks
	end

	for x, preloaded_x_blocks in preloadedChunks[chunkX][chunkZ] do
		for z, preloaded_z_blocks in preloaded_x_blocks do
			for y, blockName in preloaded_z_blocks do

				chunkBlocks[x][z][y] = blockName
			end
		end
	end

	return chunkBlocks
end


-- Handles the differences applied by preloaded data
function handleNewPreloadedData(new_preloaded_data: {})

	for chunkX, preloaded_chunk_x_blocks in new_preloaded_data do
		for chunkZ, preloaded_chunk_z_blocks in preloaded_chunk_x_blocks do

			for x, preloaded_x_blocks in preloaded_chunk_z_blocks do
				for z, preloaded_z_blocks in preloaded_x_blocks do
					for y, blockName in preloaded_z_blocks do

						-- Prevents preloaded blocks taking over
						if chunkDifferences[chunkX] and chunkDifferences[chunkX][chunkZ] then
							if chunkDifferences[chunkX][chunkZ][x][z][y] ~= nil then 
								continue 
							end
						end

						-- If not preloaded -> Create preloaded data
						if not preloadedChunks[chunkX] or not preloadedChunks[chunkX][chunkZ] then
							preloadedChunks = createEmptyBlockTable(preloadedChunks, chunkX, chunkZ)

						else -- If preloaded -> update preloaded data (only update air and leaves)

							local preloaded_block_at_position = preloadedChunks[chunkX][chunkZ][x][z][y]

							if preloaded_block_at_position ~= nil and preloaded_block_at_position ~= 'Oak Leaves' then 
								continue 
							end
						end

						-- If chunk is loaded -> update loaded data (only update air and leaves)
						if loadedChunks[chunkX] and loadedChunks[chunkX][chunkZ] then

							local loaded_block_at_position = loadedChunks[chunkX][chunkZ][x][z][y]

							if loaded_block_at_position ~= 'Air' and loaded_block_at_position ~= 'Oak Leaves' then 
								continue 
							end

							loadedChunks[chunkX][chunkZ][x][z][y] = blockName
						end

						preloadedChunks[chunkX][chunkZ][x][z][y] = blockName
					end
				end
			end
		end
	end
end


-- Given a table of differences, if its location is rendered then it culls neighbours else it stores in loaded
function registerDifferences(differences: {}): ()

	for _, differenceData in differences do

		local blockName = differenceData[1]
		local worldPosition = differenceData[2]

		local chunkPosition = ChunksUtil.worldToChunkPosition(worldPosition)

		local chunkX = chunkPosition[1]
		local chunkZ = chunkPosition[2]
		local x = chunkPosition[3]
		local z = chunkPosition[4]
		local y = chunkPosition[5]

		chunkDifferences = createEmptyBlockTable(chunkDifferences, chunkX, chunkZ)

		-- Loading
		if -- If chunk is loaded -> register block name
			loadedChunks[chunkX] 
			and loadedChunks[chunkX][chunkZ] 
		then
			loadedChunks[chunkX][chunkZ][x][z][y] = blockName
			chunkDifferences[chunkX][chunkZ][x][z][y] = blockName
		end

		-- Rendering
		if -- If chunk is rendered
			renderedChunks[chunkX] 
			and renderedChunks[chunkX][chunkZ] 
		then
			-- If air -> erase, else render block
			if blockName == 'Air' then

				-- Delete block at position
				if renderedChunks[chunkX][chunkZ][x][z][y] then

					renderedChunks[chunkX][chunkZ][x][z][y]:Destroy()
					renderedChunks[chunkX][chunkZ][x][z][y] = nil

					-- Update neighbouring blocks (put into function)
					for _, neighbouringBlockData in getNeighbouringBlocks(worldPosition) do

						local neighbouringBlockName = neighbouringBlockData[1]
						local neighbouringBlockWorldPosition = neighbouringBlockData[2]

						if 
							neighbouringBlockName == 'Air' 
							or ItemData[neighbouringBlockName]['TYPE'] == 'PLANT'
						then 
							continue 
						end

						local neighbouringBlockChunkPosition = ChunksUtil.worldToChunkPosition(neighbouringBlockWorldPosition)

						local chunkX = neighbouringBlockChunkPosition[1]
						local chunkZ = neighbouringBlockChunkPosition[2]
						local x = neighbouringBlockChunkPosition[3]
						local z = neighbouringBlockChunkPosition[4]
						local y = neighbouringBlockChunkPosition[5]

						local neighbouringBlock = renderedChunks[chunkX][chunkZ][x][z][y]

						-- Neighbour block NOT rendered -> render block
						if not neighbouringBlock then

							local chunkFolder = workspace.Map:FindFirstChild(`{chunkX}x{chunkZ}`)

							neighbouringBlock = renderBlock(neighbouringBlockName, chunkFolder, neighbouringBlockWorldPosition)
							renderedChunks[chunkX][chunkZ][x][z][y] = neighbouringBlock

						else -- Neighbour block IS rendered -> update textures

							local faceVector = (worldPosition - neighbouringBlockWorldPosition) / 3
							local sideName = RELATIVE_POSITION_TO_FACE[faceVector]

							local side_decal = ReplicatedStorage.ITEMS.FACES:FindFirstChild(neighbouringBlockName):FindFirstChild(sideName):Clone()
							side_decal.Parent = neighbouringBlock
						end
					end
				end
			else
				-- Creates block twice, this check prevents it
				if renderedChunks[chunkX][chunkZ][x][z][y] then continue end

				local chunkFolder = workspace.Map:FindFirstChild(`{chunkX}x{chunkZ}`)
				local block = renderBlock(blockName, chunkFolder, worldPosition)
				renderedChunks[chunkX][chunkZ][x][z][y] = block
			end
		end		
	end
end


-- If plant above position -> erase plant
function erasePlantAbove(worldPosition: Vector3): ()

	local chunkPosition = ChunksUtil.worldToChunkPosition(worldPosition)

	local chunkX = chunkPosition[1]
	local chunkZ = chunkPosition[2]
	local x = chunkPosition[3]
	local z = chunkPosition[4]
	local y = chunkPosition[5]

	-- Check block above
	local above_block_name = loadedChunks[chunkX][chunkZ][x][z][y + 1]

	if 
		above_block_name 
		and above_block_name ~= 'Air' 
		and ItemData[above_block_name]['TYPE'] == 'PLANT'
	then
		local aboveBlock = renderedChunks[chunkX][chunkZ][x][z][y + 1]
		aboveBlock:Destroy()

		loadedChunks[chunkX][chunkZ][x][z][y + 1] = 'Air'
		renderedChunks[chunkX][chunkZ][x][z][y + 1] = nil

		ReplicatedStorage.Remotes.UpdateChunk:FireServer({{'Air', ChunksUtil.chunk_to_world_position(chunkX, chunkZ, x, z, y + 1)}})
	end
end


-- Teleports player's character to a random location around spawn (chunks 0, 0) or where they last died
function teleportCharacterToSpawn(character: Model): ()

	local HumanoidRootPart = character:WaitForChild('HumanoidRootPart')
	HumanoidRootPart.CFrame = lastHumanoidRootPartCFrame
	
	repeat
		task.wait(.1)
	until not isTblEmpty(renderedChunks)

	local rendered_chunk_xs = {}
	local rendered_chunk_zs = {}

	for rendered_chunk_x in renderedChunks do
		table.insert(rendered_chunk_xs, rendered_chunk_x)
	end

	local chunkX = rendered_chunk_xs[math.random(#rendered_chunk_xs)]

	for rendered_chunk_z in renderedChunks[chunkX] do
		table.insert(rendered_chunk_zs, rendered_chunk_z)
	end

	local chunkZ = rendered_chunk_zs[math.random(#rendered_chunk_zs)]

	local x = math.random(CHUNK_SIZE)
	local z = math.random(CHUNK_SIZE)

	--print(loadedChunks)

	local blocks_at_spawn = loadedChunks[chunkX][chunkZ][x][z]

	for y = MAX_HEIGHT, MIN_HEIGHT, -1 do

		local blockName = blocks_at_spawn[y]

		if blockName ~= 'Air' and ItemData[blockName]['TYPE'] ~= 'PLANT' then

			local block = renderedChunks[chunkX][chunkZ][x][z][y]

			HumanoidRootPart.CFrame = CFrame.new(block.Position + character:GetExtentsSize() / 2)

			return
		end
	end
end


function registerPlayerPosition(character: Model)

	local humanoid = character:WaitForChild('Humanoid')
	local HumanoidRootPart = character:WaitForChild('HumanoidRootPart')

	humanoid.Died:Connect(function()
		lastHumanoidRootPartCFrame = HumanoidRootPart.CFrame
	end)
end


-- PUBLIC 

function Generator.renderChunk(chunkX: number, chunkZ: number): ()

	local chunkFolder = Instance.new('Folder')
	chunkFolder.Name = `{chunkX}x{chunkZ}`
	chunkFolder.Parent = workspace.Map

	local loaded_chunk_blocks = loadedChunks[chunkX][chunkZ]
	local renderedChunkBlocks = {}

	for x = 1, CHUNK_SIZE do
		renderedChunkBlocks[x] = {}

		for z = 1, CHUNK_SIZE do
			renderedChunkBlocks[x][z] = {}

			for y = MAX_HEIGHT, MIN_HEIGHT, -1 do

				local blockName = loaded_chunk_blocks[x][z][y]

				if blockName == 'Air' then 
					continue 
				end

				local worldPosition = ChunksUtil.chunk_to_world_position(chunkX, chunkZ, x, z, y)

				local block

				if ItemData[blockName]['TYPE'] == 'PLANT' then
					block = renderPlant(blockName, chunkFolder, worldPosition)
				else
					block = renderBlock(blockName, chunkFolder, worldPosition)
				end

				if block then
					renderedChunkBlocks[x][z][y] = block
				end
			end
		end
	end

	if not renderedChunks[chunkX] then
		renderedChunks[chunkX] = {}
	end

	renderedChunks[chunkX][chunkZ] = renderedChunkBlocks
end


-- Deletes chunk folder
function Generator.unrenderChunk(chunkX: number, chunkZ: number): ()

	workspace.Map:FindFirstChild(`{chunkX}x{chunkZ}`):Destroy()

	renderedChunks[chunkX][chunkZ] = nil

	if isTblEmpty(renderedChunks[chunkX]) then
		renderedChunks[chunkX] = nil
	end
end


-- Stores chunk information in loadedChunks[chunkX][chunkZ]
function Generator.loadChunk(chunkX: number, chunkZ: number): ({})

	local chunkBlocks = {} -- Blocks for each position in chunk x, z, y
	local chunkSurfaceY = {} -- Surface level for each position in chunk
	local chunk_preloaded_data = {}

	chunkBlocks = createAirTable()
	chunkBlocks = loadPreloadedChunkData(chunkBlocks, chunkX, chunkZ)
	chunkBlocks = M_TERRAIN_GENERATION.generate(chunkBlocks, chunkX, chunkZ, SEED)
	chunkBlocks, chunkSurfaceY = M_SURFACE_LAYER_GENERATION.generate(chunkBlocks, chunkX, chunkZ, SEED)
	chunkBlocks, chunk_preloaded_data = M_DECORATIVE_GENERATION.generate(chunkBlocks, chunkSurfaceY, SEED, chunkX, chunkZ)

	handleNewPreloadedData(chunk_preloaded_data)

	if not loadedChunks[chunkX] then
		loadedChunks[chunkX] = {}
	end
	loadedChunks[chunkX][chunkZ] = {}

	loadedChunks[chunkX][chunkZ] = chunkBlocks
	ReplicatedStorage.Remotes.GetChunkDifferences:FireServer(chunkX, chunkZ)
end


-- Erases given chunk from loadedChunks
function Generator.unloadChunk(chunkX: number, chunkZ: number): ()
	loadedChunks[chunkX][chunkZ] = nil

	if isTblEmpty(loadedChunks[chunkX]) then
		loadedChunks[chunkX] = nil
	end

	if chunkDifferences[chunkX] and chunkDifferences[chunkX][chunkZ] then
		chunkDifferences[chunkX][chunkZ] = nil
	end
end


-- Breaking a block chunk loading logic
function Generator.handleMinedBlock(blockName: string, worldPosition: Vector3)

	erasePlantAbove(worldPosition)

	local chunkPosition = ChunksUtil.worldToChunkPosition(worldPosition)

	local chunkX = chunkPosition[1]
	local chunkZ = chunkPosition[2]
	local x = chunkPosition[3]
	local z = chunkPosition[4]
	local y = chunkPosition[5]

	-- Erase existing block
	renderedChunks[chunkX][chunkZ][x][z][y]:Destroy()
	renderedChunks[chunkX][chunkZ][x][z][y] = nil
	loadedChunks[chunkX][chunkZ][x][z][y] = 'Air'

	-- Update neighbouring blocks
	for _, neighbouringBlockData in getNeighbouringBlocks(worldPosition) do

		local neighbouringBlockName = neighbouringBlockData[1]
		local neighbouringBlockWorldPosition = neighbouringBlockData[2]

		if 
			neighbouringBlockName == 'Air' 
			or ItemData[neighbouringBlockName]['TYPE'] == 'PLANT' 
		then 
			continue 
		end

		local neighbouringBlockChunkPosition = ChunksUtil.worldToChunkPosition(neighbouringBlockWorldPosition)

		local chunkX = neighbouringBlockChunkPosition[1]
		local chunkZ = neighbouringBlockChunkPosition[2]
		local x = neighbouringBlockChunkPosition[3]
		local z = neighbouringBlockChunkPosition[4]
		local y = neighbouringBlockChunkPosition[5]

		if not renderedChunks[chunkX] or not renderedChunks[chunkX][chunkZ] then 
			continue 
		end

		local neighbouringBlock = renderedChunks[chunkX][chunkZ][x][z][y]

		-- Neighbour block NOT rendered -> render block
		if not neighbouringBlock then

			local chunkFolder = workspace.Map:FindFirstChild(`{chunkX}x{chunkZ}`)

			neighbouringBlock = renderBlock(neighbouringBlockName, chunkFolder, neighbouringBlockWorldPosition)
			renderedChunks[chunkX][chunkZ][x][z][y] = neighbouringBlock

		else -- Neighbour block IS rendered -> update textures

			local faceVector = (worldPosition - neighbouringBlockWorldPosition) / 3
			local sideName = RELATIVE_POSITION_TO_FACE[faceVector]


			local side_decal = ReplicatedStorage.ITEMS.FACES:FindFirstChild(neighbouringBlockName):FindFirstChild(sideName):Clone()
			side_decal.Parent = neighbouringBlock
		end
	end

	ReplicatedStorage.Remotes.UpdateChunk:FireServer({{'Air', worldPosition}})
end


function Generator.handle_block_placed(blockName: string, worldPosition: Vector3)

	local chunkPosition = ChunksUtil.worldToChunkPosition(worldPosition)

	local chunkX = chunkPosition[1]
	local chunkZ = chunkPosition[2]
	local x = chunkPosition[3]
	local z = chunkPosition[4]
	local y = chunkPosition[5]
end


-- Updates fog's range
function Generator.updateFog()

	Lighting.FogEnd = CHUNK_DISTANCE * CHUNK_SIZE * BLOCK_SIZE
	Lighting.FogStart = CHUNK_DISTANCE * CHUNK_SIZE * BLOCK_SIZE - (BLOCK_SIZE * CHUNK_SIZE)
end


-- EVENTS

ReplicatedStorage.Remotes.UpdateChunk.OnClientEvent:Connect(registerDifferences) -- When different player mines block
ReplicatedStorage.Remotes.GetChunkDifferences.OnClientEvent:Connect(registerDifferences) -- When chunk is loaded

Player.CharacterAdded:Connect(teleportCharacterToSpawn)
Player.CharacterAdded:Connect(registerPlayerPosition)

Generator.updateFog()

-- Initalize
if Player.Character then
	coroutine.wrap(teleportCharacterToSpawn)(Player.Character)
end

return Generator