local DroppedObjects = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local StarterPlayer = game:GetService('StarterPlayer')

local Modules = StarterPlayer.StarterPlayerScripts.Modules
local ChunksUtil = require(ReplicatedStorage.Modules.ChunksUtil)
local ChunkSettings = require(ReplicatedStorage.Modules.ChunkSettings)
local Model = require(Modules.Model)
local LoadedChunks = require(Modules.LoadedChunks)

local Player = Players.LocalPlayer

local MAX_HEIGHT = ChunkSettings['MAX_HEIGHT']
local MIN_HEIGHT = ChunkSettings['MIN_HEIGHT']

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

local loadedDroppedObjects = {}
local renderedDroppedObjects = {}

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


-- PRIVATE

function createTblTables(tbl: {}, chunkX: number, chunkZ: number, x: number, z: number, y: number): ()

	if not tbl[chunkX][chunkZ][x] then
		tbl[chunkX][chunkZ][x] = {}
	end

	if not tbl[chunkX][chunkZ][x][z] then
		tbl[chunkX][chunkZ][x][z] = {}
	end

	if not tbl[chunkX][chunkZ][x][z][y] then
		tbl[chunkX][chunkZ][x][z][y] = {}
	end
end


-- Handles up, down and rotational animations
function handle_animations(): ()

end


function scaleObject(object: BasePart): ()

	if object:IsA('Model') then
		
		local largestSize = object.PrimaryPart.Size.Y -- find largest side?
		local scaleFactor = DROPPED_OBJECT_SIZE / largestSize

		object:ScaleTo(scaleFactor)
	else
		object.Size = Vector3.new(DROPPED_OBJECT_SIZE, DROPPED_OBJECT_SIZE, DROPPED_OBJECT_SIZE)
	end
end


function generate_stack(objectName: string, chunkFolder: Folder, world_position: Vector3): (Model)

	local object_1 = ReplicatedStorage.ITEMS:FindFirstChild(objectName):Clone()
	local object_2 = object_1:Clone()
	object_1.CanCollide = false
	object_2.CanCollide = false

	local grouped_dropped_objects = workspace.GROUPED_DROPPED_OBJECTS:Clone()
	grouped_dropped_objects.Name = objectName

	scaleObject(object_1)
	scaleObject(object_2)

	object_1.CFrame = grouped_dropped_objects.HITBOX.Point1.CFrame
	object_2.CFrame = grouped_dropped_objects.HITBOX.Point2.CFrame

	object_1.Parent = grouped_dropped_objects
	object_2.Parent = grouped_dropped_objects
	grouped_dropped_objects:PivotTo(CFrame.new(world_position + Vector3.new(math.random(-100, 100) / 100, 0, math.random(-100, 100) / 100)))
	grouped_dropped_objects.Parent = chunkFolder

	return grouped_dropped_objects
end


-- Generates a single object 
function generate_object(objectName: string, chunkFolder: Folder, world_position: Vector3): (BasePart)

	local object = ReplicatedStorage.ITEMS:FindFirstChild(objectName):Clone()
	object.Position = world_position
	object.CanCollide = false
	object.Position = world_position + Vector3.new(math.random(-100, 100) / 100, 0, math.random(-100, 100) / 100)

	scaleObject(object)

	object.Parent = chunkFolder

	return object
end


-- Register server's chunk dropped objects
function register_chunk_dropped_objects(chunkX: number, chunkZ: number, dropped_objects: {}): ()

	for x, objects_xs in dropped_objects do

		x = tonumber(x)
		loadedDroppedObjects[chunkX][chunkZ][x] = {}

		for z, objects_zs in objects_xs do

			z = tonumber(z)
			loadedDroppedObjects[chunkX][chunkZ][x][z] = {}

			for y, objects in objects_zs do

				y = tonumber(y)
				loadedDroppedObjects[chunkX][chunkZ][x][z][y] = {}

				for objectName, objectAmount in objects do
					loadedDroppedObjects[chunkX][chunkZ][x][z][y][objectName] = objectAmount
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

	if not typing then 
		return 
	end

	if input.KeyCode == Enum.KeyCode.Q then
		drop_equipped_object()
	end
