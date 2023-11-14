local OXEYEDAISY_GENERATION = {}

--// Services
local S_RS = game:GetService('ReplicatedStorage')

--// Modules
local M_CHUNK_SETTINGS = require(S_RS.MODULE_SCRIPTS.CHUNK_SETTINGS)
local M_CHUNKS_UTIL = require(S_RS.MODULE_SCRIPTS.CHUNKS_UTIL)

--// Constants
local CHUNK_SIZE = M_CHUNK_SETTINGS['CHUNK_SIZE']
local CHANCE = 20

--// Returns chunk blocks table including oxeye daisies
function OXEYEDAISY_GENERATION.generate(chunk_blocks: {}, surface_y: {}, SEED: number, random: Random, chunk_x: number, chunk_z: number): ({})
	
	SEED += 3
	
	for x = 1, CHUNK_SIZE do
		for z = 1, CHUNK_SIZE do
			
			for _, y in surface_y[x][z] do
				
				if chunk_blocks[x][z][y + 1] ~= 'Air' then continue end

				local x_pos = chunk_x * CHUNK_SIZE + x
				local z_pos = chunk_z * CHUNK_SIZE + z

				local current_chance = (M_CHUNKS_UTIL.fractal_noise(x_pos, z_pos, 1, 1, 1, 10, SEED)) -- Returns [0, 100]
				local current_value = random:NextInteger(-100, 1) -- Controls frequency

				if current_chance < current_value then
					chunk_blocks[x][z][y + 1] = 'Oxeye Daisy'
				end
			end
		end
	end

	return chunk_blocks
end

return OXEYEDAISY_GENERATION
