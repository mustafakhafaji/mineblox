local CRAFTING_RECIPES = {
	
	[1] =  -- # of rows
		{
			[1] = -- # of columns
			{
				{
					['Result'] = 'Oak Wood Planks',
					['Quantity'] = 4, -- # of result
					['Recipe'] =
					{'Oak Log'}
				},
			},
			
			[2] = 
			{
			},
			
			[3] = 
			{
				
			},
		},
	
	[2] = 
		{
			[1] = 
			{
				{
					['Result'] = 'Stick',
					['Recipe'] =
					{'Oak Wood Planks',
					'Oak Wood Planks'}
				},
				{
					['Result'] = 'Torch',
					['Recipe'] = 
					{'Coal',
					'Stick'}
				},
			},
			
			[2] = 
			{
				['Crafting Table'] = 
				{
					['Result'] = 'Crafting Table',
					['Recipe'] = 
					{'Oak Wood Planks', 'Oak Wood Planks',
					'Oak Wood Planks', 'Oak Wood Planks'}
				},
			},
			
			[3] = 
			{
				-- Helmets
				{
					['Result'] = 'Iron Helmet',
					['Recipe'] = 
					{'Iron Ingot', 'Iron Ingot', 'Iron Ingot',
					'Iron Ingot', 'X', 'Iron Ingot'}
				},
				{
					['Result'] = 'Diamond Helmet',
					['Recipe'] = 
					{'Diamond', 'Diamond', 'Diamond',
					'Diamond', 'X', 'Diamond'}
				},
				

				-- Boots -- UPDATE RECIPE TO 2X2, ignore middle column/row?
				{ 
					['Result'] = 'Iron Boots',
					['Recipe'] = 
					{'Iron Ingot', 'X', 'Iron Ingot',
					'Iron Ingot', 'X', 'Iron Ingot'}
				},
				{
					['Result'] = 'Diamond Boots',
					['Recipe'] = 
					{'Diamond', 'X', 'Diamond',
					'Diamond', 'X', 'Diamond'}
				},
			},
		},
	
	[3] = 
		{
			[1] = 
			{
				-- Swords
				{
					['Result'] = 'Wooden Sword',
					['Recipe'] = 
					{'Oak Wood Planks',
					'Oak Wood Planks',
					'Stick'}
				},
				{
					['Result'] = 'Stone Sword',
					['Recipe'] = 
					{'Cobblestone',
					'Cobblestone',
					'Stick',}
				},
				{
					['Result'] = 'Iron Sword',
					['Recipe'] = 
					{'Iron Ingot',
					'Iron Ingot',
					'Stick'}
				},
				{
					['Result'] = 'Diamond Sword',
					['Recipe'] = 
					{'Diamond',
					'Diamond',
					'Stick'}
				},
			},

			[2] = 
			{

			},

			[3] = 
			{
				{
					['Result'] = 'Furnace',
					['Recipe'] = 
					{'Cobblestone', 'Cobblestone', 'Cobblestone',
					'Cobblestone', 'X', 'Cobblestone',
					'Cobblestone', 'Cobblestone', 'Cobblestone'}
				},
				{
					['Result'] = 'Chest',
					['Recipe'] = 
					{'Oak Wood Planks', 'Oak Wood Planks', 'Oak Wood Planks',
					'Oak Wood Planks', 'X', 'Oak Wood Planks',
					'Oak Wood Planks', 'Oak Wood Planks', 'Oak Wood Planks'}
				},
				
				-- Pickaxes
				{
					['Result'] = 'Wooden Pickaxe',
					['Recipe'] = 
					{'Oak Wood Planks', 'Oak Wood Planks', 'Oak Wood Planks',
					'X', 'Stick', 'X',
					'X', 'Stick', 'X'}
				},
				{
					['Result'] = 'Stone Pickaxe',
					['Recipe'] = 
					{'Cobblestone', 'Cobblestone', 'Cobblestone',
					'X', 'Stick', 'X',
					'X', 'Stick', 'X'}
				},
				{
					['Result'] = 'Iron Pickaxe',
					['Recipe'] = 
					{'Iron Ingot', 'Iron Ingot', 'Iron Ingot',
					'X', 'Stick', 'X',
					'X', 'Stick', 'X'}
				},
				{
					['Result'] = 'Diamond Pickaxe',
					['Recipe'] = 
					{'Diamond', 'Diamond', 'Diamond',
					'X', 'Stick', 'X',
					'X', 'Stick', 'X'}
				},
				
				-- Axes
				{
					['Result'] = 'Wooden Axe',
					['Recipe'] = 
					{'X', 'Oak Wood Planks', 'Oak Wood Planks',
					'X', 'Stick', 'Oak Wood Planks',
					'X', 'Stick', 'X'}
				},
				{
					['Result'] = 'Stone Axe',
					['Recipe'] = 
					{'X', 'Cobblestone', 'Cobblestone',
					'X', 'Stick', 'Cobblestone',
					'X', 'Stick', 'X'}
				},
				{
					['Result'] = 'Iron Axe',
					['Recipe'] = 
					{'X', 'Iron Ingot', 'Iron Ingot',
					'X', 'Stick', 'Iron Ingot',
					'X', 'Stick', 'X'}
				},
				{
					['Result'] = 'Diamond Axe',
					['Recipe'] = 
					{'X', 'Diamond', 'Diamond',
					'X', 'Stick', 'Diamond',
					'X', 'Stick', 'X'}
				},
				
				-- Shovels
				{
					['Result'] = 'Wooden Shovel',
					['Recipe'] = 
					{'X', 'Oak Wood Planks', 'Oak Wood Planks',
					'X', 'Stick', 'Oak Wood Planks',
					'X', 'Stick', 'X'}
				},
				{
					['Result'] = 'Stone Shovel',
					['Recipe'] = 
					{'X', 'Cobblestone', 'Cobblestone',
					'X', 'Stick', 'Cobblestone',
					'X', 'Stick', 'X'}
				},
				{
					['Result'] = 'Iron Shovel',
					['Recipe'] = 
					{'X', 'Iron Ingot', 'Iron Ingot',
					'X', 'Stick', 'Iron Ingot',
					'X', 'Stick', 'X'}
				},
				{
					['Result'] = 'Diamond Shovel',
					['Recipe'] = 
					{'X', 'Diamond', 'Diamond',
					'X', 'Stick', 'Diamond',
					'X', 'Stick', 'X'}
				},
				
				-- Chestplate
				{
					['Result'] = 'Iron Chestplate',
					['Recipe'] = 
					{'Iron Ingot', 'X', 'Iron Ingot',
					'Iron Ingot', 'Iron Ingot', 'Iron Ingot',
					'Iron Ingot', 'Iron Ingot', 'Iron Ingot'}
				},
				{
					['Result'] = 'Diamond Chestplate',
					['Recipe'] = 
					{'Diamond', 'X', 'Diamond',
					'Diamond', 'Diamond', 'Diamond',
					'Diamond', 'Diamond', 'Diamond'}
				},
				
				-- Leggings
				{
					['Result'] = 'Iron Leggings',
					['Recipe'] = 
					{'Iron Ingot', 'Iron Ingot', 'Iron Ingot',
					'Iron Ingot', 'X', 'Iron Ingot',
					'Iron Ingot', 'X', 'Iron Ingot'}
				},
				{
					['Result'] = 'Diamond Leggings',
					['Recipe'] = 
					{'Diamond', 'Diamond', 'Diamond',
					'Diamond', 'X', 'Diamond',
					'Diamond', 'X', 'Diamond'}
				},
			}
		}
}

return CRAFTING_RECIPES