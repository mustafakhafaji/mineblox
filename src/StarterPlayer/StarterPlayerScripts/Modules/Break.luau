local Destroy = {}

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local StarterPlayer = game:GetService('StarterPlayer')
local UserInputService = game:GetService('UserInputService')

local ChunksData = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Data.ChunksData)
local ChunkRenderer = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Rendering.ChunkRenderer)
local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)

local Player: Player = Players.LocalPlayer

local mouse: Mouse = Player:GetMouse()
local camera: Camera = workspace.CurrentCamera

local BLOCK_SIZE: number = ChunkSettings['BLOCK_SIZE']
local CHUNK_SIZE: number = ChunkSettings['CHUNK_SIZE']

local AIR_ID: number = ItemsData['Air']['ID']

-- PRIVATE

function roundToNearest(value: number, snap: number): number
	return math.round(value / snap) * snap
end


function handleInputBegan(input: InputObject, typing: boolean): ()
	if 
		typing 
		or input.UserInputType ~= Enum.UserInputType.MouseButton1
		or not Player.Character
	then
		return
	end
	
	local rayOrigin = camera.CFrame.Position
	local rayDirection = mouse.UnitRay.Direction 
	
	local lastRoundedPosition = nil

	-- Keep raycasting with increments
	for i = 1, 150 do
		local location = rayOrigin + rayDirection * (i / 10)
		local roundedPosition = Vector3.new(
			roundToNearest(location.X, BLOCK_SIZE),
			roundToNearest(location.Y, BLOCK_SIZE),
			roundToNearest(location.Z, BLOCK_SIZE)
		)
		
		if roundedPosition == lastRoundedPosition then
			continue
		end
		
		local chunkPosition = ChunksUtil.worldToChunkPosition(roundedPosition)
		local chunkX = chunkPosition[1]
		local chunkZ = chunkPosition[2]
		local chunkY = chunkPosition[3]
		local x = chunkPosition[4]
		local z = chunkPosition[5]
		local y = math.clamp(chunkPosition[6], 0, CHUNK_SIZE)
		
		local bufferPosition = ChunksUtil.chunkToBufferPosition(x, z, y)
		
		local blockId = buffer.readu8(ChunksData[chunkX][chunkZ][chunkY]['buffer'], bufferPosition)
		
		if blockId ~= AIR_ID then
			buffer.writeu8(ChunksData[chunkX][chunkZ][chunkY]['buffer'], bufferPosition, AIR_ID)
			local toRerender = {{chunkX, chunkZ, chunkY}}
			
			if x == 1 then
				table.insert(toRerender, {chunkX - 1, chunkZ, chunkY})
			elseif x == CHUNK_SIZE then
				table.insert(toRerender, {chunkX + 1, chunkZ, chunkY})
			end
			if z == 1 then
				table.insert(toRerender, {chunkX, chunkZ - 1, chunkY})
			elseif z == CHUNK_SIZE then
				table.insert(toRerender, {chunkX, chunkZ + 1, chunkY})
			end
			if y == 1 then
				table.insert(toRerender, {chunkX, chunkZ, chunkY - 1})
			elseif y == CHUNK_SIZE then
				table.insert(toRerender, {chunkX, chunkZ, chunkY + 1})
			end
			
			for _, chunk in toRerender do
				ChunkRenderer.unrenderChunk(chunk[1], chunk[2], chunk[3])
				ChunkRenderer.renderChunk(chunk[1], chunk[2], chunk[3])
			end
			return
		end
		
		lastRoundedPosition = roundedPosition
	end
end

-- EVENTS

UserInputService.InputBegan:Connect(handleInputBegan)

return Destroy