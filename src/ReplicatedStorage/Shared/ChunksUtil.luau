local ChunksUtil = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)

local CHUNK_SIZE = ChunkSettings['CHUNK_SIZE']
local BLOCK_SIZE = ChunkSettings['BLOCK_SIZE']

-- PUBLIC

-- Converts [chunk_x][chunk_z][x][z][y] position to a Vector3(x, y, z)
function ChunksUtil.chunkToWorldPosition(chunkX: number, chunkZ: number, xPos: number, zPos: number, yPos: number): (Vector3)

	local x = (chunkX * CHUNK_SIZE + xPos) * BLOCK_SIZE
	local z = (chunkZ * CHUNK_SIZE + zPos) * BLOCK_SIZE
	local y = yPos * BLOCK_SIZE

	return Vector3.new(x, y, z)
end


-- Converts Vector3(x, y, z) position to a [chunk_x][chunk_z][x][z][y] 
function ChunksUtil.worldToChunkPosition(coordinate : Vector3): ({number})

	local chunk_x =  ((coordinate.X - BLOCK_SIZE) / BLOCK_SIZE) // CHUNK_SIZE
	local chunk_z = ((coordinate.Z - BLOCK_SIZE) / BLOCK_SIZE) // CHUNK_SIZE

	local x = coordinate.X / BLOCK_SIZE - (chunk_x * CHUNK_SIZE)
	local y = coordinate.Y / BLOCK_SIZE
	local z = coordinate.Z / BLOCK_SIZE - (chunk_z * CHUNK_SIZE)

	return {chunk_x, chunk_z, x, z, y}
end


function ChunksUtil.fractalNoise(x: number, y: number, octaves: number, lacunarity: number, persistence: number, scale: number, seed: number): (number)

	-- The sum of our octaves
	local value = 0 

	-- These coordinates will be scaled the lacunarity
	local x1 = x 
	local y1 = y

	-- Determines the effect of each octave on the previous sum
	local amplitude = 1

	for i = 1, octaves, 1 do
		-- Multiply the noise output by the amplitude and add it to our sum
		value += math.noise(x1 / scale, y1 / scale, seed) * amplitude

		-- Scale up our perlin noise by multiplying the coordinates by lacunarity
		y1 *= lacunarity
		x1 *= lacunarity

		-- Reduce our amplitude by multiplying it by persistence
		amplitude *= persistence
	end

	-- It is possible to have an output value outside of the range [-1,1]
	-- For consistency let's clamp it to that range
	return math.clamp(value, -1, 1)
end


-- Returns (-1, 1)
function ChunksUtil.simpleNoise(x: number, y: number, seed: number): (number)

	local noise = math.noise(x / 10, y / 10, seed)

	return noise
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