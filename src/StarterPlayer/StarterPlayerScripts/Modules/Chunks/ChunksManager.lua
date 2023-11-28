local ChunkLoading = {}

local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local M_WORLD_GENERATION = require(script.WORLD_GENERATION)
local M_DROPPED_OBJECTS = require(script.DROPPED_OBJECTS)
local M_CHUNK_SETTINGS = require(ReplicatedStorage.MODULE_SCRIPTS.CHUNK_SETTINGS)

local Player = Players.LocalPlayer

local BLOCK_SIZE = M_CHUNK_SETTINGS['BLOCK_SIZE']

local CHUNK_SIZE = M_CHUNK_SETTINGS['CHUNK_SIZE']
local CHUNK_DISTANCE = M_CHUNK_SETTINGS['CHUNK_DISTANCE']

local LOAD_OFFSET = 2

local CHUNKS_TO_RENDER_PER_UPDATE = 1

local loadedChunks = {}
local rendered_chunks = {}

local frames = 0

-- PRIVATE

function renderChunks(toRender: {}): ()
	
	local current_updates = 0
	
	for _, chunk in toRender do

		local chunk_x = chunk[1]
		local chunk_z = chunk[2]
		
		M_WORLD_GENERATION.render_chunk(chunk_x, chunk_z)
		M_DROPPED_OBJECTS.render_chunk(chunk_x, chunk_z)
		
		if not rendered_chunks[chunk_x] then
			rendered_chunks[chunk_x] = {}
		end
		rendered_chunks[chunk_x][chunk_z] = true
		
		current_updates += 1
		
		if current_updates > CHUNKS_TO_RENDER_PER_UPDATE then
			return
		end
	end
end


function unrenderChunks(to_unrender: {}): ()
	
	local current_updates = 0
	
	for i = #to_unrender, 1, -1 do
		
		local chunk = to_unrender[i]
		
		local chunk_x = chunk[1]
		local chunk_z = chunk[2]
		
		M_WORLD_GENERATION.unrender_chunk(chunk_x, chunk_z)
		M_DROPPED_OBJECTS.unrender_chunk(chunk_x, chunk_z)
		
		rendered_chunks[chunk_x][chunk_z] = nil
		
		current_updates += 1
		
		if current_updates > CHUNKS_TO_RENDER_PER_UPDATE then
			return
		end
	end
end


-- Calls load_chunk() on every chunk to load
function load_chunks(to_load: {}): ()
	
	for _, chunk in to_load do

		local chunk_x = chunk[1]
		local chunk_z = chunk[2]
		
		M_WORLD_GENERATION.load_chunk(chunk_x, chunk_z)
		M_DROPPED_OBJECTS.load_chunk(chunk_x, chunk_z)
		
		if not loadedChunks[chunk_x] then
			loadedChunks[chunk_x] = {}
		end
		loadedChunks[chunk_x][chunk_z] = true
	end
end


-- Calls unloadChunk on every chunk in toUnload
function unloadChunks(toUnload: {}): ()
	
	for _, chunk in toUnload do
		
		local chunk_x = chunk[1]
		local chunk_z = chunk[2]
		
		M_WORLD_GENERATION.unloadChunk(chunk_x, chunk_z)
		M_DROPPED_OBJECTS.unloadChunk(chunk_x, chunk_z)
		
		loadedChunks[chunk_x][chunk_z] = nil
	end
end


-- Returns chunks to render
function find_chunks_to_render(): ({})
	
	local character_position = Player.Character.HumanoidRootPart.Position

	local chunk_x = math.floor(character_position.X / (CHUNK_SIZE * BLOCK_SIZE))
	local chunk_z = math.floor(character_position.Z / (CHUNK_SIZE * BLOCK_SIZE))
	
	local to_render = {}
	
	local radius = CHUNK_DISTANCE

	for x = -radius, radius do
		for z = -radius, radius do
			
			local position_x = chunk_x + x
			local position_z = chunk_z + z

			if rendered_chunks[position_x] and rendered_chunks[position_x][position_z] then continue end

			local distance = x * x + z * z

			if distance <= radius * radius then
				
				--to_render[position_x][position_z] = true
				table.insert(to_render, {position_x, position_z})
			end
		end
	end
	
	return to_render
end


