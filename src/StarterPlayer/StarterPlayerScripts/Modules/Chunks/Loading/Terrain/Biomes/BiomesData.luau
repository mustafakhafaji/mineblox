local StarterPlayer = game:GetService('StarterPlayer')

local ForestGenerator = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Loading.Terrain.Biomes.Forest.ForestGenerator)
local DesertGenerator = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Loading.Terrain.Biomes.Desert.DesertGenerator)
local JungleGenerator = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Loading.Terrain.Biomes.Jungle.JungleGenerator)
local TundraGenerator = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Loading.Terrain.Biomes.Tundra.TundraGenerator)

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