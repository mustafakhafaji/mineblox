--!native
local ChunkLoading = {}

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local Player: Player = Players.LocalPlayer
local Character: Model = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart: Part = Character:WaitForChild('HumanoidRootPart') :: Part
local PlayerScripts = Player.PlayerScripts

local Modules = PlayerScripts:WaitForChild('Modules')
local Events = PlayerScripts:WaitForChild('Events')

local ChunkRenderer = require(Modules.Chunks.Rendering.ChunkRenderer)
local ChunksData = require(Modules.Chunks.Data.ChunksData)
local ChunkGenerationStages = require(Modules.Chunks.Data.ChunkGenerationStages)
local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)

local ParallelScripts = PlayerScripts:WaitForChild('ParallelScripts')

local BiomeLoaderParallel: LocalScript = ParallelScripts.BiomeLoaderParallel
local TerrainLoaderParallel: LocalScript = ParallelScripts.TerrainLoaderParallel

local ClientSettings = PlayerScripts:WaitForChild('ClientSettings')

local BLOCK_SIZE: number = ChunkSettings['BLOCK_SIZE']
local CHUNK_SIZE: number = ChunkSettings['CHUNK_SIZE']
local CHUNK_DISTANCE: number = ChunkSettings['CHUNK_DISTANCE']
local MAX_CHUNK_DISTANCE: number = ChunkSettings['MAX_CHUNK_DISTANCE']
local MAX_CHUNK_LOADING_ACTORS: number = ChunkSettings['MAX_CHUNK_LOADING_ACTORS']

local LOAD_OFFSET: number = 2

local CHUNKS_TO_RENDER_PER_UPDATE: number = 2
local CHUNKS_TO_LOAD_TERRAIN_PER_UPDATE: number = 7

local FRAMES_BETWEEN_RENDERS: number = 1
local FRAMES_BETWEEN_LOADS: number = 4

local AIR_ID: number = ItemsData['Air']['ID']
local SEED: number = 500

local framesSinceLastRender: number = 0
local framesSinceLastLoad: number = 0

local chunkLoadingActors: number = ClientSettings:GetAttribute('ChunkLoadingActors')
local chunkLoadingActorsHalf: number = chunkLoadingActors // 2 -- Amount of biome and terrain actors seperately

local terrainActors = table.create(chunkLoadingActorsHalf)
local biomeActors = table.create(chunkLoadingActorsHalf)

local ActorsFolder = Instance.new('Folder')
ActorsFolder.Name = 'Actors'
ActorsFolder.Parent = ParallelScripts

-- Create actors for loadChunk()
for i = 1, MAX_CHUNK_LOADING_ACTORS // 2 do
	local terrainActor = Instance.new('Actor')
	terrainActor.Name = 'TerrainActor' .. i
	local terrainScript = TerrainLoaderParallel:Clone()
	terrainScript.Parent = terrainActor
	terrainActor.Parent = ActorsFolder

	local biomeActor = Instance.new('Actor')
	biomeActor.Name = 'BiomeActor' .. i
	local biomeScript = BiomeLoaderParallel:Clone()
	biomeScript.Parent = biomeActor
	biomeActor.Parent = ActorsFolder

	table.insert(terrainActors, terrainActor)
	table.insert(biomeActors, biomeActor)
end

-- PRIVATE

local function onChunkLoadingActorsChanged(): ()
	local newValue = ClientSettings:GetAttribute('ChunkLoadingActors')
	ClientSettings:SetAttribute('ChunkLoadingActors', math.clamp(newValue, 2, MAX_CHUNK_LOADING_ACTORS))
	newValue = ClientSettings:GetAttribute('ChunkLoadingActors')

	chunkLoadingActors = newValue
	chunkLoadingActorsHalf = newValue // 2
end

local function renderChunks(toRender: {}): ()
	local chunksRendered: number = 0
	for _, chunk in toRender do
		local chunkX = chunk[1]
		local chunkZ = chunk[2]
		local chunkY = chunk[3]
		
		ChunksData[chunkX][chunkZ][chunkY]['isRendered'] = true
		ChunkRenderer.renderChunk(chunkX, chunkZ, chunkY)

		chunksRendered += 1
		if chunksRendered > CHUNKS_TO_RENDER_PER_UPDATE then
			return
		end
	end
end


