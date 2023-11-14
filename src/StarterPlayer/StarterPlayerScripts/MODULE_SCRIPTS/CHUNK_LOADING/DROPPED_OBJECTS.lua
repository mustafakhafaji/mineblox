local DROPPED = {}

--// Services
local S_REPLICATED = game:GetService('ReplicatedStorage')
local S_TS = game:GetService('TweenService')
local S_RUN = game:GetService('RunService')
local S_UIS = game:GetService('UserInputService')
local S_RS = game:GetService('ReplicatedStorage')
local S_PLAYERS = game:GetService('Players')
local S_SP = game:GetService('StarterPlayer')

--// Modules
local MODULES = S_SP.StarterPlayerScripts.MODULE_SCRIPTS
local M_CHUNKS_UTIL = require(S_RS.MODULE_SCRIPTS.CHUNKS_UTIL)
local M_CHUNK_SETTINGS = require(S_RS.MODULE_SCRIPTS.CHUNK_SETTINGS)
local M_MODEL = require(MODULES.MODEL)
local M_LOADED_CHUNKS = require(MODULES.LOADED_CHUNKS)

--// Constants
local PLAYER = S_PLAYERS.LocalPlayer

local MAX_HEIGHT = M_CHUNK_SETTINGS['MAX_HEIGHT']
local MIN_HEIGHT = M_CHUNK_SETTINGS['MIN_HEIGHT']

local CHUNKS_TO_RENDER_PER_UPDATE = 1

local OBJECT_STACK_SIZE = 64
local LEFT_OVER_SIZE = 1

local DROPPED_OBJECT_SIZE = .75

local NEIGHBOUR_ORDER = 
	{
		Vector3.new(0, 3, 0),
		Vector3.new(0, -3, 0),
		Vector3.new(3, 0, 0),
		Vector3.new(-3, 0, 0),
		Vector3.new(0, 0, 3),
		Vector3.new(0, 0, -3)
	}

--// Variables
local loaded_dropped_objects = {}
local rendered_dropped_objects = {}

--[[



when near [x][z][y], picks up, returns # inventory can pick up, subtract # to that

how to deal with if inventory can pick up a certain part (animation wise) ? 

if single  then	
delete rendered, animate

all animations create new object to pick up

if multiple
create new object, animate


sequence of mining block
block mined -> add to loaded blocks with name
if there -> increase quantity by 1 -> check if object needs to be created
-> if not there -> create block -> block bounces -> added to module -> 

sequence of dropping block
q pressed -> object created -> animate towards position -> added to module

server updates chunk
handled differently


]]


--[[ PRIVATE ]]--

--// Returns true if table is empty
function is_tbl_empty(tbl: {}): (boolean)

	for _ in tbl do
		return true
	end
	return false
end




function create_tbl_tables(tbl: {}, chunk_x: number, chunk_z: number, x: number, z: number, y: number): ()

	if not tbl[chunk_x][chunk_z][x] then
		tbl[chunk_x][chunk_z][x] = {}
	end

	if not tbl[chunk_x][chunk_z][x][z] then
		tbl[chunk_x][chunk_z][x][z] = {}
	end

	if not tbl[chunk_x][chunk_z][x][z][y] then
		tbl[chunk_x][chunk_z][x][z][y] = {}
	end
end




--// Handles up, down and rotational animations
function handle_animations(): ()

end




function scale_object(object: BasePart): ()

	if object:IsA('Model') then
		
		local largest_size = object.PrimaryPart.Size.Y -- find largest side?
		
		local scale_factor = DROPPED_OBJECT_SIZE / largest_size

		object:ScaleTo(scale_factor)
	else
		object.Size = Vector3.new(DROPPED_OBJECT_SIZE, DROPPED_OBJECT_SIZE, DROPPED_OBJECT_SIZE)
	end
end



function generate_stack(object_name: string, chunk_folder: Folder, world_position: Vector3): (Model)

	local object_1 = S_RS.ITEMS:FindFirstChild(object_name):Clone()
	local object_2 = object_1:Clone()
	object_1.CanCollide = false
	object_2.CanCollide = false

	local grouped_dropped_objects = workspace.GROUPED_DROPPED_OBJECTS:Clone()
	grouped_dropped_objects.Name = object_name

	scale_object(object_1)
	scale_object(object_2)

	object_1.CFrame = grouped_dropped_objects.HITBOX.Point1.CFrame
	object_2.CFrame = grouped_dropped_objects.HITBOX.Point2.CFrame

	object_1.Parent = grouped_dropped_objects
	object_2.Parent = grouped_dropped_objects
	grouped_dropped_objects:PivotTo(CFrame.new(world_position + Vector3.new(math.random(-100, 100) / 100, 0, math.random(-100, 100) / 100)))
	grouped_dropped_objects.Parent = chunk_folder

	return grouped_dropped_objects
