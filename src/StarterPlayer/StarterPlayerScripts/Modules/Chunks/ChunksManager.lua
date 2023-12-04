--!strict
local ChunkLoading = {}

local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local StarterPlayer = game:GetService("StarterPlayer")

local Modules = StarterPlayer.StarterPlayerScripts.Modules
local GenerationManager = require(Modules.Chunks.Terrain.GenerationManager)
--local DroppedObjectsHandler = require(Modules.Chunks.DroppedObjects.DroppedObjectsHandler)
local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)

local Player = Players.LocalPlayer

local BLOCK_SIZE = ChunkSettings['BLOCK_SIZE']
local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']
local CHUNK_DISTANCE = ChunkSettings['CHUNK_DISTANCE']

local LOAD_OFFSET = 2

local CHUNKS_TO_RENDER_PER_UPDATE = 1

local loadedChunks = {}
local renderedChunks = {}

local frames = 0

-- PRIVATE

function renderChunks(toRender: {}): ()
	
	local currentUpdates = 0
	
	for _, chunk in toRender do

		local chunkX = chunk[1]
		local chunkZ = chunk[2]
		
		GenerationManager.renderChunk(chunkX, chunkZ)
		--DroppedObjectsHandler.renderChunk(chunkX, chunkZ)
		
		if not renderedChunks[chunkX] then
			renderedChunks[chunkX] = {}
		end
		renderedChunks[chunkX][chunkZ] = true
		
		currentUpdates += 1
		
		if currentUpdates > CHUNKS_TO_RENDER_PER_UPDATE then
			return
		end
	end
end


function unrenderChunks(toUnrender: {}): ()
	
	local currentUpdates = 0
	
	for i = #toUnrender, 1, -1 do
		
		local chunk = toUnrender[i]
		
		local chunkX = chunk[1]
		local chunkZ = chunk[2]
		
		GenerationManager.unrenderChunk(chunkX, chunkZ)
		--DroppedObjectsHandler.unrenderChunk(chunkX, chunkZ)
		
		renderedChunks[chunkX][chunkZ] = nil
		
		currentUpdates += 1
		
		if currentUpdates > CHUNKS_TO_RENDER_PER_UPDATE then
			return
		end
	end
end


-- Calls loadChunk() on every chunk to load
function loadChunks(toLoad: {}): ()
	
	for _, chunk in toLoad do

		local chunkX = chunk[1]
		local chunkZ = chunk[2]
		
		GenerationManager.loadChunk(chunkX, chunkZ)
		--DroppedObjectsHandler.loadChunk(chunkX, chunkZ)
		
		if not loadedChunks[chunkX] then
			loadedChunks[chunkX] = {}
		end
		loadedChunks[chunkX][chunkZ] = true
	end
end


-- Calls unloadChunk on every chunk in toUnload
function unloadChunks(toUnload: {}): ()
	
	for _, chunk in toUnload do
		
		local chunkX = chunk[1]
		local chunkZ = chunk[2]
		
		GenerationManager.unloadChunk(chunkX, chunkZ)
		--DroppedObjectsHandler.unloadChunk(chunkX, chunkZ)
		
		loadedChunks[chunkX][chunkZ] = nil
	end
end


-- Returns chunks to render
function findChunksToRender(): ({})
	
	local characterPosition = Player.Character.HumanoidRootPart.Position

	local chunkX = math.floor(characterPosition.X / (CHUNK_SIZE * BLOCK_SIZE))
	local chunkZ = math.floor(characterPosition.Z / (CHUNK_SIZE * BLOCK_SIZE))
	
	local toRender = {}
	
	local radius = CHUNK_DISTANCE

	for x = -radius, radius do
		for z = -radius, radius do
			
			local positionX = chunkX + x
			local positionZ = chunkZ + z

			if renderedChunks[positionX] and renderedChunks[positionX][positionZ] then continue end

			local distance = x * x + z * z

			if distance <= radius * radius then
				
				--toRender[positionX][positionZ] = true
				table.insert(toRender, {positionX, positionZ})
			end
		end
	end
	
	return toRender
end


