local BlockMeshData = {}

BlockMeshData.rightVertices = {
	Vector3.new(.5, .5, .5),
	Vector3.new(.5, .5, -.5),
	Vector3.new(.5, -.5, .5),
	Vector3.new(.5, -.5, -.5)
}
BlockMeshData.rightIndices = {3, 4, 2, 2, 1, 3}

BlockMeshData.leftVertices = {
	Vector3.new(-.5, .5, -.5),
	Vector3.new(-.5, .5, .5),
	Vector3.new(-.5, -.5, -.5),
	Vector3.new(-.5, -.5, .5)
}
BlockMeshData.leftIndices = {3, 4, 2, 2, 1, 3}

BlockMeshData.topVertices = {
	Vector3.new(-.5, .5, -.5),
	Vector3.new(.5, .5, -.5),
	Vector3.new(-.5, .5, .5),
	Vector3.new(.5, .5, .5)
}
BlockMeshData.topIndices = {3, 4, 2, 2, 1, 3}

BlockMeshData.bottomVertices = {
	Vector3.new(-.5, -.5, -.5),
	Vector3.new(.5, -.5, -.5),
	Vector3.new(-.5, -.5, .5),
	Vector3.new(.5, -.5, .5)
}
BlockMeshData.bottomIndices = {2, 4, 3, 3, 1, 2}

BlockMeshData.frontVertices = {
	Vector3.new(-.5, .5, .5),
	Vector3.new(.5, .5, .5),
	Vector3.new(-.5, -.5, .5),
	Vector3.new(.5, -.5, .5),
}
BlockMeshData.frontIndices = {3, 4, 2, 2, 1, 3}

BlockMeshData.backVertices = {
	Vector3.new(-.5, .5, -.5),
	Vector3.new(.5, .5, -.5),
	Vector3.new(-.5, -.5, -.5),
	Vector3.new(.5, -.5, -.5),
}
BlockMeshData.backIndices = {2, 4, 3, 3, 1, 2}

return BlockMeshData