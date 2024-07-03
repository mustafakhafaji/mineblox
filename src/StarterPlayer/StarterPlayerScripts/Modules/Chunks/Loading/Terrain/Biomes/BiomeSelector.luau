local BiomeSelector = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local StarterPlayer = game:GetService('StarterPlayer')

local SplineMaps = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Loading.Terrain.SplineMaps)
local BiomesData = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Loading.Terrain.Biomes.BiomesData)
local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)

local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']

-- PRIVATE

function getBiomeGenerator(worldPositionX: number, worldPositionZ: number, chunkY: number, SEED: number): ModuleScript
	local temperature: number = math.clamp(ChunksUtil.simpleNoise(worldPositionX, worldPositionZ, SEED) * 2, -2, 2)
	local humidity: number = math.clamp(ChunksUtil.simpleNoise(worldPositionX, worldPositionZ, SEED + 1) * 2, -2, 2)
	
	return BiomesData[1].biomeGenerator
	-- Get surface level biome
	--[[for _, biomeData in BiomesData do 
		if 
			temperature < biomeData.temperature.min 
			or temperature > biomeData.temperature.max 
			or humidity < biomeData.humidity.min
			or humidity > biomeData.humidity.max
		then
			continue
		end
		return biomeData.biomeGenerator
	end]]
end

-- PUBLIC

function BiomeSelector.generateBiome(chunkX: number, chunkZ: number, chunkY: number, chunkBlocks: buffer, neighbouringChunks: {}, SEED: number): ()
	for x = 1, CHUNK_SIZE do
		local worldPositionX: number = chunkX * CHUNK_SIZE + x

		for z = 1, CHUNK_SIZE do
			local worldPositionZ: number = chunkZ * CHUNK_SIZE + z

			local biomeGenerator: ModuleScript = getBiomeGenerator(worldPositionX, worldPositionZ, chunkY, SEED)
			local neighbouringChunksModifications = biomeGenerator.generate(chunkBlocks, neighbouringChunks, chunkX, chunkZ, chunkY, x, z)
		end
	end
end

return BiomeSelector