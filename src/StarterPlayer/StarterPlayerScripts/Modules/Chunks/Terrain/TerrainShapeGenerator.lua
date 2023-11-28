local TERRAIN_GENERATION = {}

--// Services
local S_RS = game:GetService('ReplicatedStorage')

--// Modules
local M_CHUNK_SETTINGS = require(S_RS.MODULE_SCRIPTS.CHUNK_SETTINGS)
local M_CHUNKS_UTIL = require(S_RS.MODULE_SCRIPTS.CHUNKS_UTIL)

--// Constants
local CHUNK_SIZE = M_CHUNK_SETTINGS['CHUNK_SIZE']
local MAX_HEIGHT = M_CHUNK_SETTINGS['MAX_HEIGHT']
local MIN_HEIGHT = M_CHUNK_SETTINGS['MIN_HEIGHT']

local FREQUENCY = 10
local SCALE = 200
local AMPLITUDE = 32

--[[ PUBLIC ]]--

--// Returns a table of blocks to go in a chunk
function TERRAIN_GENERATION.generate(chunk_blocks: {}, chunk_x: number, chunk_z: number, SEED: number): ({}, {})
	
	-- Generate base terrain height
	for x = 1, CHUNK_SIZE do
		
		local world_position_x = chunk_x * CHUNK_SIZE + x
		
		for z = 1, CHUNK_SIZE do
			
			local world_position_z = chunk_z * CHUNK_SIZE + z
			
			local base_height = math.floor(M_CHUNKS_UTIL.fractal_noise(world_position_x, world_position_z, 1, 3, .35, 150, SEED) * MAX_HEIGHT / 2)
			
			for y = MAX_HEIGHT, MIN_HEIGHT, -1 do
				
				local density = math.noise(world_position_x / 20, world_position_z / 20, y / 20)
				
				local squish_factor = 30 -- Make it dynamic
				local density_modifier = (base_height - y) / squish_factor
				
				density += density_modifier

				if density > 0 then
					chunk_blocks[x][z][y] = 'Stone'
				end
			end
		end
	end
	
	return chunk_blocks
end




return TERRAIN_GENERATION