end




--// Generates a single object 
function generate_object(object_name: string, chunk_folder: Folder, world_position: Vector3): (BasePart)

	local object = S_RS.ITEMS:FindFirstChild(object_name):Clone()
	object.Position = world_position
	object.CanCollide = false
	object.Position = world_position + Vector3.new(math.random(-100, 100) / 100, 0, math.random(-100, 100) / 100)

	scale_object(object)

	object.Parent = chunk_folder

	return object
end






--// Register server's chunk dropped objects
function register_chunk_dropped_objects(chunk_x: number, chunk_z: number, dropped_objects: {}): ()

	for x, objects_xs in dropped_objects do

		x = tonumber(x)
		loaded_dropped_objects[chunk_x][chunk_z][x] = {}

		for z, objects_zs in objects_xs do

			z = tonumber(z)
			loaded_dropped_objects[chunk_x][chunk_z][x][z] = {}

			for y, objects in objects_zs do

				y = tonumber(y)
				loaded_dropped_objects[chunk_x][chunk_z][x][z][y] = {}

				for object_name, object_amount in objects do
					loaded_dropped_objects[chunk_x][chunk_z][x][z][y][object_name] = object_amount
				end
			end
		end
	end
end





function drop_equipped_object(): ()

	-- check what object is equipped
	-- unequip
	-- add to drop
end





function handle_input(input, typing): ()
	if not typing then return end

	if input.KeyCode == Enum.KeyCode.Q then
		drop_equipped_object()
	end
end



--[[function get_number_of_needed_objects(chunk_x: number, chunk_z: number, x: number, z: number, y: number, object_name: string)
	
	if not 
end]]





function update_stacks_at_position(chunk_x: number, chunk_z: number, x: number, z: number, y: number): ()

	for object_name, object_amount in loaded_dropped_objects[chunk_x][chunk_z][x][z][y] do

		if not rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object_name] then
			rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object_name] = {}
			rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object_name]['stacks'] = {}
			rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object_name]['left_over'] = {}
		end
		
		local rendered_objects = rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object_name]

		local needed_number_of_stacks = math.ceil((object_amount - LEFT_OVER_SIZE) / OBJECT_STACK_SIZE)
		local needed_left_over = if object_amount % OBJECT_STACK_SIZE <= LEFT_OVER_SIZE then object_amount % OBJECT_STACK_SIZE else 0

		local current_number_of_stacks = #rendered_objects['stacks']
		local current_left_over = #rendered_objects['left_over']

		local chunk_folder = workspace.DROPPED:FindFirstChild(`{chunk_x}x{chunk_z}`)

		-- Add stack to rendered objects
		if needed_number_of_stacks > current_number_of_stacks then

			local stack = generate_stack(object_name, chunk_folder, M_CHUNKS_UTIL.chunk_to_world_position(chunk_x, chunk_z, x, z, y))
			table.insert(rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object_name]['stacks'], stack)

			-- Remove stacks from rendered objects
		elseif needed_number_of_stacks < current_number_of_stacks then

			local stacks_to_remove = current_number_of_stacks - needed_number_of_stacks

			for i = 1, stacks_to_remove do
				rendered_objects['stacks'][i]:Destroy()
				rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object_name]['stacks'][i] = nil
			end
		end

		-- Add left over to rendered object
		if needed_left_over > current_left_over then

			local left_over = generate_object(object_name, chunk_folder, M_CHUNKS_UTIL.chunk_to_world_position(chunk_x, chunk_z, x, z, y))
			table.insert(rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object_name]['left_over'], left_over)

			-- Remove left over from rendered object
		elseif needed_left_over < current_left_over then

			local left_over_to_remove = current_left_over - needed_left_over

			for i = 1, left_over_to_remove do

				rendered_objects['left_over'][i]:Destroy()
				rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object_name]['left_over'][i] = nil
			end
		end
	end
end





