--!strict
local Players = game:GetService('Players')
local ReplicatedFirst = game:GetService('ReplicatedFirst')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')

local LoadingScreenMessages = require(ReplicatedFirst.LoadingScreenMessages)

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild('PlayerGui')
local LoadingScreenGui = ReplicatedFirst:WaitForChild('LoadingScreenGui')
local LoadingBar = LoadingScreenGui:WaitForChild('LoadingBar')
local LoadingMessage = LoadingScreenGui:WaitForChild('LoadingMessage')

local X_PER_SECOND = 150

-- PRIVATE

function updateMessage(message: string): ()
	for _, gui in LoadingMessage:GetChildren() do
		gui.Text = message
	end
end


function updateBarLength(xSize: number): ()
	
	local barFrame = LoadingBar.BarFrame

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

	for i = 1, 4 do
	
		local xSize = i * 20
		local message = LoadingScreenMessages[i]
		
		updateBarLength(xSize)
		updateMessage(message)
		
		task.wait(xSize / X_PER_SECOND)
	end
	
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	LoadingScreenGui:Destroy()
end


-- Initalize
init()