end


--[[function get_number_of_needed_objects(chunkX: number, chunkZ: number, x: number, z: number, y: number, objectName: string)
	
	if not 
end]]


function update_stacks_at_position(chunkX: number, chunkZ: number, x: number, z: number, y: number): ()

	for objectName, objectAmount in loadedDroppedObjects[chunkX][chunkZ][x][z][y] do

		if not renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName] then
			renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName] = {}
			renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]['stacks'] = {}
			renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]['left_over'] = {}
		end
		
		local rendered_objects = renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]

		local needed_number_of_stacks = math.ceil((objectAmount - LEFT_OVER_SIZE) / OBJECT_STACK_SIZE)
		local needed_left_over = if objectAmount % OBJECT_STACK_SIZE <= LEFT_OVER_SIZE then objectAmount % OBJECT_STACK_SIZE else 0

		local current_number_of_stacks = #rendered_objects['stacks']
		local current_left_over = #rendered_objects['left_over']

		local chunkFolder = workspace.DroppedObjects:FindFirstChild(`{chunkX}x{chunkZ}`)

		-- Add stack to rendered objects
		if needed_number_of_stacks > current_number_of_stacks then

			local stack = generate_stack(objectName, chunkFolder, ChunksUtil.chunk_to_world_position(chunkX, chunkZ, x, z, y))
			table.insert(renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]['stacks'], stack)

			-- Remove stacks from rendered objects
		elseif needed_number_of_stacks < current_number_of_stacks then

			local stacks_to_remove = current_number_of_stacks - needed_number_of_stacks

			for i = 1, stacks_to_remove do
				rendered_objects['stacks'][i]:Destroy()
				renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]['stacks'][i] = nil
			end
		end

		-- Add left over to rendered object
		if needed_left_over > current_left_over then

			local left_over = generate_object(objectName, chunkFolder, ChunksUtil.chunk_to_world_position(chunkX, chunkZ, x, z, y))
			table.insert(renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]['left_over'], left_over)

			-- Remove left over from rendered object
		elseif needed_left_over < current_left_over then

			local left_over_to_remove = current_left_over - needed_left_over

			for i = 1, left_over_to_remove do

				rendered_objects['left_over'][i]:Destroy()
				renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]['left_over'][i] = nil
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
		
		local chunkX = chunk_data[1]
		local chunkZ = chunk_data[2]
		local x = chunk_data[3]
		local z = chunk_data[4]
		local y = chunk_data[5]
		
		if  
			loadedDroppedObjects[chunkX][chunkZ][x]
			and loadedDroppedObjects[chunkX][chunkZ][x][z]
			and loadedDroppedObjects[chunkX][chunkZ][x][z][y] 
		then
			for objectName in loadedDroppedObjects[chunkX][chunkZ][x][z][y] do
				
				loadedDroppedObjects[chunkX][chunkZ][x][z][y][objectName] = 0
				update_stacks_at_position(chunkX, chunkZ, x, z, y)
			end
			
		end
	end
	
	local chunkX = to_update[1]
	local chunkZ = to_update[2]
	local x = to_update[3]
	local z = to_update[4]
	local y = to_update[5]
	
	local objects_amount = to_update[6]
	
	createTblTables(loadedDroppedObjects, chunkX, chunkZ, x, z, y)
	createTblTables(renderedDroppedObjects, chunkX, chunkZ, x, z, y)
	loadedDroppedObjects[chunkX][chunkZ][x][z][y] = objects_amount
	
	update_stacks_at_position(chunkX, chunkZ, x, z, y)
end


local frames = 0

function checkForPickup()
	
	frames += 1
	
	if 
		frames % 10 ~= 0 
		or not Player.Character
	then 
		return 
	end

	local HumanoidRootPart = Player.Character:WaitForChild('HumanoidRootPart')
	
	-- loop through all rendered objects
	-- if player is close then 
