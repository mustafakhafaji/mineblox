local SURFACE_LAYER_GENERATION = {}

--// Services
local S_RS = game:GetService('ReplicatedStorage')

--// Modules
local M_CHUNK_SETTINGS = require(S_RS.MODULE_SCRIPTS.CHUNK_SETTINGS)
local M_CHUNKS_UTIL = require(S_RS.MODULE_SCRIPTS.CHUNKS_UTIL)

--// Constants
local CHUNK_SIZE = M_CHUNK_SETTINGS['CHUNK_SIZE']
local MAX_HEIGHT = M_CHUNK_SETTINGS['MAX_HEIGHT']
local MIN_HEIGHT = M_CHUNK_SETTINGS['MIN_HEIGHT']

local BASE_SURFACE_LEVEL = 3

--[[ PRIVATE ]]--

--// Create x, z, y chunk_surface_y table
local function generate_chunk_surface_y_table()

	local chunk_surface_y = {}

	for x = 1, CHUNK_SIZE do

		chunk_surface_y[x] = {}

		for z = 1, CHUNK_SIZE do
			chunk_surface_y[x][z] = {}
		end
	end

	return chunk_surface_y
end




--[[ PUBLIC ]]--

function SURFACE_LAYER_GENERATION.generate(chunk_blocks: {}, chunk_x: number, chunk_z: number, SEED: number): ({})
	
	local chunk_surface_y = generate_chunk_surface_y_table()
	
	for x = 1, CHUNK_SIZE do
		for z = 1, CHUNK_SIZE do
			
			local dirts = 0
			local placed_dirt = false
			
			local pos_x = chunk_x * CHUNK_SIZE + x
			local pos_z = chunk_z * CHUNK_SIZE + z
			
			local max_dirt = BASE_SURFACE_LEVEL + math.round(math.noise(pos_x / 5, pos_z / 5, SEED)) 
			
			for y = MAX_HEIGHT, MIN_HEIGHT, -1 do
				
				if chunk_blocks[x][z][y] == 'Air' or chunk_blocks[x][z][y] == 'Oak Leaves' then
					dirts = 0
					placed_dirt = false
					continue
				end
				
				if placed_dirt == true then continue end
				
				dirts += 1
				
				if dirts == 1 then
					chunk_blocks[x][z][y] = 'Grass Block'
					table.insert(chunk_surface_y[x][z], y)
					
				elseif dirts > max_dirt then
					
					placed_dirt = true
					dirts = 0
				else
					chunk_blocks[x][z][y] = 'Dirt'
				end
				
			end
		end
	end
	
	return chunk_blocks, chunk_surface_y
end

return SURFACE_LAYER_GENERATION