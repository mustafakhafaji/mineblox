local PoppyGeneration = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)

local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']

local AIR_ID = ItemsData['Air']['ID']
local POPPY_ID = ItemsData['Poppy']['ID']

-- PUBLIC

-- Returns chunk blocks table including poppies
function PoppyGeneration.generate(chunkBlocks: {}, surfaceY: {}, SEED: number, random: Random, chunkX: number, chunkZ: number): ({})
	
	SEED += 4

	for x = 1, CHUNK_SIZE do
		for z = 1, CHUNK_SIZE do
			
			for _, y in surfaceY[x][z] do
				
				if chunkBlocks[x][z][y + 1] ~= AIR_ID then
					continue 
				end

				local xPos = chunkX * CHUNK_SIZE + x
				local zPos = chunkZ * CHUNK_SIZE + z

				local currentChance = ChunksUtil.simpleNoise(xPos, zPos, SEED) -- Returns [-1, 1]
				local currentValue = random:NextInteger(-55, 1) -- Controls frequency

				if currentChance < currentValue then
					chunkBlocks[x][z][y + 1] = POPPY_ID
				end
			end
		end
	end

	return chunkBlocks
end

return PoppyGeneration