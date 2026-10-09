--!strict
-- Creates a personal farm for each player when Play starts. The Rojo project
-- keeps its existing mapping; the world is built from these simple parts.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local shared = ReplicatedStorage:WaitForChild("Shared")
local AlienData = require(shared:WaitForChild("AlienData"))
local SlimeModel = require(shared:WaitForChild("SlimeModel"))

type Plot = {
	Model: Model,
	Center: Vector3,
	Slot: number,
	Pets: Folder,
	PetCount: number,
	Summary: TextLabel,
	CharacterConnection: RBXScriptConnection,
}

local LabWorld = {}
local plots: { [Player]: Plot } = {}
local slots: { [number]: boolean } = {}
local world: Folder? = nil
local white = Color3.fromRGB(225, 239, 232)
local mint = Color3.fromRGB(102, 232, 150)
local dark = Color3.fromRGB(29, 51, 46)

local function part(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.Position = position
	item.Color = color
	item.Material = Enum.Material.SmoothPlastic
	item.Anchored = true
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Parent = parent
	return item
end

local function sign(adornee: BasePart, name: string, text: string, tint: Color3, width: number): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Name = name
	gui.Adornee = adornee
	gui.Size = UDim2.fromOffset(width, 58)
	gui.StudsOffset = Vector3.new(0, 2.3, 0)
	gui.MaxDistance = 100
	gui.Parent = adornee
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = dark
	label.BackgroundTransparency = 0.15
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = tint
	label.TextSize = 15
	label.TextWrapped = true
	label.Text = text
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
	return label
end

function LabWorld.Init()
	if world then return end
	local folder = Instance.new("Folder")
	folder.Name = "AlienLabWorld"
	folder.Parent = Workspace
	world = folder
end

-- Prompt events still need ownership, health, and distance checks on the
-- server. This check is also used immediately before charging for an egg.
function LabWorld.CanUseStation(player: Player, station: BasePart): boolean
	local plot = plots[player]
	local character = player.Character
	if not plot or not station:IsDescendantOf(plot.Model) or not character then return false end
	local root = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return root ~= nil and root:IsA("BasePart") and humanoid ~= nil and humanoid.Health > 0
		and (root.Position - station.Position).Magnitude <= 12
end

local function stationPrompt(owner: Player, station: BasePart, action: string, object: string, callback: (Player) -> ())
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Interact"
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.HoldDuration = 0.15
	prompt.RequiresLineOfSight = false
	prompt.Parent = station
	prompt.Triggered:Connect(function(player: Player)
		if player == owner and LabWorld.CanUseStation(player, station) then callback(player) end
	end)
end

function LabWorld.AddPlayer(player: Player, hatch: (Player) -> (), sell: (Player) -> ())
	if plots[player] then return end
	LabWorld.Init()
	local slot = 1
	while slots[slot] do slot += 1 end
	slots[slot] = true
	-- Three farms per row, with enough space for paths between neighbors.
	local center = Vector3.new(((slot - 1) % 3 - 1) * 78, 0, math.floor((slot - 1) / 3) * 72)
	local model = Instance.new("Model")
	model.Name = "Farm_" .. player.UserId
	model:SetAttribute("OwnerUserId", player.UserId)
	local function block(name: string, size: Vector3, offset: Vector3, tint: Color3): Part
		return part(model, name, size, center + offset, tint)
	end
	block("Foundation", Vector3.new(66, 0.5, 60), Vector3.new(0, 0.25, 0), dark)
	block("FarmDeck", Vector3.new(64, 0.5, 58), Vector3.new(0, 0.75, 0), white)
	local garden = block("SlimeGarden", Vector3.new(48, 0.25, 32), Vector3.new(0, 1.125, 6), Color3.fromRGB(91, 166, 111))
	garden.Material = Enum.Material.Grass
	block("EntrancePath", Vector3.new(8, 0.1, 17), Vector3.new(0, 1.05, -18), Color3.fromRGB(160, 196, 174))
	for _, side in { -1, 1 } do
		for _, z in { -10, 22 } do
			block("FencePost", Vector3.new(0.85, 3.6, 0.85), Vector3.new(side * 24, 2.8, z), white)
		end
		block("SideRail", Vector3.new(0.55, 0.5, 32), Vector3.new(side * 24, 3.9, 6), white)
		block("FrontRail", Vector3.new(20, 0.5, 0.55), Vector3.new(side * 14, 3.9, -10), white)
		local glass = block("SideGlass", Vector3.new(0.25, 2.6, 32), Vector3.new(side * 24, 2.5, 6), mint)
		glass.Material = Enum.Material.Glass
		glass.Transparency = 0.72
		local front = block("FrontGlass", Vector3.new(20, 2.6, 0.25), Vector3.new(side * 14, 2.5, -10), mint)
		front.Material = Enum.Material.Glass
		front.Transparency = 0.72
	end
	block("BackRail", Vector3.new(48, 0.5, 0.55), Vector3.new(0, 3.9, 22), white)
	local back = block("BackGlass", Vector3.new(48, 2.6, 0.25), Vector3.new(0, 2.5, 22), mint)
	back.Material = Enum.Material.Glass
	back.Transparency = 0.72
	local namePost = block("FarmSign", Vector3.new(0.5, 5, 0.5), Vector3.new(0, 3.5, 26), dark)
	sign(namePost, "Owner", player.DisplayName .. "'s SLIME FARM", mint, 240)
	local summaryPost = block("GardenSign", Vector3.new(0.4, 2, 0.4), Vector3.new(0, 2, -10), dark)
	summaryPost.CanCollide = false
	local summary = sign(summaryPost, "Production", "SLIME GARDEN\nYour aliens live here", white, 220)

	-- A visible egg dispenser on the left of the garden entrance.
	block("EggCounter", Vector3.new(9, 2, 7), Vector3.new(-18, 2, -20), dark)
	local eggBase = block("EggStand", Vector3.new(5, 0.5, 5), Vector3.new(-18, 3.25, -20), mint)
	eggBase.Material = Enum.Material.Neon
	local egg = block("StarterEgg", Vector3.new(3.5, 4.5, 3.5), Vector3.new(-18, 5.75, -20), Color3.fromRGB(232, 255, 220))
	egg.Shape = Enum.PartType.Ball
	local spot = block("EggSpot", Vector3.new(1.3, 1.7, 0.3), Vector3.new(-18.4, 5.7, -21.6), mint)
	spot.Shape = Enum.PartType.Ball
	sign(egg, "EggLabel", string.format("STARTER EGG\n$%d", AlienData.StarterEgg.Price), mint, 150)
	stationPrompt(player, egg, "Hatch egg", "Starter Egg", hatch)

	-- The green tank on the right is the slime selling station.
	block("SellCounter", Vector3.new(9, 2, 7), Vector3.new(18, 2, -20), dark)
	local tank = block("SellTank", Vector3.new(4, 4, 4), Vector3.new(18, 5, -20), mint)
	tank.Material = Enum.Material.Glass
	tank.Transparency = 0.25
	block("TankLid", Vector3.new(4.4, 0.5, 4.4), Vector3.new(18, 7.25, -20), white)
	sign(tank, "SellLabel", string.format("SELL SLIME\n1 slime = $%d", AlienData.CashPerSlime), mint, 155)
	stationPrompt(player, tank, "Sell all slime", "Slime Tank", sell)

	local pets = Instance.new("Folder")
	pets.Name = "Aliens"
	pets.Parent = model
	-- Face your character toward the garden whenever it spawns or respawns.
	local spawnAt = center + Vector3.new(0, 4.5, -23)
	local function placeCharacter(character: Model)
		task.defer(function()
			local root = character:WaitForChild("HumanoidRootPart", 8)
			if root and plots[player] and plots[player].Model == model and player.Character == character then
				character:PivotTo(CFrame.lookAt(spawnAt, spawnAt + Vector3.new(0, 0, 1)))
			end
		end)
	end
	local connection = player.CharacterAdded:Connect(placeCharacter)
	plots[player] = { Model = model, Center = center, Slot = slot, Pets = pets, PetCount = 0, Summary = summary, CharacterConnection = connection }
	model.Parent = world
	if player.Character then placeCharacter(player.Character) end
	LabWorld.AddAlien(player, AlienData.StarterAlienId)
end

function LabWorld.AddAlien(player: Player, alienId: string)
	local plot = plots[player]
	if not plot or plot.PetCount >= AlienData.MaxAliens then return end
	local model = SlimeModel.Create(alienId)
	plot.PetCount += 1
	model.Name = string.format("%s_%d", alienId, plot.PetCount)
	local home = plot.Center + Vector3.new(0, 1.25, 6)
	local seed = (player.UserId % 1000) * 0.1 + plot.PetCount * 1.9
	model:SetAttribute("RoamHome", home)
	model:SetAttribute("RoamSeed", seed)
	model:SetAttribute("OwnerUserId", player.UserId)
	model:SetAttribute("AlienId", alienId)
	model:PivotTo(CFrame.new(home + Vector3.new(math.sin(seed) * 18, 0, math.cos(seed) * 10)))
	local body = model.PrimaryPart :: BasePart
	local alien = AlienData.Aliens[alienId]
	local label = sign(body, "AlienLabel", string.format("%s\n+%d slime / sec", alien.DisplayName, alien.SlimePerSecond), white, 140)
	label.TextSize = 12
	local billboard = label.Parent :: BillboardGui
	billboard.Size = UDim2.fromOffset(140, 36)
	billboard.MaxDistance = 45
	model.Parent = plot.Pets
	-- Only real farm aliens receive this tag. The HUD icon stays still.
	CollectionService:AddTag(model, "AlienLabPet")
end

function LabWorld.UpdatePlayer(player: Player, state: AlienData.State)
	local plot = plots[player]
	if plot then
		plot.Summary.Text = string.format("SLIME GARDEN\n%d slime   +%d / sec", state.Slime, state.ProductionRate)
	end
end

function LabWorld.RemovePlayer(player: Player)
	local plot = plots[player]
	if not plot then return end
	plot.CharacterConnection:Disconnect()
	slots[plot.Slot] = nil
	plot.Model:Destroy()
	plots[player] = nil
end

return LabWorld
