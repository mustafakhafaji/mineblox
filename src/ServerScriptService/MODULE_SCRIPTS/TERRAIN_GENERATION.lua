local TERRAIN_GENERATION = {}

--// Services
local S_RS = game:GetService('ReplicatedStorage')
local S_PLAYERS = game:GetService('Players')

--// Modules
local M_CHUNK_SETTINGS = require(S_RS.MODULE_SCRIPTS.CHUNK_SETTINGS)
local M_CHUNKS_UTIL = require(S_RS.MODULE_SCRIPTS.CHUNKS_UTIL)

--// Constants
local BLOCK_SIZE = 3
local CHUNK_SIZE = M_CHUNK_SETTINGS['CHUNK_SIZE']
local SEED = 500--math.random(1, 99999999) -- 5000

--// Variables
local chunk_differences = {}


--[[ PRIVATE ]]---

local function floor_divide(n,m)
	return math.floor(n/m)
end




--// Creates table if empty
local function create_chunk_difference_tables(chunk_x: string, chunk_z: string, x: string, z: string, y: string)
	
	if not chunk_differences[chunk_x] then
		chunk_differences[chunk_x] = {}
	end

	if not chunk_differences[chunk_x][chunk_z] then
		chunk_differences[chunk_x][chunk_z] = {}
	end
	
	if not chunk_differences[chunk_x][chunk_z][x] then
		chunk_differences[chunk_x][chunk_z][x] = {}
	end
	
	if not chunk_differences[chunk_x][chunk_z][x][z] then
		chunk_differences[chunk_x][chunk_z][x][z] = {}
	end
end




--// Store differences in chunk difference table
local function register_chunk_update(client_differences: {}): ()

	for _, difference_data in client_differences do
		
		local block_name = difference_data[1]
		local world_position = difference_data[2]
		
		local chunk_position = M_CHUNKS_UTIL.world_to_chunk_position(world_position)
		
		local chunk_x = tostring(chunk_position[1]) 
		local chunk_z = tostring(chunk_position[2])
		local x = tostring(chunk_position[3]) 
		local z = tostring(chunk_position[4]) 
		local y = tostring(chunk_position[5]) 
		
		create_chunk_difference_tables(chunk_x, chunk_z, x, z, y, block_name)
		chunk_differences[chunk_x][chunk_z][x][z][y] = block_name
	end
end





--// Fire all clients (excluding 1) with remote event and data
local function fire_clients_excluding(player_to_ignore: Player, event: RemoteEvent, ...)

	for _, current_player in S_PLAYERS:GetPlayers() do
		if current_player == player_to_ignore then continue end

		event:FireClient(current_player, ...)
	end
end





--[[ REMOTES ]]--

--// Returns server's seed
S_RS.REMOTES.GetSeed.OnServerInvoke = function()
	return SEED
end




S_RS.REMOTES.GetChunkDifferences.OnServerEvent:Connect(function(player: Player, chunk_x: number, chunk_z: number)
	
	local chunk_x = tostring(chunk_x)
	local chunk_z = tostring(chunk_z)
	
	if chunk_differences[chunk_x] and chunk_differences[chunk_x][chunk_z] then
		
		local differences = {}
		
		for x, x_values in chunk_differences[chunk_x][chunk_z] do
			for z, z_values in x_values do
				for y, block_name in z_values do
					
					table.insert(differences, {block_name, M_CHUNKS_UTIL.chunk_to_world_position(chunk_x, chunk_z, x, z, y)})
				end
			end
		end
		
		S_RS.REMOTES.GetChunkDifferences:FireClient(player, differences)
	end
end)




--// Update blocks, when a block is destroyed
S_RS.REMOTES.UpdateChunk.OnServerEvent:Connect(function(player: Player, client_differences: {})
	
	-- Register differences
	register_chunk_update(client_differences)
	fire_clients_excluding(player, S_RS.REMOTES.UpdateChunk, client_differences)
end)






return TERRAIN_GENERATION