-- Returns chunks to unrender
function find_chunks_to_unrender(should_be_rendered: {}): ({})
	
	local character_position = Player.Character.HumanoidRootPart.Position

	local chunk_x = math.floor(character_position.X / (CHUNK_SIZE * BLOCK_SIZE))
	local chunk_z = math.floor(character_position.Z / (CHUNK_SIZE * BLOCK_SIZE))

	local should_be_rendered = {}
	local to_unrender = {}	
	
	local radius = CHUNK_DISTANCE + 1
	
	-- Find what chunks should be loaded

	for x = -radius, radius do

		local position_x = chunk_x + x
		should_be_rendered[position_x] = {}

		for z = -radius, radius do

			local position_z = chunk_z + z

			local distance = x * x + z * z

			if distance <= radius * radius then
				should_be_rendered[position_x][position_z] = true
			end
		end
	end
	
	-- Find what loaded chunks aren't in should_be_rendered
	for x in rendered_chunks do
		for z in rendered_chunks[x] do
			
			if not should_be_rendered[x] then
				table.insert(to_unrender, {x, z})
				continue
			end

			if not should_be_rendered[x][z] then
				table.insert(to_unrender, {x, z})
				continue
			end
		end
	end
	
	return to_unrender
end


-- Returns the closest chunks to the character
function find_chunks_to_load(): ({number: {chunk_x: number, chunk_z: number}})
	
	local character_position = Player.Character.HumanoidRootPart.Position

	local chunk_x = math.floor(character_position.X / (CHUNK_SIZE * BLOCK_SIZE))
	local chunk_z = math.floor(character_position.Z / (CHUNK_SIZE * BLOCK_SIZE))

	local to_load = {}
	
	local radius = CHUNK_DISTANCE + LOAD_OFFSET
	
	for x = -radius, radius do
		for z = -radius, radius do
			
			local position_x = chunk_x + x
			local position_z = chunk_z + z
			
			if loadedChunks[position_x] and loadedChunks[position_x][position_z] then continue end -- Skip if already loaded
			
			local distance = x * x + z * z
			
			if distance <= radius * radius then
				table.insert(to_load, {position_x, position_z})
			end
		end
	end
	
	return to_load
end


-- Returns chunks not within character's range
function find_chunks_to_unload(): ({})
	
	local character_position = Player.Character.HumanoidRootPart.Position

	local chunk_x = math.floor(character_position.X / (CHUNK_SIZE * BLOCK_SIZE))
	local chunk_z = math.floor(character_position.Z / (CHUNK_SIZE * BLOCK_SIZE))

	local should_be_loaded = {}
	local toUnload = {}
	
	-- Find what chunks should be loaded
	local radius = CHUNK_DISTANCE + LOAD_OFFSET

	for x = -radius, radius do
		
		local position_x = chunk_x + x
		should_be_loaded[position_x] = {}

		for z = -radius, radius do

			local position_z = chunk_z + z

			local distance = x * x + z * z

			if distance <= radius * radius then
				should_be_loaded[position_x][position_z] = true
			end
		end
	end
	
	-- Find what loaded chunks aren't in should_be_loaded
	for x in loadedChunks do
		for z in loadedChunks[x] do
			
			if not should_be_loaded[x] then
				table.insert(toUnload, {x, z})
				continue
			end
			
			if not should_be_loaded[x][z] then
				table.insert(toUnload, {x, z})
				continue
			end
		end
	end
	
	return toUnload
end


-- Reorders table of chunks based on distance from player
function reorderChunkPriority(chunks: {}): ({})
	
	local character_position = Player.Character.HumanoidRootPart.Position
	
	local player_chunk_x = math.floor(character_position.X / (CHUNK_SIZE * BLOCK_SIZE))
	local player_chunk_z = math.floor(character_position.Z / (CHUNK_SIZE * BLOCK_SIZE))
	
	table.sort(chunks, function(a, b)
		return 
			math.sqrt((a[1] - player_chunk_x) * (a[1] - player_chunk_x) + (a[2] - player_chunk_z) * (a[2] - player_chunk_z))
			< 
			math.sqrt((b[1] - player_chunk_x) * (b[1] - player_chunk_x) + (b[2] - player_chunk_z) * (b[2] - player_chunk_z))
	end)
	return chunks
end


function handleFrame(): ()
	
	frames += 1

	if 
		not Player.Character 
		or not Player.Character:FindFirstChild('HumanoidRootPart') 
		or frames % 4 ~= 0
	then
		return
	end
		
	local chunks_to_load = find_chunks_to_load()
	load_chunks(chunks_to_load)
	
	local chunks_to_render = find_chunks_to_render()
	chunks_to_render = reorderChunkPriority(chunks_to_render)
	renderChunks(chunks_to_render)
	
	local chunks_to_unload = find_chunks_to_unload()
	unloadChunks(chunks_to_unload)
	
	local chunks_to_unrender = find_chunks_to_unrender()
	chunks_to_unrender = reorderChunkPriority(chunks_to_unrender)
	unrenderChunks(chunks_to_unrender)
	
	frames = 0
end

-- EVENTS

RunService.Heartbeat:Connect(handleFrame)

return ChunkLoading