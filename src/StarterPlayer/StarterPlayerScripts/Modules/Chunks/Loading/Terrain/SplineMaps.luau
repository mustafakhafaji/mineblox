--!native
local SplineMaps = {}

local continentalnessBaseHeight: number = 15
local erosionBaseHeight: number = 15
local peaksAndValleysBaseHeight: number = 25

local continentalnessTerrainHeightOffsetSpline = {
	{-1, continentalnessBaseHeight * 0},
	{-0.8, continentalnessBaseHeight * .1},
	{-0.5, continentalnessBaseHeight * .2},
	{-.3, continentalnessBaseHeight * .32},
	{-.1, continentalnessBaseHeight * .5},
	{0, continentalnessBaseHeight * .85},
	{.15, continentalnessBaseHeight * 1},
	{1, continentalnessBaseHeight * 1},
}

local continentalnessSquashFactorSpline = {
	{},
	{}
}

local erosionTerrainHeightOffsetSpline = {
	{-1, erosionBaseHeight * 0},
	{-.6, erosionBaseHeight * .2},
	{-.3, erosionBaseHeight * .4},
	{0, erosionBaseHeight * .65},
	{0.2, erosionBaseHeight * .8},
	{.3, erosionBaseHeight * 1},
	{1, erosionBaseHeight * 1},
}

local erosionSquashFactorSpline = {
	{0, 1},
	{.1, .75},
	{.275, .6},
	{.3, .675},
	{.475, .15},
	{.6, .13},
	{.7, .13},
	{.72, .3},
	{.8, .3},
	{.82, .13},
	{1, .05}
}

local peaksAndValleysTerrainHeightOffsetSpline = {
	{-1, .4},
	{-0.3, peaksAndValleysBaseHeight * .25},
	{-0.1, 0},
	{0, peaksAndValleysBaseHeight * .25},
	{.35, peaksAndValleysBaseHeight},
	{.45, peaksAndValleysBaseHeight * .6},
	{.5, peaksAndValleysBaseHeight * .3},
	{1, peaksAndValleysBaseHeight}
}

local peaksAndValleysSquashFactorSpline = {
	{0, 0},
	{.1, .1},
	{.33, .33},
	{.4, .35},
	{.6, .85},
	{1, 1}
}


-- PRIVATE

function evaluateSpline(sequence: {}, x: number): (number)
	if x <= -1 then
		return sequence[1][2]
	elseif x >= 1 then
		return sequence[#sequence][2]
	end

	for i = 1, #sequence - 1 do
		local currentKeypoint = sequence[i]
		local nextKeypoint = sequence[i + 1]

		if x >= currentKeypoint[1] and x < nextKeypoint[1] then
			local t = (x - currentKeypoint[1]) / (nextKeypoint[1] - currentKeypoint[1])
			return (1 - t) * currentKeypoint[2] + t * nextKeypoint[2]
		end
	end
end

-- PUBLIC

function SplineMaps.getContinentalnessTerrainHeightOffset(x: number): (number)
	return evaluateSpline(continentalnessTerrainHeightOffsetSpline, x)
end


function SplineMaps.getErosionTerrainHeightOffset(x: number): (number)
	return evaluateSpline(erosionTerrainHeightOffsetSpline, x)
end


function SplineMaps.getPeaksAndValleysTerrainHeightOffset(x: number): (number)
	return evaluateSpline(peaksAndValleysTerrainHeightOffsetSpline, x)
end


function SplineMaps.getContinentalnessSquashFactor(x: number): (number)
	return evaluateSpline(continentalnessSquashFactorSpline, x)
end


function SplineMaps.getErosionSquashFactor(x: number): (number)
	return evaluateSpline(erosionSquashFactorSpline, x)
end


function SplineMaps.getPeaksAndValleysSquashFactor(x: number): (number)
	return evaluateSpline(peaksAndValleysSquashFactorSpline, x)
end


return SplineMaps
