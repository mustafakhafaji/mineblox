local TREE = {}

local MIN_LOGS = 3
local MAX_LOGS = 5

local LOGS_IN_TREE = 2

local MISSING_LEAVES_CHANCE = 30 -- in percent

--[[ PRIVATE ]]--

--// Stores oak logs positions in table
local function generate_logs(random: Random, height: number): ({})
	
	local tree = {}

	-- Store oak logs
	for y = 1, height do
		table.insert(tree, {0, 0, y, 'Oak Log'})
	end
	
	return tree
end




--// Stores oak leaves positions in table
local function generate_leaves_layers(tree: {}, random: Random, height: number): ({})
	
	-- Store first layer
	local LAYER = 1
	
	for x = -2, 2 do
		for z = -2, 2 do

			if x == 0 and z == 0 then continue end -- Skip center
			
			if math.abs(x) == 2 and math.abs(z) == 2 then
				if random:NextInteger(1, 4) <= 1 then
					continue
				end
			end
			
			table.insert(tree, {x, z, LAYER + height - LOGS_IN_TREE, 'Oak Leaves'})
		end
	end
	LAYER += 1

	-- Store second layer
	for x = -2, 2 do
		for z = -2, 2 do

			if x == 0 and z == 0 then continue end -- Skip center

			if math.abs(x) == 2 and math.abs(z) == 2 then
				if random:NextInteger(1, 4) <= 1 then
					continue
				end
			end
			
			table.insert(tree, {x, z, LAYER + height - LOGS_IN_TREE, 'Oak Leaves'})
		end
	end
	LAYER += 1

	-- Store third layer
	for x = -1, 1 do
		for z = -1, 1 do
			
			table.insert(tree, {x, z, LAYER + height - LOGS_IN_TREE, 'Oak Leaves'})
		end
	end
	LAYER += 1


	-- Store fourth layer
	for x = -1, 1 do
		for z = -1, 1 do
			
			if math.abs(x) == 1 and math.abs(z) == 1 then
				continue
			end
			
			table.insert(tree, {x, z, LAYER + height - LOGS_IN_TREE, 'Oak Leaves'})
		end
	end
	
	return tree
end




--[[ PUBLIC ]]--

function TREE.get_random_tree(RANDOM: Random): ({})
	
	local height = RANDOM:NextInteger(MIN_LOGS, MAX_LOGS)
	
	local tree = generate_logs(RANDOM, height)
	tree = generate_leaves_layers(tree, RANDOM, height) --TODO returns nil
	
	return tree
end

	
return TREE