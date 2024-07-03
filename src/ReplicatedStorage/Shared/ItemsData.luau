local itemsData = {
	Air = {
		isTransparent = true,
	},

	Water = {
		isTransparent = true,
	},

	Stone = {
		Hardness = 20,
		PreferredTool = 'Pickaxe',
		DropItem = 'Cobblestone',
		Type = 'Block',
	},

	Cobblestone = {
		Hardness = 20,
		PreferredTool = 'Pickaxe',
		Type = 'Block',
	},

	['Grass Block'] = {
		Hardness = 6,
		PreferredTool = 'Shovel',
		DropItem = 'Dirt',
		Type = 'Block',
	},

	Dirt = {
		Hardness = 5,
		PreferredTool = 'Shovel',
		Type = 'Block',
	},

	['Oak Wood Planks'] = {
		Hardness = 20,
		PreferredTool = 'Axe',
		Type = 'Block',
	},

	Bedrock = {},

	Sand = {
		Hardness = 8,
		PreferredTool = 'Shovel',
		Type = 'Block',
	},

	['Oak Log'] = {
		Hardness = 20,
		PreferredTool = 'Axe',
		Type = 'Block',
	},

	['Oak Leaves'] = {
		Hardness = 2,
		Type = 'Block',
		isTransparent = true,
	},

	Glass = {
		isTransparent = true,
	},

	['Coal Ore'] = {
		Hardness = 30,
		PreferredTool = 'Pickaxe',
		DropItem = 'Coal',
		Type = 'Block',
	},

	['Gold Ore'] = {
		Hardness = 30,
		PreferredTool = 'Pickaxe',
		DropItem = 'Raw Gold',
		Type = 'Block',
	},

	['Iron Ore'] = {
		Hardness = 30,
		PreferredTool = 'Pickaxe',
		DropItem = 'Raw Iron',
		Type = 'Block',
	},

	['Diamond Ore'] = {
		Hardness = 30,
		PreferredTool = 'Pickaxe',
		DropItem = 'Diamond',
		Type = 'Block',
	},

	['Wooden Pickaxe'] = {
		Type = 'Pickaxe',
	},

	Dandelion = {
		Hardness = 0,
		Type = 'Plant',
	},
	
	Grass = {
		Hardness = 0,
		Type = 'Plant',
	},

	['Oxeye Daisy'] = {
		Hardness = 0,
		Type = 'Plant',
	},
	
	Poppy = {
		Hardness = 0,
		Type = 'Plant',
	},
	
	Clay = {
		Hardness = 6,
		PreferredTool = 'Shovel',
		Type = 'Block',
	},
	
	Gravel = {
		Hardness = 6,
		PreferredTool = 'Shovel',
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