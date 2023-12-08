local Time = {}

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local startTime = os.time()

-- TODO Just send client the time when joining then they update it

-- PRIVATE

function handleRequestTime(player: Player): (number)
	ReplicatedStorage.Remotes.RequestTime:FireClient(player, startTime)
end

-- EVENTS

ReplicatedStorage.Remotes.RequestTime.OnServerEvent:Connect(handleRequestTime)

return Time