local MODEL = {}


--// Weld every part in model to primary part
function MODEL.start_weld(model: Model): ()
	
	local weld_folder = Instance.new('Folder')
	weld_folder.Name = 'WELD_FOLDER'
	weld_folder.Parent = model
	
	local primary_part = model.PrimaryPart
	
	for _, child in model:GetChildren() do
		if not child:IsA('BasePart') then continue end
		if child == primary_part then continue end
		
		local weld = Instance.new('WeldConstraint')
		weld.Parent = weld_folder
		
		weld.Part0 = child
		weld.Part1 = primary_part
		
		child.Anchored = false
	end
end



--// Delete welds and anchor children
function MODEL.end_weld(model: Model): ()
	
	for _, child in model:GetChildren() do
		if not child:IsA('BasePart') then continue end
		
		child.Anchored = true
	end
	
	if model:FindFirstChild('WELD_FOLDER') then
		model:FindFirstChild('WELD_FOLDER'):Destroy()
	end
end




return MODEL