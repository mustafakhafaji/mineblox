local BEDROCK_GENERATION = {}

--[[ PUBLIC ]]--

function BEDROCK_GENERATION.generate(chunk_blocks: {}, CHUNK_SIZE: number, BOTTOM_HEIGHT: number, RANDOM: Random): ({})
	
	for x = 1, CHUNK_SIZE, 1 do

		for z = 1, CHUNK_SIZE, 1 do
			
			if RANDOM:NextInteger(1, 2) == 2 then
				chunk_blocks[x][z][BOTTOM_HEIGHT + 1] = 'Bedrock'
			else
				chunk_blocks[x][z][BOTTOM_HEIGHT] = 'Bedrock'
			end
		end
	end
	
	return chunk_blocks, RANDOM
end

return BEDROCK_GENERATION