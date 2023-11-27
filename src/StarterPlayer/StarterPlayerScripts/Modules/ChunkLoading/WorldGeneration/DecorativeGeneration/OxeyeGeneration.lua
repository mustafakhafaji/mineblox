local OxeyeGeneration = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ChunkSettings = require(ReplicatedStorage.Modules.ChunkSettings)
local ChunksUtil = require(ReplicatedStorage.Modules.ChunksUtil)

local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']

-- PUBLIC

-- Returns chunk blocks table including oxeye daisies
function OxeyeGeneration.generate(chunkBlocks: {}, surfaceY: {}, SEED: number, random: Random, chunkX: number, chunkZ: number): ({})
	
	SEED += 3
	
	for x = 1, CHUNK_SIZE do
		for z = 1, CHUNK_SIZE do
			
			for _, y in surfaceY[x][z] do
				
				if chunkBlocks[x][z][y + 1] ~= 'Air' then 
					continue 
				end

				local xPos = chunkX * CHUNK_SIZE + x
				local zPos = chunkZ * CHUNK_SIZE + z

				local currentChance = (ChunksUtil.fractalNoise(xPos, zPos, 1, 1, 1, 10, SEED)) -- Returns [0, 100]
				local currentValue = random:NextInteger(-100, 1) -- Controls frequency

				if currentChance < currentValue then
					chunkBlocks[x][z][y + 1] = 'Oxeye Daisy'
				end
			end
		end
	end

	return chunkBlocks
end

return OxeyeGeneration