local function unrenderChunks(toUnrender: {}): ()
	local chunksUnrendered: number = 0
	for i = #toUnrender, 1, -1 do
		local chunk = toUnrender[i]
		local chunkX = chunk[1]
		local chunkZ = chunk[2]
		local chunkY = chunk[3]

		ChunkRenderer.unrenderChunk(chunkX, chunkZ, chunkY)
		ChunksData[chunkX][chunkZ][chunkY]['isRendered'] = false

		chunksUnrendered += 1
		if chunksUnrendered > CHUNKS_TO_RENDER_PER_UPDATE then
			return
		end
	end
end


-- Calls loadChunk() on every chunk to load
local function loadChunks(toLoad: {}): ()
	local chunksTerrainLoaded: number = 0
	
	local chunksToLoadTerrain = {}
	local chunksToLoadBiome = {}
	
	for _, chunk in toLoad do
		local chunkX: number = chunk[1]
		local chunkZ: number = chunk[2]
		local chunkY: number = chunk[3]
		
		if ChunksData[chunkX][chunkZ][chunkY]['stage'] == ChunkGenerationStages['none'] then
			if chunksTerrainLoaded > CHUNKS_TO_LOAD_TERRAIN_PER_UPDATE then
				continue
			end
			ChunksData[chunkX][chunkZ][chunkY]['isLoading'] = true
			
			table.insert(chunksToLoadTerrain, chunk)
			
			chunksTerrainLoaded += 1
			
		elseif ChunksData[chunkX][chunkZ][chunkY]['stage'] == ChunkGenerationStages['terrain'] then
			if -- Neighbours' terrain must be loaded
				not ChunksData[chunkX][chunkZ][chunkY - 1]
				or ChunksData[chunkX][chunkZ][chunkY - 1]['stage'] == ChunkGenerationStages['none']
			then
				continue
			end
			ChunksData[chunkX][chunkZ][chunkY]['isLoading'] = true
			
			table.insert(chunksToLoadBiome, chunk)
		end
	end
	
	task.defer(function()
		for _, chunk in chunksToLoadTerrain do
			local chunkX: number = chunk[1]
			local chunkZ: number = chunk[2]
			local chunkY: number = chunk[3]
			
			terrainActors[math.random(1, chunkLoadingActorsHalf)]:SendMessage('beginLoading', chunkX, chunkZ, chunkY, SEED)
		end
		
		for _, chunk in chunksToLoadBiome do
			local chunkX: number = chunk[1]
			local chunkZ: number = chunk[2]
			local chunkY: number = chunk[3]
			
			local chunkBlocks: buffer = ChunksData[chunkX][chunkZ][chunkY]['buffer']
			local neighbouringChunks = {
				[chunkX .. 'x' .. chunkZ .. 'x' .. chunkY - 1] = ChunksData[chunkX][chunkZ][chunkY - 1]['buffer']
			}
			
			biomeActors[math.random(1, chunkLoadingActorsHalf)]:SendMessage('beginLoading', chunkX, chunkZ, chunkY, chunkBlocks, neighbouringChunks, SEED)
		end
	end)
end