-- Returns chunks to unrender
function findChunksToUnrender(): ({})
	
	local characterPosition = Player.Character.HumanoidRootPart.Position

	local chunkX = math.floor(characterPosition.X / (CHUNK_SIZE * BLOCK_SIZE))
	local chunkZ = math.floor(characterPosition.Z / (CHUNK_SIZE * BLOCK_SIZE))

	local shouldBeRendered = {}
	local toUnrender = {}	
	
	local radius = CHUNK_DISTANCE + 1
	
	-- Find what chunks should be loaded

	for x = -radius, radius do

		local positionX = chunkX + x
		shouldBeRendered[positionX] = {}

		for z = -radius, radius do

			local positionZ = chunkZ + z

			local distance = x * x + z * z

			if distance <= radius * radius then
				shouldBeRendered[positionX][positionZ] = true
			end
		end
	end
	
	-- Find what loaded chunks aren't in shouldBeRendered
	for x in renderedChunks do
		for z in renderedChunks[x] do
			
			if not shouldBeRendered[x] then
				table.insert(toUnrender, {x, z})
				continue
			end

			if not shouldBeRendered[x][z] then
				table.insert(toUnrender, {x, z})
				continue
			end
		end
	end
	
	return toUnrender
end


-- Returns the closest chunks to the character
function findChunksToLoad(): ({number: {chunkX: number, chunkZ: number}})
	
	local characterPosition = Player.Character.HumanoidRootPart.Position

	local chunkX = math.floor(characterPosition.X / (CHUNK_SIZE * BLOCK_SIZE))
	local chunkZ = math.floor(characterPosition.Z / (CHUNK_SIZE * BLOCK_SIZE))

	local toLoad = {}
	
	local radius = CHUNK_DISTANCE + LOAD_OFFSET
	
	for x = -radius, radius do
		for z = -radius, radius do
			
			local positionX = chunkX + x
			local positionZ = chunkZ + z
			
			if loadedChunks[positionX] and loadedChunks[positionX][positionZ] then 
				continue 
			end
			
			local distance = x * x + z * z
			
			if distance <= radius * radius then
				table.insert(toLoad, {positionX, positionZ})
			end
		end
	end
	
	return toLoad
end


-- Returns chunks not within character's range
function findChunksToUnload(): ({})
	
	local characterPosition = Player.Character.HumanoidRootPart.Position

	local chunkX = math.floor(characterPosition.X / (CHUNK_SIZE * BLOCK_SIZE))
	local chunkZ = math.floor(characterPosition.Z / (CHUNK_SIZE * BLOCK_SIZE))

	local shouldBeLoaded = {}
	local toUnload = {}
	
	-- Find what chunks should be loaded
	local radius = CHUNK_DISTANCE + LOAD_OFFSET

	for x = -radius, radius do
		
		local positionX = chunkX + x
		shouldBeLoaded[positionX] = {}

		for z = -radius, radius do

			local positionZ = chunkZ + z

			local distance = x * x + z * z

			if distance <= radius * radius then
				shouldBeLoaded[positionX][positionZ] = true
			end
		end
	end
	
	-- Find what loaded chunks aren't in shouldBeLoaded
	for x in loadedChunks do
		for z in loadedChunks[x] do
			
			if not shouldBeLoaded[x] then
				table.insert(toUnload, {x, z})
				continue
			end
			
			if not shouldBeLoaded[x][z] then
				table.insert(toUnload, {x, z})
				continue
			end
		end
	end
	
	return toUnload
end


-- Reorders table of chunks based on distance from player
function reorderChunkPriority(chunks: {}): ({})
	
	local characterPosition = Player.Character.HumanoidRootPart.Position
	
	local playerChunkX = math.floor(characterPosition.X / (CHUNK_SIZE * BLOCK_SIZE))
	local playerChunkZ = math.floor(characterPosition.Z / (CHUNK_SIZE * BLOCK_SIZE))
	
	table.sort(chunks, function(a, b)
		return 
			math.sqrt((a[1] - playerChunkX) * (a[1] - playerChunkX) + (a[2] - playerChunkZ) * (a[2] - playerChunkZ))
			< 
			math.sqrt((b[1] - playerChunkX) * (b[1] - playerChunkX) + (b[2] - playerChunkZ) * (b[2] - playerChunkZ))
	end)
	return chunks
end


function handleFrame(): ()
	
	frames += 1

	if 
		not Player.Character 
		or not Player.Character:FindFirstChild('HumanoidRootPart') 
		or frames % 4 ~= 0
	then
		return
	end
		
	local chunksToLoad = findChunksToLoad()
	loadChunks(chunksToLoad)
	
	local chunksToRender = findChunksToRender()
	chunksToRender = reorderChunkPriority(chunksToRender)
	renderChunks(chunksToRender)
	
	local chunksToUnload = findChunksToUnload()
	unloadChunks(chunksToUnload)
	
	local ChunksToUnrender = findChunksToUnrender()
	ChunksToUnrender = reorderChunkPriority(ChunksToUnrender)
	unrenderChunks(ChunksToUnrender)
	
	frames = 0
end

-- EVENTS

RunService.Heartbeat:Connect(handleFrame)

return ChunkLoading