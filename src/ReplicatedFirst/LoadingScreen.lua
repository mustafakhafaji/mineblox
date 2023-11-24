--!strict

local Players = game:GetService('Players')
local ReplicatedFirst = game:GetService('ReplicatedFirst')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild('PlayerGui')
local LoadingScreenGui = ReplicatedFirst:WaitForChild('LoadingScreenGui')
local loadingBarFolder = LoadingScreenGui:WaitForChild('LoadingBarFolder')
local loadingMessageFolder = LoadingScreenGui:WaitForChild('LoadingMessageFolder')

local X_PER_SECOND = 150

local LOAD_INFO = 
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

-- PRIVATE

function updateMessage(message: string): ()
	for _, gui in loadingMessageFolder:GetChildren() do
		gui.Text = message
	end
end


local function updateBar(xSize: number): ()
	
	local barFrame = loadingBarFolder.BarFrame

	local tween = TweenService:Create(
		barFrame,
		TweenInfo.new(xSize / X_PER_SECOND),
		{
			Size = UDim2.new(0, xSize, 0, barFrame.Size.Y.Offset)
		}
	)
	tween:Play()
end


function init(): ()

	LoadingScreenGui.Parent = PlayerGui
	ReplicatedFirst:RemoveDefaultLoadingScreen()
	UserInputService.MouseIconEnabled = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	for _, info in LOAD_INFO do
	
		local x_size = info[1]
		local message = info[2]
		
		updateBar(x_size)
		updateMessage(message)
		
		task.wait(x_size / X_PER_SECOND)
	end
	
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	LoadingScreenGui:Destroy()
end

-- Init
init()