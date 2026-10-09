--!strict
-- Private farming state. Clients request actions; the server checks and charges them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local AlienData = require(shared:WaitForChild("AlienData"))
local FarmData = require(shared:WaitForChild("FarmData"))
local LabService = {}
local profiles: { [Player]: any } = {}
local random = Random.new()

local function failure(message: string): AlienData.Result return { Success = false, Message = message } end
local function success(message: string): AlienData.Result return { Success = true, Message = message } end
local function copyBeds(beds: { any }): { any }
	local copy = {}
	for i = 1, FarmData.BedCount do copy[i] = table.clone(beds[i]) end
	return copy
end

local function has(profile: any, id: string): boolean return table.find(profile.Equipped, id) ~= nil end
local function growthBonus(profile: any): number
	return profile.LabLevel * AlienData.BonusPerLevel + (if has(profile, "Slimelet") then 0.1 else 0)
		+ (if profile.Tools.Sprinkler then 0.2 else 0)
end
local function weakest(profile: any): (number, string)
	local index = 1
	for i, id in profile.Aliens do
		-- This old ranking field is retained for save compatibility, not passive income.
		if AlienData.Aliens[id].SlimePerSecond < AlienData.Aliens[profile.Aliens[index]].SlimePerSecond then index = i end
	end
	return index, profile.Aliens[index]
end
local function setCash(profile: any, cash: number)
	profile.Cash = math.min(1e12, cash)
	profile.CashValue.Value = profile.Cash
end

function LabService.AddPlayer(player: Player, saved: any?, status: string?)
	if profiles[player] then return end
	local beds = {}; for i = 1, FarmData.BedCount do beds[i] = {} end
	local leaderstats = Instance.new("Folder"); leaderstats.Name = "leaderstats"
	local cash = Instance.new("IntValue"); cash.Name = "Cash"
	cash.Value = if saved then saved.Cash else AlienData.StartingCash
	cash.Parent = leaderstats; leaderstats.Parent = player
	profiles[player] = {
		Cash = cash.Value, CashValue = cash,
		Aliens = if saved then table.clone(saved.Aliens) else { AlienData.StarterAlienId },
		Equipped = if saved then table.clone(saved.Equipped) else { AlienData.StarterAlienId },
		Discovered = if saved then table.clone(saved.Discovered) else { [AlienData.StarterAlienId] = true },
		LabLevel = if saved then saved.LabLevel else 0,
		Seeds = if saved then table.clone(saved.Seeds) else table.clone(FarmData.StartingSeeds),
		Harvest = if saved then table.clone(saved.Harvest) else {},
		HarvestValue = if saved then saved.HarvestValue else 0,
		Tools = if saved then table.clone(saved.Tools) else {},
		Beds = if saved then copyBeds(saved.Beds) else beds,
		EventActive = if saved then saved.EventActive else false,
		EventProgress = if saved then saved.EventProgress else 0,
		EventCompletions = if saved then saved.EventCompletions else 0,
		SelectedSeed = "StarCarrot", SelectedAction = "Plant",
		SaveStatus = status or "Session mode", NextHatchAt = 0, NextSellAt = 0,
	}
end

function LabService.RemovePlayer(player: Player) profiles[player] = nil end
function LabService.SetSaveStatus(player: Player, status: string)
	if profiles[player] then profiles[player].SaveStatus = status end
end

function LabService.Export(player: Player): any?
	local p = profiles[player]; if not p then return nil end
	return { FarmVersion = 1, Cash = p.Cash, Aliens = table.clone(p.Aliens), Equipped = table.clone(p.Equipped),
		Discovered = table.clone(p.Discovered), LabLevel = p.LabLevel, Seeds = table.clone(p.Seeds),
		Harvest = table.clone(p.Harvest), HarvestValue = p.HarvestValue, Tools = table.clone(p.Tools),
		Beds = copyBeds(p.Beds), EventActive = p.EventActive, EventProgress = p.EventProgress, EventCompletions = p.EventCompletions }
end

