--!strict
-- 어비스리움식 단위: 1A=1000, 1B=1000A, ..., 1Z, 1AA, 1AB ...
local NumberFormat = {}

local function suffix(index: number): string
	local result = ""
	while index > 0 do
		index -= 1
		result = string.char(65 + index % 26) .. result
		index = index // 26
	end
	return result
end

function NumberFormat.format(n: number): string
	if n ~= n then
		return "0"
	end
	if n == math.huge then
		return "MAX"
	end
	if n < 1000 then
		return tostring(math.floor(n))
	end
	local index = math.floor(math.log10(n) / 3)
	local scaled = n / 1000 ^ index
	if scaled >= 1000 then
		index += 1
		scaled /= 1000
	end
	return string.format("%.2f%s", scaled, suffix(index))
end

return NumberFormat
