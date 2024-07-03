local DandelionGeneration = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)

local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']

local AIR_ID = ItemsData['Air']['ID']
local DANDELION_ID = ItemsData['Dandelion']['ID']

-- PUBLIC

-- Returns chunk blocks table including dandelions
function DandelionGeneration.generate(chunkBlocks: {}, surfaceY: {}, SEED: number, random: Random, chunkX: number, chunkZ: number): ({})
	
	SEED += 1
	
	for x = 1, CHUNK_SIZE do
		for z = 1, CHUNK_SIZE do
			
			for _, y in surfaceY[x][z] do
				
				if chunkBlocks[x][z][y + 1] ~= AIR_ID then
					continue
				 end
				
				local xPos = chunkX * CHUNK_SIZE + x
				local zPos = chunkZ * CHUNK_SIZE + z

				local currentChance = ChunksUtil.simpleNoise(xPos, zPos, SEED) -- Returns [-1, 1]
				local currentValue = random:NextInteger(-45, 1) -- Controls frequency

				if currentChance < currentValue then
					chunkBlocks[x][z][y + 1] = DANDELION_ID
				end
			end
		end
	end

	return chunkBlocks
end

return DandelionGeneration