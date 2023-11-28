local Time = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local startTime = os.time()

-- TODO Just send client the time when joining then they update it

-- PRIVATE

function handleGetTime(): (number)
	return startTime
end


-- EVENTS

ReplicatedStorage.Remotes.GetTime.OnServerInvoke = handleGetTime()

return Time