local ChunksUtil = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)

local CHUNK_SIZE: number = ChunkSettings['CHUNK_SIZE']
local BLOCK_SIZE: number = ChunkSettings['BLOCK_SIZE']

-- PUBLIC

-- Converts [chunk_x][chunk_z][x][z][y] position to a Vector3(x, y, z)
function ChunksUtil.chunkToWorldPosition(chunkX: number, chunkZ: number, chunkY: number, x: number, z: number, y: number): Vector3
	local worldX = (chunkX * CHUNK_SIZE + x) * BLOCK_SIZE
	local worldZ = (chunkZ * CHUNK_SIZE + z) * BLOCK_SIZE
	local worldY = (chunkY * CHUNK_SIZE + y) * BLOCK_SIZE
	return Vector3.new(worldX, worldY, worldZ)
end


-- Returns the buffer position of blockId from relative chunk position
function ChunksUtil.chunkToBufferPosition(x: number, z: number, y: number): number
	return (x - 1) * CHUNK_SIZE + (z - 1) * CHUNK_SIZE * CHUNK_SIZE + (y - 1) 
end


-- Converts Vector3(x, y, z) position to a [chunk_x][chunk_z][x][z][y] 
function ChunksUtil.worldToChunkPosition(coordinate : Vector3): {number}
	local chunkX =  ((coordinate.X - BLOCK_SIZE) / BLOCK_SIZE) // CHUNK_SIZE
	local chunkZ = ((coordinate.Z - BLOCK_SIZE) / BLOCK_SIZE) // CHUNK_SIZE
	local chunkY = ((coordinate.Y - BLOCK_SIZE) / BLOCK_SIZE) // CHUNK_SIZE
	local x = coordinate.X / BLOCK_SIZE - (chunkX * CHUNK_SIZE)
	local z = coordinate.Z / BLOCK_SIZE - (chunkZ * CHUNK_SIZE)
	local y = coordinate.Y / BLOCK_SIZE - (chunkY * CHUNK_SIZE)
	return {chunkX, chunkZ, chunkY, x, z, y}
end


-- Returns (-1, 1)
function ChunksUtil.simpleNoise(x: number, y: number, seed: number): number
	return math.noise(x / 20, y / 20, seed)
end

--[[
	Octaves = 2,
	Lacunarity = 5, -- > 1
	Persistence = .2, -- > 0, < 1
	Scale = 40,
]]
function ChunksUtil.continentalnessNoise(x: number, y: number, seed: number): number
	local value = 0 
	local amplitude = 1
	local x1 = x 
	local y1 = y

	for i = 1, 2, 1 do
		value += math.noise(x1 / 160, y1 / 160, seed) * amplitude

		y1 *= 5
		x1 *= 5

		amplitude *= .2
	end
	return value
end


--[[
	Octaves = 2,
	Lacunarity = 4, -- > 1
	Persistence = .2, -- > 0, < 1
	Scale = 50,
]]
function ChunksUtil.erosionNoise(x: number, y: number, seed: number): number
	local value = 0 
	local amplitude = 1
	local x1 = x 
	local y1 = y

	for i = 1, 2, 1 do
		value += math.noise(x1 / 200, y1 / 200, seed) * amplitude

		y1 *= 4
		x1 *= 4

		amplitude *= .2
	end
	return value
end


function ChunksUtil.peaksAndValleysNoise(x: number, y: number, seed: number): number
	local value = 0 
	local amplitude = 1
	local x1 = x 
	local y1 = y

	for i = 1, 2, 1 do
		value += math.noise(x1 / 100, y1 / 100, seed) * amplitude

		y1 *= 4
		x1 *= 4

		amplitude *= .2
	end
	return value
end


-- Fills in table contents with chunkxz + xyz indices
function ChunksUtil.fillChunksTable(tbl: {}, ...): ()
	local data = {...}

	while #data > 0 do
		if not tbl[data[1]] then
			tbl[data[1]] = {}
		end
		tbl = tbl[data[1]]
		table.remove(data, 1)
	end
end


return ChunksUtil