--!native
local TerrainShapeGenerator = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Player: Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts

local Modules = PlayerScripts:WaitForChild('Modules')

local SplineMaps = require(Modules.Chunks.Loading.Terrain.SplineMaps)
local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)

local CHUNK_SIZE: number = ChunkSettings['CHUNK_SIZE']

local STONE_ID: number = ItemsData['Stone']['ID']

local squishFactor: number = 20

-- PUBLIC

function TerrainShapeGenerator.generate(chunkX: number, chunkZ: number, chunkY: number, chunkBlocks: buffer, SEED: number): (buffer)
	local baseHeights = {}
	for x = 1, CHUNK_SIZE do
		local worldPositionX: number = chunkX * CHUNK_SIZE + x
		local bufferPositionX: number = (x - 1) * CHUNK_SIZE
		baseHeights[x] = {}

		for z = 1, CHUNK_SIZE do
			local worldPositionZ: number = chunkZ * CHUNK_SIZE + z
			local bufferPositionZ: number = (z - 1) * CHUNK_SIZE * CHUNK_SIZE
			
			-- maybe use the more complex noise function with diff parameters for each noise
			local continentalnessPerlin: number = ChunksUtil.continentalnessNoise(worldPositionX, worldPositionZ, SEED - 1)
			local erosionPerlin: number = ChunksUtil.erosionNoise(worldPositionX, worldPositionZ, SEED)
			local peaksAndValleysPerlin: number = ChunksUtil.peaksAndValleysNoise(worldPositionX, worldPositionZ, SEED + 1)

			local continentalnessHeightOffset: number = SplineMaps.getContinentalnessTerrainHeightOffset(continentalnessPerlin)
			local erosionHeightOffset: number = SplineMaps.getErosionTerrainHeightOffset(erosionPerlin)
			local peaksAndValleysHeightOffset: number = SplineMaps.getPeaksAndValleysTerrainHeightOffset(peaksAndValleysPerlin)
			
			--local continentalnessSquashFactor = SplineMaps.getContinentalnessSquashFactor(continentalnessPerlin)
			--local erosionSquashFactor = SplineMaps.getErosionSquashFactor(erosionPerlin)
			--local peaksAndValleysSquashFactor = SplineMaps.getPeaksAndValleysSquashFactor(peaksAndValleysPerlin)
			
			local baseHeight: number = continentalnessHeightOffset - erosionHeightOffset + peaksAndValleysHeightOffset
			baseHeights[x][z] = baseHeight
			
			for y = CHUNK_SIZE, 1, -1 do
				local worldPositionY: number = chunkY * CHUNK_SIZE + y

				local density = math.noise(worldPositionX / 20, worldPositionZ / 20, worldPositionY / 20)
				local densityModifier: number = (baseHeight - worldPositionY) / squishFactor

				if density + densityModifier > 0 then
					buffer.writeu8(chunkBlocks, bufferPositionX + bufferPositionZ + (y - 1), STONE_ID)
				end
			end
		end
	end
	return chunkBlocks
end

return TerrainShapeGenerator