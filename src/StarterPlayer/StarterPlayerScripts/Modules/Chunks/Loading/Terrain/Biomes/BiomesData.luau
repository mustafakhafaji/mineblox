local Players = game:GetService('Players')

local Player: Player = Players.LocalPlayer
local PlayerScripts = Player.PlayerScripts

local Modules = PlayerScripts:WaitForChild('Modules')

local ForestGenerator = require(Modules.Chunks.Loading.Terrain.Biomes.Forest.ForestGenerator)
local DesertGenerator = require(Modules.Chunks.Loading.Terrain.Biomes.Desert.DesertGenerator)
local JungleGenerator = require(Modules.Chunks.Loading.Terrain.Biomes.Jungle.JungleGenerator)
local TundraGenerator = require(Modules.Chunks.Loading.Terrain.Biomes.Tundra.TundraGenerator)

return {
	{
		temperature = {
			min = -1,
			max = 1
		},
		humidity = {
			min = -2,
			max = 0
		},
		biomeGenerator = ForestGenerator
	},
	{
		temperature = {
			min = 1,
			max = 2
		},
		humidity = {
			min = -2,
			max = 2
		},
		biomeGenerator = DesertGenerator
	},
	{
		temperature = {
			min = -1,
			max = 1
		},
		humidity = {
			min = 0,
			max = 2
		},
		biomeGenerator = JungleGenerator
	},
	{
		temperature = {
			min = -2,
			max = -1
		},
		humidity = {
			min = -2,
			max = 2
		},
		biomeGenerator = TundraGenerator
	},
}