--!strict
-- Validate saved farming data and migrate v0.3 accounts without losing cash or aliens.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local AlienData = require(shared:WaitForChild("AlienData"))
local FarmData = require(shared:WaitForChild("FarmData"))
local Schema = {}

local function integer(value: any, fallback: number, maximum: number): number
	if typeof(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return fallback end
	return math.clamp(math.floor(value), 0, maximum)
end

function Schema.Normalize(raw: any): any
	local source = if typeof(raw) == "table" then raw else {}
	local aliens = {}; local owned = {}
	if typeof(source.Aliens) == "table" then
		for _, id in source.Aliens do
			if #aliens >= AlienData.MaxAliens then break end
			if typeof(id) == "string" and AlienData.Aliens[id] then table.insert(aliens, id); owned[id] = true end
		end
	end
	if #aliens == 0 then table.insert(aliens, AlienData.StarterAlienId); owned[AlienData.StarterAlienId] = true end
	local equipped = {}; local equippedSet = {}
	if typeof(source.Equipped) == "table" then
		for _, id in source.Equipped do
			if #equipped >= AlienData.MaxEquipped then break end
			if typeof(id) == "string" and owned[id] and not equippedSet[id] then table.insert(equipped, id); equippedSet[id] = true end
		end
	else table.insert(equipped, aliens[1]) end
	local discovered = { [AlienData.StarterAlienId] = true }
	for _, id in AlienData.AlienOrder do
		if owned[id] or (typeof(source.Discovered) == "table" and source.Discovered[id] == true) then discovered[id] = true end
	end
	local farming = source.FarmVersion == 1
	local cash = integer(source.Cash, AlienData.StartingCash, 1e12)
	-- Old stored slime is exchanged once during migration; farming saves have no slime field.
	if not farming then cash = math.min(1e12, cash + integer(source.Slime, 0, 1e12)) end
	local seeds = if farming then {} else table.clone(FarmData.StartingSeeds)
	local harvest = {}; local baseValue = 0; local maximumValue = 0
	for id, crop in FarmData.Crops do
		if farming and typeof(source.Seeds) == "table" then seeds[id] = integer(source.Seeds[id], 0, 100000) end
		if not crop.Event and farming and typeof(source.Harvest) == "table" then
			local count = integer(source.Harvest[id], 0, 100000)
			harvest[id] = count; baseValue += count * crop.SellValue
			local bonus = if crop.Category == "Crystal" then 1.35 elseif crop.Category == "Berry" then 1.25 else 1
			maximumValue += count * crop.SellValue * 3 * bonus
		end
	end
	local tools = {}
	for id in FarmData.Tools do if farming and typeof(source.Tools) == "table" and source.Tools[id] == true then tools[id] = true end end
	local beds = {}
	for i = 1, FarmData.BedCount do
		local old = if farming and typeof(source.Beds) == "table" then source.Beds[i] else nil
		local bed = {}
		if typeof(old) == "table" and typeof(old.CropId) == "string" and FarmData.Crops[old.CropId] then
			local progress = old.Progress
			if typeof(progress) ~= "number" or progress ~= progress or math.abs(progress) == math.huge then progress = 0 end
			local mutation = if typeof(old.Mutation) == "string" and FarmData.MutationMultiplier[old.Mutation] then old.Mutation else "Normal"
			bed = { CropId = old.CropId, Progress = math.clamp(progress, 0, 1), Watered = old.Watered == true,
				Mutation = if FarmData.Crops[old.CropId].Event then "Normal" else mutation }
		end
		beds[i] = bed
	end
	return { FarmVersion = 1, Cash = cash, Aliens = aliens, Equipped = equipped, Discovered = discovered,
		LabLevel = integer(source.LabLevel, 0, #AlienData.UpgradePrices), Seeds = seeds, Harvest = harvest,
		HarvestValue = math.max(baseValue, integer(source.HarvestValue, baseValue, math.min(1e12, math.floor(maximumValue)))),
		Tools = tools, Beds = beds, EventActive = farming and source.EventActive == true,
		EventProgress = if farming and source.EventActive == true then integer(source.EventProgress, 0, FarmData.Event.Required) else 0,
		EventCompletions = integer(source.EventCompletions, 0, 1000000) }
end

return Schema
