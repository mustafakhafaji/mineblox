local DecorativeGeneration = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local M_TREE_GENERATION = require(script.TREE_GENERATION)
local M_DANDELION_GENERATION = require(script.DANDELION_GENERATION)
local M_GRASS_GENERATION = require(script.GRASS_GENERATION)
local M_POPPY_GENERATION = require(script.POPPY_GENERATION)
local M_OXEYEDAISY_GENERATION = require(script.OXEYEDAISY_GENERATION)
local ChunkSettings = require(ReplicatedStorage.Modules.ChunkSettings)

local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']

-- PUBLIC

function DecorativeGeneration.generate(chunkBlocks: {}, surfaceY: {}, SEED: number, chunkX: number, chunkZ: number): ({}, {})
	
	local preloadedBlocks = {}
	
	local chunkKey = .5 * (chunkX + chunkZ) * (chunkX + chunkZ + 1) + chunkZ
	local random = Random.new(SEED + chunkKey)
	
	chunkBlocks, preloadedBlocks = M_TREE_GENERATION.generate(chunkBlocks, preloadedBlocks, surfaceY, random, chunkX, chunkZ)
	chunkBlocks = M_GRASS_GENERATION.generate(chunkBlocks, surfaceY, SEED, random, chunkX, chunkZ)
	chunkBlocks = M_DANDELION_GENERATION.generate(chunkBlocks, surfaceY, SEED, random, chunkX, chunkZ)
	chunkBlocks = M_POPPY_GENERATION.generate(chunkBlocks, surfaceY, SEED, random, chunkX, chunkZ)
	chunkBlocks = M_OXEYEDAISY_GENERATION.generate(chunkBlocks, surfaceY, SEED, random, chunkX, chunkZ)
	
	return chunkBlocks, preloadedBlocks
end

return DecorativeGeneration