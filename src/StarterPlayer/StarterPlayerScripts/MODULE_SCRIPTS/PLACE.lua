local PLACE = {}

--// Services
local S_UIS = game:GetService('UserInputService')
local S_SP = game:GetService('StarterPlayer')
local S_RS = game:GetService('ReplicatedStorage')

--// Modules
local MODULES = S_SP.StarterPlayerScripts:FindFirstChild('MODULE_SCRIPTS')
local M_CHUNK_SETTINGS = require(S_RS.MODULE_SCRIPTS.CHUNK_SETTINGS)
local M_SELECTION = require(MODULES.SELECTION)
local M_INPUT_TABLE = require(MODULES.INPUT_TABLE)
local M_EQUIPPED = require(MODULES.EQUIPPED)

--// Constants
local BLOCK_SIZE = M_CHUNK_SETTINGS['BLOCK_SIZE']
local MAX_HEIGHT = M_CHUNK_SETTINGS['MAX_HEIGHT']

local NORMAL_OFFSETS = 
	{
		[Vector3.new(1, 0, 0)]   = Vector3.new(BLOCK_SIZE, 0, 0),
		[Vector3.new(-1, 0, 0)]  = Vector3.new(-BLOCK_SIZE, 0, 0),
		[Vector3.new(0, 1, 0)]   = Vector3.new(0, BLOCK_SIZE, 0),
		[Vector3.new(0, -1, 0)]  = Vector3.new(0, -BLOCK_SIZE, 0),
		[Vector3.new(0, 0, 1)]   = Vector3.new(0, 0, BLOCK_SIZE),
		[Vector3.new(0, 0, -1)]  = Vector3.new(0, 0, -BLOCK_SIZE),
		
	}

--[[ PRIVATE ]]--

local function get_world_position(raycast_instance: BasePart, raycast_normal: Vector3)
	
	local hit_world_position = raycast_instance.Position
	
	local offset = NORMAL_OFFSETS[raycast_normal]
	
	return hit_world_position + offset
end


local function place()
	
	-- get equipped item
	
	-- place relative to current hovering and normal id
	if M_SELECTION.get_hovering() then
		get_world_position(M_SELECTION.get_hovering(), M_SELECTION.get_normal())
	end
	
	-- subtract from inventory
	
	-- if still right clicking and its been over .1 seconds then place again
	
end





local function end_place()
	
end





S_UIS.InputBegan:Connect(function(input, typing)
	if typing then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		place()
	end
end)

S_UIS.InputEnded:Connect(function(input, typing)
	if typing then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		end_place()
	end
end)




return PLACE