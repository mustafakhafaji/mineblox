--!native
local actor: Actor = script:GetActor()

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local StarterPlayer = game:GetService('StarterPlayer')

local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local BiomeSelector = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Loading.Terrain.Biomes.BiomeSelector)

local BLOCK_SIZE: number = ChunkSettings['BLOCK_SIZE']
local CHUNK_SIZE: number = ChunkSettings['CHUNK_SIZE']
local CHUNK_DISTANCE: number = ChunkSettings['CHUNK_DISTANCE']

local ChunkLoadedBiome: BindableEvent = StarterPlayer.StarterPlayerScripts.Events.ChunkLoadedBiome

-- FUNCTIONS

function loadChunk(chunkX: number, chunkZ: number, chunkY: number, chunkBlocks: buffer, neighbouringChunks: {}, SEED: number): ()
	local neighbouringChunksModifications = BiomeSelector.generateBiome(chunkX, chunkZ, chunkY, chunkBlocks, neighbouringChunks, SEED)
	
	ChunkLoadedBiome:Fire(chunkX, chunkZ, chunkY, chunkBlocks, neighbouringChunks)
end


actor:BindToMessageParallel('beginLoading', loadChunk)
