local DroppedObjects = {}

local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')
local StarterPlayer = game:GetService('StarterPlayer')

local Modules = StarterPlayer.StarterPlayerScripts.Modules
local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)
local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
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
function handleAnimations(): ()

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


function generateStack(objectName: string, chunkFolder: Folder, worldPosition: Vector3): (Model)

	local object1 = ReplicatedStorage.Items:FindFirstChild(objectName):Clone()
	local object2 = object1:Clone()
	object1.CanCollide = false
	object2.CanCollide = false

	local groupedDroppedObjects = workspace.groupedDroppedObjects:Clone()
	groupedDroppedObjects.Name = objectName

	scaleObject(object1)
	scaleObject(object2)

	object1.CFrame = groupedDroppedObjects.HITBOX.Point1.CFrame
	object2.CFrame = groupedDroppedObjects.HITBOX.Point2.CFrame

	object1.Parent = groupedDroppedObjects
	object2.Parent = groupedDroppedObjects
	groupedDroppedObjects:PivotTo(CFrame.new(worldPosition + Vector3.new(math.random(-100, 100) / 100, 0, math.random(-100, 100) / 100)))
	groupedDroppedObjects.Parent = chunkFolder

	return groupedDroppedObjects
end


-- Generates a single object 
function generateObject(objectName: string, chunkFolder: Folder, worldPosition: Vector3): (BasePart)

	local object = ReplicatedStorage.Items:FindFirstChild(objectName):Clone()
	object.Position = worldPosition
	object.CanCollide = false
	object.Position = worldPosition + Vector3.new(math.random(-100, 100) / 100, 0, math.random(-100, 100) / 100)

	scaleObject(object)

	object.Parent = chunkFolder

	return object
end


-- Register server's chunk dropped objects
function registerChunkDroppedObjects(chunkX: number, chunkZ: number, dropped_objects: {}): ()

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


function handleInput(input, typing): ()

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


function updateStacksAtPosition(chunkX: number, chunkZ: number, x: number, z: number, y: number): ()

	for objectName, objectAmount in loadedDroppedObjects[chunkX][chunkZ][x][z][y] do

		if not renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName] then
			renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName] = {}
			renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]['stacks'] = {}
			renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]['leftOver'] = {}
		end
		
		local rendered_objects = renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]

		local neededNumberOfStacks = math.ceil((objectAmount - LEFT_OVER_SIZE) / OBJECT_STACK_SIZE)
		local neededLeftOver = if objectAmount % OBJECT_STACK_SIZE <= LEFT_OVER_SIZE then objectAmount % OBJECT_STACK_SIZE else 0

		local currentNumberOfStacks = #rendered_objects['stacks']
		local currentLeftOver = #rendered_objects['leftOver']

		local chunkFolder = workspace.DroppedObjects:FindFirstChild(`{chunkX}x{chunkZ}`)

		-- Add stack to rendered objects
		if neededNumberOfStacks > currentNumberOfStacks then

			local stack = generateStack(objectName, chunkFolder, ChunksUtil.chunkToWorldPosition(chunkX, chunkZ, x, z, y))
			table.insert(renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]['stacks'], stack)

			-- Remove stacks from rendered objects
		elseif neededNumberOfStacks < currentNumberOfStacks then

			local stacks_to_remove = currentNumberOfStacks - neededNumberOfStacks

			for i = 1, stacks_to_remove do
				rendered_objects['stacks'][i]:Destroy()
				renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]['stacks'][i] = nil
			end
		end

		-- Add left over to rendered object
		if neededLeftOver > currentLeftOver then

			local leftOver = generateObject(objectName, chunkFolder, ChunksUtil.chunkToWorldPosition(chunkX, chunkZ, x, z, y))
			table.insert(renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]['leftOver'], leftOver)

			-- Remove left over from rendered object
		elseif neededLeftOver < currentLeftOver then

			local left_over_to_remove = currentLeftOver - neededLeftOver

			for i = 1, left_over_to_remove do

				rendered_objects['leftOver'][i]:Destroy()
				renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]['leftOver'][i] = nil
			end
		end
	end
end


function findHighestAirY(startY: number, blocks: {}): (number)

	for y = startY, MIN_HEIGHT, -1 do
		if blocks[y] ~= 'Air' then
			return y + 1
		end
	end
end


function handleUpdateDroppedObjects(to_clear: {}, toUpdate: {}): ()
	
	for _, chunkData in to_clear do
		
		local chunkX = chunkData[1]
		local chunkZ = chunkData[2]
		local x = chunkData[3]
		local z = chunkData[4]
		local y = chunkData[5]
		
		if  
			loadedDroppedObjects[chunkX][chunkZ][x]
			and loadedDroppedObjects[chunkX][chunkZ][x][z]
			and loadedDroppedObjects[chunkX][chunkZ][x][z][y] 
		then
			for objectName in loadedDroppedObjects[chunkX][chunkZ][x][z][y] do
				
				loadedDroppedObjects[chunkX][chunkZ][x][z][y][objectName] = 0
				updateStacksAtPosition(chunkX, chunkZ, x, z, y)
			end
			
		end
	end
	
	local chunkX = toUpdate[1]
	local chunkZ = toUpdate[2]
	local x = toUpdate[3]
	local z = toUpdate[4]
	local y = toUpdate[5]
	
	local objects_amount = toUpdate[6]
	
	createTblTables(loadedDroppedObjects, chunkX, chunkZ, x, z, y)
	createTblTables(renderedDroppedObjects, chunkX, chunkZ, x, z, y)
	loadedDroppedObjects[chunkX][chunkZ][x][z][y] = objects_amount
	
	updateStacksAtPosition(chunkX, chunkZ, x, z, y)
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



