local module = {}

--// Services
local S_REPLICATED = game:GetService('ReplicatedStorage')
local S_RUN = game:GetService('RunService')
local S_UIS = game:GetService('UserInputService')
local S_TS = game:GetService('TweenService')
local S_SP = game:GetService('StarterPlayer')

--// Modules
local MODULE_SCRIPTS = S_SP.StarterPlayerScripts.MODULE_SCRIPTS
local M_ITEM_DATA = require(S_REPLICATED.MODULE_SCRIPTS.ITEM_DATA)
local M_SELECTION = require(MODULE_SCRIPTS.SELECTION)
local M_EQUIPPED = require(MODULE_SCRIPTS.EQUIPPED)
local M_CHUNK_LOADING = require(MODULE_SCRIPTS.CHUNK_LOADING)
local M_MODEL = require(MODULE_SCRIPTS.MODEL)
local M_FACES = require(script.FACES)

--// Constants
local FACES = {Enum.NormalId.Top, Enum.NormalId.Bottom, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Front, Enum.NormalId.Back}
local NUMBER_OF_STAGES = 9

--// Variables
local block_being_mined = nil
local punched = false
local is_mining = false

local mining: RBXScriptConnection
local mine_check: RBXScriptConnection


--[[ PRIVATE ]]--

local function animate_block_jump(drop_item: string)
	
end

local function destroy_block()
	
	local drop_item = M_ITEM_DATA[block_being_mined.Name]['DROP']
	
	if drop_item then animate_block_jump(drop_item) end
	
	if block_being_mined.Parent and block_being_mined.Parent:IsA('Model') then -- Destroy model
		block_being_mined.Parent:Destroy()
		
	else -- If block, cull around it
		
		M_CHUNK_LOADING.cull(block_being_mined.Position)
		block_being_mined:Destroy()
	end
end

--// Handles blocks with hardness of 0
local function break_block_instantly()
	
end


local function end_mine()
	
	block_being_mined = nil
	is_mining = false
end

local function check_hovering()
	
	local current_hovering = M_SELECTION.get_hovering()
	if current_hovering ~= block_being_mined then
		end_mine()
	end
end

local function check_normal(normal: Vector3)
	
	local current_normal = M_SELECTION.get_normal()
	if current_normal ~= normal then

	end
end

local function get_break_time(block_name: string): number

	local block_hardness = M_ITEM_DATA[block_name]['HARDNESS']
	local block_preferred_tool = M_ITEM_DATA[block_name]['PREFERRED_TOOL']

	-- get current tool being used
	-- get current tool level
end




local function start_mine(break_time: number)
	
	is_mining = true
	
	local stage = 1
	local stage_interval = break_time / NUMBER_OF_STAGES
	local stage_check = os.clock()
	
	local normal = M_SELECTION.get_normal()
	--M_EQUIPPED.punch()
	
	mining = S_RUN.RenderStepped:Connect(function()
		
		check_hovering()
		
		-- TODO
		-- tell module to start punch (keeps punching endlessly)
		-- tell module to stop punch (stops animation of punching)
		M_EQUIPPED.punch()


		
		
	end)
end



--// Handle left click (punch, break block, start mining)
local function left_click_start()
	
	local current_target = M_SELECTION.get_hovering()
	
	if not current_target then -- Punch
		punched = true
		M_EQUIPPED.punch()
		return
	end
	
	block_being_mined = current_target
	local break_time = get_break_time(current_target.Name)
	
	if break_time == 0 then
		M_EQUIPPED.punch()
		destroy_block()
		return
	end
	
	start_mine(break_time)
end




--// Handle ending left click (reset punch, ending mining)
local function left_click_end()
	
	if is_mining then
		end_mine()
	end
	
	punched = false
end




--[[ EVENTS ]]--

S_UIS.InputBegan:Connect(function(input, typing)
	if typing then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		left_click_start()
	end
end)

S_UIS.InputEnded:Connect(function(input, typing)
	if typing then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		left_click_end()
	end
end)



return module