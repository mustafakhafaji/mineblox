local DecorationsGenerator = {}

local StarterPlayer = game:GetService("StarterPlayer")

local Modules = StarterPlayer.StarterPlayerScripts.Modules

local TreesGenerator = require(Modules.Chunks.Terrain.Decorations.Trees.TreesGenerator)
local DandelionGenerator = require(Modules.Chunks.Terrain.Decorations.DandelionGenerator)
local GrassGenerator = require(Modules.Chunks.Terrain.Decorations.GrassGenerator)
local PoppyGenerator = require(Modules.Chunks.Terrain.Decorations.PoppyGenerator)
local OxeyeDaisyGenerator = require(Modules.Chunks.Terrain.Decorations.OxeyeDaisyGenerator)

-- PUBLIC

function DecorationsGenerator.generate(chunkBlocks: {}, surfaceY: {}, SEED: number, chunkX: number, chunkZ: number): ({}, {})
	
	local preloadedBlocks = {}
	
	local chunkKey = .5 * (chunkX + chunkZ) * (chunkX + chunkZ + 1) + chunkZ
	local random = Random.new(SEED + chunkKey)
	
	chunkBlocks, preloadedBlocks = TreesGenerator.generate(chunkBlocks, preloadedBlocks, surfaceY, random, chunkX, chunkZ)
	chunkBlocks = GrassGenerator.generate(chunkBlocks, surfaceY, SEED, random, chunkX, chunkZ)
	chunkBlocks = DandelionGenerator.generate(chunkBlocks, surfaceY, SEED, random, chunkX, chunkZ)
	chunkBlocks = PoppyGenerator.generate(chunkBlocks, surfaceY, SEED, random, chunkX, chunkZ)
	chunkBlocks = OxeyeDaisyGenerator.generate(chunkBlocks, surfaceY, SEED, random, chunkX, chunkZ)
	
	return chunkBlocks, preloadedBlocks
end

return DecorationsGenerator