end



--[[ PUBLIC ]]--

function DroppedObjects.render_chunk(chunkX: number, chunkZ: number): ()

	if not (loadedDroppedObjects[chunkX] and loadedDroppedObjects[chunkX][chunkZ]) then return end

	local chunkFolder = Instance.new('Folder')
	chunkFolder.Name = `{chunkX}x{chunkZ}`
	chunkFolder.Parent = workspace.DroppedObjects

	if not renderedDroppedObjects[chunkX] then
		renderedDroppedObjects[chunkX] = {}
	end
	renderedDroppedObjects[chunkX][chunkZ] = {}

	for x, object_xs in loadedDroppedObjects[chunkX][chunkZ] do
		for z, object_zs in object_xs do
			for y, objects_data in object_zs do
				
				createTblTables(renderedDroppedObjects, chunkX, chunkZ, x, z, y)
				
				for objectName in objects_data do
					renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName] = {}
					renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]['stacks'] = {}
					renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]['left_over'] = {}
				end
				
				update_stacks_at_position(chunkX, chunkZ, x, z, y)
			end
		end
	end
end


function DroppedObjects.unrender_chunk(chunkX: number, chunkZ: number): ()

	local chunkFolder = workspace.DroppedObjects:FindFirstChild(`{chunkX}x{chunkZ}`)
	chunkFolder:Destroy()

	renderedDroppedObjects[chunkX][chunkZ] = nil
end


function DroppedObjects.loadChunk(chunkX: number, chunkZ: number): ()
	ReplicatedStorage.Remotes.GetDroppedObjects:FireServer(chunkX, chunkZ)

	if not loadedDroppedObjects[chunkX] then
		loadedDroppedObjects[chunkX] = {}
	end
	loadedDroppedObjects[chunkX][chunkZ] = {}
end


function DroppedObjects.unloadChunk(chunkX: number, chunkZ: number): ()

	if not loadedDroppedObjects[chunkX] or not loadedDroppedObjects[chunkX][chunkZ] then return end

	loadedDroppedObjects[chunkX][chunkZ] = nil
end


-- Adds to already loaded object and renders if necessary (if block mined -> play anim in that script -> add to here)
function DroppedObjects.add(object: BasePart, amount: number, world_position: Vector3): ()

	local chunk_position = ChunksUtil.worldToChunkPosition(world_position)

	local chunkX = chunk_position[1]
	local chunkZ = chunk_position[2]
	local x = chunk_position[3]
	local z = chunk_position[4]
	local y = chunk_position[5]

	-- Must be a loaded / rendered chunk
	if not loadedDroppedObjects[chunkX] or not loadedDroppedObjects[chunkX][chunkZ] then return end

	createTblTables(loadedDroppedObjects, chunkX, chunkZ, x, z, y)
	createTblTables(renderedDroppedObjects, chunkX, chunkZ, x, z, y)

	if loadedDroppedObjects[chunkX][chunkZ][x][z][y][object.Name] then
		loadedDroppedObjects[chunkX][chunkZ][x][z][y][object.Name] += amount
	else
		loadedDroppedObjects[chunkX][chunkZ][x][z][y][object.Name] = amount
	end

	-- Rendered
	if not renderedDroppedObjects[chunkX][chunkZ][x][z][y][object.Name] then
		renderedDroppedObjects[chunkX][chunkZ][x][z][y][object.Name] = {}
	end
	if not renderedDroppedObjects[chunkX][chunkZ][x][z][y][object.Name]['stacks'] then
		renderedDroppedObjects[chunkX][chunkZ][x][z][y][object.Name]['stacks'] = {}
	end
	if not renderedDroppedObjects[chunkX][chunkZ][x][z][y][object.Name]['left_over'] then
		renderedDroppedObjects[chunkX][chunkZ][x][z][y][object.Name]['left_over'] = {}
	end
	table.insert(renderedDroppedObjects[chunkX][chunkZ][x][z][y][object.Name]['left_over'], object)

	update_stacks_at_position(chunkX, chunkZ, x, z, y)
