local EQUIPPED = {}

--// Services
local S_RUN = game:GetService('RunService')
local S_REPLICATED = game:GetService('ReplicatedStorage')
local S_SP = game:GetService('StarterPlayer')

--// Modules
local MODULES = S_SP.StarterPlayerScripts:FindFirstChild('MODULE_SCRIPTS')

local M_PLAYER_STATE = require(MODULES:FindFirstChild('PLAYER_STATE'))
local M_MODEL = require(MODULES:FindFirstChild('MODEL'))
local M_ITEM_DATA = require(S_REPLICATED:FindFirstChild('MODULE_SCRIPTS'):FindFirstChild('ITEM_DATA'))

--// Constants
local CAMERA = workspace.CurrentCamera
local VIEW_MODEL = workspace.VIEWMODEL ; VIEW_MODEL.Parent = CAMERA

local ANIMATION_CONTROLLER = VIEW_MODEL.AnimationController
local ANIMATOR = Instance.new('Animator')
ANIMATOR.Parent = ANIMATION_CONTROLLER

--// Variables
local punching: boolean = false
local equipped: BasePart

local animations: {[string] : Animation} = {}
local current_animation: AnimationTrack




function EQUIPPED.load_animations(punch_id: number)
	
	local punch_animation = Instance.new('Animation')
	punch_animation.AnimationId = `rbxassetid://{punch_id}`
	punch_animation.Parent = equipped
	animations['punch'] = punch_animation
end





--// Play punch animation
function EQUIPPED.punch()
	
	--TODO: cancel punch animation with another punch animation, don't spam this function	
	
	if punching or M_PLAYER_STATE['INVENTORY_OPENED'] then return end
	punching = true
	
	local punch_animation = ANIMATOR:LoadAnimation(animations['punch'])
	punch_animation.Priority = Enum.AnimationPriority.Action
	punch_animation.Looped = false
	punch_animation:Play(0)
	punch_animation:AdjustSpeed(1.2)
	
	local stopped_connection
	stopped_connection = punch_animation.Stopped:Connect(function()
		
		punching = false
		stopped_connection:Disconnect()
	end)
end





--// Updates the equipped item on the screen (where arm is)
function EQUIPPED.update_equipped(item_name: string)
	
	if equipped then
		equipped:Destroy()
	end
	
	equipped = S_REPLICATED.ITEMS:FindFirstChild(item_name):Clone()
	-- get ids
	
	if M_ITEM_DATA[item_name]['TYPE'] == 'BLOCK' then
		EQUIPPED.load_animations(13159806842)
	else
		EQUIPPED.load_animations(13159108455)
	end
	
	local part = equipped
	if equipped:IsA('Model') then
		part = equipped.PrimaryPart
		M_MODEL.start_weld(equipped)
		equipped:ScaleTo(1/3)
	end
	
	part.Anchored = false
	part.CanCollide = false
	
	local joint: Motor6D = Instance.new('Motor6D')
	joint.Parent = equipped
	joint.Part0 = VIEW_MODEL.CAMERA
	joint.Part1 = part
	
	-- Offset
	if M_ITEM_DATA[item_name]['TYPE'] == 'BLOCK' then -- Block
		equipped.Size = Vector3.new(.25, .25, .25)
		equipped.Name = 'DIRT' -- has to be called dirt cuz im stupid and dk how to change animation object name
		
		joint.C0 = CFrame.new(0.33, -0.29, -0.45) * 
			CFrame.Angles(
				math.rad(0),
				math.rad(47),
				math.rad(0)
			)
	else -- Arm
		joint.C0 = CFrame.new(0.6, -0.65, -0.75) * 
			CFrame.fromOrientation(
				math.rad(35),
				math.rad(-20),
				math.rad(-35)
			)
	end
	
	equipped.Parent = VIEW_MODEL
end



EQUIPPED.update_equipped('ARM')

S_RUN:BindToRenderStep('Camera', Enum.RenderPriority.Camera.Value + 1, function(dt: number)
	VIEW_MODEL:FindFirstChild('CAMERA').CFrame = CAMERA.CFrame
end)




return EQUIPPED


-- CAMERA part is anchored and its cframe is set to camera's
-- equipped object will not be anchored but it will be welded to camera object