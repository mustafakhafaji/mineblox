local INPUT_REGISTER = {}

--// Services
local S_UIS = game:GetService('UserInputService')
local S_SP = game:GetService('StarterPlayer')

--// Modules
local M_INPUT_TABLE = require(S_SP.StarterPlayerScripts.MODULE_SCRIPTS.INPUT_TABLE)


--TODO: display each input on gui, good for testing and showing how game works

--// Update inputs triggered
S_UIS.InputBegan:Connect(function(current_input, typing)
	if typing then return end
	
	for input, _ in M_INPUT_TABLE do
		if current_input.UserInputType == input then
			M_INPUT_TABLE[input] = true
		end

		if current_input.KeyCode == input then
			M_INPUT_TABLE[current_input.KeyCode] = true
		end
	end
end)


S_UIS.InputEnded:Connect(function(current_input, typing)
	if typing then return end
	
	for input, _ in M_INPUT_TABLE do
		if current_input.UserInputType == input then
			M_INPUT_TABLE[input] = false
		end

		if current_input.KeyCode == input then
			M_INPUT_TABLE[current_input.KeyCode] = false
		end
	end
end)


--// Initalize
S_UIS.MouseIconEnabled = false


return INPUT_REGISTER