function LabService.GetState(player: Player): AlienData.State?
	local p = profiles[player]; if not p then return nil end
	local count = 0; for _, amount in p.Harvest do count += amount end
	local discovered = {}; for _, id in AlienData.AlienOrder do if p.Discovered[id] then table.insert(discovered, id) end end
	return { Cash = p.Cash, AlienCount = #p.Aliens, LabLevel = p.LabLevel, Discovered = discovered,
		SaveStatus = p.SaveStatus, WeakestAlienId = select(2, weakest(p)),
		HatchCooldownRemaining = math.max(0, p.NextHatchAt - os.clock()), LastHatchedAlienId = p.LastHatchedAlienId,
		OwnedAliens = table.clone(p.Aliens), Equipped = table.clone(p.Equipped), Seeds = table.clone(p.Seeds),
		Harvest = table.clone(p.Harvest), HarvestCount = count, SellValue = p.HarvestValue,
		Tools = table.clone(p.Tools), Beds = copyBeds(p.Beds), SelectedSeed = p.SelectedSeed, SelectedAction = p.SelectedAction,
		GrowthBonus = growthBonus(p), EventActive = p.EventActive, EventProgress = p.EventProgress, EventCompletions = p.EventCompletions }
end

function LabService.Tick(player: Player, elapsed: number)
	local p = profiles[player]; if not p then return end
	local speed = 1 + growthBonus(p)
	for _, bed in p.Beds do
		if bed.CropId then
			-- Only online server time grows crops. Aliens produce no cash or slime.
			bed.Progress = math.min(1, bed.Progress + math.clamp(elapsed, 0, 5) * speed / FarmData.Crops[bed.CropId].GrowSeconds)
		end
	end
end

function LabService.BuySeed(player: Player, id: any): AlienData.Result
	local p = profiles[player]; if not p then return failure("Your garden is loading.") end
	if typeof(id) ~= "string" or not FarmData.Crops[id] or FarmData.Crops[id].Event then return failure("That seed is not sold here.") end
	local crop = FarmData.Crops[id]
	if p.Cash < crop.SeedPrice then return failure("You need more cash for this seed.") end
	if (p.Seeds[id] or 0) >= 100000 then return failure("Your seed bag is full for this crop.") end
	setCash(p, p.Cash - crop.SeedPrice); p.Seeds[id] = (p.Seeds[id] or 0) + 1
	return success("Bought one " .. crop.DisplayName .. " seed. Select it in your farm menu!")
end

function LabService.BuyTool(player: Player, id: any): AlienData.Result
	local p = profiles[player]; if not p then return failure("Your garden is loading.") end
	if typeof(id) ~= "string" or not FarmData.Tools[id] then return failure("That tool does not exist.") end
	if p.Tools[id] then return failure("You already own this tool.") end
	local tool = FarmData.Tools[id]
	if p.Cash < tool.Price then return failure("You need more cash for this tool.") end
	setCash(p, p.Cash - tool.Price); p.Tools[id] = true
	return success(tool.DisplayName .. " unlocked! " .. tool.Description)
end

function LabService.SelectSeed(player: Player, id: any): AlienData.Result
	local p = profiles[player]; if not p then return failure("Your garden is loading.") end
	if typeof(id) ~= "string" or not FarmData.Crops[id] or (p.Seeds[id] or 0) <= 0 then return failure("Buy or collect this seed first.") end
	p.SelectedSeed = id; p.SelectedAction = "Plant"
	return success("Selected " .. FarmData.Crops[id].DisplayName .. ". Walk to an empty bed and press E.")
end

function LabService.SelectAction(player: Player, action: any): AlienData.Result
	local p = profiles[player]; if not p then return failure("Your garden is loading.") end
	if action ~= "Plant" and action ~= "Water" and action ~= "Harvest" then return failure("Unknown garden action.") end
	p.SelectedAction = action
	return success(action .. " mode selected. Walk to one of your beds and press E.")
end

