local ChunkRenderer = {}

-- 3333 max blocks, if face culling implemented
-- = 8 * 8 * 52 = 3328 blocks
--local buffer = buffer.create(12288)

local AssetService = game:GetService("AssetService")
local Atlas = AssetService:CreateEditableImageAsync("rbxassetid://17400483416")
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local StarterPlayer = game:GetService("StarterPlayer")

local ChunksData = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Data.ChunksData)
local BlockMeshData = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Rendering.Data.BlockMeshData)
local PlantMeshData = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Rendering.Data.PlantMeshData)
local AtlasTextureData = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Rendering.Data.AtlasTextureData)
local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local ChunksUtil = require(ReplicatedStorage.Shared.ChunksUtil)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)

local CHUNK_SIZE: number = ChunkSettings['CHUNK_SIZE']
local BLOCK_SIZE: number = ChunkSettings['BLOCK_SIZE']

local AIR_ID: number = ItemsData['Air']['ID']

local ATLAS_SIZE: number = 8

local faceOrder = {
	{BlockMeshData.frontVertices, BlockMeshData.frontIndices},
	{BlockMeshData.backVertices, BlockMeshData.backIndices},
	{BlockMeshData.rightVertices, BlockMeshData.rightIndices},
	{BlockMeshData.leftVertices, BlockMeshData.leftIndices},
	{BlockMeshData.topVertices, BlockMeshData.topIndices},
	{BlockMeshData.bottomVertices, BlockMeshData.bottomIndices}
}

local BLOCK_NEIGHBOUR_VECTORS = 
	{
		Vector3.new(0, 0, BLOCK_SIZE),
		Vector3.new(0, 0, -BLOCK_SIZE),
		Vector3.new(BLOCK_SIZE, 0, 0),
		Vector3.new(-BLOCK_SIZE, 0, 0),
		Vector3.new(0, BLOCK_SIZE, 0),
		Vector3.new(0, -BLOCK_SIZE, 0),
	}

-- PRIVATE

function createFace(EditableMesh: EditableMesh, faceVertices, faceIndices, blockId, faceId, x, z, y)
	local vertices = {}
	for _, vertexOffset in faceVertices do
		local vertexPosition = Vector3.new(x + vertexOffset.X, y + vertexOffset.Y, z + vertexOffset.Z)
		local vertexId = EditableMesh:AddVertex(vertexPosition)
		table.insert(vertices, vertexId)
	end
	for i = 1, 4, 3 do
		local vertexId0Position = faceIndices[i]
		local vertexId1Position = faceIndices[i + 1]
		local vertexId2Position = faceIndices[i + 2]
		EditableMesh:AddTriangle(vertices[vertexId0Position], vertices[vertexId1Position], vertices[vertexId2Position])
	end

	-- Find face's texture in atlas -> set vertice's UVs to texture's corner
	local texturePosition = AtlasTextureData[blockId][faceId]
	local x = texturePosition % ATLAS_SIZE - 1
	local y = texturePosition // ATLAS_SIZE
	EditableMesh:SetUV(vertices[1], Vector2.new(x / ATLAS_SIZE, y / ATLAS_SIZE)) -- Top left of image
	EditableMesh:SetUV(vertices[2], Vector2.new((x + 1) / ATLAS_SIZE, y / ATLAS_SIZE)) -- Top right of image
	EditableMesh:SetUV(vertices[3], Vector2.new(x / ATLAS_SIZE, (y + 1) / ATLAS_SIZE)) -- Bottom left of image 
	EditableMesh:SetUV(vertices[4], Vector2.new((x + 1) / ATLAS_SIZE, (y + 1) / ATLAS_SIZE) ) --  Bottom right of image
end


function getShouldSidesRender(chunkX: number, chunkZ: number, chunkY: number, x: number, z: number, y: number): {}
	local shouldSidesRender = {false, false, false, false, false, false}
	local worldPosition = ChunksUtil.chunkToWorldPosition(chunkX, chunkZ, chunkY, x, z, y)
	
	for i, offsetVector in BLOCK_NEIGHBOUR_VECTORS do
		local neighborWorldPosition = Vector3.new(
			worldPosition.X + offsetVector.X,
			worldPosition.Y + offsetVector.Y,
			worldPosition.Z + offsetVector.Z
		)
		
		local neighborChunkPosition = ChunksUtil.worldToChunkPosition(neighborWorldPosition)
		local neighborChunkX = neighborChunkPosition[1]
		local neighborChunkZ = neighborChunkPosition[2]
		local neighborChunkY = neighborChunkPosition[3]
		local neighborX = neighborChunkPosition[4]
		local neighborZ = neighborChunkPosition[5]
		local neighborY = neighborChunkPosition[6]
		
		local bufferPosition = ChunksUtil.chunkToBufferPosition(neighborX, neighborZ, neighborY)

		shouldSidesRender[i] = buffer.readu8(ChunksData[neighborChunkX][neighborChunkZ][neighborChunkY]['buffer'], bufferPosition) == AIR_ID
	end
	return shouldSidesRender
end

-- PUBLIC

function ChunkRenderer.renderChunk(chunkX: number, chunkZ: number, chunkY: number): ()
	local MeshPart = Instance.new('MeshPart')
	MeshPart.Name = `{chunkX}x{chunkZ}x{chunkY}`
	MeshPart.Size = Vector3.new(BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
	MeshPart.CanCollide = false
	MeshPart.Anchored = true
	
	local EditableMesh = Instance.new('EditableMesh')
	local EditableImage = Atlas:Clone()
	
	local loadedChunkBlocks: buffer = ChunksData[chunkX][chunkZ][chunkY]['buffer']

	for x = 1, CHUNK_SIZE do
		local bufferPositionX = (x - 1) * CHUNK_SIZE
		
		for z = 1, CHUNK_SIZE do
			local bufferPositionZ = (z - 1) * CHUNK_SIZE * CHUNK_SIZE
			
			for y = 1, CHUNK_SIZE do
				local blockId = buffer.readu8(loadedChunkBlocks, bufferPositionX + bufferPositionZ + (y - 1))
				if 
					not blockId
					or blockId == AIR_ID
					or not AtlasTextureData[blockId]
				then 
					continue 
				end

				local shouldSidesRender: {} = getShouldSidesRender(chunkX, chunkZ, chunkY, x, z, y)
				for faceId, shouldRender in shouldSidesRender do
					if not shouldRender then
						continue
					end

					local faceVertices = faceOrder[faceId][1]
					local faceIndices = faceOrder[faceId][2]

					createFace(EditableMesh, faceVertices, faceIndices, blockId, faceId, x, z, y)
				end
			end
		end
	end
	
	EditableMesh.Parent = MeshPart
	EditableImage.Parent = MeshPart
	MeshPart.Position = Vector3.new(
		chunkX * CHUNK_SIZE * BLOCK_SIZE,
		chunkY * CHUNK_SIZE * BLOCK_SIZE,
		chunkZ * CHUNK_SIZE * BLOCK_SIZE
	)
	MeshPart.Parent = workspace
end


function ChunkRenderer.unrenderChunk(chunkX: number, chunkZ: number, chunkY: number): ()
	if workspace:FindFirstChild(`{chunkX}x{chunkZ}x{chunkY}`) then
		workspace:FindFirstChild(`{chunkX}x{chunkZ}x{chunkY}`):Destroy()
	end
end


return ChunkRenderer