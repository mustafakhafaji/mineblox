local GrassGeneration = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ChunkSettings = require(ReplicatedStorage.Modules.ChunkSettings)
local ChunksUtil = require(ReplicatedStorage.Modules.ChunksUtil)

local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']

-- PUBLIC

function GrassGeneration.generate(chunkBlocks: {}, surfaceY: {}, SEED: number, random: Random, chunkX: number, chunkZ: number): ({})
	
	SEED += 2
	
	for x = 1, CHUNK_SIZE do
		for z = 1, CHUNK_SIZE do
			
			for _, y in surfaceY[x][z] do
				
				if chunkBlocks[x][z][y + 1] ~= 'Air' then 
					continue 
				end

				local xPos = chunkX * CHUNK_SIZE + x
				local ZPos = chunkX * CHUNK_SIZE + z

				local currentChance = (ChunksUtil.fractal_noise(xPos, ZPos, 1, 1, 1, 10, SEED)) -- Returns [0, 100]
				local currentValue = random:NextInteger(-8, 1) -- Controls frequency

				if currentChance < currentValue then
					chunkBlocks[x][z][y + 1] = 'Grass'
				end
			end
			
			--[[local surface_y_at_xz = surface_y[x][z]
			
			if chunk_blocks[x][z][surface_y_at_xz + 1] ~= 'Air' then continue end
			if chunk_blocks[x][z][surface_y_at_xz] ~= 'Grass Block' then continue end
			
			local x_pos = chunk_x * CHUNK_SIZE + x
			local z_pos = chunk_z * CHUNK_SIZE + z

			local current_chance = (M_CHUNKS_UTIL.fractal_noise(x_pos, z_pos, 1, 1, 1, 10, SEED)) -- Returns [0, 100]
			local current_value = random:NextInteger(-8, 1) -- Controls frequency
			
			if current_chance < current_value then
				chunk_blocks[x][z][surface_y_at_xz + 1] = 'Grass'
			end]]
		end
	end
	
	return chunkBlocks
end

return GrassGeneration