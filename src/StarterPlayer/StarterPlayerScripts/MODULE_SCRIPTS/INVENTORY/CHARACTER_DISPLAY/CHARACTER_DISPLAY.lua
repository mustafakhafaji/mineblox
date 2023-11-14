local CHARACTER_DISPLAY = {}

--// Services
local S_PLAYERS = game:GetService('Players')
local S_RUN = game:GetService('RunService')

--// Modules
local M_BODY_PARTS = require(script:WaitForChild('BODY_PARTS'))

--// Constants
local PLAYER = S_PLAYERS.LocalPlayer
local MOUSE = PLAYER:GetMouse()
local CAMERA = workspace.CurrentCamera

local PLAYER_GUI = PLAYER:WaitForChild('PlayerGui'):WaitForChild('SCREENGUI')
local INVENTORY_GUI = PLAYER_GUI:WaitForChild('INVENTORY'):WaitForChild('INVENTORY'):WaitForChild('INVENTORY')

--// Variables
local moving_character
local inventory_character


--[[ PUBLIC ]]--

--// Create the character display viewport frame in gui
function CHARACTER_DISPLAY.init()
	
	-- Wait until PLAYER's character is loaded in
	for _, body_part_name in M_BODY_PARTS do
		PLAYER.Character:WaitForChild(body_part_name)
	end

	local player_viewportframe = INVENTORY_GUI:FindFirstChild('PLAYER'):FindFirstChild('ViewportFrame')

	PLAYER.Character.Archivable = true
	inventory_character = S_PLAYERS:CreateHumanoidModelFromUserId(PLAYER.UserId) -- failed because http500 (internal server error)
	inventory_character.Parent = player_viewportframe
	
	local new_camera = Instance.new('Camera')
	new_camera.CFrame = inventory_character.HumanoidRootPart.CFrame * CFrame.new(0, 1, -9.5) * CFrame.Angles(math.rad(5), math.rad(180), 0)
	new_camera.FieldOfView = 40
	new_camera.Parent = player_viewportframe

	player_viewportframe.CurrentCamera = new_camera
end




--TODO: make only torso rotate, add extra rotation to head; welds and motor6s dont work in viewportframes
-- possibly render the character in workspace then copy each cframe into viewport frame
--// Character starts pointing towards cursor
function CHARACTER_DISPLAY.start()
	
	--TODO fix: orientation math
	local screen_x_size = CAMERA.ViewportSize.X
	local screen_y_size = CAMERA.ViewportSize.Y
	
	moving_character = S_RUN.Heartbeat:Connect(function()
		
		local mouse_x_percent = MOUSE.X / screen_x_size
		local mouse_y_percent = MOUSE.Y / screen_y_size
		
		--TODO: find max rotation, * it by x percent
		
		
		
		local x, y, z = CFrame.new(
			Vector3.new(0, 1, -9.5),
			Vector3.new(MOUSE.x, -MOUSE.y, 1000)
		):ToOrientation()
		
		
		inventory_character:SetPrimaryPartCFrame(
			CFrame.new(inventory_character.PrimaryPart.Position) * 
				CFrame.fromOrientation(
					math.rad(x * 50),
					math.rad(y * 50),
					math.rad(z)) *
				CFrame.Angles(
					0,
					math.rad(130),
					0)
		)
	end)
end




--// Character stops pointing
function CHARACTER_DISPLAY.stop()
	
	moving_character:Disconnect()
	moving_character = nil
end

return CHARACTER_DISPLAY