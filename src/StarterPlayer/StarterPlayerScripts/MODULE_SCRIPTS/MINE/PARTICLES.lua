local PARTICLES = {}

--// Services
local S_RS = game:GetService('ReplicatedStorage')

--// Variables
local surface_particle = nil




--// Particle for when a block is mined
function PARTICLES.break_particle(block: BasePart)

	if not block then return end
	
	local particle = S_RS.EXTRA.PARTICLES.BREAK_PARTICLE:Clone()
	
	
	particle['1'].Color = ColorSequence.new(block.Color)
	particle['2'].Color = ColorSequence.new(block.Color)
	particle.Position = block.Position
	particle.Parent = workspace.IGNORE
	
	coroutine.wrap(function()
		wait(.05)
		particle['1'].Rate = 0
		particle['2'].Rate = 0

		wait(3)
		particle:Destroy()
	end)()
end




--// Particles for when mining a block (on the surface of the block)
function PARTICLES.start_surface(block: Instance, normal: Vector3)
	
	if not normal then return end

	local particle = S_RS.EXTRA.PARTICLES.SURFACE_PARTICLE:Clone()
	particle['1'].Color = ColorSequence.new(block.Color)
	particle['2'].Color = ColorSequence.new(block.Color)

	local values = {normal.x, normal.y, normal.z}

	for i, value in values do
		if value == 0 then
			values[i] = 2.5
		else
			values[i] = .1
		end
	end

	particle.Size = Vector3.new(values[1], values[2], values[3])
	particle.Position = block.Position + normal * 1.5
	particle.Parent = workspace.IGNORE

	surface_particle = particle
end




--// End particles on the surface of block 
function PARTICLES.end_surface()
	
	if surface_particle then
		
		local particle = surface_particle
		particle['1'].Rate = 0
		particle['2'].Rate = 0

		coroutine.wrap(function()
			wait(3)
			particle:Destroy()
		end)()
	end
	
	surface_particle = nil
end




return PARTICLES