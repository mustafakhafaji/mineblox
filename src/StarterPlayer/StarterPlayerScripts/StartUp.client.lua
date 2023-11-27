local ReplicatedStorage = game:GetService('ReplicatedStorage')
local StarterPlayer = game:GetService('StarterPlayer')
local ContentProvider = game:GetService('ContentProvider')

ContentProvider:PreloadAsync(ReplicatedStorage.Extra.Stages:GetChildren()) -- Preload decals

local Modules = StarterPlayer.StarterPlayerScripts.Modules

require(Modules.ChunkLoading)
--require(Modules.Mine)
--require(Modules.Movement)
require(Modules.Selection)
--require(Modules.Health)
--require(Modules.Inventory)
--require(Modules.Equipped)
require(Modules.FallDamage)
--require(Modules.Footsteps)