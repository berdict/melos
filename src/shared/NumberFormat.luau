--!strict
-- 1,234 -> 1.23K, 5,000,000 -> 5M, 단위: K M B T Qa Qi Sx Sp Oc No Dc
local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local NumberFormat = {}

function NumberFormat.format(n: number): string
	if n ~= n or n < 0 then
		return "0"
	end
	if n == math.huge then
		return "MAX"
	end
	if n < 1000 then
		return tostring(math.floor(n))
	end

	local index = math.floor(math.log10(n) / 3)
	if index > #SUFFIXES then
		return string.format("%.2e", n)
	end

	local scaled = n / 1000 ^ index
	if scaled >= 999.995 and index < #SUFFIXES then -- 반올림하면 1000.00이 되는 경계 (999,999 -> 1M)
		index += 1
		scaled /= 1000
	end

	-- 소수 둘째 자리까지, 뒤쪽 0 제거 (1.50 -> 1.5, 10.00 -> 10)
	local text = (string.gsub(string.format("%.2f", scaled), "%.?0+$", ""))
	return text .. SUFFIXES[index]
end

return NumberFormat
