local ReplicatedStorage = game:GetService('ReplicatedStorage')
local StarterPlayer = game:GetService('StarterPlayer')

game:GetService('ContentProvider'):PreloadAsync(ReplicatedStorage.EXTRA.STAGES:GetChildren()) -- Preload decals

local Modules = StarterPlayer.StarterPlayerScripts.MODULE_SCRIPTS

local ChunkLoading = require(Modules.CHUNK_LOADING)
local Mine = require(Modules.MINE)
local Movement = require(Modules.MOVEMENT)
local Selection = require(Modules.SELECTION)
local Health = require(Modules.HEALTH)
local Inventory = require(Modules.INVENTORY)
local Equipped = require(Modules.EQUIPPED)
local FallDamage = require(Modules.FALL_DAMAGE)
local FootSteps = require(Modules.FOOTSTEPS)