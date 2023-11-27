local Time = {}

local Lighting = game:GetService('Lighting')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local currentTime = Lighting.ClockTime
local nextCheck = os.clock()

-- TODO Just send client the time when joining then they update it

-- PRIVATE

function advanceTime()
	
	if os.clock() > nextCheck then

		currentTime += .1

		if currentTime >= 24 then
			currentTime = 0
		end

		--S_LIGHTING.ClockTime = current_time

		nextCheck += 10
	end
end


function handleGetTime()
	return currentTime
end


-- EVENTS

RunService.Heartbeat:Connect(advanceTime)
RunService.REMOTES.GetTime.OnServerInvoke = handleGetTime()

return Time