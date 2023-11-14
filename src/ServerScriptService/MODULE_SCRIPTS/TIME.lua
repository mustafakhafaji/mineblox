local TIME = {}

--// Services
local S_LIGHTING = game:GetService('Lighting')
local S_RUN = game:GetService('RunService')
local S_RS = game:GetService('ReplicatedStorage')

--[[ PRIVATE ]]--

--// day and night cycle of the game
local current_time = S_LIGHTING.ClockTime
local next_check = os.clock()

--// Just send client the time when joining then they update it

function advance_time()
	
	if os.clock() > next_check then

		current_time += .1

		if current_time >= 24 then
			current_time = 0
		end

		--S_LIGHTING.ClockTime = current_time

		next_check += 10
	end
end




function handle_get_time()
	return current_time
end



--[[ EVENTS ]]--

S_RUN.Heartbeat:Connect(advance_time)
S_RS.REMOTES.GetTime.OnServerInvoke = handle_get_time()

return TIME