function find_highest_air_y(start_y: number, blocks: {}): (number)

	for y = start_y, MIN_HEIGHT, -1 do
		if blocks[y] ~= 'Air' then
			return y + 1
		end
	end
end




function handle_update_dropped_objects(to_clear: {}, to_update: {}): ()
	
	for _, chunk_data in to_clear do
		
		local chunk_x = chunk_data[1]
		local chunk_z = chunk_data[2]
		local x = chunk_data[3]
		local z = chunk_data[4]
		local y = chunk_data[5]
		
		if  
			loaded_dropped_objects[chunk_x][chunk_z][x]
			and loaded_dropped_objects[chunk_x][chunk_z][x][z]
			and loaded_dropped_objects[chunk_x][chunk_z][x][z][y] 
		then
			for object_name in loaded_dropped_objects[chunk_x][chunk_z][x][z][y] do
				
				loaded_dropped_objects[chunk_x][chunk_z][x][z][y][object_name] = 0
				update_stacks_at_position(chunk_x, chunk_z, x, z, y)
			end
			
		end
	end
	
	local chunk_x = to_update[1]
	local chunk_z = to_update[2]
	local x = to_update[3]
	local z = to_update[4]
	local y = to_update[5]
	
	local objects_amount = to_update[6]
	
	create_tbl_tables(loaded_dropped_objects, chunk_x, chunk_z, x, z, y)
	create_tbl_tables(rendered_dropped_objects, chunk_x, chunk_z, x, z, y)
	loaded_dropped_objects[chunk_x][chunk_z][x][z][y] = objects_amount
	
	update_stacks_at_position(chunk_x, chunk_z, x, z, y)
end



local frames = 0

function check_for_pickup()
	
	frames += 1
	
	if frames % 10 ~= 0 then return end
	if not PLAYER.Character then return end
	
	local hrp_position = PLAYER.Character:WaitForChild('HumanoidRootPart').Position
	
	-- loop through all rendered objects
	-- if player is close then 
end



--[[ PUBLIC ]]--

function DROPPED.render_chunk(chunk_x: number, chunk_z: number): ()

	if not (loaded_dropped_objects[chunk_x] and loaded_dropped_objects[chunk_x][chunk_z]) then return end

	local chunk_folder = Instance.new('Folder')
	chunk_folder.Name = `{chunk_x}x{chunk_z}`
	chunk_folder.Parent = workspace.DROPPED

	if not rendered_dropped_objects[chunk_x] then
		rendered_dropped_objects[chunk_x] = {}
	end
	rendered_dropped_objects[chunk_x][chunk_z] = {}

	for x, object_xs in loaded_dropped_objects[chunk_x][chunk_z] do
		for z, object_zs in object_xs do
			for y, objects_data in object_zs do
				
				create_tbl_tables(rendered_dropped_objects, chunk_x, chunk_z, x, z, y)
				
				for object_name in objects_data do
					rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object_name] = {}
					rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object_name]['stacks'] = {}
					rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object_name]['left_over'] = {}
				end
				
				update_stacks_at_position(chunk_x, chunk_z, x, z, y)
			end
		end
	end
end


function DROPPED.unrender_chunk(chunk_x: number, chunk_z: number): ()

	local chunk_folder = workspace.DROPPED:FindFirstChild(`{chunk_x}x{chunk_z}`)
	chunk_folder:Destroy()

	rendered_dropped_objects[chunk_x][chunk_z] = nil
end


function DROPPED.load_chunk(chunk_x: number, chunk_z: number): ()
	S_RS.REMOTES.GetDroppedObjects:FireServer(chunk_x, chunk_z)

	if not loaded_dropped_objects[chunk_x] then
		loaded_dropped_objects[chunk_x] = {}
	end
	loaded_dropped_objects[chunk_x][chunk_z] = {}
end


function DROPPED.unload_chunk(chunk_x: number, chunk_z: number): ()

	if not loaded_dropped_objects[chunk_x] or not loaded_dropped_objects[chunk_x][chunk_z] then return end

	loaded_dropped_objects[chunk_x][chunk_z] = nil
end




