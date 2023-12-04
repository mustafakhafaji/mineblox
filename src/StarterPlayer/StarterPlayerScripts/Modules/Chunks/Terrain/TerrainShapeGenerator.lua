local TerrainShapeGenerator = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)

local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']
local MAX_HEIGHT = ChunkSettings['MAX_HEIGHT']
local MIN_HEIGHT = ChunkSettings['MIN_HEIGHT']

local OCTAVES = 1
local LACUNARITY = 3
local PERSISTENCE = .35
local SCALE = 150

local STONE_ID = ItemsData['Stone']['ID']

-- PUBLIC

-- Returns a table of blocks to go in a chunk
function TerrainShapeGenerator.generate(chunkBlocks: {}, chunkX: number, chunkZ: number, SEED: number): ({}, {})
	
	-- Generate base terrain height
	for x = 1, CHUNK_SIZE do
		
		local worldPositionX = chunkX * CHUNK_SIZE + x
		
		for z = 1, CHUNK_SIZE do
			
			local worldPositionZ = chunkZ * CHUNK_SIZE + z
			
			local baseHeight = math.floor(
				ChunksUtil.fractalNoise(
					worldPositionX,
					worldPositionZ,
					OCTAVES, 
					LACUNARITY, 
					PERSISTENCE, 
					SCALE, 
					SEED
				) * MAX_HEIGHT / 2
			)
			
			for y = MAX_HEIGHT, MIN_HEIGHT, -1 do
				
				local density = math.noise(worldPositionX / 20, worldPositionZ / 20, y / 20)
				
				local squishFactor = 30 -- Make it dynamic
				local densityModifier = (baseHeight - y) / squishFactor
				
				density += densityModifier

				if density > 0 then
					chunkBlocks[x][z][y] = STONE_ID
				end
			end
		end
	end
	
	return chunkBlocks
end


return TerrainShapeGenerator