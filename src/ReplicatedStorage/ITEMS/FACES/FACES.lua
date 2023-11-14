local FACES = {
	[Vector3.new(3, 0, 0)] = Enum.NormalId.Top,
	[Vector3.new(-3, 0, 0)] = Enum.NormalId.Bottom,
	[Vector3.new(0, 0, 3)] = Enum.NormalId.Left,
	[Vector3.new(0, 0, -3)] = Enum.NormalId.Right,
	[Vector3.new(0, 3, 0)] = Enum.NormalId.Front,
	[Vector3.new(0, -3, 0)] = Enum.NormalId.Back
}

return FACES
