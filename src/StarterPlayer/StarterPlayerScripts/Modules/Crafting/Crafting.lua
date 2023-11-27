local CRAFTING = {}

--// MODULES
local M_CRAFTING_RECIPES = require(script.CRAFTING_RECIPES)

--[[ PRIVATE ]]--

--// Returns true if 2 tables are equal
local function are_tables_equal(table_1 , table_2)
	for i, v in next, table_1 do if table_2[i] ~= v then return false end end
	for i, v in next, table_2 do if table_1[i] ~= v then return false end end
	return true
end



--// Removes empty rows
local function shrink_rows(items: {}, rows: number, columns: number): ({}, number)
	
	local shrunk_items = {}
	
	for _, row in items do
		
		local is_empty = true
		
		for _, ingredient in row do
			if ingredient ~= 'X' then
				is_empty = false
			end
		end
		
		if not is_empty then
			local to_add = {}
			for _, ingredient in row do
				table.insert(to_add, ingredient)
			end
			table.insert(shrunk_items, to_add)
		else
			rows -= 1
		end
	end
	
	return shrunk_items, rows
end



--// True if left and right columns are not empty, false if one in either, or empty
local function is_left_and_right_filled(items: {}, rows: number, columns: number): boolean
	
	local left_empty = true
	local right_empty = true
	
	-- Check left side
	for row = 1, rows do
		if items[row][1] ~= 'X' then
			left_empty = false
		end
	end
	
	-- Check right side
	for row = 1, rows do
		if items[row][3] ~= 'X' then
			right_empty = false
		end
	end
	
	if not (left_empty and right_empty) then
		return true
	else
		return false
	end
end



--// Removes empty columns from items list
local function shrink_columns(items: {}, rows: number, columns: number): ({}, number)
	
	-- If left and right columns arent empty then dont clear any columns
	if columns == 3 then
		if is_left_and_right_filled(items, rows, columns) then
			return items, columns
		end
	end
	
	local shrunk_items = table.clone(items)
	
	for column = columns, 1, -1 do
		
		local is_empty = true
		
		for row = 1, rows do
			if items[row][column] ~= 'X' then
				is_empty = false
			end
		end
		
		if is_empty then
			for row = 1, rows do
				table.remove(shrunk_items[row], column)
			end
			columns -= 1
		end
	end

	return shrunk_items, columns
end




--// Converts a 2D array into a 1D table
local function convert_to_1D(items: {})
	
	local ingredients = {}
	
	for _, row in items do
		
		for _, ingredient in row do
			table.insert(ingredients, ingredient)
		end
	end
	
	return ingredients
end




--[[ PUBLIC ]]--

--// Returns an item result given a 2D array of items (ingredients)
function CRAFTING.craft(items: {}): (string)
		
	local rows = #items
	local columns = #items[1]
	
	items, rows = shrink_rows(items, rows, columns)
	items, columns = shrink_columns(items, rows, columns)
	items = convert_to_1D(items)
	
	-- Check if it matches a recipe
	local possible_recipes = M_CRAFTING_RECIPES[rows][columns]
	
	for _, item in possible_recipes do
		
		local recipe = item['Recipe']
		
		if are_tables_equal(recipe, items) then
			
			local quantity = item['Quantity']
			local result = item['Result']
			
			return result
		end
	end
end



return CRAFTING