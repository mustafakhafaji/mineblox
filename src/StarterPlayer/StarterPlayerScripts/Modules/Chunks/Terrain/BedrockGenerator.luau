local BedrockGeneration = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)

local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']
local BEDROCK_ID = ItemsData['Bedrock']['ID']

-- PUBLIC

function BedrockGeneration.generate(chunkBlocks: {}, BOTTOM_HEIGHT: number, RANDOM: Random): ({}, Random)
	
	for x = 1, CHUNK_SIZE, 1 do

		for z = 1, CHUNK_SIZE, 1 do
			
			if RANDOM:NextInteger(1, 2) == 2 then
				chunkBlocks[x][z][BOTTOM_HEIGHT + 1] = BEDROCK_ID
			else
				chunkBlocks[x][z][BOTTOM_HEIGHT] = BEDROCK_ID
			end
		end
	end
	
	return chunkBlocks, RANDOM
end

return BedrockGeneration