-- Returns chunks to render
local function findChunksToRender(): {}
	local characterPosition: Vector3 = HumanoidRootPart.Position
	local characterPositionChunkX: number = characterPosition.X // (CHUNK_SIZE * BLOCK_SIZE)
	local characterPositionChunkZ: number = characterPosition.Z // (CHUNK_SIZE * BLOCK_SIZE)
	local characterPositionChunkY: number = characterPosition.Y // (CHUNK_SIZE * BLOCK_SIZE)
	
	local toRender = {}
	for chunkX = characterPositionChunkX - CHUNK_DISTANCE, characterPositionChunkX + CHUNK_DISTANCE do
		local chunkXDistance = (chunkX - characterPositionChunkX) ^ 2
		for chunkZ = characterPositionChunkZ - CHUNK_DISTANCE, characterPositionChunkZ + CHUNK_DISTANCE do
			local chunkZDistance = (chunkZ - characterPositionChunkZ) ^ 2
			for chunkY = characterPositionChunkY - CHUNK_DISTANCE, characterPositionChunkY + CHUNK_DISTANCE do
				-- All neighbours must be fully loaded
				local distance = chunkXDistance + chunkZDistance + (chunkY - characterPositionChunkY) ^ 2
				if 
					distance > CHUNK_DISTANCE * CHUNK_DISTANCE
					or not ChunksData[chunkX]
					or not ChunksData[chunkX][chunkZ]
					or not ChunksData[chunkX][chunkZ][chunkY]
					or ChunksData[chunkX][chunkZ][chunkY]['isRendered'] == true
					or ChunksData[chunkX][chunkZ][chunkY]['stage'] ~= ChunkGenerationStages['done']
					or not ChunksData[chunkX + 1]
					or not ChunksData[chunkX + 1][chunkZ]
					or not ChunksData[chunkX + 1][chunkZ][chunkY]
					or ChunksData[chunkX + 1][chunkZ][chunkY]['stage'] ~= ChunkGenerationStages['done']
					or not ChunksData[chunkX - 1]
					or not ChunksData[chunkX - 1][chunkZ]
					or not ChunksData[chunkX - 1][chunkZ][chunkY]
					or ChunksData[chunkX - 1][chunkZ][chunkY]['stage'] ~= ChunkGenerationStages['done']
					or not ChunksData[chunkX][chunkZ + 1]
					or not ChunksData[chunkX][chunkZ + 1][chunkY]
					or ChunksData[chunkX][chunkZ + 1][chunkY]['stage'] ~= ChunkGenerationStages['done']
					or not ChunksData[chunkX][chunkZ - 1]
					or not ChunksData[chunkX][chunkZ - 1][chunkY]
					or ChunksData[chunkX][chunkZ - 1][chunkY]['stage'] ~= ChunkGenerationStages['done']
					or not ChunksData[chunkX][chunkZ][chunkY + 1]
					or ChunksData[chunkX][chunkZ][chunkY + 1]['stage'] ~= ChunkGenerationStages['done']
					or not ChunksData[chunkX][chunkZ][chunkY - 1]
					or ChunksData[chunkX][chunkZ][chunkY - 1]['stage'] ~= ChunkGenerationStages['done']
				then
					continue
				end
				local isAllAir: boolean = true
				local chunkBlocks: buffer = ChunksData[chunkX][chunkZ][chunkY]['buffer']
				for i = 1, CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE do
					if buffer.readu8(chunkBlocks, i) ~= AIR_ID then
						isAllAir = false
						break
					end
				end
				if isAllAir then
					continue
				end
				
				table.insert(toRender, {chunkX, chunkZ, chunkY})
			end
		end
	end
	return toRender
end


-- Returns chunks to unrender
local function findChunksToUnrender(): {} --TODO not good has issues
	local characterPosition: Vector3 = HumanoidRootPart.Position
	local characterPositionChunkX: number = characterPosition.X // (CHUNK_SIZE * BLOCK_SIZE)
	local characterPositionChunkZ: number = characterPosition.Z // (CHUNK_SIZE * BLOCK_SIZE)
	local characterPositionChunkY: number = characterPosition.Y // (CHUNK_SIZE * BLOCK_SIZE)

	local safeChunks = {}
	
	local radius = CHUNK_DISTANCE + 1
	
	for chunkX = characterPositionChunkX - radius, characterPositionChunkX + radius do
		safeChunks[chunkX] = {}
		local chunkXDistance = (chunkX - characterPositionChunkX) ^ 2

		for chunkZ = characterPositionChunkZ - radius, characterPositionChunkZ + radius do
			safeChunks[chunkX][chunkZ] = {}
			local chunkZDistance = (chunkZ - characterPositionChunkZ) ^ 2

			for chunkY = characterPositionChunkY - radius, characterPositionChunkY + radius do
				local distance = chunkXDistance + chunkZDistance + (chunkY - characterPositionChunkY) ^ 2
				if distance <= radius * radius then
					safeChunks[chunkX][chunkZ][chunkY] = true
				end
			end
		end
	end
	
	local toUnrender = {}
	-- Find what loaded chunks aren't in shouldBeRendered
	for chunkX in ChunksData do
		for chunkZ in ChunksData[chunkX] do
			for chunkY in ChunksData[chunkX][chunkZ] do
				if not ChunksData[chunkX][chunkZ][chunkY]['isRendered'] then
					continue
				end
				if 
					not safeChunks[chunkX]
					or not safeChunks[chunkX][chunkZ]
					or not safeChunks[chunkX][chunkZ][chunkY]
				then
					table.insert(toUnrender, {chunkX, chunkZ, chunkY})
				end
			end
		end
	end
	return toUnrender
end