-- PUBLIC 

function DroppedObjects.renderChunk(chunkX: number, chunkZ: number): ()

	if not (loadedDroppedObjects[chunkX] and loadedDroppedObjects[chunkX][chunkZ]) then 
		return 
	end

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
					renderedDroppedObjects[chunkX][chunkZ][x][z][y][objectName]['leftOver'] = {}
				end
				
				updateStacksAtPosition(chunkX, chunkZ, x, z, y)
			end
		end
	end
end


function DroppedObjects.unrenderChunk(chunkX: number, chunkZ: number): ()

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
function DroppedObjects.add(object: BasePart, amount: number, worldPosition: Vector3): ()

	local chunk_position = ChunksUtil.worldToChunkPosition(worldPosition)

	local chunkX = chunk_position[1]
	local chunkZ = chunk_position[2]
	local x = chunk_position[3]
	local z = chunk_position[4]
	local y = chunk_position[5]

	-- Must be a loaded / rendered chunk
	if 
		not loadedDroppedObjects[chunkX] 
		or not loadedDroppedObjects[chunkX][chunkZ] 
	then 
		return 
	end

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
	if not renderedDroppedObjects[chunkX][chunkZ][x][z][y][object.Name]['leftOver'] then
		renderedDroppedObjects[chunkX][chunkZ][x][z][y][object.Name]['leftOver'] = {}
	end
	table.insert(renderedDroppedObjects[chunkX][chunkZ][x][z][y][object.Name]['leftOver'], object)

	updateStacksAtPosition(chunkX, chunkZ, x, z, y)
end


