local PoppyGeneration = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ChunkSettings = require(ReplicatedStorage.Modules.ChunkSettings)
local ChunksUtil = require(ReplicatedStorage.Modules.ChunksUtil)

local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']

-- PUBLIC

-- Returns chunk blocks table including poppies
function PoppyGeneration.generate(chunkBlocks: {}, surfaceY: {}, SEED: number, random: Random, chunkX: number, chunkZ: number): ({})
	
	SEED += 4

	for x = 1, CHUNK_SIZE do
		for z = 1, CHUNK_SIZE do
			
			for _, y in surfaceY[x][z] do
				
				if chunkBlocks[x][z][y + 1] ~= 'Air' then continue end

				local x_pos = chunkX * CHUNK_SIZE + x
				local z_pos = chunkZ * CHUNK_SIZE + z

				local current_chance = (ChunksUtil.fractal_noise(x_pos, z_pos, 1, 1, 1, 10, SEED)) -- Returns [0, 100]
				local current_value = random:NextInteger(-50, 1) -- Controls frequency

				if current_chance < current_value then
					chunkBlocks[x][z][y + 1] = 'Poppy'
				end
			end

			--[[local surface_y_at_xz = surface_y[x][z]

			if chunk_blocks[x][z][surface_y_at_xz + 1] ~= 'Air' then continue end
			if chunk_blocks[x][z][surface_y_at_xz] ~= 'Grass Block' then continue end

			local x_pos = chunk_x * CHUNK_SIZE + x
			local z_pos = chunk_z * CHUNK_SIZE + z
			
			local current_chance = (M_CHUNKS_UTIL.fractal_noise(x_pos, z_pos, 1, 1, 1, 10, SEED)) -- Returns [0, 100]
			local current_value = random:NextInteger(-50, 1) -- Controls frequency

			if current_chance < current_value then
				chunk_blocks[x][z][surface_y_at_xz + 1] = 'Poppy'
			end]]
		end
	end

	return chunkBlocks
end

return PoppyGeneration