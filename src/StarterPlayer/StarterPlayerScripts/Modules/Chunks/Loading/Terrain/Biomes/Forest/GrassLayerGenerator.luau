local GrassLayerGenerator = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)
local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)

local CHUNK_SIZE: number = ChunkSettings['CHUNK_SIZE']

local AIR_ID: number = ItemsData['Air']['ID']
local GRASS_BLOCK_ID: number = ItemsData['Grass Block']['ID']
local DIRT_ID: number = ItemsData['Dirt']['ID']
local STONE_ID: number = ItemsData['Stone']['ID']

local MAX_DIRT: number = 3

-- PUBLIC

function GrassLayerGenerator.generate(chunkBlocks: buffer, neighbouringChunks: {}, chunkX: number, chunkZ: number, chunkY: number, x: number, z: number): ()
	-- Skip air and dirt blocks.
	local didPlaceGrassBlock: boolean = false
	local dirtsPlaced: number = 0
	
	for y = 1, CHUNK_SIZE - 1 do
		if buffer.readu8(chunkBlocks, ChunksUtil.chunkToBufferPosition(x, z, y)) ~= STONE_ID then
			didPlaceGrassBlock = false
			dirtsPlaced = 0
			continue
		end
		
		if didPlaceGrassBlock then
			dirtsPlaced += 1
			buffer.writeu8(chunkBlocks, ChunksUtil.chunkToBufferPosition(x, z, y), DIRT_ID)
		else
			if buffer.readu8(chunkBlocks, ChunksUtil.chunkToBufferPosition(x, z, y + 1)) == AIR_ID then
				didPlaceGrassBlock = true
				buffer.writeu8(chunkBlocks, ChunksUtil.chunkToBufferPosition(x, z, y), GRASS_BLOCK_ID)
			end
		end
		
		if dirtsPlaced >= MAX_DIRT then
			didPlaceGrassBlock = false
			dirtsPlaced = 0
		end
	end
	
	--local chunkBelowBlocks: buffer = neighbouringChunks[chunkX .. 'x' .. chunkZ .. 'x' .. chunkY - 1]
	--buffer.writeu8(chunkBelowBlocks, ChunksUtil.chunkToBufferPosition(x, z, 5), DIRT_ID)
	
	-- If bottom blockId == Air -> add grass + dirt sequence in below chunk
	if buffer.readu8(chunkBlocks, ChunksUtil.chunkToBufferPosition(x, z, 1)) == AIR_ID then
		local chunkBelowBlocks: buffer = neighbouringChunks[chunkX .. 'x' .. chunkZ .. 'x' .. chunkY - 1]
		if buffer.readu8(chunkBelowBlocks, ChunksUtil.chunkToBufferPosition(x, z, CHUNK_SIZE), AIR_ID) then
			return
		end
		buffer.writeu8(chunkBelowBlocks, ChunksUtil.chunkToBufferPosition(x, z, CHUNK_SIZE), GRASS_BLOCK_ID)
		
		for y = 1, MAX_DIRT do
			buffer.writeu8(chunkBelowBlocks, ChunksUtil.chunkToBufferPosition(x, z, CHUNK_SIZE - y), DIRT_ID)
		end
	end
end

return GrassLayerGenerator