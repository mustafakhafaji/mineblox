local DECORATIVE_GENERATION = {}

--// Services
local S_RS = game:GetService('ReplicatedStorage')

--// Modules
local M_TREE_GENERATION = require(script.TREE_GENERATION)
local M_DANDELION_GENERATION = require(script.DANDELION_GENERATION)
local M_GRASS_GENERATION = require(script.GRASS_GENERATION)
local M_POPPY_GENERATION = require(script.POPPY_GENERATION)
local M_OXEYEDAISY_GENERATION = require(script.OXEYEDAISY_GENERATION)

local M_CHUNK_SETTINGS = require(S_RS.MODULE_SCRIPTS.CHUNK_SETTINGS)

--// Constants
local CHUNK_SIZE = M_CHUNK_SETTINGS['CHUNK_SIZE']

--[[ PUBLIC ]]--

function DECORATIVE_GENERATION.generate(chunk_blocks: {}, surface_y: {}, SEED: number, chunk_x: number, chunk_z: number): ({})
	
	local preloaded_blocks = {}
	
	local chunk_key = .5 * (chunk_x + chunk_z) * (chunk_x + chunk_z + 1) + chunk_z
	local random = Random.new(SEED + chunk_key)
	
	chunk_blocks, preloaded_blocks = M_TREE_GENERATION.generate(chunk_blocks, preloaded_blocks, surface_y, random, chunk_x, chunk_z)
	chunk_blocks = M_GRASS_GENERATION.generate(chunk_blocks, surface_y, SEED, random, chunk_x, chunk_z)
	chunk_blocks = M_DANDELION_GENERATION.generate(chunk_blocks, surface_y, SEED, random, chunk_x, chunk_z)
	chunk_blocks = M_POPPY_GENERATION.generate(chunk_blocks, surface_y, SEED, random, chunk_x, chunk_z)
	chunk_blocks = M_OXEYEDAISY_GENERATION.generate(chunk_blocks, surface_y, SEED, random, chunk_x, chunk_z)
	
	return chunk_blocks, preloaded_blocks
end

return DECORATIVE_GENERATION