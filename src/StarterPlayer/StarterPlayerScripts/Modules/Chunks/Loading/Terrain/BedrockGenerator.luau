--!native
local BedrockGeneration = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)

local CHUNK_SIZE: number = ChunkSettings['CHUNK_SIZE']
local MAX_CHUNK_DISTANCE: number = ChunkSettings['MAX_CHUNK_DISTANCE']

local BEDROCK_ID: number = ItemsData['Bedrock']['ID']

-- PUBLIC

function BedrockGeneration.generate(chunkBlocks: {}, chunkY: number, random: Random): ({}, Random)
	if chunkY ~= -MAX_CHUNK_DISTANCE then
		return
	end
	for x = 1, CHUNK_SIZE do
		for z = 1, CHUNK_SIZE do
			if random:NextInteger(1, 2) == 2 then
				chunkBlocks[x][z][CHUNK_SIZE - 1] = BEDROCK_ID
			else
				chunkBlocks[x][z][CHUNK_SIZE] = BEDROCK_ID
			end
		end
	end
	return chunkBlocks, random
end

return BedrockGeneration