--// Adds to already loaded object and renders if necessary (if block mined -> play anim in that script -> add to here)
function DROPPED.add(object: BasePart, amount: number, world_position: Vector3): ()

	local chunk_position = M_CHUNKS_UTIL.world_to_chunk_position(world_position)

	local chunk_x = chunk_position[1]
	local chunk_z = chunk_position[2]
	local x = chunk_position[3]
	local z = chunk_position[4]
	local y = chunk_position[5]

	-- Must be a loaded / rendered chunk
	if not loaded_dropped_objects[chunk_x] or not loaded_dropped_objects[chunk_x][chunk_z] then return end

	create_tbl_tables(loaded_dropped_objects, chunk_x, chunk_z, x, z, y)
	create_tbl_tables(rendered_dropped_objects, chunk_x, chunk_z, x, z, y)

	if loaded_dropped_objects[chunk_x][chunk_z][x][z][y][object.Name] then
		loaded_dropped_objects[chunk_x][chunk_z][x][z][y][object.Name] += amount
	else
		loaded_dropped_objects[chunk_x][chunk_z][x][z][y][object.Name] = amount
	end

	-- Rendered
	if not rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object.Name] then
		rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object.Name] = {}
	end
	if not rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object.Name]['stacks'] then
		rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object.Name]['stacks'] = {}
	end
	if not rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object.Name]['left_over'] then
		rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object.Name]['left_over'] = {}
	end
	table.insert(rendered_dropped_objects[chunk_x][chunk_z][x][z][y][object.Name]['left_over'], object)

	update_stacks_at_position(chunk_x, chunk_z, x, z, y)
end








--// Updates block positions to fall
function DROPPED.block_mined(object_name: string, world_position: Vector3): ()

	local chunk_position = M_CHUNKS_UTIL.world_to_chunk_position(world_position)

	local chunk_x = chunk_position[1]
	local chunk_z = chunk_position[2]
	local x = chunk_position[3]
	local z = chunk_position[4]
	local y = chunk_position[5]

	local blocks_at_xz = M_LOADED_CHUNKS[chunk_x][chunk_z][x][z]
	local new_y = find_highest_air_y(y, blocks_at_xz)
	
	create_tbl_tables(loaded_dropped_objects, chunk_x, chunk_z, x, z, new_y)

	local to_move = {}
	local destination = {chunk_x, chunk_z, x, z, new_y}

	-- If dropped block above mined -> move block down, TODO fire server, server doesnt know where air is, client must tell server
	local loaded_dropped_objects_above = loaded_dropped_objects[chunk_x][chunk_z][x][z][y + 1]
	local loaded_dropped_objects_at = loaded_dropped_objects[chunk_x][chunk_z][x][z][y]
	local loaded_dropped_objects_new = loaded_dropped_objects[chunk_x][chunk_z][x][z][new_y]
	
	-- Moves ABOVE to NEW
	if loaded_dropped_objects_above then
		
		for object_name, object_amount in loaded_dropped_objects_above do

			if loaded_dropped_objects_new[object_name] then
				loaded_dropped_objects_new[object_name] += object_amount
			else
				loaded_dropped_objects_new[object_name] = object_amount
			end
		end
		loaded_dropped_objects[chunk_x][chunk_z][x][z][y + 1] = nil
		table.insert(to_move, {chunk_x, chunk_z, x, z, y + 1})
	end

	-- Moves AT to NEW
	if y ~= new_y then
		
		for object_name, object_amount in loaded_dropped_objects_at do

			if loaded_dropped_objects_new[object_name] then
				loaded_dropped_objects_new[object_name] += object_amount
			else
				loaded_dropped_objects_new[object_name] = object_amount
			end
		end
		loaded_dropped_objects[chunk_x][chunk_z][x][z][y] = nil
		table.insert(to_move, {chunk_x, chunk_z, x, z, y})
	end

	-- If dropped block above mined block is rendered -> animate block down
	local rendered_dropped_objects_above = rendered_dropped_objects[chunk_x][chunk_z][x][z][y + 1]
	local rendered_dropped_objects_at = rendered_dropped_objects[chunk_x][chunk_z][x][z][y]
	local rendered_dropped_objects_new = rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y]

	if not rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y] then
		rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y] = {}
	end

	-- Move ABOVE to NEW
	for object_name, object_data in rendered_dropped_objects_above or {} do

		if not rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object_name] then
			rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object_name] = {}
		end
		if not rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object_name]['stacks'] then
			rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object_name]['stacks'] = {}
		end
		if not rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object_name]['left_over'] then
			rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object_name]['left_over'] = {}
		end

		-- Stacks
		for _, object in object_data['stacks'] do

			object:PivotTo(CFrame.new(object.PrimaryPart.Position.X, new_y * 3, object.PrimaryPart.Position.Z))
			table.insert(rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object_name]['stacks'], object)
		end

		-- Left over
		if object_data['left_over'] then

			for _, object in object_data['left_over'] do

				object.Position = Vector3.new(object.Position.X, new_y * 3, object.Position.Z)
				table.insert(rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object.Name]['left_over'], object)
			end
		end
	end
	rendered_dropped_objects[chunk_x][chunk_z][x][z][y + 1] = nil

	-- Move AT to NEW
	if y ~= new_y then

		for object_name, object_data in rendered_dropped_objects_at do

			if not rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object_name] then
				rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object_name] = {}
			end
			if not rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object_name]['stacks'] then
				rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object_name]['stacks'] = {}
			end
			if not rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object_name]['left_over'] then
				rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object_name]['left_over'] = {}
			end

			-- Stacks
			for _, object in object_data['stacks'] do

				object:PivotTo(CFrame.new(object.PrimaryPart.Position.X, new_y * 3, object.PrimaryPart.Position.Z))
				table.insert(rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object_name]['stacks'], object)
			end

			-- Left over
			if object_data['left_over'] then

				for _, object in object_data['left_over'] do

					object.Position = Vector3.new(object.Position.X, new_y * 3, object.Position.Z)
					table.insert(rendered_dropped_objects[chunk_x][chunk_z][x][z][new_y][object.Name]['left_over'], object)
				end
			end
		end
		rendered_dropped_objects[chunk_x][chunk_z][x][z][y] = nil
	end

	update_stacks_at_position(chunk_x, chunk_z, x, z, new_y)
	
	S_RS.REMOTES.BlockMined:FireServer(object_name, M_CHUNKS_UTIL.chunk_to_world_position(chunk_x, chunk_z, x, z, new_y))
	S_RS.REMOTES.UpdateDroppedObjects:FireServer(to_move, destination)
