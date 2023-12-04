local WaterGenerator = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)

local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']
local SEA_LEVEL = ChunkSettings['SEA_LEVEL']
local MIN_HEIGHT = ChunkSettings['MIN_HEIGHT']

local AIR_ID = ItemsData['Air']['ID']
local WATER_ID = ItemsData['Water']['ID']

-- PUBLIC

-- Sets air blocks under sea level to water
function WaterGenerator.generate(chunkBlocks: {}): ({})
	
	for x = 1, CHUNK_SIZE do
		for z = 1, CHUNK_SIZE do
			
			for y = SEA_LEVEL, MIN_HEIGHT, -1 do
				
				if chunkBlocks[x][z][y] ~= AIR_ID then
					break
				end
				
				chunkBlocks[x][z][y] = WATER_ID
			end
		end
	end
	
	return chunkBlocks
end

return WaterGenerator