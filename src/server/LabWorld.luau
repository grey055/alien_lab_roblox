--!strict
-- The playable cosmic village is generated at runtime, leaving the existing
-- Rojo project intact. The server owns beds, shops, prompts, and crop stages.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local shared = ReplicatedStorage:WaitForChild("Shared")
local AlienData = require(shared:WaitForChild("AlienData"))
local FarmData = require(shared:WaitForChild("FarmData"))
local SlimeModel = require(shared:WaitForChild("SlimeModel"))
local CropModel = require(shared:WaitForChild("CropModel"))
local Decor = require(script.Parent:WaitForChild("GardenDecor"))

type Callbacks = {
	OpenShop: (Player, string) -> (),
	Bed: (Player, number) -> (),
	ClaimEvent: (Player) -> (),
}
type Bed = { Soil: Part, Prompt: ProximityPrompt, Label: TextLabel, Crop: Model?, LastKey: string, Water: Part }
type Plot = {
	Model: Model, At: CFrame, Slot: number, Pets: Folder, PetCount: number, Serial: number,
	Beds: { Bed }, Summary: TextLabel, Callbacks: Callbacks, CharacterConnection: RBXScriptConnection,
}
local LabWorld = {}
local plots: { [Player]: Plot } = {}
local slots: { [number]: boolean } = {}
local world: Folder? = nil
local eventStation: BasePart? = nil
local purple = Color3.fromRGB(72, 63, 115)
local cream = Color3.fromRGB(255, 237, 198)
local mint = Color3.fromRGB(151, 248, 192)

local function floatingLabel(adornee: BasePart, name: string, text: string, tint: Color3, width: number, height: number, distance: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Name = name; gui.Adornee = adornee; gui.Size = UDim2.fromOffset(width, height)
	gui.StudsOffset = Vector3.new(0, 2.9, 0); gui.MaxDistance = distance; gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Name = "Text"; label.Size = UDim2.fromScale(1, 1); label.BackgroundColor3 = purple
	label.BackgroundTransparency = 0.16; label.Font = Enum.Font.GothamBold; label.TextColor3 = tint
	label.TextSize = 12; label.TextWrapped = true; label.Text = text; label.Parent = gui
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 12); corner.Parent = label
	local stroke = Instance.new("UIStroke"); stroke.Color = tint; stroke.Transparency = 0.58; stroke.Thickness = 1; stroke.Parent = label
	return label
end

-- ProximityPrompt events are requests, so the server still checks a real,
-- living character's distance before using any station or another player's bed.
local function near(player: Player, station: BasePart?, distance: number): boolean
	local character = player.Character
	if not station or not character then return false end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return root ~= nil and root:IsA("BasePart") and humanoid ~= nil and humanoid.Health > 0
		and (root.Position - station.Position).Magnitude <= distance
end

local function prompt(station: BasePart, action: string, object: string, callback: (Player) -> ()): ProximityPrompt
	local p = Instance.new("ProximityPrompt")
	p.Name = "Interact"; p.ActionText = action; p.ObjectText = object; p.KeyboardKeyCode = Enum.KeyCode.E
	p.MaxActivationDistance = 9; p.HoldDuration = 0.1; p.RequiresLineOfSight = false
	p.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton; p.Parent = station
	p.Triggered:Connect(callback)
	return p
end

