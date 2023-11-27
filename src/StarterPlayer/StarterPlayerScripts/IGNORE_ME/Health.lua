local Health = {}

local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild('PlayerGui')
local HEALTH_BAR_GUI = PlayerGui:WaitForChild('SCREENGUI'):WaitForChild('HEALTH')

local HEARTS_TO_SHAKE_HEARTS = 2
local SHAKE_OFFSET = 2
local SECONDS_UNTIL_HEALING = 2.5

local healing = nil
local canHealTime = os.clock()
local hearts = 10

local heartShake = nil

-- PRIVATE

-- make function that calculates what guis should be visible, and which shouldnt be
-- make function that makes said hearts visible

-- set all guis to invisible
-- set all guis from find visible guis to visible
-- for flashing, get find visible guis, if visible then do thing then blabla

-- Sets all heart guis (full and half hearts) to invisible
function heartsGuiInvisible()
	
	for heart = 1, 10, 1 do

		local current_heart_gui = HEALTH_BAR_GUI:FindFirstChild(heart)
		local full_heart_gui = current_heart_gui:FindFirstChild('FULL_HEART')
		local half_heart_gui = current_heart_gui:FindFirstChild('HALF_HEART')
		
		full_heart_gui.Visible = false
		half_heart_gui.Visible = false
	end
end


-- Returns what gui elements should be visibe given a number of hearts
function find_visible_guis(hearts: number): ({})
	
	local full_hearts = math.floor(hearts)
	local half_heart = hearts - full_hearts
	
	local heart_guis = {}
	
	for heart = 1, 10, 1 do

		local current_heart_gui = HEALTH_BAR_GUI:FindFirstChild(heart)
		local full_heart_gui = current_heart_gui:FindFirstChild('FULL_HEART')
		local half_heart_gui = current_heart_gui:FindFirstChild('HALF_HEART')

		if heart <= full_hearts then
			table.insert(heart_guis, full_heart_gui)

		elseif half_heart > 0 then
			table.insert(heart_guis, half_heart_gui)
			break
		end
	end
	
	return heart_guis
end


-- Sets player's heart guis visible corresponding to hearts #
function update_hearts()
	
	if not Player.Character then 
		return 
	end
	
	local full_hearts = math.floor(hearts)
	local half_heart = hearts - full_hearts
	
	hearts_gui_invisible()
	
	for _, gui in find_visible_guis(hearts) do
		gui.Visible = true
	end
	
	local humanoid = Player.Character:WaitForChild('Humanoid')
	
	humanoid.Health = full_hearts * 10 + half_heart * 10
	if hearts <= 0 then
		PLAYER.Character.Humanoid.Health = 0
	end
end


-- Randomly moves hearts up and down at random times
function shake_hearts()
	
	if not heart_shake then

		local shake_times = {}

		for i = 1, 10, 1 do
			shake_times[i] = os.clock() + math.random(10, 30) / 100
		end

		heart_shake = S_RUN.Heartbeat:Connect(function()

			for i, v in shake_times do
				if os.clock() >= v then
					
					local heart = HEALTH_BAR_GUI:FindFirstChild(i)
					local heart_position = heart.Position
					
					if heart.Position.Y.Offset == 0 then
						heart.Position = UDim2.new(heart_position.X.Scale, 0, 0, -SHAKE_OFFSET)
					else
						heart.Position = UDim2.new(heart_position.X.Scale, 0, 0, 0)
					end

					shake_times[i] = os.clock() + math.random(4, 25) / 100
				end
			end

			if hearts > HEARTS_TO_SHAKE_HEARTS then
				
				for _, heart in HEALTH_BAR_GUI:GetChildren() do
					heart.Position = UDim2.new(heart.Position.X.Scale, 0, 0, 0)
				end
				heart_shake:Disconnect()
				heart_shake = nil
			end
		end)

	end
end


function flash_previous_hearts()
	
	-- flash what health was before losing it, change transparency of hearts?
	-- calculate the extra hearts
end


local borderFlash = nil
local SECONDS_BETWEEN_SWITCHES = .115

function flashHeartsBorder(previousHearts: number): ()
	
	if borderFlash then
		borderFlash:Disconnect()
		
		for _, heart_gui in HEALTH_BAR_GUI:GetChildren() do
			for _, element in heart_gui:FindFirstChild('BORDER'):GetChildren() do
				element.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			end
			
			for _, element in heart_gui:FindFirstChild('FULL_HEART'):GetChildren() do
				element.BackgroundTransparency = 0
			end
			
			for _, element in heart_gui:FindFirstChild('HALF_HEART'):GetChildren() do
				element.BackgroundTransparency = 0
			end
		end
	end
	
	
	-- Each switch is treated as a repeat
	local switches = 6
	local next_flash = os.clock()
	local is_white = false
	
	local previous_hearts_gui = find_visible_guis(previous_hearts)
	local half_visible_guis = {}
	
	for _, previous_heart_gui in previous_hearts_gui do
		if not previous_heart_gui.Visible then
			table.insert(half_visible_guis, previous_heart_gui)
			
			for _, child in previous_heart_gui:GetChildren() do
				child.BackgroundTransparency = .5
			end
		end
	end
	
	border_flash = S_RUN.RenderStepped:Connect(function()
		if os.clock() > next_flash then
			
			for _, heart_gui in HEALTH_BAR_GUI:GetChildren() do
				
				if not is_white then
					for _, element in heart_gui:FindFirstChild('BORDER'):GetChildren() do -- border
						element.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					end
					
					for _, element in half_visible_guis do -- previous hearts
						element.Visible = true
					end
				else
					for _, element in heart_gui:FindFirstChild('BORDER'):GetChildren() do
						element.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
					end
					
					for _, element in half_visible_guis do
						element.Visible = false
					end
				end
			end
			
			switches -= 1
			
			if switches <= 0 then
				
				for _, element in half_visible_guis do 
					for _, child in element:GetChildren() do
						child.BackgroundTransparency = 0
					end
				end
				
				border_flash:Disconnect()
				border_flash = nil
			end
			
			is_white = not is_white
			next_flash = os.clock() + SECONDS_BETWEEN_SWITCHES
		end
	end)
end


function heal()
	
	if healing then 
		healing:Disconnect()
		healing = nil
	end
	
	local timeToHeal = tick() + SECONDS_UNTIL_HEALING

	healing = RunService.Heartbeat:Connect(function()

		if tick() > timeToHealeal then

			hearts += .5
			updateHearts()

			if hearts >= 10 then
				healing:Disconnect()
				healing = nil
			end

			timeToHeal = tick() + SECONDS_UNTIL_HEALING
		end
	end)
end


function resetHearts()
	hearts = 10
	updateHearts()
end


-- PUBLIC

-- Pass in number of hearts to reduce player's health
function Health.takeDamage(amount: number)
	
	local previousHearts = hearts
	hearts -= .5 * math.floor(amount / .5) -- Rounds to nearest 0.5 value
	
	updateHearts()
	flashHeartsBorder(previousHearts)
	heal()
	
	if hearts <= HEARTS_TO_SHAKE_HEARTS then
		shakeHearts()
	end
end

-- EVENTS

Player.CharacterAdded:Connect(resetHearts)


return Health