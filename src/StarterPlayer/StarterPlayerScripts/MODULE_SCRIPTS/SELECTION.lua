--!strict
local SELECTION = {}

--// Services
local S_UIS = game:GetService('UserInputService')
local S_RUN = game:GetService('RunService')
local S_PLAYERS = game:GetService('Players')
local S_SP = game:GetService('StarterPlayer')
local S_GUI = game:GetService('GuiService')

--// Modules
local MODULES = S_SP.StarterPlayerScripts.MODULE_SCRIPTS
local M_PLAYER_STATE = require(MODULES.PLAYER_STATE)

--// Constants
local PLAYER = S_PLAYERS.LocalPlayer
local SELECTION_BOX = workspace.EXTRA.SELECTION

local RAYCAST_DISTANCE = 13.5

local MAX_DISTANCE = 15
local MAX_THICKNESS = .025
local MIN_THICKNESS = .004

local INSET = S_GUI:GetGuiInset()

--// Variables
local hovering = nil
local normal = nil
local position = nil

local filter = {workspace.MAP}

--[[ PRIVATE ]]--

local function get_raycast(): RaycastResult | nil
	
	if M_PLAYER_STATE['INVENTORY_OPENED'] then return end
	
	local raycast_params = RaycastParams.new()
	raycast_params.FilterType = Enum.RaycastFilterType.Include
	raycast_params.FilterDescendantsInstances = filter

	local camera = workspace.CurrentCamera
	local mouse = S_UIS:GetMouseLocation()
	local unit_ray = camera:ScreenPointToRay(mouse.x, mouse.y - INSET.Y)

	return workspace:Raycast(
		unit_ray.Origin,
		unit_ray.Direction * RAYCAST_DISTANCE,
		raycast_params
	)
end




--[[ PUBLIC ]]--

function SELECTION.get_hovering(): BasePart | nil
	return hovering
end


function SELECTION.get_normal(): Vector3 | nil
	return normal
end


function SELECTION.get_position(): Vector3 | nil
	return position
end



local function reset_values()
	normal = nil
	hovering = nil
	SELECTION_BOX.Adornee = nil
end





S_RUN.RenderStepped:Connect(function()

	if not PLAYER.Character or not PLAYER.Character:FindFirstChild('HumanoidRootPart') then return end

	local raycast = get_raycast()

	if not raycast then -- Raycast at nothing
		reset_values()
		return
	end
	
	local current_hovering = raycast.Instance
	local current_normal = raycast.Normal

	local hrp = PLAYER.Character.HumanoidRootPart
	local distance = (hrp.Position - raycast.Position).Magnitude

	SELECTION_BOX.LineThickness = math.clamp((distance / 15) * MAX_THICKNESS, MIN_THICKNESS, MAX_DISTANCE) 
	
	if hovering ~= current_hovering then

		hovering = current_hovering
		SELECTION_BOX.Adornee = hovering
	end
	
	if normal ~= current_normal then
		normal = current_normal
	end
end)


return SELECTION