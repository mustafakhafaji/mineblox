local GenerationManager = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local Lighting = game:GetService('Lighting')
local StarterPlayer = game:GetService('StarterPlayer')

local Modules = StarterPlayer.StarterPlayerScripts.Modules
local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)
local ItemsIDs = require(ReplicatedStorage.Shared.ItemsIDs)
local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)
local TerrainShapeGenerator = require(Modules.Chunks.Terrain.TerrainShapeGenerator)
local DecorationsGenerator = require(Modules.Chunks.Terrain.Decorations.DecorationsGenerator)
local SurfaceLayerGenerator = require(Modules.Chunks.Terrain.SurfaceLayerGenerator)

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

local SEED = ReplicatedStorage.Remotes.Chunks.GetSeed:InvokeServer()

local AIR_ID = ItemsData['Air']['ID']
local OAK_LEAVES_ID = ItemsData['Oak Leaves']['ID']

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


function generateBlock(blockID: number, worldPosition: Vector3): (Part)

	local referenceBlockName = ItemsIDs[blockID]
	local referenceBlock = ReplicatedStorage.Items:FindFirstChild(referenceBlockName)

	local block = Instance.new('Part')
	block.Color = referenceBlock.Color
	block.Material = Enum.Material.SmoothPlastic
	block.Transparency = referenceBlock.Transparency
	block.Size = Vector3.new(3, 3, 3)
	block.Position = worldPosition
	block.Name = referenceBlockName
	block.Anchored = true
	block.CastShadow = false
	block.CanTouch = false

	return block
end


-- Returns position, block name, and chunk of neighbouring blocks given a coordinate location
function getNeighbouringBlocks(centerBlockWorldPosition : Vector3): ({number: {number: number | Vector3}})

	local neighbouringBlocks = {}

	for _, offsetVector in BLOCK_NEIGHBOUR_VECTORS do

		local neighborWorldPosition = Vector3.new(
			centerBlockWorldPosition.X + offsetVector.X,
			centerBlockWorldPosition.Y + offsetVector.Y,
			centerBlockWorldPosition.Z + offsetVector.Z
		)

		local neighborChunkPosition = ChunksUtil.worldToChunkPosition(neighborWorldPosition)

		local neighborChunkX = neighborChunkPosition[1]
		local neighborChunkZ = neighborChunkPosition[2]
		local neighborX = neighborChunkPosition[3]
		local neighborZ = neighborChunkPosition[4]
		local neighborY = neighborChunkPosition[5]

		-- If neighbor block is loaded (exists) -> add to neighbouringBlocks table
		if 
			not loadedChunks[neighborChunkX] 
			or not loadedChunks[neighborChunkX][neighborChunkZ] 
		then
			return
		end

		local blockID = loadedChunks[neighborChunkX][neighborChunkZ][neighborX][neighborZ][neighborY]

		table.insert(neighbouringBlocks, {blockID, neighborWorldPosition})
	end

	return neighbouringBlocks
end


function renderPlant(blockID: number, chunkFolder: Folder, worldPosition: Vector3): (Model)

	local plantName = ItemsIDs[blockID]
	local plant = ReplicatedStorage.Items:FindFirstChild(plantName):Clone()

	local plantSize = plant.PrimaryPart.Size

	local widthDifference = (BLOCK_SIZE - plantSize.X) / 200
	local heightDifference = (BLOCK_SIZE - plantSize.Y)

	local plantCFrame = CFrame.new(
		(worldPosition.X + math.random(-widthDifference, widthDifference) / 100),
		(worldPosition.Y - heightDifference / 2),-- + heightDifference * 3 - heightDifference / 2),
		(worldPosition.Z + math.random(-widthDifference, widthDifference) / 100)
	)

	plant:PivotTo(plantCFrame)
	plant.Parent = chunkFolder

	return plant
end


