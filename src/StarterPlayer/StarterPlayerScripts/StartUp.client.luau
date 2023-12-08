local ReplicatedStorage = game:GetService('ReplicatedStorage')
local StarterPlayer = game:GetService('StarterPlayer')
local ContentProvider = game:GetService('ContentProvider')

ContentProvider:PreloadAsync(ReplicatedStorage.Extra.BreakingDecals:GetChildren()) -- Preload decals

local Modules = StarterPlayer.StarterPlayerScripts.Modules

require(Modules.Chunks.ChunksManager)
--require(Modules.Mine)
--require(Modules.Movement)
--require(Modules.Selection)
--require(Modules.Health)
--require(Modules.Inventory)
--require(Modules.Equipped)
--require(Modules.FallDamage)
--require(Modules.Footsteps)