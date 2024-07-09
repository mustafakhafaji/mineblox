local ForestGenerator = {}

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Player: Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts

local Modules = PlayerScripts:WaitForChild('Modules')

local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)
local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)
local GrassLayerGenerator = require(Modules.Chunks.Loading.Terrain.Biomes.Forest.GrassLayerGenerator)
--local TreesGenerator = require(Modules.Chunks.Loading.Terrain.Biomes.Forest.Decorations.Trees.TreesGenerator)

local CHUNK_SIZE: number = ChunkSettings['CHUNK_SIZE']

local AIR_ID: number = ItemsData['Air']['ID']
local GRASS_BLOCK_ID: number = ItemsData['Grass Block']['ID']
local DIRT_ID: number = ItemsData['Dirt']['ID']

-- PUBLIC

function ForestGenerator.generate(chunkBlocks: buffer, neighbouringChunks: {}, chunkX: number, chunkZ: number, chunkY: number, x: number, z: number): {}
	GrassLayerGenerator.generate(chunkBlocks, neighbouringChunks, chunkX, chunkZ, chunkY, x, z)
	--TreesGenerator.generate(chunkBlocks, neighbouringChunks, neighbouringChunksModifications)
	return neighbouringChunks
	--[[if buffer.readu8(chunkBlocks, ChunksUtil.chunkToBufferPosition(x, z, y)) == AIR_ID then
		return
	end
	
	if y == CHUNK_SIZE then
		local aboveChunk: buffer = neighbouringChunks[chunkX .. chunkZ .. chunkY + 1]
		if buffer.readu8(aboveChunk, ChunksUtil.chunkToBufferPosition(x, z, 1)) == AIR_ID  then
			buffer.writeu8(chunkBlocks, ChunksUtil.chunkToBufferPosition(x, z, y), GRASS_BLOCK_ID)
		end
		return
	end
	
	if buffer.readu8(chunkBlocks, ChunksUtil.chunkToBufferPosition(x, z, y + 1)) == AIR_ID then
		buffer.writeu8(chunkBlocks, ChunksUtil.chunkToBufferPosition(x, z, y), GRASS_BLOCK_ID)
		
	elseif buffer.readu8(chunkBlocks, ChunksUtil.chunkToBufferPosition(x, z, y + 1)) == GRASS_BLOCK_ID then
		buffer.writeu8(chunkBlocks, ChunksUtil.chunkToBufferPosition(x, z, y), DIRT_ID)
	end]]
end

return ForestGenerator