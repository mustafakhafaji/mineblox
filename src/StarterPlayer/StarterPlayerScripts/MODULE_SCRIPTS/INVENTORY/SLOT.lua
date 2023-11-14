local SLOT = {}
SLOT.__index = SLOT

--// Services
local S_RUN = game:GetService('ReplicatedStorage')

--// Variables
local items = S_RUN:FindFirstChild('ITEMS')

--[[ PUBLIC ]]--

--// Create a new slot object
function SLOT.new(index: number, item_name: string, quantity: number, guis: {}, slot_type: string): ()
	
	local self = setmetatable({}, SLOT)
	
	self.index = index or nil
	self.item = item_name or nil
	self.quantity = quantity or 0
	self.guis = guis or {}
	self.slot_type = slot_type or nil
	
	self._active = false
	
	return self
end




--// Update existing slot data
function SLOT:update(item_name: string, quantity: number): ()
	
	-- If quantity is 0, then delete object
	if quantity == 0 then
		self._active = false
		self.item = nil
		self.quantity = 0
		
		for _, gui in self.guis do
			for _, element in gui.ITEM:GetChildren() do
				element:Destroy()
			end

			gui.NUMBER.Text = ''
		end
		
		return
	end
	
	-- Update item data
	self._active = true
	self.item = item_name or self.item
	self.quantity += quantity or 0
	
	if not self.item then return end
	
	for _, gui in self.guis do
		
		local item_gui = gui:FindFirstChild('ITEM')
		
		for _, element in item_gui:GetChildren() do
			element:Destroy()
		end
		
		--TODO: what if item is a model?
		local item = items:FindFirstChild(item_name):Clone()
		local part = item
		
		if item:IsA('Model') then
			part = item.PrimaryPart
			item:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
		else
			item.Position = Vector3.new(0, 0, 0)
		end
		
		item.Parent = item_gui
		item_gui.BackgroundColor3 = part.Color

		local size = math.max(part.Size.x, part.Size.y, part.Size.z)

		local new_camera = Instance.new('Camera')
		new_camera.CFrame = CFrame.new(Vector3.new(size * 60, size * 60, size * 60), part.Position)
		new_camera.FieldOfView = 1
		new_camera.Parent = item_gui

		gui.ITEM.CurrentCamera = new_camera
		
		
		-- Update number of item text
		if self.quantity > 1 then
			gui:FindFirstChild('NUMBER').Visible = true
			gui:FindFirstChild('NUMBER').Text = self.quantity
		else
			gui:FindFirstChild('NUMBER').Visible = false
			gui:FindFirstChild('NUMBER').Text = ''
		end
	end
end




return SLOT