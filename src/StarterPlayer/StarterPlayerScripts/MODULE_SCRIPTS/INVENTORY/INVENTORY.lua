local INVENTORY = {}


--TODO: while holding right click, place single item into single slot
-- when player starts right clicking, find applicable slots (empty slots)
-- if player hovers over while still right clicking then update slot and remove from applicable slots


--// Services
local S_UIS = game:GetService('UserInputService')
local S_REPLICATED = game:GetService('ReplicatedStorage')
local S_TS = game:GetService('TweenService')
local S_RUN = game:GetService('RunService')
local S_SP = game:GetService('StarterPlayer')
local S_PLAYERS = game:GetService('Players')

--// Modules
local MODULES = S_SP.StarterPlayerScripts.MODULE_SCRIPTS

local M_SLOT = require(script.SLOT)
local M_HOTKEYS = require(script.HOTKEYS)
local M_POSITIONS = require(script.POSITIONS)
local M_CHARACTER_DISPLAY = require(script.CHARACTER_DISPLAY)
local M_ITEM_DATA = require(S_REPLICATED.MODULE_SCRIPTS.ITEM_DATA)
local M_MOVEMENT = require(MODULES.MOVEMENT)
local M_PLAYER_STATE = require(MODULES.PLAYER_STATE)
local M_EQUIPPED = require(MODULES.EQUIPPED)
local M_DROP = require(MODULES.CHUNK_LOADING.DROPPED_OBJECTS)

--// Constants
local PLAYER = S_PLAYERS.LocalPlayer
local MOUSE = PLAYER:GetMouse()

local PLAYER_GUI = PLAYER:WaitForChild('PlayerGui'):WaitForChild('SCREENGUI')

local HOTBAR_GUI = PLAYER_GUI:WaitForChild('HOTBAR')
local SELECTED_GUI = HOTBAR_GUI:WaitForChild('1'):WaitForChild('SELECTED')

local INVENTORY_GUI = PLAYER_GUI:WaitForChild('INVENTORY'):WaitForChild('INVENTORY'):WaitForChild('INVENTORY')
local SLOTS_GUI = INVENTORY_GUI:WaitForChild('SLOTS')
local MOVING_GUI = INVENTORY_GUI:WaitForChild('MOVING')

local MAX: number = 64

--// Variables
local opened: boolean = false
local moving_slot: SLOT
local selected: number = 1
local inventory: {[number] : SLOT} = {}

local moving_slot_connection
local last_highlighted = nil



--[[ PRIVATE ]]--


local function update_gui()
	
end

--// Add hotbar SLOTs to inventory table
local function init_hotbar_slots()
	
	for i = 1, 9, 1 do

		local hotbar_element = HOTBAR_GUI:FindFirstChild(i)
		local inventory_element = SLOTS_GUI:FindFirstChild(i)

		local new_slot = M_SLOT.new(i, nil, 0, {inventory_element, hotbar_element})
		table.insert(inventory, new_slot)
	end
end

--// Add inventory SLOTs to inventory table
local function init_inventory_slots()
	
	for i = 10, 36, 1 do

		local inventory_element = SLOTS_GUI:FindFirstChild(i)
		local new_slot = M_SLOT.new(i, nil, 0, {inventory_element})
		table.insert(inventory, new_slot)
	end
end

