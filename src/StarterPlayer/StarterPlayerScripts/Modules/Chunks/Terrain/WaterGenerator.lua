local WATER_GENERATION = {}

--// Services
local S_RS = game:GetService('ReplicatedStorage')

--// Modules
local M_CHUNK_SETTINGS = require(S_RS.MODULE_SCRIPTS.CHUNK_SETTINGS)

--// Constants
local CHUNK_SIZE = M_CHUNK_SETTINGS['CHUNK_SIZE']
local SEA_LEVEL = M_CHUNK_SETTINGS['SEA_LEVEL']
local MIN_HEIGHT = M_CHUNK_SETTINGS['MIN_HEIGHT']
--[[ PUBLIC ]]--

--// Sets air blocks under sea level to water
function WATER_GENERATION.generate(chunk_blocks: {}): ({})
	
	for x = 1, CHUNK_SIZE do
		for z = 1, CHUNK_SIZE do
			
			for y = SEA_LEVEL, MIN_HEIGHT, -1 do
				
				if chunk_blocks[x][z][y] ~= 'Air' then
					break
				end
				
				chunk_blocks[x][z][y] = 'Water'
			end
		end
	end
	
	return chunk_blocks
end

return WATER_GENERATION