function LabService.InteractBed(player: Player, index: any, action: any?): AlienData.Result
	local p = profiles[player]; if not p then return failure("Your garden is loading.") end
	if typeof(index) ~= "number" or index ~= index or index % 1 ~= 0 or index < 1 or index > FarmData.BedCount then return failure("Invalid planting bed.") end
	local selectedAction = action or p.SelectedAction
	if selectedAction ~= "Plant" and selectedAction ~= "Water" and selectedAction ~= "Harvest" then return failure("Unknown garden action.") end
	local bed = p.Beds[index]
	if bed.CropId and bed.Progress >= 1 then
		local id = bed.CropId; local crop = FarmData.Crops[id]
		if crop.Event then
			if not p.EventActive then return failure("Speak to the plaza researcher to start this quest.") end
			p.EventProgress = math.min(FarmData.Event.Required, p.EventProgress + 1)
			p.Beds[index] = {}
			return success(string.format("Nebula Sprout delivered: %d / %d. Return to the researcher when ready!", p.EventProgress, FarmData.Event.Required))
		end
		if (p.Harvest[id] or 0) >= 100000 then return failure("Sell your harvest bag before collecting more of this crop.") end
		local value = crop.SellValue * FarmData.MutationMultiplier[bed.Mutation]
		if crop.Category == "Berry" and has(p, "Blossom") then value *= 1.25 end
		if crop.Category == "Crystal" and has(p, "Ember") then value *= 1.35 end
		p.Harvest[id] = (p.Harvest[id] or 0) + 1
		p.HarvestValue = math.min(1e12, p.HarvestValue + math.floor(value))
		p.Beds[index] = {}
		return success(crop.DisplayName .. " harvested! Sell your harvest at the market.")
	end
	if selectedAction == "Harvest" then return failure("This bed has no ripe crop yet.") end
	-- E uses the obvious action for the bed: plant an empty bed, water a growing
	-- crop, and pick a ripe one. The journal can also select Water explicitly.
	if bed.CropId and selectedAction == "Plant" then selectedAction = "Water" end
	if selectedAction == "Water" then
		if not bed.CropId then return failure("Plant a seed before watering.") end
		if bed.Watered then return failure("This crop is watered and growing. Come back when it is ripe!") end
		bed.Watered = true
		local boost = (if p.Tools.WateringCan then 0.30 else 0.15) + (if has(p, "Glowbug") then 0.10 else 0)
		bed.Progress = math.min(1, bed.Progress + boost)
		return success("Watered! Growth advanced by " .. math.floor(boost * 100) .. "%.")
	end
	if bed.CropId then return failure("This crop is growing. Select Water to help it, or harvest when ripe.") end
	local id = p.SelectedSeed; local crop = FarmData.Crops[id]
	if (p.Seeds[id] or 0) <= 0 then return failure("No seeds left. Visit the seed shop or select another seed.") end
	if crop.Event and not p.EventActive then return failure("Start the researcher quest before planting its seeds.") end
	p.Seeds[id] -= 1
	if not crop.Event and has(p, "Frost") and random:NextNumber() < 0.2 then p.Seeds[id] += 1 end
	local cosmic = if has(p, "Nebula") then 0.04 else 0
	local golden = (if has(p, "Starling") then 0.08 else 0) + (if p.Tools.Scanner then 0.05 else 0)
	local roll = random:NextNumber()
	local mutation = if crop.Event then "Normal" elseif roll < cosmic then "Cosmic" elseif roll < cosmic + golden then "Golden" else "Normal"
	p.Beds[index] = { CropId = id, Progress = 0, Watered = false, Mutation = mutation }
	return success("Planted " .. crop.DisplayName .. ". Water once to speed it up!")
end

function LabService.SellHarvest(player: Player): AlienData.Result
	local p = profiles[player]; if not p then return failure("Your garden is loading.") end
	local now = os.clock()
	if now < p.NextSellAt then return failure("Please wait before selling again.") end
	p.NextSellAt = now + AlienData.SellCooldown
	if p.HarvestValue <= 0 then return failure("Your harvest bag is empty. Grow and harvest a crop first.") end
	local earned = p.HarvestValue
	p.HarvestValue = 0; table.clear(p.Harvest)
	setCash(p, p.Cash + earned)
	return success(string.format("Harvest sold for $%d!", earned))
end