end


-- Updates block positions to fall
function DroppedObjects.block_mined(objectName: string, world_position: Vector3): ()

	local chunk_position = ChunksUtil.world_to_chunk_position(world_position)

	local chunkX = chunk_position[1]
	local chunkZ = chunk_position[2]
	local x = chunk_position[3]
	local z = chunk_position[4]
	local y = chunk_position[5]

	local blocksAtXZ = LoadedChunks[chunkX][chunkZ][x][z]
	local new_y = find_highest_air_y(y, blocksAtXZ)
	
	createTblTables(loadedDroppedObjects, chunkX, chunkZ, x, z, new_y)

	local to_move = {}
	local destination = {chunkX, chunkZ, x, z, new_y}

	-- If dropped block above mined -> move block down, TODO fire server, server doesnt know where air is, client must tell server
	local loaded_dropped_objects_above = loadedDroppedObjects[chunkX][chunkZ][x][z][y + 1]
	local loaded_dropped_objects_at = loadedDroppedObjects[chunkX][chunkZ][x][z][y]
	local loaded_dropped_objects_new = loadedDroppedObjects[chunkX][chunkZ][x][z][new_y]
	
	-- Moves ABOVE to NEW
	if loaded_dropped_objects_above then
		
		for objectName, objectAmount in loaded_dropped_objects_above do

			if loaded_dropped_objects_new[objectName] then
				loaded_dropped_objects_new[objectName] += objectAmount
			else
				loaded_dropped_objects_new[objectName] = objectAmount
			end
		end
		loadedDroppedObjects[chunkX][chunkZ][x][z][y + 1] = nil
		table.insert(to_move, {chunkX, chunkZ, x, z, y + 1})
	end

	-- Moves AT to NEW
	if y ~= new_y then
		
		for objectName, objectAmount in loaded_dropped_objects_at do

			if loaded_dropped_objects_new[objectName] then
				loaded_dropped_objects_new[objectName] += objectAmount
			else
				loaded_dropped_objects_new[objectName] = objectAmount
			end
		end
		loadedDroppedObjects[chunkX][chunkZ][x][z][y] = nil
		table.insert(to_move, {chunkX, chunkZ, x, z, y})
	end

	-- If dropped block above mined block is rendered -> animate block down
	local rendered_dropped_objects_above = renderedDroppedObjects[chunkX][chunkZ][x][z][y + 1]
	local rendered_dropped_objects_at = renderedDroppedObjects[chunkX][chunkZ][x][z][y]
	local rendered_dropped_objects_new = renderedDroppedObjects[chunkX][chunkZ][x][z][new_y]

	if not renderedDroppedObjects[chunkX][chunkZ][x][z][new_y] then
		renderedDroppedObjects[chunkX][chunkZ][x][z][new_y] = {}
	end

	-- Move ABOVE to NEW
	for objectName, object_data in rendered_dropped_objects_above or {} do

		if not renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][objectName] then
			renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][objectName] = {}
		end
		if not renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][objectName]['stacks'] then
			renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][objectName]['stacks'] = {}
		end
		if not renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][objectName]['left_over'] then
			renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][objectName]['left_over'] = {}
		end

		-- Stacks
		for _, object in object_data['stacks'] do

			object:PivotTo(CFrame.new(object.PrimaryPart.Position.X, new_y * 3, object.PrimaryPart.Position.Z))
			table.insert(renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][objectName]['stacks'], object)
		end

		-- Left over
		if object_data['left_over'] then

			for _, object in object_data['left_over'] do

				object.Position = Vector3.new(object.Position.X, new_y * 3, object.Position.Z)
				table.insert(renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][object.Name]['left_over'], object)
			end
		end
	end
	renderedDroppedObjects[chunkX][chunkZ][x][z][y + 1] = nil

	-- Move AT to NEW
	if y ~= new_y then

		for objectName, object_data in rendered_dropped_objects_at do

			if not renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][objectName] then
				renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][objectName] = {}
			end
			if not renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][objectName]['stacks'] then
				renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][objectName]['stacks'] = {}
			end
			if not renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][objectName]['left_over'] then
				renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][objectName]['left_over'] = {}
			end

			-- Stacks
			for _, object in object_data['stacks'] do

				object:PivotTo(CFrame.new(object.PrimaryPart.Position.X, new_y * 3, object.PrimaryPart.Position.Z))
				table.insert(renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][objectName]['stacks'], object)
			end

			-- Left over
			if object_data['left_over'] then

				for _, object in object_data['left_over'] do

					object.Position = Vector3.new(object.Position.X, new_y * 3, object.Position.Z)
					table.insert(renderedDroppedObjects[chunkX][chunkZ][x][z][new_y][object.Name]['left_over'], object)
				end
			end
		end
		renderedDroppedObjects[chunkX][chunkZ][x][z][y] = nil
	end

	update_stacks_at_position(chunkX, chunkZ, x, z, new_y)
	
	ReplicatedStorage.REMOTES.BlockMined:FireServer(objectName, ChunksUtil.chunk_to_world_position(chunkX, chunkZ, x, z, new_y))
	ReplicatedStorage.REMOTES.UpdateDroppedObjects:FireServer(to_move, destination)
