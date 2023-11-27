local Model = {}

-- PUBLIC

-- Weld every part in model to primary part
function Model.startWeld(model: Model): ()
	
	local weldFolder = Instance.new('Folder')
	weldFolder.Name = 'WeldFolder'
	weldFolder.Parent = model
	
	local primaryPart = model.PrimaryPart
	
	for _, child in model:GetChildren() do
		
		if 
			not child:IsA('BasePart') 
			or child == primaryPart
		then 
			continue 
		end
		
		local weld = Instance.new('WeldConstraint')
		weld.Parent = weldFolder
		
		weld.Part0 = child
		weld.Part1 = primaryPart
		
		child.Anchored = false
	end
end


-- Delete welds and anchor children
function Model.endWeld(model: Model): ()
	
	for _, child in model:GetChildren() do
		
		if not child:IsA('BasePart') then 
			continue 
		end
		
		child.Anchored = true
	end
	
	if model:FindFirstChild('WeldFolder') then
		model:FindFirstChild('WeldFolder'):Destroy()
	end
end


return Model