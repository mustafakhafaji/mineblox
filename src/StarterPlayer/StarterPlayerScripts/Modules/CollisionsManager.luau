local CollisionsManager = {}

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local StarterPlayer = game:GetService('StarterPlayer')

local ChunksData = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Data.ChunksData)
local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)

local CHUNK_SIZE: number = ChunkSettings['CHUNK_SIZE']
local BLOCK_SIZE: number = ChunkSettings['BLOCK_SIZE']

local AIR_ID: number = ItemsData['Air']['ID']

local Player: Player = Players.LocalPlayer

local CollisionParts: Folder = workspace.CollisionParts
local collisionParts = {}

local IS_DEBUGGING: boolean = false

for i = 1, 10 do
	local collisionPart: BasePart = Instance.new('Part')
	collisionPart.Transparency = 1
	collisionPart.Material = Enum.Material.Neon
	collisionPart.Color = Color3.fromRGB(52, 255, 0)
	collisionPart.Anchored = true
	collisionPart.CanCollide = true
	collisionPart.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
	if IS_DEBUGGING then
		collisionPart.Transparency = .9
		collisionPart.Size = Vector3.new(BLOCK_SIZE + .01, BLOCK_SIZE + .01, BLOCK_SIZE + .01)
	end
	collisionPart.Parent = CollisionParts
	table.insert(collisionParts, collisionPart)
end


function roundToNearest(value: number, snap: number): number
	return math.round(value / snap) * snap
end


function updateCollisionParts()
	local Character: Model? = Player.Character
	if not Character or not Character:FindFirstChild('HumanoidRootPart') then
		return
	end
	
	local characterPosition: Vector3 = Character.HumanoidRootPart.Position
	local roundedPosition: Vector3 = Vector3.new(
		roundToNearest(characterPosition.X, BLOCK_SIZE),
		roundToNearest(characterPosition.Y - 1, BLOCK_SIZE),
		roundToNearest(characterPosition.Z, BLOCK_SIZE)
	)
	
	local surroundingBlockPositions: {Vector3} = {}
	
	for worldX = roundedPosition.X - BLOCK_SIZE, roundedPosition.X + BLOCK_SIZE, BLOCK_SIZE do
		for worldZ = roundedPosition.Z - BLOCK_SIZE, roundedPosition.Z + BLOCK_SIZE, BLOCK_SIZE do
			for worldY = roundedPosition.Y - BLOCK_SIZE, roundedPosition.Y + BLOCK_SIZE, BLOCK_SIZE do
				local chunkPosition = ChunksUtil.worldToChunkPosition(Vector3.new(worldX, worldY, worldZ))
				local chunkX = chunkPosition[1]
				local chunkZ = chunkPosition[2]
				local chunkY = chunkPosition[3]
				local x = chunkPosition[4]
				local z = chunkPosition[5]
				local y = chunkPosition[6]
				
				if 
					not ChunksData[chunkX] 
					or not ChunksData[chunkX][chunkZ]
					or not ChunksData[chunkX][chunkZ][chunkY]
				then
					continue
				end
				local chunkBlocks: buffer = ChunksData[chunkX][chunkZ][chunkY]['buffer']
				
				local bufferPosition = ChunksUtil.chunkToBufferPosition(x, z, y)
				if buffer.readu8(chunkBlocks, bufferPosition) == AIR_ID then
					continue
				end
				table.insert(surroundingBlockPositions, Vector3.new(worldX, worldY, worldZ))
			end
		end
	end

	table.sort(surroundingBlockPositions, function(a, b)
		return 
			(a.X - roundedPosition.X) ^ 2 + (a.Y - roundedPosition.Y) ^ 2 + (a.Z - roundedPosition.Z) ^ 2 
			<
			(b.X - roundedPosition.X) ^ 2 + (b.Y - roundedPosition.Y) ^ 2 + (b.Z - roundedPosition.Z) ^ 2 
	end)
	
	for i = 1, #collisionParts do
		if not surroundingBlockPositions[i] then
			collisionParts[i].Position = Vector3.new(0, -1000, 0)
			continue
		end
		collisionParts[i].Position = surroundingBlockPositions[i]
	end
end

RunService.PreRender:Connect(updateCollisionParts)

return CollisionsManager