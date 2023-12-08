local Tree = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemsData = require(ReplicatedStorage.Shared.ItemsData)

local OAK_LOG_ID = ItemsData['Oak Log']['ID']
local OAK_LEAVES_ID = ItemsData['Oak Leaves']['ID']

local MIN_LOGS = 3
local MAX_LOGS = 5

local LOGS_IN_TREE = 2

-- PRIVATE

-- Stores oak logs positions in table
function generateLogs(height: number): ({})
	
	local tree = {}

	for y = 1, height do
		table.insert(tree, {0, 0, y, OAK_LOG_ID})
	end
	
	return tree
end


-- Stores oak leaves positions in table
function generateLeavesLayers(tree: {}, random: Random, height: number): ({})
	
	-- Store first layer
	local layer = 1
	
	for x = -2, 2 do
		for z = -2, 2 do

			-- Skip center
			if x == 0 and z == 0 then 
				continue 
			end 
			
			if math.abs(x) == 2 and math.abs(z) == 2 then
				if random:NextInteger(1, 4) <= 1 then
					continue
				end
			end
			
			table.insert(tree, {x, z, layer + height - LOGS_IN_TREE, OAK_LEAVES_ID})
		end
	end
	layer += 1

	-- Store second layer
	for x = -2, 2 do
		for z = -2, 2 do

			if x == 0 and z == 0 then continue end -- Skip center

			if math.abs(x) == 2 and math.abs(z) == 2 then
				if random:NextInteger(1, 4) <= 1 then
					continue
				end
			end
			
			table.insert(tree, {x, z, layer + height - LOGS_IN_TREE, OAK_LEAVES_ID})
		end
	end
	layer += 1

	-- Store third layer
	for x = -1, 1 do
		for z = -1, 1 do
			
			table.insert(tree, {x, z, layer + height - LOGS_IN_TREE, OAK_LEAVES_ID})
		end
	end
	layer += 1


	-- Store fourth layer
	for x = -1, 1 do
		for z = -1, 1 do
			
			if math.abs(x) == 1 and math.abs(z) == 1 then
				continue
			end
			
			table.insert(tree, {x, z, layer + height - LOGS_IN_TREE, OAK_LEAVES_ID})
		end
	end
	
	return tree
end


-- PUBLIC

function Tree.getRandomTree(Random: Random): ({})
	
	local height = Random:NextInteger(MIN_LOGS, MAX_LOGS)
	
	local tree = generateLogs(height)
	tree = generateLeavesLayers(tree, Random, height)
	
	return tree
end

	
return Tree