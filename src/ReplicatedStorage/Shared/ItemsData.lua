local itemsData = {

	Air = {},

	Water = {},

	Stone = {
		Hardness = 2,
		PreferredTool = 'Pickaxe',
		DropItem = 'Cobblestone',
		Type = 'Block',
	},

	Cobblestone = {
		Hardness = 2,
		PreferredTool = 'Pickaxe',
		DropItem = 'Cobblestone',
		Type = 'Block',
	},

	['Grass Block'] = {
		Hardness = 0.6,
		PreferredTool = 'Shovel',
		DropItem = 'Dirt',
		Type = 'Block',
	},

	Dirt = {
		Hardness = 0.5,
		PreferredTool = 'Shovel',
		DropItem = 'Dirt',
		Type = 'Block',
	},

	['Oak Wood Planks'] = {
		Hardness = 2,
		PreferredTool = 'Axe',
		DropItem = 'Oak Planks',
		Type = 'Block',
	},

	Bedrock = {},

	Sand = {
		Hardness = 0.8,
		PreferredTool = 'Shovel',
		DropItem = 'Sand',
		Type = 'Block',
	},

	['Oak Log'] = {
		Hardness = 2,
		PreferredTool = 'Axe',
		DropItem = 'Oak Log',
		Type = 'Block',
	},

	['Oak Leaves'] = {
		Hardness = 0.2,
		Type = 'Block',
	},

	Glass = {},

	['Coal Ore'] = {
		Hardness = 3,
		PreferredTool = 'Pickaxe',
		DropItem = 'Coal',
		Type = 'Block',
	},

	['Gold Ore'] = {
		Hardness = 3,
		PreferredTool = 'Pickaxe',
		DropItem = 'Raw Gold',
		Type = 'Block',
	},

	['Iron Ore'] = {
		Hardness = 3,
		PreferredTool = 'Pickaxe',
		DropItem = 'Raw Iron',
		Type = 'Block',
	},

	['Diamond Ore'] = {
		Hardness = 3,
		PreferredTool = 'Pickaxe',
		DropItem = 'Diamond',
		Type = 'Block',
	},

	['Wooden Pickaxe'] = {
		Type = 'Pickaxe',
	},

	Dandelion = {
		Hardness = 0,
		DropItem = 'Dandelion',
		Type = 'Plant',
	},
	
	Grass = {
		Hardness = 0,
		Type = 'Plant',
	},

	['Oxeye Daisy'] = {
		Hardness = 0,
		DropItem = 'Oxeye Daisy',
		Type = 'Plant',
	},
	
	Poppy = {
		Hardness = 0,
		DropItem = 'Poppy',
		Type = 'Plant',
	},
	
	Clay = {
		Hardness = 0.6,
		PreferredTool = 'Shovel',
		DropItem = 'Clay',
		Type = 'Block',
	},
	
	Gravel = {
		Hardness = 0.6,
		PreferredTool = 'Shovel',
		DropItem = 'Gravel',
		Type = 'Block',
	},
	
	['Raw Iron'] = {
		Type = 'Ore'
	},
	
	['Diamond'] = {
		Type = 'Ore'
	},
	
	['Coal'] = {
		Type = 'Ore'
	},
	
	['Iron Ingot'] = {
		Type = 'Ore'
	},
	
	['Wooden Sword'] = {
		Type = 'Sword',
	},
	
	['Stone Sword'] = {
		Type = 'Sword',
	},
	
	['Iron Sword'] = {
		Type = 'Sword',
	},
	
	['Diamond Sword'] = {
		Type = 'Sword',
	},
	
	['Stone Pickaxe'] = {
		Type = 'Pickaxe',
	},
	
	['Iron Pickaxe'] = {
		Type = 'Pickaxe',
	},
	
	['Diamond Pickaxe'] = {
		Type = 'Pickaxe',
	},

	['Wooden Axe'] = {
		Type = 'Axe',
	},

	['Stone Axe'] = {
		Type = 'Axe',
	},

	['Iron Axe'] = {
		Type = 'Axe',
	},

	['Diamond Axe'] = {
		Type = 'Axe',
	},
	
	['Wooden Shovel'] = {
		Type = 'Shovel',
	},

	['Stone Shovel'] = {
		Type = 'Shovel',
	},

	['Iron Shovel'] = {
		Type = 'Shovel',
	},

	['Diamond Shovel'] = {
		Type = 'Shovel',
	},
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemsIDs = require(ReplicatedStorage.Shared.ItemsIDs)

function _init()
	
	for itemID, itemName in ipairs(ItemsIDs) do

		if not itemsData[itemName] then
			itemsData[itemName] = {}
		end
		
		itemsData[itemName]['ID'] = itemID
	end
end

-- Init
_init()

return itemsData