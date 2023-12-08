local Crafting = {}

local StarterPlayer = game:GetService('StarterPlayer')

local Modules = StarterPlayer.StarterCharacterScripts.Modules
local CraftingRecipes = require(Modules.Crafting.CraftingRecipes)

-- PRIVATE

-- Returns true if given tables are equal
function areTablesEqual(table1: {}, table2: {}): (boolean)

	for i, v in next, table1 do
		if table2[i] ~= v then 
			return false 
		end 
	end

	for i, v in next, table2 do
		if table1[i] ~= v then 
			return false 
		end 
	end

	return true
end


-- Returns true if left and right columns are not empty, false if one in either, or empty
function isLeftAndRightFilled(items: {}, rows: number, columns: number): (boolean)
	
	local leftEmpty = true
	local rightEmpty = true
	
	-- Check left side
	for row = 1, rows do
		if items[row][1] ~= 'X' then
			leftEmpty = false
		end
	end
	
	-- Check right side
	for row = 1, rows do
		if items[row][3] ~= 'X' then
			rightEmpty = false
		end
	end
	
	return not (leftEmpty and rightEmpty)
end


-- Removes empty rows from table
function shrinkRows(items: {}, rows: number, columns: number): ({}, number)
	
	local shrunkItems = {}
	
	for _, row in items do
		
		local isEmpty = true
		
		for _, ingredient in row do
			if ingredient ~= 'X' then
				isEmpty = false
			end
		end
		
		if not isEmpty then
			local to_add = {}
			for _, ingredient in row do
				table.insert(to_add, ingredient)
			end
			table.insert(shrunkItems, to_add)
		else
			rows -= 1
		end
	end
	
	return shrunkItems, rows
end


-- Removes empty columns from table
function shrinkColumns(items: {}, rows: number, columns: number): ({}, number)
	
	-- If left and right columns arent empty then dont clear any columns
	if columns == 3 then
		if isLeftAndRightFilled(items, rows, columns) then
			return items, columns
		end
	end
	
	local shrunkItems = table.clone(items)
	
	for column = columns, 1, -1 do
		
		local isEmpty = true
		
		for row = 1, rows do
			if items[row][column] ~= 'X' then
				isEmpty = false
			end
		end
		
		if isEmpty then
			for row = 1, rows do
				table.remove(shrunkItems[row], column)
			end
			columns -= 1
		end
	end

	return shrunkItems, columns
end


-- Converts a 2D array into a 1D table
function convertTo1D(items: {}): ({})
	
	local ingredients = {}
	
	for _, row in items do
		
		for _, ingredient in row do
			table.insert(ingredients, ingredient)
		end
	end
	
	return ingredients
end


-- PUBLIC

-- Returns an item result given a 2D array of items (ingredients)
function Crafting.craft(items: {}): (string, number)
		
	local rows = #items
	local columns = #items[1]
	
	items, rows = shrinkRows(items, rows, columns)
	items, columns = shrinkColumns(items, rows, columns)
	items = convertTo1D(items)
	
	-- Check if it matches a recipe
	local possibleRecipes = CraftingRecipes[rows][columns]
	
	for _, item in possibleRecipes do
		
		local recipe = item['Recipe']
		
		if not areTablesEqual(recipe, items) then
			continue
		end

		local quantity = item['Quantity']
		local result = item['Result']
		
		return result, quantity
	end
end


return Crafting