--!native
local actor: Actor = script:GetActor()

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local StarterPlayer = game:GetService('StarterPlayer')

local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)
local TerrainShapeGenerator = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Loading.Terrain.TerrainShapeGenerator)

local BLOCK_SIZE: number = ChunkSettings['BLOCK_SIZE']
local CHUNK_SIZE: number = ChunkSettings['CHUNK_SIZE']
local CHUNK_DISTANCE: number = ChunkSettings['CHUNK_DISTANCE']

local AIR_ID: number = ItemsData['Air']['ID']

local ChunkLoadedTerrain: BindableEvent = StarterPlayer.StarterPlayerScripts.Events.ChunkLoadedTerrain

-- FUNCTIONS

function createAirBuffer(): buffer
	local chunkBlocks = buffer.create(CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE + 2) -- Offset of 2 when checking for neighbours
	buffer.fill(chunkBlocks, 0, AIR_ID)
	return chunkBlocks
end


function loadChunk(chunkX: number, chunkZ: number, chunkY: number, SEED: number): ()
	local chunkBlocks = createAirBuffer()
	TerrainShapeGenerator.generate(chunkX, chunkZ, chunkY, chunkBlocks, SEED)
	
	ChunkLoadedTerrain:Fire(chunkX, chunkZ, chunkY, chunkBlocks)
end


actor:BindToMessageParallel('beginLoading', loadChunk)
