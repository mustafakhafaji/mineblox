local TREE_GENERATION = {}

--// Services
local S_RS = game:GetService('ReplicatedStorage')

--// Modules
local M_CHUNK_SETTINGS = require(S_RS.MODULE_SCRIPTS.CHUNK_SETTINGS)
local M_CHUNKS_UTIL = require(S_RS.MODULE_SCRIPTS.CHUNKS_UTIL)
local M_TREE = require(script.TREE)

--// Constants
local BLOCK_SIZE = M_CHUNK_SETTINGS['BLOCK_SIZE']
local CHUNK_SIZE = M_CHUNK_SETTINGS['CHUNK_SIZE']

local PERCENT_CHANCE_FOR_TREE = 2

--[[ PRIVATE ]]--

function create_empty_preloaded_blocks(preloaded_blocks: {}, chunk_x: number, chunk_z: number)
	
	if not preloaded_blocks[chunk_x] then
		preloaded_blocks[chunk_x] = {}
	end
	if not preloaded_blocks[chunk_x][chunk_z] then
		preloaded_blocks[chunk_x][chunk_z] = {}
	end

	for x = 1, CHUNK_SIZE do
		preloaded_blocks[chunk_x][chunk_z][x] = {}

		for z = 1, CHUNK_SIZE do
			preloaded_blocks[chunk_x][chunk_z][x][z] = {}
		end
	end

	return preloaded_blocks
end

--[[ PUBLIC ]]--

function TREE_GENERATION.generate(chunk_blocks: {}, preloaded_blocks: {}, surface_y: {}, random: Random, chunk_x: number, chunk_z: number): ({})
	
	for x = 1, CHUNK_SIZE do
		for z = 1, CHUNK_SIZE do
			
			for _, y in surface_y[x][z] do
				
				local current_value = random:NextInteger(0, 200)
				
				if current_value < PERCENT_CHANCE_FOR_TREE then

					--local surface_y_at_xz = surface_y[x][z]
					--if chunk_blocks[x][z][surface_y_at_xz] ~= 'Grass Block' then continue end

					local tree_blocks = M_TREE.get_random_tree(random)

					for _, block_data in tree_blocks do

						local relative_tree_x = block_data[1]
						local relative_tree_z = block_data[2]
						local relative_tree_y = block_data[3]
						local block_name = block_data[4]

						local block_x = relative_tree_x + x
						local block_z = relative_tree_z + z
						local block_y = y + relative_tree_y

						local world_position = Vector3.new(
							(chunk_x * CHUNK_SIZE + block_x) * BLOCK_SIZE,
							block_y * BLOCK_SIZE,
							(chunk_z * CHUNK_SIZE + block_z) * BLOCK_SIZE
						) 

						local chunk_position = M_CHUNKS_UTIL.world_to_chunk_position(world_position)

						local leaves_chunk_x = chunk_position[1]
						local leaves_chunk_z = chunk_position[2]
						local leaves_x = chunk_position[3]
						local leaves_z = chunk_position[4]
						local leaves_y = chunk_position[5]

						if leaves_chunk_x ~= chunk_x or leaves_chunk_z ~= chunk_z then -- Block IS out of bounds

							-- If chunk not in preloaded -> add chunk to preloaded
							if not preloaded_blocks[leaves_chunk_x] or not preloaded_blocks[leaves_chunk_x][leaves_chunk_z] then
								preloaded_blocks = create_empty_preloaded_blocks(preloaded_blocks, leaves_chunk_x, leaves_chunk_z)
							end

							preloaded_blocks[leaves_chunk_x][leaves_chunk_z][leaves_x][leaves_z][leaves_y] = block_name

						else -- Block is NOT out of bounds

						--[[ To stop replacing terrain (dirt, stone, etc) with leaves or logs
						if 
							chunk_blocks[block_x][block_z][block_y] ~= 'Air' or plant
						then continue end]]

							chunk_blocks[block_x][block_z][block_y] = block_name
						end
					end
				end
			end
		end
	end
	
	return chunk_blocks, preloaded_blocks
end

return TREE_GENERATION