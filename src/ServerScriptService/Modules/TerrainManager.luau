local Terrain = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)

local SEED = 500 -- CONTROLS THE SEED OF THE WORLD

local chunkDifferences = {}

-- PRIVATE 

-- Store differences in chunk difference table
function registerChunkUpdate(clientDifferences: {}): ()

	for _, differenceData in clientDifferences do
		
		local blockName = differenceData[1]
		local worldPosition = differenceData[2]
		
		local chunkPosition = ChunksUtil.worldToChunkPosition(worldPosition)
		
		local chunkX = tostring(chunkPosition[1]) 
		local chunkZ = tostring(chunkPosition[2])
		local x = tostring(chunkPosition[3]) 
		local z = tostring(chunkPosition[4]) 
		local y = tostring(chunkPosition[5]) 
		
		ChunksUtil.fillChunksTable(chunkDifferences, chunkX, chunkZ, x, z, y)
		--createChunkDifferenceTables(chunkX, chunkZ, x, z, y)
		chunkDifferences[chunkX][chunkZ][x][z][y] = blockName
	end
end


function handleGetSeed(player: Player): (number)
	return SEED
end


-- Fire all clients (excluding 1) with remote event and data
function fireClientsExcluding(playerToIgnore: Player, event: RemoteEvent, ...): ()

	for _, currentPlayer in Players:GetPlayers() do

		if currentPlayer == playerToIgnore then
			continue 
		end

		event:FireClient(currentPlayer, ...)
	end
end


function getChunkDifferences(player: Player, chunkX: number, chunkZ: number): ()

	chunkX = tostring(chunkX)
	chunkZ = tostring(chunkZ)
	
	if not (chunkDifferences[chunkX] and chunkDifferences[chunkX][chunkZ]) then
		return 
	end
		
	local differences = {}
	
	for x, xValues in chunkDifferences[chunkX][chunkZ] do
		for z, zValues in xValues do
			for y, blockName in zValues do
				
				table.insert(differences, {blockName, ChunksUtil.chunkToWorldPosition(chunkX, chunkZ, x, z, y)})
			end
		end
	end
	
	ReplicatedStorage.Remotes.GetChunkDifferences:FireClient(player, differences)
end


-- Update blocks, when a block is destroyed
function updateChunk(player: Player, clientDifferences: {})

	registerChunkUpdate(clientDifferences)
	fireClientsExcluding(player, ReplicatedStorage.Remotes.UpdateChunk, clientDifferences)
end


-- EVENTS

ReplicatedStorage.Remotes.Chunks.GetSeed.OnServerInvoke = function(player: Player)
	return handleGetSeed(player)
end
ReplicatedStorage.Remotes.Chunks.GetChunkDifferences.OnServerEvent:Connect(getChunkDifferences)
ReplicatedStorage.Remotes.Chunks.UpdateChunk.OnServerEvent:Connect(updateChunk)


return Terrain