end





--// Updates block positions to nearest air neighbour
function DROPPED.block_placed(world_position: Vector3): ()

	local chunk_position = M_CHUNKS_UTIL.world_to_chunk_position(world_position)

	local chunk_x = chunk_position[1]
	local chunk_z = chunk_position[2]
	local x = chunk_position[3]
	local z = chunk_position[4]
	local y = chunk_position[5]

	local to_move = {{chunk_x, chunk_z, x, z, y}}
	local destination = {}

	if not (loaded_dropped_objects[chunk_x] and loaded_dropped_objects[chunk_x][chunk_z]) then return end
	
	for _, offset_position in NEIGHBOUR_ORDER do
		
		local neighbour_world_position = Vector3.new(
			world_position.X + offset_position.X,
			world_position.Y + offset_position.Y,
			world_position.Z + offset_position.Z
		)
		
		local neighbour_chunk_position = M_CHUNKS_UTIL.world_to_chunk_position(neighbour_world_position)
		
		local neighbour_chunk_x = neighbour_chunk_position[1]
		local neighbour_chunk_z = neighbour_chunk_position[2]
		local neighbour_x = neighbour_chunk_position[3]
		local neighbour_z = neighbour_chunk_position[4]
		local neighbour_y = neighbour_chunk_position[5]
		
		if M_LOADED_CHUNKS[neighbour_chunk_x][neighbour_chunk_z][neighbour_x][neighbour_z][neighbour_y] == 'Air' then
			destination = {neighbour_chunk_x, neighbour_chunk_z, neighbour_x, neighbour_z, neighbour_y}
		end
	end
	
	if not destination then
		warn(`No destination found after block placed at chunk_x: {chunk_x}, chunk_z: {chunk_z}, x: {x}, z: {z}, y: {y}`)
	end
	
	-- move loaded to new, make function

	if not (rendered_dropped_objects[chunk_x] and rendered_dropped_objects[chunk_x][chunk_z]) then return end

	S_RS.REMOTES.UpdateDroppedObjects:FireServer(to_move, destination)
end


--[[ EVENTS ]]--

S_RS.REMOTES.GetDroppedObjects.OnClientEvent:Connect(register_chunk_dropped_objects)
S_RS.REMOTES.UpdateDroppedObjects.OnClientEvent:Connect(handle_update_dropped_objects)

S_RUN.Heartbeat:Connect(check_for_pickup)
S_RUN.Heartbeat:Connect(handle_animations)

S_UIS.InputBegan:Connect(handle_input)




return DROPPED