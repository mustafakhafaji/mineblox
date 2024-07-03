local DecorationsGenerator = {}

local StarterPlayer = game:GetService("StarterPlayer")

local TreesGenerator = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Loading.Terrain.Decorations.Trees.TreesGenerator)
--local DandelionGenerator = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Loading.Terrain.Decorations.DandelionGenerator)
--local GrassGenerator = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Loading.Terrain.Decorations.GrassGenerator)
--local PoppyGenerator = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Loading.Terrain.Decorations.PoppyGenerator)
--local OxeyeDaisyGenerator = require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.Loading.Terrain.Decorations.OxeyeDaisyGenerator)

-- PUBLIC

function DecorationsGenerator.generate(chunkBlocks: buffer, surfaceY: {}, SEED: number, chunkX: number, chunkZ: number): ({}, {})
	--local chunkKey = .5 * (chunkX + chunkZ) * (chunkX + chunkZ + 1) + chunkZ
	
	TreesGenerator.generate(chunkBlocks, surfaceY, chunkX, chunkZ)
	--GrassGenerator.generate(chunkBlocks, surfaceY, SEED, random, chunkX, chunkZ)
	--DandelionGenerator.generate(chunkBlocks, surfaceY, SEED, random, chunkX, chunkZ)
	--PoppyGenerator.generate(chunkBlocks, surfaceY, SEED, random, chunkX, chunkZ)
	--OxeyeDaisyGenerator.generate(chunkBlocks, surfaceY, SEED, random, chunkX, chunkZ)
	
	return chunkBlocks
end

return DecorationsGenerator