function LabWorld.Init()
	if world then return end
	-- The generated island supplies the playable floor. Hide the template's
	-- checkerboard only during Play; stopping the test restores the edit place.
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Transparency = 1; baseplate.CanCollide = false
	end
	local folder = Instance.new("Folder"); folder.Name = "AlienLabWorld"
	local stations = Decor.Hub(folder)
	for kind, station in stations do
		prompt(station, if kind == "Sell" then "Sell harvest" else "Open shop", kind .. " Shop", function(player: Player)
			local plot = plots[player]
			if plot and near(player, station, 12) then plot.Callbacks.OpenShop(player, kind) end
		end)
	end
	local captain = SlimeModel.Create("Glowbug")
	captain.Name = "CaptainNova"; captain:ScaleTo(1.22); captain:PivotTo(CFrame.new(0, 6.9, -12.5))
	captain.Parent = folder
	local head = captain:FindFirstChild("Head")
	if head and head:IsA("BasePart") then
		local hat = Decor.Part(captain, "CaptainHat", Vector3.new(3.5, 0.5, 2.9), head.CFrame * CFrame.new(0, 1.6, 0), purple)
		hat.CanCollide = false
		local badge = Decor.Ball(captain, "CaptainBadge", Vector3.new(0.6, 0.6, 0.14), head.CFrame * CFrame.new(0, 1.56, -1.55), cream)
		badge.Material = Enum.Material.Neon
	end
	local body = captain.PrimaryPart :: BasePart
	eventStation = body
	local speech = floatingLabel(body, "QuestDialogue", "CAPTAIN NOVA\nGrow 3 Nebula Sprouts for me!\nReturn for $500 + Crystal Seeds", cream, 270, 78, 70)
	speech.Font = Enum.Font.FredokaOne; speech.TextSize = 15
	local speechGui = speech.Parent :: BillboardGui; speechGui.StudsOffset = Vector3.new(0, 5.8, 0)
	prompt(body, "Talk / claim reward", "The Comet Harvest", function(player: Player)
		local plot = plots[player]
		if plot and LabWorld.CanUseEvent(player) then plot.Callbacks.ClaimEvent(player) end
	end)
	-- Studio checks can substitute the decoration module's Lighting function;
	-- normal Play applies this palette only to the runtime place.
	Decor.Lighting()
	folder.Parent = Workspace; world = folder
end

function LabWorld.CanUseEvent(player: Player): boolean
	return plots[player] ~= nil and near(player, eventStation, 14)
end

function LabWorld.CanUseStation(player: Player, station: BasePart): boolean
	local plot = plots[player]
	return plot ~= nil and station:IsDescendantOf(plot.Model) and near(player, station, 12)
end

function LabWorld.CanUseBed(player: Player, index: number): boolean
	if typeof(index) ~= "number" or index ~= math.floor(index) then return false end
	local plot = plots[player]; if not plot then return false end
	local bed = plot.Beds[index]
	return bed ~= nil and near(player, bed.Soil, 12)
end

function LabWorld.GetBedPosition(player: Player, index: number): Vector3?
	local plot = plots[player]; local bed = if plot then plot.Beds[index] else nil
	return if bed then bed.Soil.Position else nil
end