-- Returns the closest chunks to the character
local function findChunksToLoad(): {}
	local characterPosition: Vector3 = HumanoidRootPart.Position
	local characterPositionChunkX: number = characterPosition.X // (CHUNK_SIZE * BLOCK_SIZE)
	local characterPositionChunkZ: number = characterPosition.Z // (CHUNK_SIZE * BLOCK_SIZE)
	local characterPositionChunkY: number = characterPosition.Y // (CHUNK_SIZE * BLOCK_SIZE)

	local toLoad = {}
	local radius = CHUNK_DISTANCE + LOAD_OFFSET

	for chunkX = characterPositionChunkX - radius, characterPositionChunkX + radius do
		local chunkXDistance = (chunkX - characterPositionChunkX) ^ 2
		for chunkZ = characterPositionChunkZ - radius, characterPositionChunkZ + radius do
			local chunkZDistance = (chunkZ - characterPositionChunkZ) ^ 2
			for chunkY = characterPositionChunkY - radius, characterPositionChunkY + radius do
				
				local distance = chunkXDistance + chunkZDistance + (chunkY - characterPositionChunkY) ^ 2
				if
					ChunksData[chunkX] 
					and ChunksData[chunkX][chunkZ] 
					and ChunksData[chunkX][chunkZ][chunkY]
				then
					local chunkData = ChunksData[chunkX][chunkZ][chunkY]
					if 
						chunkData['stage'] == ChunkGenerationStages['done']
						or chunkData['isLoading']
						or (chunkData['stage'] == ChunkGenerationStages['terrain']
						and distance > (radius - 1) * (radius - 1))
					then
						continue
					end
				end
					
				if
					math.abs(chunkX) > MAX_CHUNK_DISTANCE
					or math.abs(chunkY) > MAX_CHUNK_DISTANCE
					or math.abs(chunkZ) > MAX_CHUNK_DISTANCE
					or distance > radius * radius
				then
					continue 
				end
				
				table.insert(toLoad, {chunkX, chunkZ, chunkY})
				if
					not ChunksData[chunkX] 
					or not ChunksData[chunkX][chunkZ] 
					or not ChunksData[chunkX][chunkZ][chunkY]
				then
					ChunksUtil.fillChunksTable(ChunksData, chunkX, chunkZ, chunkY)
					ChunksData[chunkX][chunkZ][chunkY]['stage'] = ChunkGenerationStages['none']
				end
			end
		end
	end
	return toLoad
end


-- Returns chunks not within character's range
local function unloadChunks(chunksToLoad: {}): ()
	local characterPosition: Vector3 = HumanoidRootPart.Position
	local characterPositionChunkX: number = characterPosition.X // (CHUNK_SIZE * BLOCK_SIZE)
	local characterPositionChunkZ: number = characterPosition.Z // (CHUNK_SIZE * BLOCK_SIZE)
	local characterPositionChunkY: number = characterPosition.Y // (CHUNK_SIZE * BLOCK_SIZE)

	local shouldBeLoaded = {}
	
	-- Find what chunks should be loaded
	local radius = CHUNK_DISTANCE + LOAD_OFFSET + 1

	for chunkX = characterPositionChunkX - radius, characterPositionChunkX + radius do
		shouldBeLoaded[chunkX] = {}
		local chunkXDistance = (chunkX - characterPositionChunkX) ^ 2
		
		for chunkZ = characterPositionChunkZ - radius, characterPositionChunkZ + radius do
			shouldBeLoaded[chunkX][chunkZ] = {}
			local chunkZDistance = (chunkZ - characterPositionChunkZ) ^ 2
			
			for chunkY = characterPositionChunkY - radius, characterPositionChunkY + radius do
				local distance = chunkXDistance + chunkZDistance + (chunkY - characterPositionChunkY) ^ 2
				if distance <= radius * radius then
					shouldBeLoaded[chunkX][chunkZ][chunkY] = true
				end
			end
		end
	end
	
	-- Find what loaded chunks aren't in shouldBeLoaded
	for chunkX in ChunksData do
		for chunkZ in ChunksData[chunkX] do
			for chunkY in ChunksData[chunkX][chunkZ] do
				if 
					not shouldBeLoaded[chunkX]
					or not shouldBeLoaded[chunkX][chunkZ]
					or not shouldBeLoaded[chunkX][chunkZ][chunkY]
				then
					ChunksData[chunkX][chunkZ][chunkY] = nil
				end
			end
		end
	end
end