-- Creates a block and textures 
function renderBlock(blockID: number, chunkFolder: Folder, worldPosition: Vector3 ): (BasePart | nil)

	local block = nil

	-- Find what sides should be visible
	local neighborsData = getNeighbouringBlocks(worldPosition)

	for _, neighbouringBlockData in neighborsData do

		local neighborBlockID = neighbouringBlockData[1]
		local neighborBlockWorldPosition = neighbouringBlockData[2]
		local neighborBlockName = ItemsIDs[neighborBlockID]

		local neighbourBlockChunkPosition = ChunksUtil.worldToChunkPosition(neighborBlockWorldPosition)

		local neighborChunkX = neighbourBlockChunkPosition[1]
		local neighborChunkZ = neighbourBlockChunkPosition[2]

		if not loadedChunks[neighborChunkX] or not loadedChunks[neighborChunkX][neighborChunkZ] then 
			continue 
		end

		-- Determine whether side of block should be visible -> (generate block if haven't already), apply texture
		if 
			neighborBlockID == AIR_ID
			or ItemsData[neighborBlockName]['Type'] == 'Plant'
			or ItemsData[neighborBlockName]['isTransparent']
		then

			if not block then
				block = generateBlock(blockID, worldPosition)
			end

			local faceVector = (neighborBlockWorldPosition - worldPosition) / 3
			local sideName = RELATIVE_POSITION_TO_FACE[faceVector]

			local blockName = ItemsIDs[blockID]

			local sideDecal = ReplicatedStorage.Items.FaceDecals:FindFirstChild(blockName):FindFirstChild(sideName):Clone()
			sideDecal.Parent = block
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
				chunkBlocks[x][z][y] = AIR_ID
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

	for x, preloadedBlocksX in preloadedChunks[chunkX][chunkZ] do
		for z, preloadedBlocksZ in preloadedBlocksX do
			for y, blockName in preloadedBlocksZ do

				chunkBlocks[x][z][y] = blockName
			end
		end
	end

	return chunkBlocks
end


-- Handles the differences applied by preloaded data
function handleNewPreloadedData(newPreloadedData: {})

	for chunkX, preloadedChunkXBlocks in newPreloadedData do
		for chunkZ, preloadedChunkZBlocks in preloadedChunkXBlocks do

			for x, preloadedBlocksX in preloadedChunkZBlocks do
				for z, preloadedBlocksZ in preloadedBlocksX do
					for y, blockName in preloadedBlocksZ do

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

							local preloadedBlockAtPosition = preloadedChunks[chunkX][chunkZ][x][z][y]

							if preloadedBlockAtPosition ~= nil and preloadedBlockAtPosition ~= 'Oak Leaves' then 
								continue 
							end
						end

						-- If chunk is loaded -> update loaded data (only update air and leaves)
						if loadedChunks[chunkX] and loadedChunks[chunkX][chunkZ] then

							local loadedBlockAtPosition = loadedChunks[chunkX][chunkZ][x][z][y]

							if loadedBlockAtPosition ~= AIR_ID and loadedBlockAtPosition ~= 'Oak Leaves' then 
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
			not (renderedChunks[chunkX] 
			and renderedChunks[chunkX][chunkZ])
		then
			return
		end
			
		-- If air -> erase, else render block
		if blockName == AIR_ID then

			-- Delete block at position
			if renderedChunks[chunkX][chunkZ][x][z][y] then

				renderedChunks[chunkX][chunkZ][x][z][y]:Destroy()
				renderedChunks[chunkX][chunkZ][x][z][y] = nil

				-- Update neighbouring blocks (put into function)
				for _, neighbouringBlockData in getNeighbouringBlocks(worldPosition) do

					local neighbouringBlockName = neighbouringBlockData[1]
					local neighbouringBlockWorldPosition = neighbouringBlockData[2]

					if 
						neighbouringBlockName == AIR_ID 
						or ItemsData[neighbouringBlockName]['Type'] == 'Plant'
					then 
						continue 
					end

					local neighbourBlockChunkPosition = ChunksUtil.worldToChunkPosition(neighbouringBlockWorldPosition)

					local chunkX = neighbourBlockChunkPosition[1]
					local chunkZ = neighbourBlockChunkPosition[2]
					local x = neighbourBlockChunkPosition[3]
					local z = neighbourBlockChunkPosition[4]
					local y = neighbourBlockChunkPosition[5]

					local neighbouringBlock = renderedChunks[chunkX][chunkZ][x][z][y]

					-- Neighbour block NOT rendered -> render block
					if not neighbouringBlock then

						local chunkFolder = workspace.Map:FindFirstChild(`{chunkX}x{chunkZ}`)

						neighbouringBlock = renderBlock(neighbouringBlockName, chunkFolder, neighbouringBlockWorldPosition)
						renderedChunks[chunkX][chunkZ][x][z][y] = neighbouringBlock

					else -- Neighbour block IS rendered -> update textures

						local faceVector = (worldPosition - neighbouringBlockWorldPosition) / 3
						local sideName = RELATIVE_POSITION_TO_FACE[faceVector]

						local sideDecal = ReplicatedStorage.Items.FaceDecals:FindFirstChild(neighbouringBlockName):FindFirstChild(sideName):Clone()
						sideDecal.Parent = neighbouringBlock
					end
				end
			end
		else
			-- Creates block twice, this check prevents it
			if renderedChunks[chunkX][chunkZ][x][z][y] then 
				continue 
			end

			local chunkFolder = workspace.Map:FindFirstChild(`{chunkX}x{chunkZ}`)
			local block = renderBlock(blockName, chunkFolder, worldPosition)
			renderedChunks[chunkX][chunkZ][x][z][y] = block
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

	local aboveBlockName = loadedChunks[chunkX][chunkZ][x][z][y + 1]

	-- If block above plant -> erase
	if 
		aboveBlockName 
		and aboveBlockName ~= AIR_ID 
		and ItemsData[aboveBlockName]['Type'] == 'Plant'
	then
		local aboveBlock = renderedChunks[chunkX][chunkZ][x][z][y + 1]
		aboveBlock:Destroy()

		loadedChunks[chunkX][chunkZ][x][z][y + 1] = AIR_ID
		renderedChunks[chunkX][chunkZ][x][z][y + 1] = nil

		ReplicatedStorage.Remotes.Chunks.UpdateChunk:FireServer({{AIR_ID, ChunksUtil.chunkToWorldPosition(chunkX, chunkZ, x, z, y + 1)}})
	end
end


-- Teleports player's character to a random location around spawn (chunks 0, 0) or where they last died
function teleportCharacterToSpawn(character: Model): ()

	local HumanoidRootPart = character:WaitForChild('HumanoidRootPart')
	HumanoidRootPart.CFrame = lastHumanoidRootPartCFrame
	
	repeat
		task.wait(.1)
	until not isTblEmpty(renderedChunks)

	local renderedChunkXs = {}
	local renderedChunkZs = {}

	for renderedChunkX in renderedChunks do
		table.insert(renderedChunkXs, renderedChunkX)
	end

	local chunkX = renderedChunkXs[math.random(#renderedChunkXs)]

	for renderedChunkZ in renderedChunks[chunkX] do
		table.insert(renderedChunkZs, renderedChunkZ)
	end

	local chunkZ = renderedChunkZs[math.random(#renderedChunkZs)]

	local x = math.random(CHUNK_SIZE)
	local z = math.random(CHUNK_SIZE)

	--print(loadedChunks)

	local blocksAtSpawn = loadedChunks[chunkX][chunkZ][x][z]

	for y = MAX_HEIGHT, MIN_HEIGHT, -1 do

		local blockID = blocksAtSpawn[y]
		local blockName = ItemsIDs[blockID]

		if blockID ~= AIR_ID and ItemsData[blockName]['Type'] ~= 'Plant' then

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

function GenerationManager.renderChunk(chunkX: number, chunkZ: number): ()

	local chunkFolder = Instance.new('Folder')
	chunkFolder.Name = `{chunkX}x{chunkZ}`
	chunkFolder.Parent = workspace.Map

	local loadedChunkBlocks = loadedChunks[chunkX][chunkZ]
	local renderedChunkBlocks = {}

	for x = 1, CHUNK_SIZE do
		renderedChunkBlocks[x] = {}

		for z = 1, CHUNK_SIZE do
			renderedChunkBlocks[x][z] = {}

			for y = MAX_HEIGHT, MIN_HEIGHT + 1, -1 do

				local blockID = loadedChunkBlocks[x][z][y]
				local blockName = ItemsIDs[blockID]

				if 
					not blockID 
					or blockID == AIR_ID
				then 
					continue 
				end

				local worldPosition = ChunksUtil.chunkToWorldPosition(chunkX, chunkZ, x, z, y)

				local block

				if ItemsData[blockName]['Type'] == 'Plant' then
					block = renderPlant(blockID, chunkFolder, worldPosition)
				else
					block = renderBlock(blockID, chunkFolder, worldPosition)
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
function GenerationManager.unrenderChunk(chunkX: number, chunkZ: number): ()

	workspace.Map:FindFirstChild(`{chunkX}x{chunkZ}`):Destroy()

	renderedChunks[chunkX][chunkZ] = nil

	if isTblEmpty(renderedChunks[chunkX]) then
		renderedChunks[chunkX] = nil
	end
end


-- Stores chunk information in loadedChunks[chunkX][chunkZ]
function GenerationManager.loadChunk(chunkX: number, chunkZ: number): ({})

	local chunkBlocks = {} -- Blocks for each position in chunk x, z, y
	local chunkSurfaceY = {} -- Surface level for each position in chunk
	local chunkPreloadedData = {}

	chunkBlocks = createAirTable()
	chunkBlocks = TerrainShapeGenerator.generate(chunkBlocks, chunkX, chunkZ, SEED)
	chunkBlocks, chunkSurfaceY = SurfaceLayerGenerator.generate(chunkBlocks, chunkX, chunkZ, SEED)
	chunkBlocks, chunkPreloadedData = DecorationsGenerator.generate(chunkBlocks, chunkSurfaceY, SEED, chunkX, chunkZ)
	chunkBlocks = loadPreloadedChunkData(chunkBlocks, chunkX, chunkZ) -- MOVE LOWER?

	handleNewPreloadedData(chunkPreloadedData)

	if not loadedChunks[chunkX] then
		loadedChunks[chunkX] = {}
	end
	loadedChunks[chunkX][chunkZ] = {}

	loadedChunks[chunkX][chunkZ] = chunkBlocks
	ReplicatedStorage.Remotes.Chunks.GetChunkDifferences:FireServer(chunkX, chunkZ)
end


-- Erases given chunk from loadedChunks
function GenerationManager.unloadChunk(chunkX: number, chunkZ: number): ()
	loadedChunks[chunkX][chunkZ] = nil

	if isTblEmpty(loadedChunks[chunkX]) then
		loadedChunks[chunkX] = nil
	end

	if chunkDifferences[chunkX] and chunkDifferences[chunkX][chunkZ] then
		chunkDifferences[chunkX][chunkZ] = nil
	end
end


-- Breaking a block chunk loading logic
function GenerationManager.handleMinedBlock(blockName: string, worldPosition: Vector3)

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
	loadedChunks[chunkX][chunkZ][x][z][y] = AIR_ID

	-- Update neighbouring blocks
	for _, neighbouringBlockData in getNeighbouringBlocks(worldPosition) do

		local neighbouringBlockID = neighbouringBlockData[1]
		local neighbouringBlockWorldPosition = neighbouringBlockData[2]

		if 
		neighbouringBlockID == AIR_ID 
			or ItemsData[neighbouringBlockID]['Type'] == 'Plant' 
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

			neighbouringBlock = renderBlock(neighbouringBlockID, chunkFolder, neighbouringBlockWorldPosition)
			renderedChunks[chunkX][chunkZ][x][z][y] = neighbouringBlock

		else -- Neighbour block IS rendered -> update textures

			local faceVector = (worldPosition - neighbouringBlockWorldPosition) / 3
			local sideName = RELATIVE_POSITION_TO_FACE[faceVector]

			local neighbouringBlockName = ItemsIDs[neighbouringBlockID]

			local sideDecal = ReplicatedStorage.Items.FaceDecals:FindFirstChild(neighbouringBlockName):FindFirstChild(sideName):Clone()
			sideDecal.Parent = neighbouringBlock
		end
	end

	ReplicatedStorage.Remotes.UpdateChunk:FireServer({{AIR_ID, worldPosition}})
end


function GenerationManager.handleBlockPlaced(blockName: string, worldPosition: Vector3)

	local chunkPosition = ChunksUtil.worldToChunkPosition(worldPosition)

	local chunkX = chunkPosition[1]
	local chunkZ = chunkPosition[2]
	local x = chunkPosition[3]
	local z = chunkPosition[4]
	local y = chunkPosition[5]
end


-- Updates fog's range
function GenerationManager.updateFog()

	Lighting.FogEnd = CHUNK_DISTANCE * CHUNK_SIZE * BLOCK_SIZE
	Lighting.FogStart = CHUNK_DISTANCE * CHUNK_SIZE * BLOCK_SIZE - (BLOCK_SIZE * CHUNK_SIZE)
end


-- EVENTS

ReplicatedStorage.Remotes.Chunks.UpdateChunk.OnClientEvent:Connect(registerDifferences) -- When different player mines block
ReplicatedStorage.Remotes.Chunks.GetChunkDifferences.OnClientEvent:Connect(registerDifferences) -- When chunk is loaded

Player.CharacterAdded:Connect(teleportCharacterToSpawn)
Player.CharacterAdded:Connect(registerPlayerPosition)

GenerationManager.updateFog()

-- Initalize
if Player.Character then
	coroutine.wrap(teleportCharacterToSpawn)(Player.Character)
end

return GenerationManager