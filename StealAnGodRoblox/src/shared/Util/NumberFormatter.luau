--[[
	NumberFormatter — compact formatting for very large numbers (K, M, B, T, Qa, Qi, Sx, Sp, Oc, No, Dc ...).
	Pure module; safe on client and server.
]]

local NumberFormatter = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td", "Qad", "Qid" }

local function trimZeros(s: string): string
	if string.find(s, "%.") then
		s = string.gsub(s, "0+$", "")
		s = string.gsub(s, "%.$", "")
	end
	return s
end

-- Formats a number as e.g. 1.25M. decimals defaults to 2.
function NumberFormatter.format(n: number?, decimals: number?): string
	local value = tonumber(n) or 0
	if value ~= value then
		return "0" -- NaN guard
	end
	if value == math.huge then
		return "∞"
	end
	local negative = value < 0
	value = math.abs(value)
	local places = decimals or 2

	local text
	if value < 1000 then
		if value >= 100 or value == math.floor(value) then
			text = tostring(math.floor(value))
		else
			text = trimZeros(string.format("%.1f", value))
		end
	else
		local tier = math.floor(math.log10(value) / 3)
		if tier >= #SUFFIXES then
			text = string.format("%.2e", value)
		else
			local scaled = value / (10 ^ (tier * 3))
			-- floor to avoid showing 1000K due to rounding
			local factor = 10 ^ places
			scaled = math.floor(scaled * factor) / factor
			if scaled >= 1000 and tier + 1 < #SUFFIXES then
				tier += 1
				scaled = scaled / 1000
			end
			text = trimZeros(string.format("%." .. places .. "f", scaled)) .. SUFFIXES[tier + 1]
		end
	end
	return (negative and "-" or "") .. text
end

-- Full number with thousands separators (for small values / tooltips).
function NumberFormatter.commas(n: number): string
	local s = tostring(math.floor(tonumber(n) or 0))
	local out = s
	while true do
		local replaced
		out, replaced = string.gsub(out, "^(-?%d+)(%d%d%d)", "%1.%2")
		if replaced == 0 then
			break
		end
	end
	return out
end

-- Seconds -> "1h 05m", "4m 03s", "12s"
function NumberFormatter.time(seconds: number?): string
	local s = math.max(0, math.floor(tonumber(seconds) or 0))
	local h = s // 3600
	local m = (s % 3600) // 60
	local sec = s % 60
	if h > 0 then
		return string.format("%dh %02dm", h, m)
	elseif m > 0 then
		return string.format("%dm %02ds", m, sec)
	end
	return string.format("%ds", sec)
end

return NumberFormatter
