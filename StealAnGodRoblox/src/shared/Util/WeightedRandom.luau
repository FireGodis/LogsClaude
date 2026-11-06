--[[
	WeightedRandom — deterministic-friendly weighted picks.
]]

local WeightedRandom = {}

-- entries: array of items; weightOf: function(item) -> number. rng optional Random.
function WeightedRandom.pick(entries, weightOf, rng: Random?)
	local total = 0
	for _, e in entries do
		total += math.max(0, weightOf(e))
	end
	if total <= 0 then
		return entries[1]
	end
	local r = (rng and rng:NextNumber() or math.random()) * total
	for _, e in entries do
		r -= math.max(0, weightOf(e))
		if r <= 0 then
			return e
		end
	end
	return entries[#entries]
end

-- weights: array of numbers -> returns index
function WeightedRandom.index(weights: { number }, rng: Random?): number
	local total = 0
	for _, w in weights do
		total += w
	end
	local r = (rng and rng:NextNumber() or math.random()) * total
	for i, w in weights do
		r -= w
		if r <= 0 then
			return i
		end
	end
	return #weights
end

return WeightedRandom
