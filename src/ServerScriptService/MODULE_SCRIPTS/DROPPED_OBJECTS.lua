local DROPPED_OBJECTS = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Modules = ReplicatedStorage.MODULE_SCRIPTS
local ChunksUtil = require(Modules.CHUNKS_UTIL)

local dropped_objects_data = {}

-- PRIVATE

--// Fills in missing tables in dropped_objects_data
function create_dropped_objects_tables(chunk_x: number, chunk_z: number, x: number, z: number, y: number): ()

	if not dropped_objects_data[chunk_x] then
		dropped_objects_data[chunk_x] = {}
	end

	if not dropped_objects_data[chunk_x][chunk_z] then
		dropped_objects_data[chunk_x][chunk_z] = {}
	end

	if not dropped_objects_data[chunk_x][chunk_z][x] then
		dropped_objects_data[chunk_x][chunk_z][x] = {}
	end

	if not dropped_objects_data[chunk_x][chunk_z][x][z] then
		dropped_objects_data[chunk_x][chunk_z][x][z] = {}
	end
	
	if not dropped_objects_data[chunk_x][chunk_z][x][z][y] then
		dropped_objects_data[chunk_x][chunk_z][x][z][y] = {}
	end
end


function handle_dropped_objects(objectName: string, worldPosition: Vector3): ()
	
	local chunk_position = ChunksUtil.world_to_chunk_position(worldPosition)

	local chunk_x = chunk_position[1]
	local chunk_z = chunk_position[2]
	local x = chunk_position[3]
	local z = chunk_position[4]
	local y = chunk_position[5]
	
	create_dropped_objects_tables(chunk_x, chunk_z, x, z, y)
	
	-- check if block is there
	-- if there is then += 1
	-- else add and set to 1
	--dropped_objects_data[chunk_x][chunk_z]
end




--// Fires client with dropped objects 
function handle_get_dropped_objects(player: Player, chunk_x: number, chunk_z: number)
	
	if dropped_objects_data[chunk_x] and dropped_objects_data[chunk_x][chunk_z] then
		
		local dropped_objects_data = dropped_objects_data[chunk_x][chunk_z]
		
		ReplicatedStorage.REMOTES.GetDroppedObjects:FireClient(player, chunk_x, chunk_z, dropped_objects_data)
	end
end




--// Updates data, adding mined block
function handle_mined_block(player: Player, object_name: string, world_position: Vector3)
	
	local chunk_position = ChunksUtil.world_to_chunk_position(world_position)

	local chunk_x = chunk_position[1]
	local chunk_z = chunk_position[2]
	local x = chunk_position[3]
	local z = chunk_position[4]
	local y = chunk_position[5]

	create_dropped_objects_tables(chunk_x, chunk_z, x, z, y)
	
	if dropped_objects_data[chunk_x][chunk_z][x][z][y][object_name] then
		
		dropped_objects_data[chunk_x][chunk_z][x][z][y][object_name] += 1
	else
		dropped_objects_data[chunk_x][chunk_z][x][z][y][object_name] = 1
	end
end

	


--// Moves blocks in to_move to destination
function handle_update_dropped_objects(player: Player, to_move: {}, destination: {})
	
	local destination_chunk_x = destination[1]
	local destination_chunk_z = destination[2]
	local destination_x = destination[3]
	local destination_z = destination[4]
	local destination_y = destination[5]
	
	create_dropped_objects_tables(destination_chunk_x, destination_chunk_z, destination_x, destination_z, destination_y)
	
	for i, chunk_position in to_move do
		
		local chunk_x = chunk_position[1]
		local chunk_z = chunk_position[2]
		local x = chunk_position[3]
		local z = chunk_position[4]
		local y = chunk_position[5]
		
		if not dropped_objects_data[chunk_x][chunk_z][x][z][y] then 
			--table.remove(to_move, i)
			continue 
		end
		
		-- Move current data to destination
		for object_name, object_amount in dropped_objects_data[chunk_x][chunk_z][x][z][y] do
			
			if dropped_objects_data[destination_chunk_x][destination_chunk_z][destination_x][destination_z][destination_y][object_name] then
				
				dropped_objects_data[destination_chunk_x][destination_chunk_z][destination_x][destination_z][destination_y][object_name] += object_amount
			else
				dropped_objects_data[destination_chunk_x][destination_chunk_z][destination_x][destination_z][destination_y][object_name] = object_amount
			end
		end
		
		-- Remove current data
		dropped_objects_data[chunk_x][chunk_z][x][z][y] = nil
	end
	
	local objects_at_destination = dropped_objects_data[destination_chunk_x][destination_chunk_z][destination_x][destination_z][destination_y]
	local to_update = {destination_chunk_x, destination_chunk_z, destination_x, destination_z, destination_y, objects_at_destination}
	
	-- Send players data
	for _, current_player in Players:GetPlayers() do
		if current_player == player then continue end
		
		ReplicatedStorage.REMOTES.UpdateDroppedObjects:FireClient(current_player, to_move, to_update)
	end
end


-- EVENTS

ReplicatedStorage.REMOTES.GetDroppedObjects.OnServerEvent:Connect(handle_get_dropped_objects)
ReplicatedStorage.REMOTES.BlockMined.OnServerEvent:Connect(handle_mined_block)
ReplicatedStorage.REMOTES.DropObjects.OnServerEvent:Connect(handle_dropped_objects)
ReplicatedStorage.REMOTES.UpdateDroppedObjects.OnServerEvent:Connect(handle_update_dropped_objects)

return DROPPED_OBJECTS