--// Add armour SLOTs to inventory table
local function init_armour_slots()
	
	for i, name in M_POSITIONS['ARMOUR'] do

		local inventory_element = SLOTS_GUI:FindFirstChild(name)
		local new_slot = M_SLOT.new(#inventory + i, nil, 0, {inventory_element})
		inventory[name] = new_slot
	end
end

--// Add crafting SLOTs to inventory table
local function init_crafting_slots()
	
	for i, name in M_POSITIONS['CRAFTING'] do

		local inventory_element = SLOTS_GUI:FindFirstChild(name)
		local new_slot = M_SLOT.new(#inventory + i, nil, 0, {inventory_element})
		inventory[name] = new_slot
	end
end


--// Create slot objects for hotbar, inventory, etc
local function init_slots()
	
	-- Moving slot
	moving_slot = M_SLOT.new(nil, nil, 0, {MOVING_GUI})
	
	init_hotbar_slots()
	init_inventory_slots()
	init_armour_slots()
	init_crafting_slots()
end



local function check_outside_hovering(): boolean
	
	local mouse_x = MOUSE.X
	local mouse_y = MOUSE.Y
	
	local x_min = INVENTORY_GUI.AbsolutePosition.X
	local x_max = x_min + INVENTORY_GUI.AbsoluteSize.X
	local y_min = INVENTORY_GUI.AbsolutePosition.Y
	local y_max = y_min + INVENTORY_GUI.AbsoluteSize.y

	if mouse_x < x_min or mouse_x > x_max or mouse_y < y_min or mouse_y > y_max then
		return true
	end
	return false
end





--// Check slot mouse is hovering over
local function check_slot_hovering()
	local mouse_x = MOUSE.X
	local mouse_y = MOUSE.Y
	
	for _, gui in SLOTS_GUI:GetChildren() do

		local x_min = gui.AbsolutePosition.X
		local x_max = x_min + gui.AbsoluteSize.X
		local y_min = gui.AbsolutePosition.Y
		local y_max = y_min + gui.AbsoluteSize.y

		if mouse_x > x_min and mouse_x < x_max and mouse_y > y_min and mouse_y < y_max then

			local element = nil

			if inventory[tonumber(gui.Name)] then
				element = inventory[tonumber(gui.Name)]
			else
				element = inventory[gui.Name]
			end
			
			return element
		end
	end
end




--// Place item in inventory, check max stack 
local function place_item(inventory_slot: SLOT)
	
end





--// Pick up and item from inventory to move
local function move_inventory_slot(moving_element: SLOT)

	local inventory_slot = moving_element or check_slot_hovering()
	if not inventory_slot then return end
	
	-- If player is currently moving an item in inventory
	if moving_slot._active then
		
		if inventory_slot.item ~= nil and inventory_slot.item ~= moving_slot.item then return end

		inventory_slot:update(moving_slot.item, moving_slot.quantity)
		local extra = inventory_slot.quantity - MAX

		if extra > 0 then

			-- Set inventory slot to 64 max stack
			inventory_slot:update(nil, 0)
			inventory_slot:update(moving_slot.item, MAX)

			-- Set moving slot to number of extra items
			moving_slot:update(nil, 0)
			moving_slot:update(inventory_slot.item, extra)
		else

			-- Update moving slot
			moving_slot:update(nil, 0)
			moving_slot_connection:Disconnect()
		end
		
	else -- Start moving item from inventory
		
		-- Update moving slot
		moving_slot:update(inventory_slot.item, inventory_slot.quantity)
		inventory_slot:update(nil, 0)
		INVENTORY.select(selected)
		
		-- Moving slot follow cursor
		moving_slot_connection = S_RUN.RenderStepped:Connect(function()
			moving_slot.guis[1].Position = UDim2.new(
				0,
				MOUSE.x - INVENTORY_GUI.AbsolutePosition.x - 14,
				0,
				MOUSE.y - INVENTORY_GUI.AbsolutePosition.y - 14
			)
		end)
	end
end




--// Move half the quantity of an item, leaving half behind
local function move_half()
	local inventory_slot = check_slot_hovering()
	if not inventory_slot then return end
	
	-- Not already moving an item
	if moving_slot._active then return end
	
	-- Move single item, treat normally
	if inventory_slot.quantity == 1 then
		move_inventory_slot()
		
	else -- More than one item
		
		-- Split items in half
		local moving_element = M_SLOT.new(nil, inventory_slot.item, math.ceil(inventory_slot.quantity / 2), nil)
		
		inventory_slot:update(inventory_slot.item, -math.ceil(inventory_slot.quantity / 2))
		move_inventory_slot(moving_element)
	end
end




--// Place single item in inventory slot
local function place_single_item()
	
	local inventory_slot = check_slot_hovering()
	if not inventory_slot then return end
	if inventory_slot.item ~= nil and inventory_slot.item ~= moving_slot.item then return end
	
	if moving_slot.quantity < 1 then return end
	
	moving_slot:update(moving_slot.item, -1) -- Subtract 1 from moving slot
	inventory_slot:update(moving_slot.item, 1) -- Add 1 to inventory slot
	
	local extra = inventory_slot.quantity - MAX
	
	if extra > 0 then 
		
		-- Reverse changes
		moving_slot:update(moving_slot.item, 1)
		inventory_slot:update(moving_slot.item, -1) 
	end
	
	if moving_slot.quantity < 1 then
		moving_slot:update(nil, 0)
		moving_slot_connection:Disconnect()
	end
end





local function highlight_inventory_slot()

	if last_highlighted then
		last_highlighted.BackgroundColor3 = Color3.fromRGB(149, 147, 143)
	end

	local element = check_slot_hovering()

	if not element then return end

	last_highlighted = element.guis[1]
	last_highlighted.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
end





--// Returns slot to place item in 
local function find_valid_slot(item_name:string, quantity: number)
	
	for _, slot in inventory do -- existing item
		
		if slot.item == item_name then
			if slot.quantity + quantity <= 64 then
				return slot
			end
		end
	end
	
	for _, slot in inventory do
		
		if slot.item == nil then
			return slot
		end
	end
	
	return nil
end




--[[ PUBLIC ]]--

--// Create slot information
function INVENTORY.toggle()
	opened = not opened
	M_PLAYER_STATE['INVENTORY_OPENED'] = opened
	
	PLAYER_GUI:WaitForChild('INVENTORY').Visible = opened
	S_UIS.MouseIconEnabled = opened 

	if opened then
		M_MOVEMENT.freeze_player()
		--M_CHARACTER_DISPLAY.start()
	else
		M_MOVEMENT.unfreeze_player()
		--M_CHARACTER_DISPLAY.stop()
	end
end



function INVENTORY.add(item_name: string, quantity: number)
	
	local slot = find_valid_slot(item_name, quantity)
	if not slot then return end -- no space in inventory
	
	slot:update(item_name, quantity)
	
	if selected == slot.index then
		M_EQUIPPED.update_equipped(inventory[selected]['item'])
	end
	--INVENTORY.select(selected)
	
	--[[if ITEM_DATA[item_name] then
		
		-- block
	else
		-- item
		
	end]]
	
	-- check if item is already in 
	-- gui elements may be better
	-- figure out sorting use textlabels before making gui pictures
end





--// Select a hotbar position
function INVENTORY.select(index: number)
	
	local last_selected = inventory[selected]['item']
	selected = index
	
	if selected > 9 then
		selected = 1
		
	elseif selected < 1 then
		selected = 9
	end
	
	SELECTED_GUI.Parent = HOTBAR_GUI:FindFirstChild(selected)
	
	if inventory[selected]['item'] == nil then
		M_EQUIPPED.update_equipped('ARM')
		
	elseif last_selected == inventory[selected]['item'] then
	
	elseif inventory[selected]['item'] then
		M_EQUIPPED.update_equipped(inventory[selected]['item'])
	end
end




--[[ INPUTS ]]--
S_UIS.InputBegan:Connect(function(current_input)
	-- Player presses E
	if current_input.UserInputType == Enum.UserInputType.Keyboard then
		if current_input.KeyCode == Enum.KeyCode.E then
			INVENTORY.toggle()
		end
		
	end

	-- 1-9 hotkeys
	for keycode, index in M_HOTKEYS do
		if current_input.KeyCode == keycode then
			INVENTORY.select(index)
		end
	end

	if not opened then return end

	-- Player left clicks
	if current_input.UserInputType == Enum.UserInputType.MouseButton1 then
		if check_outside_hovering() and moving_slot._active then
			--drop item
		else
			move_inventory_slot()
		end

	end

	-- Player right clicks
	if current_input.UserInputType == Enum.UserInputType.MouseButton2 then

		-- Already moving item, place single item
		if moving_slot._active then
			place_single_item()

		else -- Not moving item, move half
			move_half()
		end
	end
end)


S_UIS.InputChanged:Connect(function(current_input)
	-- Player scrolls
	if current_input.UserInputType == Enum.UserInputType.MouseWheel then
		INVENTORY.select(selected + current_input.Position.Z)
	end

	if opened then
		highlight_inventory_slot()
	end
end)


--[[local success, message = pcall(M_CHARACTER_DISPLAY.init())
if not success then
	print(message)
end]]

init_slots()




return INVENTORY