function LabWorld.AddPlayer(player: Player, callbacks: Callbacks, inventory: { string }?)
	if plots[player] then return end
	LabWorld.Init()
	local slot = 1; while slots[slot] do slot += 1 end; slots[slot] = true
	local angle = ((slot - 1) % 6) * math.pi / 3
	local radius = 89 + math.floor((slot - 1) / 6) * 68
	local at = CFrame.new(math.sin(angle) * radius, 6, math.cos(angle) * radius) * CFrame.Angles(0, angle, 0)
	local model = Instance.new("Model"); model.Name = "Farm_" .. player.UserId; model:SetAttribute("OwnerUserId", player.UserId)
	if slot > 6 then
		-- Extra players keep their own plots; their little island bridges back to town.
		Decor.Disk(model, "ExtraGardenIsland", 78, 5, at * CFrame.new(0, -2.5, 0), Color3.fromRGB(137, 143, 211))
		Decor.Part(model, "IslandBridge", Vector3.new(8, 0.8, 70), at * CFrame.new(0, -0.1, -47), Color3.fromRGB(211, 189, 163))
	end
	Decor.Farm(model, at)
	Decor.Board(model, "OwnerSign", at * CFrame.new(0, 4.8, 22.5), Vector3.new(20, 3.2, 0.45), player.DisplayName .. "'s GARDEN", "PLANT  •  GROW  •  HARVEST", cream)
	for _, side in { -1, 1 } do
		Decor.Part(model, "OwnerSignPost", Vector3.new(0.7, 4.6, 0.7), at * CFrame.new(side * 8, 2.3, 22.5), Color3.fromRGB(153, 102, 75))
	end
	local welcome = Decor.Part(model, "FarmInfo", Vector3.new(0.25, 0.25, 0.25), at * CFrame.new(0, 2, -23), mint)
	welcome.Transparency = 1; welcome.CanCollide = false
	local summary = floatingLabel(welcome, "GardenSummary", "YOUR COSMIC GARDEN\nBuy seeds and plant your first crop", cream, 238, 52, 55)
	local beds: { Bed } = {}
	for index = 1, FarmData.BedCount do
		local x = ({ -20, -7, 7, 20 })[((index - 1) % 4) + 1]
		local z = -9 + math.floor((index - 1) / 4) * 10
		local bedAt = at * CFrame.new(x, 1.04, z)
		local bedModel = Instance.new("Model"); bedModel.Name = string.format("Bed_%02d", index)
		bedModel:SetAttribute("BedIndex", index); bedModel:SetAttribute("OwnerUserId", player.UserId); bedModel.Parent = model
		local soil = Decor.Part(bedModel, "PlantingSoil", Vector3.new(10.8, 0.6, 8.4), bedAt, Color3.fromRGB(107, 70, 65))
		soil.Material = Enum.Material.Ground
		for _, side in { -1, 1 } do
			Decor.Part(bedModel, "BedFrame", Vector3.new(0.35, 0.5, 8.8), bedAt * CFrame.new(side * 5.6, 0.35, 0), Color3.fromRGB(189, 132, 87))
			Decor.Part(bedModel, "BedFrame", Vector3.new(11.3, 0.5, 0.35), bedAt * CFrame.new(0, 0.35, side * 4.35), Color3.fromRGB(189, 132, 87))
		end
		-- A low water sheen communicates that this crop has been watered.
		local water = Decor.Part(bedModel, "WaterSheen", Vector3.new(10.3, 0.04, 7.9), bedAt * CFrame.new(0, 0.33, 0), Color3.fromRGB(121, 215, 232))
		water.CanCollide = false; water.CanQuery = false; water.Material = Enum.Material.Glass; water.Transparency = 1
		local label = floatingLabel(soil, "GrowthLabel", "BED " .. index .. "\nSelect a seed, then press E", cream, 148, 38, 23)
		local interact = prompt(soil, "Plant seed", "Bed " .. index, function(visitor: Player)
			if visitor == player and LabWorld.CanUseBed(visitor, index) then callbacks.Bed(visitor, index) end
		end)
		beds[index] = { Soil = soil, Prompt = interact, Label = label, Crop = nil, LastKey = "", Water = water }
	end
	local pets = Instance.new("Folder"); pets.Name = "Aliens"; pets.Parent = model
	local spawnAt = at * CFrame.new(0, 4.5, -17)
	local function placeCharacter(character: Model)
		task.defer(function()
			local root = character:WaitForChild("HumanoidRootPart", 8)
			if root and plots[player] and plots[player].Model == model and player.Character == character then
				character:PivotTo(spawnAt)
			end
		end)
	end
	local connection = player.CharacterAdded:Connect(placeCharacter)
	plots[player] = { Model = model, At = at, Slot = slot, Pets = pets, PetCount = 0, Serial = 0, Beds = beds,
		Summary = summary, Callbacks = callbacks, CharacterConnection = connection }
	model.Parent = world
	if player.Character then placeCharacter(player.Character) end
	for _, id in inventory or { AlienData.StarterAlienId } do LabWorld.AddAlien(player, id) end
end

function LabWorld.AddAlien(player: Player, alienId: string)
	local plot = plots[player]; if not plot or plot.PetCount >= AlienData.MaxAliens then return end
	local model = SlimeModel.Create(alienId); plot.PetCount += 1; plot.Serial += 1
	model.Name = string.format("%s_%d", alienId, plot.Serial)
	local home = (plot.At * CFrame.new(0, 0.7, -18)).Position
	local seed = (player.UserId % 1000) * 0.1 + plot.Serial * 1.9
	model:SetAttribute("RoamHome", home); model:SetAttribute("RoamSeed", seed)
	model:SetAttribute("RoamYaw", ((plot.Slot - 1) % 6) * math.pi / 3); model:SetAttribute("RoamExtent", Vector3.new(23, 0, 2.5))
	model:SetAttribute("OwnerUserId", player.UserId); model:SetAttribute("AlienId", alienId)
	model:PivotTo(plot.At * CFrame.new(math.sin(seed) * 23, 0.7, -18 + math.cos(seed) * 2))
	local alien = AlienData.Aliens[alienId]
	local label = floatingLabel(model.PrimaryPart :: BasePart, "AlienLabel", alien.DisplayName .. "\n" .. alien.PassiveName, mint, 138, 34, 30)
	label.TextSize = 11; label.BackgroundTransparency = 0.3
	local billboard = label.Parent :: BillboardGui
	billboard.StudsOffset = Vector3.new(0, 4.35, 0)
	model.Parent = plot.Pets; CollectionService:AddTag(model, "AlienLabPet")