-- Updates block positions to fall
function DroppedObjects.blockMined(objectName: string, worldPosition: Vector3): ()

	local chunk_position = ChunksUtil.worldToChunkPosition(worldPosition)

	local chunkX = chunk_position[1]
	local chunkZ = chunk_position[2]
	local x = chunk_position[3]
	local z = chunk_position[4]
	local y = chunk_position[5]

	local blocksAtXZ = LoadedChunks[chunkX][chunkZ][x][z]
	local newY = findHighestAirY(y, blocksAtXZ)
	
	createTblTables(loadedDroppedObjects, chunkX, chunkZ, x, z, newY)

	local toMove = {}
	local destination = {chunkX, chunkZ, x, z, newY}

	-- If dropped block above mined -> move block down, TODO fire server, server doesnt know where air is, client must tell server
	local loadedDroppedObjectsAbove = loadedDroppedObjects[chunkX][chunkZ][x][z][y + 1]
	local loaded_dropped_objects_at = loadedDroppedObjects[chunkX][chunkZ][x][z][y]
	local loaded_dropped_objects_new = loadedDroppedObjects[chunkX][chunkZ][x][z][newY]
	
	-- Moves ABOVE to NEW
	if loadedDroppedObjectsAbove then
		
		for objectName, objectAmount in loadedDroppedObjectsAbove do

			if loaded_dropped_objects_new[objectName] then
				loaded_dropped_objects_new[objectName] += objectAmount
			else
				loaded_dropped_objects_new[objectName] = objectAmount
			end
		end
		loadedDroppedObjects[chunkX][chunkZ][x][z][y + 1] = nil
		table.insert(toMove, {chunkX, chunkZ, x, z, y + 1})
	end

	-- Moves AT to NEW
	if y ~= newY then
		
		for objectName, objectAmount in loaded_dropped_objects_at do

			if loaded_dropped_objects_new[objectName] then
				loaded_dropped_objects_new[objectName] += objectAmount
			else
				loaded_dropped_objects_new[objectName] = objectAmount
			end
		end
		loadedDroppedObjects[chunkX][chunkZ][x][z][y] = nil
		table.insert(toMove, {chunkX, chunkZ, x, z, y})
	end

	-- If dropped block above mined block is rendered -> animate block down
	local renderedDroppedObjectsAbove = renderedDroppedObjects[chunkX][chunkZ][x][z][y + 1]
	local renderedDroppedObjectsAt = renderedDroppedObjects[chunkX][chunkZ][x][z][y]
	local renderedDroppedObjectsNew = renderedDroppedObjects[chunkX][chunkZ][x][z][newY]

	if not renderedDroppedObjects[chunkX][chunkZ][x][z][newY] then
		renderedDroppedObjects[chunkX][chunkZ][x][z][newY] = {}
	end

	-- Move ABOVE to NEW
	for objectName, object_data in renderedDroppedObjectsAbove or {} do

		if not renderedDroppedObjects[chunkX][chunkZ][x][z][newY][objectName] then
			renderedDroppedObjects[chunkX][chunkZ][x][z][newY][objectName] = {}
		end
		if not renderedDroppedObjects[chunkX][chunkZ][x][z][newY][objectName]['stacks'] then
			renderedDroppedObjects[chunkX][chunkZ][x][z][newY][objectName]['stacks'] = {}
		end
		if not renderedDroppedObjects[chunkX][chunkZ][x][z][newY][objectName]['leftOver'] then
			renderedDroppedObjects[chunkX][chunkZ][x][z][newY][objectName]['leftOver'] = {}
		end

		-- Stacks
		for _, object in object_data['stacks'] do

			object:PivotTo(CFrame.new(object.PrimaryPart.Position.X, newY * 3, object.PrimaryPart.Position.Z))
			table.insert(renderedDroppedObjects[chunkX][chunkZ][x][z][newY][objectName]['stacks'], object)
		end

		-- Left over
		if object_data['leftOver'] then

			for _, object in object_data['leftOver'] do

				object.Position = Vector3.new(object.Position.X, newY * 3, object.Position.Z)
				table.insert(renderedDroppedObjects[chunkX][chunkZ][x][z][newY][object.Name]['leftOver'], object)
			end
		end
	end
	renderedDroppedObjects[chunkX][chunkZ][x][z][y + 1] = nil

	-- Move AT to NEW
	if y ~= newY then

		for objectName, object_data in renderedDroppedObjectsAt do

			if not renderedDroppedObjects[chunkX][chunkZ][x][z][newY][objectName] then
				renderedDroppedObjects[chunkX][chunkZ][x][z][newY][objectName] = {}
			end
			if not renderedDroppedObjects[chunkX][chunkZ][x][z][newY][objectName]['stacks'] then
				renderedDroppedObjects[chunkX][chunkZ][x][z][newY][objectName]['stacks'] = {}
			end
			if not renderedDroppedObjects[chunkX][chunkZ][x][z][newY][objectName]['leftOver'] then
				renderedDroppedObjects[chunkX][chunkZ][x][z][newY][objectName]['leftOver'] = {}
			end

			-- Stacks
			for _, object in object_data['stacks'] do

				object:PivotTo(CFrame.new(object.PrimaryPart.Position.X, newY * 3, object.PrimaryPart.Position.Z))
				table.insert(renderedDroppedObjects[chunkX][chunkZ][x][z][newY][objectName]['stacks'], object)
			end

			-- Left over
			if object_data['leftOver'] then

				for _, object in object_data['leftOver'] do

					object.Position = Vector3.new(object.Position.X, newY * 3, object.Position.Z)
					table.insert(renderedDroppedObjects[chunkX][chunkZ][x][z][newY][object.Name]['leftOver'], object)
				end
			end
		end
		renderedDroppedObjects[chunkX][chunkZ][x][z][y] = nil
	end

	updateStacksAtPosition(chunkX, chunkZ, x, z, newY)
	
	ReplicatedStorage.REMOTES.BlockMined:FireServer(objectName, ChunksUtil.chunkToWorldPosition(chunkX, chunkZ, x, z, newY))
	ReplicatedStorage.REMOTES.UpdateDroppedObjects:FireServer(toMove, destination)
end


-- Updates block positions to nearest air neighbour
function DroppedObjects.blockPlaced(worldPosition: Vector3): ()

	local chunk_position = ChunksUtil.worldToChunkPosition(worldPosition)

	local chunkX = chunk_position[1]
	local chunkZ = chunk_position[2]
	local x = chunk_position[3]
	local z = chunk_position[4]
	local y = chunk_position[5]

	local toMove = {{chunkX, chunkZ, x, z, y}}
	local destination = {}

	if not (loadedDroppedObjects[chunkX] and loadedDroppedObjects[chunkX][chunkZ]) then 
		return 
	end
	
	for _, offsetPosition in NEIGHBOUR_ORDER do
		
		local neighbour_worldPosition = Vector3.new(
			worldPosition.X + offsetPosition.X,
			worldPosition.Y + offsetPosition.Y,
			worldPosition.Z + offsetPosition.Z
		)
		
		local neighbour_chunk_position = ChunksUtil.worldToChunkPosition(neighbour_worldPosition)
		
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

	ReplicatedStorage.Remotes.UpdateDroppedObjects:FireServer(toMove, destination)
end


-- EVENTS

ReplicatedStorage.Remotes.GetDroppedObjects.OnClientEvent:Connect(registerChunkDroppedObjects)
ReplicatedStorage.Remotes.UpdateDroppedObjects.OnClientEvent:Connect(handleUpdateDroppedObjects)
RunService.Heartbeat:Connect(checkForPickup)
RunService.Heartbeat:Connect(handleAnimations)
UserInputService.InputBegan:Connect(handleInput)

return DroppedObjects