local CHUNKS_UTIL = {}

--// Services
local S_RS = game:GetService('ReplicatedStorage')

--// Modules
local M_CHUNK_SETTINGS = require(S_RS.MODULE_SCRIPTS.CHUNK_SETTINGS)

--// Constants
local CHUNK_SIZE = M_CHUNK_SETTINGS['CHUNK_SIZE']
local BLOCK_SIZE = 3



--[[ PRIVATE ]]--

local function floor_divide(n,m)
	return math.floor(n/m)
end



--[[ PUBLIC ]]--

--// Converts [chunk_x][chunk_z][x][z][y] position to a Vector3(x, y, z)
function CHUNKS_UTIL.chunk_to_world_position(chunk_x: number, chunk_z: number, x_pos: number, z_pos: number, y_pos: number)

	local x = (chunk_x * CHUNK_SIZE + x_pos) * BLOCK_SIZE
	local z = (chunk_z * CHUNK_SIZE + z_pos) * BLOCK_SIZE
	local y = y_pos * BLOCK_SIZE

	return Vector3.new(x, y, z)
end


--// Converts Vector3(x, y, z) position to a [chunk_x][chunk_z][x][z][y] 
function CHUNKS_UTIL.world_to_chunk_position(coordinate : Vector3): ({string: {}})

	local chunk_x =  floor_divide((coordinate.X - BLOCK_SIZE) / BLOCK_SIZE, CHUNK_SIZE)
	local chunk_z = floor_divide((coordinate.Z - BLOCK_SIZE) / BLOCK_SIZE, CHUNK_SIZE)

	local x = coordinate.X / BLOCK_SIZE - (chunk_x * CHUNK_SIZE)
	local y = coordinate.Y / BLOCK_SIZE
	local z = coordinate.Z / BLOCK_SIZE - (chunk_z * CHUNK_SIZE)

	return {chunk_x, chunk_z, x, z, y}
end




function CHUNKS_UTIL.fractal_noise(x: number, y: number, octaves: number, lacunarity: number, persistence: number, scale: number, seed: number)

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



return CHUNKS_UTIL