end


-- Updates block positions to nearest air neighbour
function DroppedObjects.block_placed(world_position: Vector3): ()

	local chunk_position = ChunksUtil.world_to_chunk_position(world_position)

	local chunkX = chunk_position[1]
	local chunkZ = chunk_position[2]
	local x = chunk_position[3]
	local z = chunk_position[4]
	local y = chunk_position[5]

	local to_move = {{chunkX, chunkZ, x, z, y}}
	local destination = {}

	if not (loadedDroppedObjects[chunkX] and loadedDroppedObjects[chunkX][chunkZ]) then 
		return 
	end
	
	for _, offset_position in NEIGHBOUR_ORDER do
		
		local neighbour_world_position = Vector3.new(
			world_position.X + offset_position.X,
			world_position.Y + offset_position.Y,
			world_position.Z + offset_position.Z
		)
		
		local neighbour_chunk_position = ChunksUtil.world_to_chunk_position(neighbour_world_position)
		
		local neighbour_chunk_x = neighbour_chunk_position[1]
		local neighbour_chunk_z = neighbour_chunk_position[2]
		local neighbour_x = neighbour_chunk_position[3]
		local neighbour_z = neighbour_chunk_position[4]
		local neighbour_y = neighbour_chunk_position[5]
		
		if LoadedChunks[neighbour_chunk_x][neighbour_chunk_z][neighbour_x][neighbour_z][neighbour_y] == 'Air' then
			destination = {neighbour_chunk_x, neighbour_chunk_z, neighbour_x, neighbour_z, neighbour_y}
		end
	end
	
	if not destination then
		warn(`No destination found after block placed at chunkX: {chunkX}, chunkZ: {chunkZ}, x: {x}, z: {z}, y: {y}`)
	end
	
	-- move loaded to new, make function

	if not (renderedDroppedObjects[chunkX] and renderedDroppedObjects[chunkX][chunkZ]) then 
		return 
	end

	ReplicatedStorage.Remotes.UpdateDroppedObjects:FireServer(to_move, destination)
end


-- EVENTS

ReplicatedStorage.Remotes.GetDroppedObjects.OnClientEvent:Connect(register_chunk_dropped_objects)
ReplicatedStorage.Remotes.UpdateDroppedObjects.OnClientEvent:Connect(handle_update_dropped_objects)
RunService.Heartbeat:Connect(checkForPickup)
RunService.Heartbeat:Connect(handle_animations)
UserInputService.InputBegan:Connect(handle_input)

return DroppedObjects