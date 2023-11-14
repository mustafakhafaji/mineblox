-- Preload stages decals
game:GetService('ContentProvider'):PreloadAsync(game:GetService('ReplicatedStorage').EXTRA.STAGES:GetChildren())

--// Services
local S_SP = game:GetService('StarterPlayer')

--// Modules
local MODULES = S_SP.StarterPlayerScripts.MODULE_SCRIPTS

local M_CHUNK_LOADING = require(MODULES.CHUNK_LOADING)
local M_MINE = require(MODULES.MINE)
local M_MOVEMENT = require(MODULES.MOVEMENT)
local M_SELECTION = require(MODULES.SELECTION)
local M_HEALTH = require(MODULES.HEALTH)
local M_INVENTORY = require(MODULES.INVENTORY)
local M_EQUIPPED = require(MODULES.EQUIPPED)
local M_FALL_DAMAGE = require(MODULES.FALL_DAMAGE)
local M_FOOTSTEPS = require(MODULES.FOOTSTEPS)