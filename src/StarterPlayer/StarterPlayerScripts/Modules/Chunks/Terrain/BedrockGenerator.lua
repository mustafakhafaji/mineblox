local BedrockGeneration = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ChunkSettings = require(ReplicatedStorage.Modules.ChunkSettings)

local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']

-- PUBLIC

function BedrockGeneration.generate(chunkBlocks: {}, BOTTOM_HEIGHT: number, RANDOM: Random): ({}, Random)
	
	for x = 1, CHUNK_SIZE, 1 do

		for z = 1, CHUNK_SIZE, 1 do
			
			if RANDOM:NextInteger(1, 2) == 2 then
				chunkBlocks[x][z][BOTTOM_HEIGHT + 1] = 'Bedrock'
			else
				chunkBlocks[x][z][BOTTOM_HEIGHT] = 'Bedrock'
			end
		end
	end
	
	return chunkBlocks, RANDOM
end

return BedrockGeneration