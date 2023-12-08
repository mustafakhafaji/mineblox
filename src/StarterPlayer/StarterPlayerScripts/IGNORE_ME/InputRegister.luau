local InputRegister = {}

local UserInputService = game:GetService('UserInputService')
local StarterPlayer = game:GetService('StarterPlayer')

local InputTable = require(StarterPlayer.StarterPlayerScripts.Modules.InputTable)


--TODO: display each input on gui, good for testing and showing how game works

-- PRIVATE

function handleInputBegan(input: InputObject, typing: boolean)

	if typing then 
		return 
	end
	
	for input, _ in InputTable do
		if input.UserInputType == input then
			InputTable[input] = true
		end

		if input.KeyCode == input then
			InputTable[input.KeyCode] = true
		end
	end
end


function handleInputEnded(input: InputObject, typing: boolean)

	if typing then
		return 
	end
   
   for input, _ in InputTable do
	   if input.UserInputType == input then
		   InputTable[input] = false
	   end

	   if input.KeyCode == input then
		   InputTable[input.KeyCode] = false
	   end
   end
end

-- EVENTS

UserInputService.InputBegan:Connect(handleInputBegan)
UserInputService.InputEnded:Connect(handleInputEnded)


-- Initalize
UserInputService.MouseIconEnabled = false


return InputRegister