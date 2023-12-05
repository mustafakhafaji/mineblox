local TreeGeneration = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local StarterPlayer = game:GetService("StarterPlayer")

local Modules = StarterPlayer.StarterPlayerScripts.Modules

local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)
local Tree = require(Modules.Chunks.Terrain.Decorations.Trees.Tree)

local BLOCK_SIZE = ChunkSettings['BLOCK_SIZE']
local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']

local PERCENT_CHANCE_FOR_TREE = 2

-- PRIVATE

function createEmptyPreloadedBlocks(preloadedBlocks: {}, chunkX: number, chunkZ: number): ({number: {number: {number: {number: number}}}})
	
	if not preloadedBlocks[chunkX] then
		preloadedBlocks[chunkX] = {}
	end
	if not preloadedBlocks[chunkX][chunkZ] then
		preloadedBlocks[chunkX][chunkZ] = {}
	end

	for x = 1, CHUNK_SIZE do
		preloadedBlocks[chunkX][chunkZ][x] = {}

		for z = 1, CHUNK_SIZE do
			preloadedBlocks[chunkX][chunkZ][x][z] = {}
		end
	end

	return preloadedBlocks
end

-- PUBLIC

function TreeGeneration.generate(chunkBlocks: {}, preloadedBlocks: {}, surfaceY: {}, random: Random, chunkX: number, chunkZ: number): ({}, {})
	
	for x = 1, CHUNK_SIZE do
		for z = 1, CHUNK_SIZE do
			
			for _, y in surfaceY[x][z] do
				
				local currentValue = random:NextInteger(0, 200)
				
				if currentValue < PERCENT_CHANCE_FOR_TREE then

					--local surface_y_at_xz = surface_y[x][z]
					--if chunk_blocks[x][z][surface_y_at_xz] ~= 'Grass Block' then continue end

					local treeBlocks = Tree.getRandomTree(random)

					for _, blockData in treeBlocks do

						local relativeTreeX = blockData[1]
						local relativeTreeZ = blockData[2]
						local relativeTreeY = blockData[3]
						local blockID = blockData[4]

						local blockX = relativeTreeX + x
						local blockZ = relativeTreeZ + z
						local blockY = y + relativeTreeY

						local worldPosition = Vector3.new(
							(chunkX * CHUNK_SIZE + blockX) * BLOCK_SIZE,
							blockY * BLOCK_SIZE,
							(chunkZ * CHUNK_SIZE + blockZ) * BLOCK_SIZE
						) 

						local chunkPosition = ChunksUtil.worldToChunkPosition(worldPosition)

						local leavesChunkX = chunkPosition[1]
						local leavesChunkZ = chunkPosition[2]
						local leavesX = chunkPosition[3]
						local leavesZ = chunkPosition[4]
						local leavesY = chunkPosition[5]

						if -- Block is NOT out of bounds
							leavesChunkX == chunkX
							and leavesChunkZ == chunkZ
						then
							chunkBlocks[blockX][blockZ][blockY] = blockID

							--[[ To stop replacing terrain (dirt, stone, etc) with leaves or logs
							if 
								chunk_blocks[block_x][block_z][block_y] ~= 'Air' or plant
							then continue end]]
							continue
						end

						-- Block IS out of bounds
						
						-- If chunk not in preloaded -> add chunk to preloaded
						if 
							not preloadedBlocks[leavesChunkX] 
							or not preloadedBlocks[leavesChunkX][leavesChunkZ]
						then
							preloadedBlocks = createEmptyPreloadedBlocks(preloadedBlocks, leavesChunkX, leavesChunkZ)
						end

						preloadedBlocks[leavesChunkX][leavesChunkZ][leavesX][leavesZ][leavesY] = blockID
					end
				end
			end
		end
	end
	
	return chunkBlocks, preloadedBlocks
end

return TreeGeneration