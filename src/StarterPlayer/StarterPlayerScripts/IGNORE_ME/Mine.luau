local module = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local StarterPlayer = game:GetService('StarterPlayer')

local Modules = StarterPlayer.StarterPlayerScripts.Modules
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)
local Selection = require(Modules.Selection)
local Equipped = require(Modules.Equipped)
local ChunkLoading = require(Modules.ChunkLoading)
local Model = require(Modules.Model)

local Faces = {Enum.NormalId.Top, Enum.NormalId.Bottom, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Front, Enum.NormalId.Back}
local NUMBER_OF_STAGES = 9

local blockBeingMined = nil
local punched = false
local isMining = false

local mining: RBXScriptConnection
local mineCheck: RBXScriptConnection


-- PRIVATE

function animateBlockJump(dropItem: string)
	
end

function destroyBlock()
	
	local dropItem = ItemsData[block_being_mined.Name]['DROP']
	
	if dropItem then 
		animateBlockJump(dropItem) 
	end
	
	if 
		block_being_mined.Parent 
		and block_being_mined.Parent:IsA('Model') 
	then -- Destroy model
		block_being_mined.Parent:Destroy()
		
	else -- If block, cull around it
		
		M_CHUNK_LOADING.cull(block_being_mined.Position)
		block_being_mined:Destroy()
	end
end

-- Handles blocks with hardness of 0
function break_block_instantly()
	
end


function end_mine()
	
	block_being_mined = nil
	is_mining = false
end


function check_hovering()
	
	local current_hovering = Selection.get_hovering()
	if current_hovering ~= block_being_mined then
		end_mine()
	end
end


function check_normal(normal: Vector3): ()
	
	local current_normal = Selection.get_normal()
	if current_normal ~= normal then

	end
end


function get_break_time(blockName: string): (number)

	local block_hardness = M_ITEM_DATA[block_name]['HARDNESS']
	local block_preferred_tool = M_ITEM_DATA[block_name]['PREFERRED_TOOL']

	-- get current tool being used
	-- get current tool level
end


function startMine(break_time: number)
	
	isMining = true
	
	local stage = 1
	local stageInterval = break_time / NUMBER_OF_STAGES
	local stageCheck = os.clock()
	
	local normal = Selection.getNormal()
	--M_EQUIPPED.punch()
	
	mining = RunService.RenderStepped:Connect(function()
		
		check_hovering()
		
		-- TODO
		-- tell module to start punch (keeps punching endlessly)
		-- tell module to stop punch (stops animation of punching)
		Equipped.punch()


		
		
	end)
end


-- Handle left click (punch, break block, start mining)
function leftClickStart()
	
	local currentTarget = Selection.getHovering()
	
	if not currentTarget then -- Punch
		punched = true
		Equipped.punch()
		return
	end
	
	block_being_mined = current_target
	local breakTime = get_break_time(current_target.Name)
	
	if breakTime == 0 then
		Equipped.punch()
		destroyBlock()
		return
	end
	
	startMine(breakTime)
end


-- Handle ending left click (reset punch, ending mining)
function leftClickEnd()
	
	if isMining then
		endMine()
	end
	
	punched = false
end


function handleInputBegan(input: InputObject, typing: boolean)
	if typing then 
		return 
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		leftClickStart()
	end
end

function handleInputEnded(input: InputObject, typing: boolean)
	if typing then 
		return 
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		leftClickEnd()
	end
end


-- EVENTS

UserInputService.InputBegan:Connect(handleInputBegan)
UserInputService.InputEnded:Connect(handleInputEnded)


return module