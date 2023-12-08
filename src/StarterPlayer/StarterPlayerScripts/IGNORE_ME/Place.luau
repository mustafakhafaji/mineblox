local Place = {}

local UserInputService = game:GetService('UserInputService')
local StarterPlayer = game:GetService('StarterPlayer')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Modules = StarterPlayer.StarterPlayerScripts.Modules
local ChunkSettings = require(ReplicatedStorage.Shared.ChunkSettings)
local Selection = require(Modules.Selection)
local InputTable = require(Modules.InputTable)
local Equipped = require(Modules.Equipped)

local BLOCK_SIZE = ChunkSettings['BLOCK_SIZE']
local MAX_HEIGHT = ChunkSettings['MAX_HEIGHT']


-- PRIVATE

function getPlaceWorldPosition(raycastInstance: BasePart, raycastNormal: Vector3): (Vector3)
	
	local offset = Vector3.new(
		raycastNormal.X * BLOCK_SIZE,
		raycastNormal.Y * BLOCK_SIZE, 
		raycastNormal.Z * BLOCK_SIZE
	)

	return raycastInstance.Position + offset
end


function place(): ()
	
	-- get equipped item
	
	-- place relative to current hovering and normal id
	if Selection.getHovering() then
		getPlaceWorldPosition(Selection.getHovering(), Selection.getNormal())
	end
	
	-- subtract from inventory
	
	-- if still right clicking and its been over .1 seconds then place again
	
end


function endPlace(): ()
	
end


function handleInputBegan(input: InputObject, typing: boolean): ()
	if typing then 
		return
	end
	
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		place()
	end
end


function handleInputEnded(input: InputObject, typing: boolean): ()
	if typing then 
		return 
	end
	
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		endPlace()
	end
end

-- EVENTS

UserInputService.InputBegan:Connect(handleInputBegan)
UserInputService.InputEnded:Connect(handleInputEnded)

return Place