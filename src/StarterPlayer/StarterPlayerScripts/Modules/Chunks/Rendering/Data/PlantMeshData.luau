local PlantMeshData = {}

PlantMeshData.leftVertices = {
	Vector3.new(-.5, .5, -.5),
	Vector3.new(.5, .5, .5),
	Vector3.new(-.5, -.5, -.5),
	Vector3.new(.5, -.5, .5),
}
PlantMeshData.leftIndices = {3, 4, 2, 2, 1, 3}

PlantMeshData.rightVertices = {
	Vector3.new(-.5, .5, .5),
	Vector3.new(.5, .5, -.5),
	Vector3.new(-.5, -.5, .5),
	Vector3.new(.5, -.5, -.5),
}
PlantMeshData.rightIndices = {3, 4, 2, 2, 1, 3}

return PlantMeshData