-- Reorders table of chunks based on distance from player
local function reorderChunkPriority(chunks: {}): {}
	local characterPosition: Vector3 = HumanoidRootPart.Position
	local characterPositionChunkX: number = characterPosition.X // (CHUNK_SIZE * BLOCK_SIZE)
	local characterPositionChunkZ: number = characterPosition.Z // (CHUNK_SIZE * BLOCK_SIZE)
	local characterPositionChunkY: number = characterPosition.Y // (CHUNK_SIZE * BLOCK_SIZE)
	
	table.sort(chunks, function(a, b)
		local aDistance = (a[1] - characterPositionChunkX) ^ 2 + (a[2] - characterPositionChunkZ) ^ 2 + (a[3] - characterPositionChunkY) ^ 2
		local bDistance = (b[1] - characterPositionChunkX) ^ 2 + (b[2] - characterPositionChunkZ) ^ 2 + (b[3] - characterPositionChunkY) ^ 2
		return aDistance < bDistance
	end)
	return chunks
end


local function handleFrame(): ()
	framesSinceLastLoad += 1
	framesSinceLastRender += 1
	if not HumanoidRootPart then
		return
	end
	
	if framesSinceLastLoad >= FRAMES_BETWEEN_LOADS then
		local chunksToLoad = findChunksToLoad()
		reorderChunkPriority(chunksToLoad)
		--print(chunksToLoad)
		--[[local chunk = chunksToLoad[1]
		local x = chunk[1]
		local z = chunk[2]
		local y = chunk[3]
		
		print(x, z, y, ChunksData[x][z][y])]]
		loadChunks(chunksToLoad)
		
		unloadChunks()
		framesSinceLastLoad = 0
		return
	end
	
	if framesSinceLastRender >= FRAMES_BETWEEN_RENDERS then
		local chunksToRender = findChunksToRender()
		reorderChunkPriority(chunksToRender)
		renderChunks(chunksToRender)
		
		local ChunksToUnrender = findChunksToUnrender()
		reorderChunkPriority(ChunksToUnrender)
		unrenderChunks(ChunksToUnrender)
		framesSinceLastRender = 0
	end
end

local function handleChunkLoadedTerrain(chunkX: number, chunkZ: number, chunkY: number, chunkBlocks: buffer)
	ChunksData[chunkX][chunkZ][chunkY]['buffer'] = chunkBlocks
	ChunksData[chunkX][chunkZ][chunkY]['stage'] = ChunkGenerationStages['terrain']
	ChunksData[chunkX][chunkZ][chunkY]['isLoading'] = false
end

local function handleChunkLoadedBiome(chunkX: number, chunkZ: number, chunkY: number, chunkBlocks: buffer, neighbouringChunks: {})
	ChunksData[chunkX][chunkZ][chunkY]['buffer'] = chunkBlocks
	ChunksData[chunkX][chunkZ][chunkY]['stage'] = ChunkGenerationStages['done']
	ChunksData[chunkX][chunkZ][chunkY]['isLoading'] = false
	
	for neighbouringChunkString, neighbouringChunkNewBuffer  in neighbouringChunks do
		local neighbouringChunkPosition = string.split(neighbouringChunkString, 'x')
		local neighbouringChunkX = tonumber(neighbouringChunkPosition[1])
		local neighbouringChunkZ = tonumber(neighbouringChunkPosition[2])
		local neighbouringChunkY = tonumber(neighbouringChunkPosition[3])
		
		local neighbouringChunkOldBuffer = ChunksData[neighbouringChunkX][neighbouringChunkZ][neighbouringChunkY]['buffer']
		
		for x = 1, CHUNK_SIZE do
			local bufferPositionX: number = (x - 1) * CHUNK_SIZE
			for z = 1, CHUNK_SIZE do
				local bufferPositionZ: number = (z - 1) * CHUNK_SIZE * CHUNK_SIZE
				for y = 1, CHUNK_SIZE do
					local oldBlockId: number = buffer.readu8(neighbouringChunkOldBuffer, bufferPositionX + bufferPositionZ + (y - 1))
					local newBlockId: number = buffer.readu8(neighbouringChunkNewBuffer, bufferPositionX + bufferPositionZ + (y - 1))
					if oldBlockId == newBlockId then
						continue
					end
					buffer.writeu8(neighbouringChunkOldBuffer, bufferPositionX + bufferPositionZ + (y - 1), newBlockId)
				end
			end
		end
	end
end

-- EVENTS

RunService.Heartbeat:Connect(handleFrame)

Events.ChunkLoadedTerrain.Event:Connect(handleChunkLoadedTerrain)
Events.ChunkLoadedBiome.Event:Connect(handleChunkLoadedBiome)

ClientSettings:GetAttributeChangedSignal('ChunkLoadingActors'):Connect(onChunkLoadingActorsChanged)

return ChunkLoading