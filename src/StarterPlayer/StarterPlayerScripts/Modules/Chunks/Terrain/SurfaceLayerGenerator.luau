local SurfaceLayerGeneration = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)

local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']
local MAX_HEIGHT = ChunkSettings['MAX_HEIGHT']
local MIN_HEIGHT = ChunkSettings['MIN_HEIGHT']

local BASE_SURFACE_LEVEL = 3

local AIR_ID = ItemsData['Air']['ID']
local GRASS_BLOCK_ID = ItemsData['Grass Block']['ID']
local DIRT_ID = ItemsData['Dirt']['ID']

-- PRIVATE

-- Create x, z, y chunk_surface_y table
function generateChunkSurfaceYTable()

	local chunkSurfaceY = {}

	for x = 1, CHUNK_SIZE do

		chunkSurfaceY[x] = {}

		for z = 1, CHUNK_SIZE do
			chunkSurfaceY[x][z] = {}
		end
	end

	return chunkSurfaceY
end


-- PUBLIC

function SurfaceLayerGeneration.generate(chunkBlocks: {}, chunkX: number, chunkZ: number, SEED: number): ({}, {})
	
	local chunkSurfaceY = generateChunkSurfaceYTable()
	
	for x = 1, CHUNK_SIZE do
		for z = 1, CHUNK_SIZE do
			
			local dirts = 0
			local placedDirt = false
			
			local posX = chunkX * CHUNK_SIZE + x
			local posZ = chunkZ * CHUNK_SIZE + z
			
			local maxDirt = BASE_SURFACE_LEVEL + math.round(math.noise(posX / 5, posZ / 5, SEED)) 
			
			for y = MAX_HEIGHT, MIN_HEIGHT, -1 do
				
				if 
					chunkBlocks[x][z][y] == AIR_ID
					--or chunkBlocks[x][z][y] == 'Oak Leaves' 
				then
					dirts = 0
					placedDirt = false
					continue
				end
				
				if placedDirt then
					continue 
				end
				
				dirts += 1
				
				if dirts == 1 then
					chunkBlocks[x][z][y] = GRASS_BLOCK_ID
					table.insert(chunkSurfaceY[x][z], y)
					
				elseif dirts > maxDirt then
					
					placedDirt = true
					dirts = 0
				else
					chunkBlocks[x][z][y] = DIRT_ID
				end
				
			end
		end
	end
	
	return chunkBlocks, chunkSurfaceY
end

return SurfaceLayerGeneration