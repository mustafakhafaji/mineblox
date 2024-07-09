--!native
local actor: Actor = script:GetActor()

if not actor then
	return
end

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player: Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts

local Modules = PlayerScripts:WaitForChild('Modules')
local Events = PlayerScripts:WaitForChild('Events')

local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local BiomeSelector = require(Modules.Chunks.Loading.Terrain.Biomes.BiomeSelector)

local BLOCK_SIZE: number = ChunkSettings['BLOCK_SIZE']
local CHUNK_SIZE: number = ChunkSettings['CHUNK_SIZE']
local CHUNK_DISTANCE: number = ChunkSettings['CHUNK_DISTANCE']

local ChunkLoadedBiome: BindableEvent = Events.ChunkLoadedBiome

-- FUNCTIONS

local function loadChunk(chunkX: number, chunkZ: number, chunkY: number, chunkBlocks: buffer, neighbouringChunks: {}, SEED: number): ()
	local neighbouringChunksModifications = BiomeSelector.generateBiome(chunkX, chunkZ, chunkY, chunkBlocks, neighbouringChunks, SEED)
	
	ChunkLoadedBiome:Fire(chunkX, chunkZ, chunkY, chunkBlocks, neighbouringChunks)
end


actor:BindToMessageParallel('beginLoading', loadChunk)