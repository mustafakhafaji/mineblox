local DroppedObjects = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local Modules = ReplicatedStorage.Modules
local ChunksUtil = require(Modules.ChunksUtil)

local droppedObjectsData = {}

-- PRIVATE

-- Fills in missing tables in droppedObjectsData
function createDroppedObjectsTables(chunkX: number, chunkZ: number, x: number, z: number, y: number): ()

	if not droppedObjectsData[chunkX] then
		droppedObjectsData[chunkX] = {}
	end

	if not droppedObjectsData[chunkX][chunkZ] then
		droppedObjectsData[chunkX][chunkZ] = {}
	end

	if not droppedObjectsData[chunkX][chunkZ][x] then
		droppedObjectsData[chunkX][chunkZ][x] = {}
	end

	if not droppedObjectsData[chunkX][chunkZ][x][z] then
		droppedObjectsData[chunkX][chunkZ][x][z] = {}
	end
	
	if not droppedObjectsData[chunkX][chunkZ][x][z][y] then
		droppedObjectsData[chunkX][chunkZ][x][z][y] = {}
	end
end


function handleDroppedObjects(objectName: string, worldPosition: Vector3): ()
	
	local chunkPosition = ChunksUtil.worldToChunkPosition(worldPosition)

	local chunkX = chunkPosition[1]
	local chunkZ = chunkPosition[2]
	local x = chunkPosition[3]
	local z = chunkPosition[4]
	local y = chunkPosition[5]
	
	createDroppedObjectsTables(chunkX, chunkZ, x, z, y)
	
	-- check if block is there
	-- if there is then += 1
	-- else add and set to 1
	--droppedObjectsData[chunkX][chunkZ]
end


-- Fires client with dropped objects 
function handleGetDroppedObjects(player: Player, chunkX: number, chunkZ: number)
	
	if droppedObjectsData[chunkX] and droppedObjectsData[chunkX][chunkZ] then
		
		local data = droppedObjectsData[chunkX][chunkZ]
		
		ReplicatedStorage.Remotes.GetDroppedObjects:FireClient(player, chunkX, chunkZ, data)
	end
end


-- Updates data, adding mined block
function handleMinedBlock(Player: Player, objectName: string, worldPosition: Vector3)
	
	local chunkPosition = ChunksUtil.worldToChunkPosition(worldPosition)
	
	local chunkX = chunkPosition[1]
	local chunkZ = chunkPosition[2]
	local x = chunkPosition[3]
	local z = chunkPosition[4]
	local y = chunkPosition[5]

	createDroppedObjectsTables(chunkX, chunkZ, x, z, y)
	
	if droppedObjectsData[chunkX][chunkZ][x][z][y][objectName] then
		
		droppedObjectsData[chunkX][chunkZ][x][z][y][objectName] += 1
	else
		droppedObjectsData[chunkX][chunkZ][x][z][y][objectName] = 1
	end
end


-- Moves blocks in toMove to destination
function handleUpdateDroppedObjects(player: Player, toMove: {}, destination: {})
	
	local destinationChunkX = destination[1]
	local destinationChunkZ = destination[2]
	local destinationX = destination[3]
	local destinationZ = destination[4]
	local destinationY = destination[5]
	
	createDroppedObjectsTables(destinationChunkX, destinationChunkZ, destinationX, destinationZ, destinationY)
	
	for _, chunkPosition in toMove do
		
		local chunkX = chunkPosition[1]
		local chunkZ = chunkPosition[2]
		local x = chunkPosition[3]
		local z = chunkPosition[4]
		local y = chunkPosition[5]
		
		if not droppedObjectsData[chunkX][chunkZ][x][z][y] then 
			--table.remove(toMove, i)
			continue 
		end
		
		-- Move current data to destination
		for objectName, objectAmount in droppedObjectsData[chunkX][chunkZ][x][z][y] do
			
			if droppedObjectsData[destinationChunkX][destinationChunkZ][destinationX][destinationZ][destinationY][objectName] then
				
				droppedObjectsData[destinationChunkX][destinationChunkZ][destinationX][destinationZ][destinationY][objectName] += objectAmount
			else
				droppedObjectsData[destinationChunkX][destinationChunkZ][destinationX][destinationZ][destinationY][objectName] = objectAmount
			end
		end
		
		-- Remove current data
		droppedObjectsData[chunkX][chunkZ][x][z][y] = nil
	end
	
	local objectsAtDestination = droppedObjectsData[destinationChunkX][destinationChunkZ][destinationX][destinationZ][destinationY]
	local toUpdate = {destinationChunkX, destinationChunkZ, destinationX, destinationZ, destinationY, objectsAtDestination}
	
	-- Send players data
	for _, currentPlayer in Players:GetPlayers() do
		
		if currentPlayer == player then
			continue 
		end
		
		ReplicatedStorage.Remotes.UpdateDroppedObjects:FireClient(currentPlayer, toMove, toUpdate)
	end
end


-- EVENTS

ReplicatedStorage.Remotes.GetDroppedObjects.OnServerEvent:Connect(handleGetDroppedObjects)
ReplicatedStorage.Remotes.BlockMined.OnServerEvent:Connect(handleMinedBlock)
ReplicatedStorage.Remotes.DropObjects.OnServerEvent:Connect(handleDroppedObjects)
ReplicatedStorage.Remotes.UpdateDroppedObjects.OnServerEvent:Connect(handleUpdateDroppedObjects)

return DroppedObjects