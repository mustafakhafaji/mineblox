local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Lighting = game:GetService("Lighting")

local TIME_CHANGE_PER_SECOND = 1

-- Private

function updateTime(timeStart: number): ()

    local timeDifference = os.time() - timeStart

    Lighting:SetMinutesAfterMidnight()
end

--TODO update fog colour


-- Events

ReplicatedStorage.Shared.Remotes.RequestTime.OnClientEvent:Connect(updateTime)


-- Init
ReplicatedStorage.Shared.RequestTime:FireServer()    