function LabService.ClaimEvent(player: Player): AlienData.Result
	local p = profiles[player]; if not p then return failure("Your garden is loading.") end
	local event = FarmData.Event
	if not p.EventActive then
		p.EventActive = true; p.EventProgress = 0
		p.Seeds[event.CropId] = event.Required
		p.SelectedSeed = event.CropId; p.SelectedAction = "Plant"
		return success("Quest accepted! Grow and harvest 3 Nebula Sprouts, then return here for your rewards.")
	end
	if p.EventProgress < event.Required then return failure(string.format("Grow %d more Nebula Sprouts, then come back for your reward!", event.Required - p.EventProgress)) end
	p.EventActive = false; p.EventProgress = 0; p.EventCompletions += 1
	setCash(p, p.Cash + event.CashReward)
	p.Seeds[event.SeedRewardId] = math.min(100000, (p.Seeds[event.SeedRewardId] or 0) + event.SeedRewardCount)
	return success("Comet reward collected! $500 and 2 Crystal Bloom seeds. Talk again for a new mission.")
end

function LabService.EquipAlien(player: Player, id: any): AlienData.Result
	local p = profiles[player]; if not p then return failure("Your garden is loading.") end
	if typeof(id) ~= "string" or not AlienData.Aliens[id] or not table.find(p.Aliens, id) then return failure("Hatch this alien before equipping it.") end
	local index = table.find(p.Equipped, id)
	if index then table.remove(p.Equipped, index); return success(AlienData.Aliens[id].DisplayName .. " is resting. Its passive is off.") end
	if #p.Equipped >= AlienData.MaxEquipped then return failure("Only 3 unique helpers can be equipped. Rest one first.") end
	table.insert(p.Equipped, id)
	return success(AlienData.Aliens[id].DisplayName .. " equipped! " .. AlienData.Aliens[id].PassiveDescription)
end

function LabService.HatchEgg(player: Player, id: any): AlienData.Result
	local p = profiles[player]; if not p then return failure("Your garden is loading.") end
	if typeof(id) ~= "string" or not AlienData.Eggs[id] then return failure("That egg does not exist.") end
	local egg = AlienData.Eggs[id]; local now = os.clock()
	if now < p.NextHatchAt then return failure("Please wait for your egg cooldown.") end
	if p.LabLevel < egg.RequiredLevel then return failure("Upgrade your greenhouse to level " .. egg.RequiredLevel .. " first.") end
	if #p.Aliens >= AlienData.MaxAliens then return failure("Your companion garden is full. Release one in the alien menu.") end
	if p.Cash < egg.Price then return failure("Sell your harvest to earn more cash for this egg.") end
	local total = 0; for _, entry in egg.Pool do total += entry.Weight end
	local roll = random:NextInteger(1, total); local running = 0; local alienId = egg.Pool[#egg.Pool].AlienId
	for _, entry in egg.Pool do running += entry.Weight; if roll <= running then alienId = entry.AlienId; break end end
	setCash(p, p.Cash - egg.Price); table.insert(p.Aliens, alienId); p.Discovered[alienId] = true
	if #p.Equipped < AlienData.MaxEquipped and not has(p, alienId) then table.insert(p.Equipped, alienId) end
	p.NextHatchAt = now + egg.HatchCooldown; p.LastHatchedAlienId = alienId
	return { Success = true, Message = "New alien helper hatched!", AlienId = alienId }
end

function LabService.UpgradeLab(player: Player): AlienData.Result
	local p = profiles[player]; if not p then return failure("Your garden is loading.") end
	local price = AlienData.UpgradePrices[p.LabLevel + 1]
	if not price then return failure("Your greenhouse is fully upgraded!") end
	if p.Cash < price then return failure("Sell more harvests to afford this upgrade.") end
	setCash(p, p.Cash - price); p.LabLevel += 1
	return success(string.format("Greenhouse level %d! Crops grow faster and new egg tiers unlock.", p.LabLevel))
end

function LabService.ReleaseWeakest(player: Player): AlienData.Result
	local p = profiles[player]; if not p then return failure("Your garden is loading.") end
	if #p.Aliens <= 1 then return failure("Keep at least one alien in your garden!") end
	local index, id = weakest(p); table.remove(p.Aliens, index)
	if not table.find(p.Aliens, id) then
		local equippedIndex = table.find(p.Equipped, id); if equippedIndex then table.remove(p.Equipped, equippedIndex) end
	end
	return { Success = true, AlienId = id, Message = "Released " .. AlienData.Aliens[id].DisplayName .. ". Collection discovery kept." }
end

return LabService
