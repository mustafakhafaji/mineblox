local StarterPlayer = game:GetService('StarterPlayer')

require(StarterPlayer.StarterPlayerScripts.Modules.Chunks.ChunksManager)
--require(StarterPlayer.StarterPlayerScripts.Modules.Lighting)

task.delay(1, function()
	require(StarterPlayer.StarterPlayerScripts.Modules.Break)
	require(StarterPlayer.StarterPlayerScripts.Modules.CollisionsManager)
end)