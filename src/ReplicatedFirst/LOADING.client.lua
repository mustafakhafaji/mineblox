--!strict

-- Loading
-- 2nix
-- April 17, 2023

--[=[


]=]

--// Services
local rf = game:GetService('ReplicatedFirst')
local ts = game:GetService('TweenService')
local players = game:GetService('Players')
local uis = game:GetService('UserInputService')

--// Variables
local player = players.LocalPlayer
local player_gui = player:WaitForChild('PlayerGui')
local loading_gui = script:WaitForChild('LOADING_SCREEN_GUI')

local loading_bar = loading_gui:WaitForChild('LOADING_GUI'):WaitForChild('LOADING_BAR'):WaitForChild('BAR')
local loading_message 	= loading_gui:WaitForChild('LOADING_GUI'):WaitForChild('MESSAGE')

local X_PER_SECOND = 150

--// Init
loading_gui.Parent = player_gui
rf:RemoveDefaultLoadingScreen()
uis.MouseIconEnabled = false
uis.MouseBehavior = Enum.MouseBehavior.LockCenter




--// Functions

local function update_message(message: string)
	for _, gui in loading_message:GetChildren() do
		gui.Text = message
	end
end





local function update_bar(x_size: number)
	
	local tween = ts:Create(
		loading_bar,
		TweenInfo.new(x_size / X_PER_SECOND),
		{
			Size = UDim2.new(0, x_size, 0, loading_bar.Size.Y.Offset)
		}
	)
	tween:Play()
end





local load_info = 
	{
		{
			20,
			'downloading textures',
		},
		
		{
			60,
			'building terrain',
		},
		
		{
			100,
			'connecting to the server',
		},
		
		{
			200,
			'joining world',
		}
	}



for _, info in load_info do
	
	local x_size = info[1]
	local message = info[2]
	
	update_bar(x_size)
	update_message(message)
	
	task.wait(x_size / X_PER_SECOND)
end

uis.MouseBehavior = Enum.MouseBehavior.Default
loading_gui:Destroy()