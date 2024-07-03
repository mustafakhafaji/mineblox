local LightingController = {}

local Lighting = game:GetService('Lighting')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)

local CHUNK_DISTANCE: number = ChunkSettings['CHUNK_DISTANCE']
local CHUNK_SIZE: number = ChunkSettings['CHUNK_SIZE']
local BLOCK_SIZE: number = ChunkSettings['BLOCK_SIZE']

Lighting.FogEnd = CHUNK_DISTANCE * CHUNK_SIZE * BLOCK_SIZE
Lighting.FogStart = (CHUNK_DISTANCE - 1) * CHUNK_SIZE * BLOCK_SIZE

return LightingController
