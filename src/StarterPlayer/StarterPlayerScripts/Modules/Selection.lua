--!strict
local Selection = {}

local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local StarterPlayer = game:GetService('StarterPlayer')
local GuiService = game:GetService('GuiService')

local Modules = StarterPlayer.StarterPlayerScripts.Modules
local PlayerState = require(Modules.PlayerState)

local Player = Players.LocalPlayer
local SelectionOutline = workspace.Extra.SelectionOutline

local RAYCAST_DISTANCE = 13.5

local MAX_DISTANCE = 15
local MAX_THICKNESS = .025
local MIN_THICKNESS = .004

local INSET = GuiService:GetGuiInset()

local hovering = nil
local normal = nil
local position = nil

local filter = {workspace.Map}

-- PRIVATE

function getRaycast(): (RaycastResult | nil)
	
	if PlayerState['InventoryOpened'] then
		return
	end
	
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = filter

	local camera = workspace.CurrentCamera
	local mouse = UserInputService:GetMouseLocation()
	local unitRay = camera:ScreenPointToRay(mouse.x, mouse.y - INSET.Y)

	return workspace:Raycast(
		unitRay.Origin,
		unitRay.Direction * RAYCAST_DISTANCE,
		raycastParams
	)
end


function resetValues(): ()
	normal = nil
	hovering = nil
	SelectionOutline.Adornee = nil
end


function updateSelection(): ()

	if 	
		not Player.Character 
		or not Player.Character:FindFirstChild('HumanoidRootPart') 
	then 
		return 
	end

	local raycast = getRaycast()

	if not raycast then
		resetValues()
		return
	end

	local currentHovering = raycast.Instance
	local currentNormal = raycast.Normal

	local HumanoidRootPart = Player.Character.HumanoidRootPart
	local distance = (HumanoidRootPart.Position - raycast.Position).Magnitude

	SelectionOutline.LineThickness = math.clamp((distance / 15) * MAX_THICKNESS, MIN_THICKNESS, MAX_DISTANCE) 

	if hovering ~= currentHovering then

		hovering = currentHovering
		SelectionOutline.Adornee = hovering
	end

	if normal ~= currentNormal then
		normal = currentNormal
	end
end


-- PUBLIC 

function Selection.getHovering(): (BasePart | nil)
	return hovering
end


function Selection.getNormal(): (Vector3 | nil)
	return normal
end


function Selection.getPosition(): (Vector3 | nil)
	return position
end


-- EVENTS
RunService.RenderStepped:Connect(updateSelection)


return Selection