end

function LabWorld.RemoveAlien(player: Player, alienId: string)
	local plot = plots[player]; if not plot then return end
	for _, pet in plot.Pets:GetChildren() do
		if pet:GetAttribute("AlienId") == alienId then
			CollectionService:RemoveTag(pet, "AlienLabPet"); pet:Destroy(); plot.PetCount -= 1; return
		end
	end
end

function LabWorld.UpdatePlayer(player: Player, state: AlienData.State)
	local plot = plots[player]; if not plot then return end
	local ready, growing = 0, 0
	for index, bed in plot.Beds do
		local data = state.Beds[index] or {}
		local crop = if data.CropId then FarmData.Crops[data.CropId] else nil
		local progress = math.clamp(data.Progress or 0, 0, 1)
		local stage = if progress >= 1 then 4 elseif progress >= 0.65 then 3 elseif progress >= 0.28 then 2 else 1
		local key = if crop then tostring(data.CropId) .. ":" .. stage .. ":" .. (data.Mutation or "Normal") else ""
		-- Rebuilding only when the stage changes saves replicated parts and keeps
		-- the server's per-second updates small, even in a busy multiplayer server.
		if key ~= bed.LastKey then
			if bed.Crop then bed.Crop:Destroy(); bed.Crop = nil end
			if crop then
				local model = CropModel.Create(data.CropId, stage, data.Mutation)
				model:PivotTo(bed.Soil.CFrame * CFrame.new(0, 0.32, 0)); model.Parent = bed.Soil.Parent; bed.Crop = model
			end
			bed.LastKey = key
		end
		bed.Water.Transparency = if crop and data.Watered then 0.82 else 1
		if crop then
			if progress >= 1 then
				ready += 1; bed.Prompt.ActionText = "Harvest crop"
				bed.Label.Text = crop.DisplayName .. "\nREADY TO HARVEST"; bed.Label.TextColor3 = mint
			else
				growing += 1
				bed.Prompt.ActionText = if data.Watered then "Growing..." else "Water crop"
				bed.Label.Text = string.format("%s / %d%%\n%s", crop.DisplayName, math.floor(progress * 100), if data.Watered then "Watered / growing" else "Water to speed up growth")
				bed.Label.TextColor3 = cream
			end
			bed.Prompt.ObjectText = (if data.Mutation and data.Mutation ~= "Normal" then data.Mutation .. " " else "") .. crop.DisplayName
		else
			local selected = FarmData.Crops[state.SelectedSeed or "StarCarrot"]
			bed.Prompt.ActionText = "Plant " .. (if selected then selected.DisplayName else "seed")
			bed.Prompt.ObjectText = "Your garden / bed " .. index
			bed.Label.Text = "BED " .. index .. "\nSelect seed / press E"; bed.Label.TextColor3 = cream
		end
	end
	plot.Summary.Text = string.format("YOUR COSMIC GARDEN / LEVEL %d\n%d ready  •  %d growing  •  +%d%% growth", state.LabLevel or 0, ready, growing, math.floor((state.GrowthBonus or 0) * 100 + 0.5))
	local equipped: { [string]: boolean } = {}
	for _, id in state.Equipped or {} do equipped[id] = true end
	for _, pet in plot.Pets:GetChildren() do
		local id = pet:GetAttribute("AlienId")
		pet:SetAttribute("Equipped", equipped[id] == true)
		local body = if pet:IsA("Model") then pet.PrimaryPart else nil
		local gui = if body then body:FindFirstChild("AlienLabel") else nil
		local label = if gui then gui:FindFirstChild("Text") else nil
		if label and label:IsA("TextLabel") and AlienData.Aliens[id] then
			label.Text = AlienData.Aliens[id].DisplayName .. "\n" .. (if equipped[id] then AlienData.Aliens[id].PassiveName else "Resting / equip in Aliens")
			label.TextColor3 = if equipped[id] then mint else Color3.fromRGB(210, 198, 230)
		end
	end
end

function LabWorld.RemovePlayer(player: Player)
	local plot = plots[player]; if not plot then return end
	plot.CharacterConnection:Disconnect(); slots[plot.Slot] = nil
	for _, pet in plot.Pets:GetChildren() do CollectionService:RemoveTag(pet, "AlienLabPet") end
	plot.Model:Destroy(); plots[player] = nil
end

return LabWorld
