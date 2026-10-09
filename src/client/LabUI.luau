--!strict
-- A little field journal for your alien garden. All pictures are real 3D models.
-- This module draws the interface; the server decides purchases and rewards.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local shared = ReplicatedStorage:WaitForChild("Shared")
local AlienData = require(shared:WaitForChild("AlienData"))
local FarmData = require(shared:WaitForChild("FarmData"))
local SlimeModel = require(shared:WaitForChild("SlimeModel"))
local CropModel = require(shared:WaitForChild("CropModel"))
local UI = {}

local cream = Color3.fromRGB(255, 246, 222)
local paper = Color3.fromRGB(255, 253, 242)
local ink = Color3.fromRGB(61, 43, 91)
local muted = Color3.fromRGB(119, 109, 142)
local purple = Color3.fromRGB(189, 167, 246)
local mint = Color3.fromRGB(176, 231, 171)
local cyan = Color3.fromRGB(163, 228, 244)
local gold = Color3.fromRGB(255, 215, 140)
local pink = Color3.fromRGB(255, 191, 213)

local function roundedPart(part: Part)
	-- Built-in sphere meshes follow all three size axes, giving us egg shapes
	-- and rounded tools instead of Roblox's uniformly sized Ball parts.
	part.Shape = Enum.PartType.Block
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = part
end

local function corners(parent: Instance, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius); corner.Parent = parent
end

local function outline(parent: Instance, tint: Color3, transparency: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = tint; stroke.Transparency = transparency or 0.55
	stroke.Thickness = 1.5; stroke.Parent = parent
end

local function frame(parent: Instance, name: string, at: UDim2, size: UDim2, tint: Color3): Frame
	local item = Instance.new("Frame")
	item.Name = name; item.Position = at; item.Size = size
	item.BackgroundColor3 = tint; item.BorderSizePixel = 0; item.Parent = parent
	corners(item, 16)
	return item
end

local function label(parent: Instance, name: string, content: string, at: UDim2, size: UDim2, fontSize: number, tint: Color3?): TextLabel
	local item = Instance.new("TextLabel")
	item.Name = name; item.Text = content; item.Position = at; item.Size = size
	item.BackgroundTransparency = 1; item.TextColor3 = tint or ink
	item.Font = Enum.Font.GothamMedium; item.TextSize = fontSize
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.TextWrapped = true; item.Parent = parent
	return item
end

local function button(parent: Instance, name: string, caption: string, at: UDim2, size: UDim2, tint: Color3?): TextButton
	local item = Instance.new("TextButton")
	item.Name = name; item.Text = caption; item.Position = at; item.Size = size
	item.BackgroundColor3 = tint or mint; item.TextColor3 = ink
	item:SetAttribute("EnabledColor", item.BackgroundColor3)
	item.Font = Enum.Font.GothamBold; item.TextSize = 12; item.TextWrapped = true
	item.BorderSizePixel = 0; item.AutoButtonColor = true; item.Parent = parent
	corners(item, 11)
	local scale = Instance.new("UIScale"); scale.Parent = item
	item.MouseEnter:Connect(function()
		if item.Active then TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.025 }):Play() end
	end)
	item.MouseLeave:Connect(function() TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play() end)
	return item
end

local function fitted(item: TextLabel | TextButton, minimum: number, maximum: number)
	item.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MinTextSize = minimum; limit.MaxTextSize = maximum; limit.Parent = item
end

local function preview(parent: Instance, kind: string, id: string, at: UDim2, size: UDim2, tint: Color3?): ViewportFrame
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Preview"; viewport.Position = at; viewport.Size = size
	viewport.BackgroundTransparency = 1; viewport.Ambient = Color3.fromRGB(224, 229, 245)
	viewport.LightColor = Color3.new(1, 1, 1); viewport.LightDirection = Vector3.new(-1, -1, -2)
	viewport.Parent = parent
	local world = Instance.new("WorldModel"); world.Parent = viewport
	local model: Model
	if kind == "Egg" then
		model = Instance.new("Model")
		local egg = Instance.new("Part")
		egg.Size = Vector3.new(2.7, 3.7, 2.7); roundedPart(egg)
		egg.Position = Vector3.new(0, 1.85, 0); egg.Anchored = true
		egg.Color = tint or purple; egg.Material = Enum.Material.SmoothPlastic; egg.Parent = model
		for _, side in { -1, 1 } do
			local spot = Instance.new("Part")
			spot.Size = Vector3.new(0.65, 0.86, 0.13); roundedPart(spot)
			spot.Position = Vector3.new(side * 0.57, 1.65, -1.24)
			spot.Color = egg.Color:Lerp(paper, 0.7); spot.Anchored = true; spot.Parent = model
		end
	elseif kind == "Crop" then
		model = CropModel.Create(id, 4)
	elseif kind == "Tool" then
		model = Instance.new("Model")
		local toolColor = Color3.fromRGB(unpack(FarmData.Tools[id].Color))
		local function piece(name: string, size: Vector3, position: Vector3, color: Color3, ball: boolean?): Part
			local part = Instance.new("Part")
			part.Name = name; part.Size = size; part.Position = position; part.Color = color
			if ball then roundedPart(part) end
			part.Material = Enum.Material.SmoothPlastic; part.Anchored = true; part.Parent = model
			return part
		end
		if id == "WateringCan" then
			piece("Can", Vector3.new(1.7, 1.4, 1.2), Vector3.new(0, 0.9, 0), toolColor, true)
			piece("Spout", Vector3.new(0.4, 1.35, 0.4), Vector3.new(1.04, 1.12, 0), toolColor).CFrame *= CFrame.Angles(0, 0, -0.72)
			piece("Nozzle", Vector3.new(0.64, 0.25, 0.6), Vector3.new(1.46, 1.6, 0), gold, true)
			for i = 1, 8 do
				local angle = i * math.pi * 2 / 8
				piece("Handle", Vector3.new(0.2, 0.28, 0.2), Vector3.new(-0.9 + math.sin(angle) * 0.39, 1.05 + math.cos(angle) * 0.6, 0), gold, true)
			end
		elseif id == "Sprinkler" then
			piece("Base", Vector3.new(1.55, 0.35, 1.55), Vector3.new(0, 0.2, 0), purple, true)
			piece("Stem", Vector3.new(0.3, 1.4, 0.3), Vector3.new(0, 1.02, 0), toolColor)
			piece("Head", Vector3.new(1.9, 0.28, 0.4), Vector3.new(0, 1.7, 0), cyan)
			for _, side in { -1, 1 } do
				piece("WaterDrop", Vector3.new(0.23, 0.35, 0.23), Vector3.new(side * 1.15, 1.88, 0), cyan, true)
			end
		else
			piece("Scanner", Vector3.new(1.3, 2.1, 0.65), Vector3.new(0, 1.25, 0), toolColor)
			piece("Screen", Vector3.new(1, 1, 0.09), Vector3.new(0, 1.52, -0.38), cyan).Material = Enum.Material.Neon
			piece("Button", Vector3.new(0.28, 0.28, 0.08), Vector3.new(0, 0.66, -0.38), gold, true)
			piece("Antenna", Vector3.new(0.15, 0.65, 0.15), Vector3.new(0.36, 2.53, 0), ink)
			piece("AntennaTip", Vector3.new(0.3, 0.3, 0.3), Vector3.new(0.36, 2.88, 0), cyan, true)
		end
	else
		model = SlimeModel.Create(id)
	end
	model.Parent = world
	local bounds, dimensions = model:GetBoundingBox()
	local center = bounds.Position
	local distance = math.max(6.5, dimensions.Magnitude * 1.15)
	local camera = Instance.new("Camera"); camera.FieldOfView = 34
	camera.CFrame = CFrame.lookAt(center + Vector3.new(0.25, dimensions.Y * 0.07, -distance), center)
	camera.Parent = viewport; viewport.CurrentCamera = camera
	return viewport
end

local function list(parent: Instance, gap: number)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, gap); layout.Parent = parent
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 3); padding.PaddingBottom = UDim.new(0, 9)
	padding.PaddingLeft = UDim.new(0, 3); padding.PaddingRight = UDim.new(0, 8); padding.Parent = parent
end

local function row(parent: Instance, name: string, height: number, tint: Color3?): Frame
	return frame(parent, name, UDim2.new(), UDim2.new(1, 0, 0, height), tint or paper)
end

function UI.Number(value: number): string
	if value >= 1e9 then return string.format("%.1fB", value / 1e9) end
	if value >= 1e6 then return string.format("%.1fM", value / 1e6) end
	if value >= 10000 then return string.format("%.1fK", value / 1000) end
	return tostring(math.floor(value))
end

function UI.SetButtonEnabled(item: TextButton, enabled: boolean)
	item.Active = enabled; item.AutoButtonColor = enabled
	item.BackgroundColor3 = if enabled then (item:GetAttribute("EnabledColor") :: Color3) else Color3.fromRGB(224, 220, 227)
	item.TextColor3 = if enabled then ink else muted
end

function UI.Create(playerGui: PlayerGui)
	local gui = Instance.new("ScreenGui")
	gui.Name = "AlienLabUI"; gui.ResetOnSpawn = false; gui.DisplayOrder = 10
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local hud = frame(gui, "FieldJournal", UDim2.fromOffset(12, 12), UDim2.new(1, -24, 0, 206), cream)
	local hudLimit = Instance.new("UISizeConstraint"); hudLimit.MaxSize = Vector2.new(255, 206); hudLimit.Parent = hud
	outline(hud, ink, 0.75)
	local title = label(hud, "Title", "ALIEN GARDENS", UDim2.fromOffset(14, 9), UDim2.new(1, -28, 0, 24), 18)
	title.Font = Enum.Font.GothamBlack
	local level = label(hud, "Level", "YOUR LITTLE COSMIC FARM", UDim2.fromOffset(14, 34), UDim2.new(1, -28, 0, 14), 9, muted)
	local cashRow = frame(hud, "Coins", UDim2.fromOffset(9, 55), UDim2.new(1, -18, 0, 49), mint)
	local coin = frame(cashRow, "Coin", UDim2.fromOffset(9, 8), UDim2.fromOffset(33, 33), gold)
	local dollar = label(coin, "Dollar", "$", UDim2.new(), UDim2.fromScale(1, 1), 23)
	dollar.Font = Enum.Font.GothamBlack; dollar.TextXAlignment = Enum.TextXAlignment.Center
	label(cashRow, "Caption", "COINS", UDim2.fromOffset(53, 4), UDim2.new(1, -60, 0, 13), 8, muted)
	local cash = label(cashRow, "Value", "Loading...", UDim2.fromOffset(53, 17), UDim2.new(1, -60, 0, 28), 24)
	cash.Font = Enum.Font.GothamBold
	local harvestRow = frame(hud, "HarvestBasket", UDim2.fromOffset(9, 110), UDim2.new(1, -18, 0, 48), gold)
	label(harvestRow, "Caption", "HARVEST BASKET", UDim2.fromOffset(10, 4), UDim2.new(1, -70, 0, 13), 8, muted)
	local harvest = label(harvestRow, "Value", "0 crops", UDim2.fromOffset(10, 18), UDim2.new(1, -76, 0, 24), 15)
	fitted(harvest, 10, 15)
	local sell = button(harvestRow, "Sell", "SELL", UDim2.new(1, -64, 0, 8), UDim2.fromOffset(55, 32), cream)
	local helpers = label(hud, "Helpers", "Helpers waking up...", UDim2.fromOffset(14, 164), UDim2.new(1, -28, 0, 17), 10)
	local save = label(hud, "Saving", "Connecting...", UDim2.fromOffset(14, 186), UDim2.new(1, -28, 0, 12), 9, muted)

	local dock = frame(gui, "GardenDock", UDim2.new(0.5, 0, 1, -12), UDim2.new(1, -20, 0, 60), cream)
	dock.AnchorPoint = Vector2.new(0.5, 1); outline(dock, ink, 0.75)
	local dockLimit = Instance.new("UISizeConstraint"); dockLimit.MaxSize = Vector2.new(650, 60); dockLimit.Parent = dock
	local nav = {}
	for i, entry in { { "Farm", "FARM", mint }, { "Seeds", "SEEDS", mint }, { "Tools", "TOOLS", cyan },
		{ "Eggs", "EGGS", pink }, { "Collection", "ALIENS", purple }, { "Event", "QUEST", gold } } do
		local key = entry[1] :: string
		local item = button(dock, key, entry[2] :: string, UDim2.new((i - 1) / 6, 7, 0, 8), UDim2.new(1 / 6, -10, 0, 44), entry[3] :: Color3)
		fitted(item, 8, 12); nav[key] = item
	end
	local status = label(gui, "Status", "Choose a seed, walk to a garden bed, and press E to plant.", UDim2.new(0.5, 0, 1, -79), UDim2.new(1, -30, 0, 32), 13, cream)
	status.AnchorPoint = Vector2.new(0.5, 1); status.TextXAlignment = Enum.TextXAlignment.Center
	status.ZIndex = 11 -- Purchase errors stay readable while a shop is open.
	status.TextStrokeColor3 = ink; status.TextStrokeTransparency = 0.2
	local statusLimit = Instance.new("UISizeConstraint"); statusLimit.MaxSize = Vector2.new(680, 32); statusLimit.Parent = status

	local shade = frame(gui, "MenuShade", UDim2.new(), UDim2.fromScale(1, 1), ink)
	shade.BackgroundTransparency = 0.38; shade.Visible = false; shade.Active = true; shade.ZIndex = 10
	local modal = frame(shade, "Journal", UDim2.fromScale(0.5, 0.46), UDim2.fromScale(0.93, 0.83), cream)
	modal.AnchorPoint = Vector2.new(0.5, 0.5); outline(modal, paper, 0.1)
	local modalLimit = Instance.new("UISizeConstraint"); modalLimit.MaxSize = Vector2.new(700, 570); modalLimit.Parent = modal
	local menuTitle = label(modal, "Title", "YOUR FARM", UDim2.fromOffset(18, 12), UDim2.new(1, -80, 0, 28), 22)
	menuTitle.Font = Enum.Font.GothamBlack
	fitted(menuTitle, 14, 22)
	local menuSubtitle = label(modal, "Subtitle", "A garden with a little help from the stars.", UDim2.fromOffset(18, 43), UDim2.new(1, -36, 0, 23), 11, muted)
	local close = button(modal, "Close", "X", UDim2.new(1, -49, 0, 12), UDim2.fromOffset(34, 34), purple)
	local pages: { [string]: ScrollingFrame } = {}
	for _, key in { "Farm", "Seeds", "Tools", "Eggs", "Collection", "Event", "Lab", "Sell" } do
		local page = Instance.new("ScrollingFrame")
		page.Name = key; page.Position = UDim2.fromOffset(12, 76); page.Size = UDim2.new(1, -24, 1, -88)
		page.BackgroundTransparency = 1; page.BorderSizePixel = 0; page.AutomaticCanvasSize = Enum.AutomaticSize.Y
		page.CanvasSize = UDim2.new(); page.ScrollBarThickness = 4; page.ScrollBarImageColor3 = purple
		page.Visible = false; page.Parent = modal; list(page, 10); pages[key] = page
	end
	local headings = {
		Farm = { "YOUR FARM", "Walk to a bed. Press E to plant, water, or pick a ripe crop." },
		Seeds = { "COSMIC SEED SHOP", "Little seeds. Otherworldly harvests. Every purchase gives one seed." },
		Tools = { "THE TOOL SHED", "Permanent garden tools that make every crop a little happier." },
		Eggs = { "ALIEN EGG NURSERY", "Hatch friendly helpers, each with its own farming talent." },
		Collection = { "YOUR ALIEN HELPERS", "Equip up to 3 different species. Duplicate aliens do not stack a passive." },
		Event = { "SIGNAL FROM THE STARS", "Meet the researcher beside the planet in the central plaza." },
		Lab = { "GREENHOUSE RESEARCH", "Improve crop growth and unlock new egg tiers." },
		Sell = { "HARVEST MARKET", "Take your harvest to the market stall to sell your basket." },
	}
	local function open(key: string)
		if not pages[key] then return end
		shade.Visible = true; menuTitle.Text = headings[key][1]; menuSubtitle.Text = headings[key][2]
		for name, page in pages do page.Visible = name == key end
	end
	for key, item in nav do item.Activated:Connect(function() open(key) end) end
	close.Activated:Connect(function() shade.Visible = false end)
	sell.Activated:Connect(function() open("Sell") end)

	-- Farming actions are intentions only. Being close to your own bed is checked by the server.
	local control = row(pages.Farm, "PlantingControls", 127, paper)
	local selected = label(control, "SelectedSeed", "Selected seed: loading...", UDim2.fromOffset(12, 7), UDim2.new(1, -24, 0, 24), 14)
	local actions = {}
	for i, action in { "Plant", "Water", "Harvest" } do
		actions[action] = button(control, action, string.upper(action), UDim2.new((i - 1) / 3, 9, 0, 43), UDim2.new(1 / 3, -18, 0, 37), if action == "Water" then cyan else mint)
	end
	label(control, "Instructions", "Ripe crops are picked automatically with E. Choose Water for a one-time growth boost. Empty beds need a seed.", UDim2.fromOffset(12, 86), UDim2.new(1, -24, 0, 31), 10, muted)
	local bedFrame = row(pages.Farm, "Beds", 402)
	local beds = {}
	for index = 1, 12 do
		local column, line = (index - 1) % 3, math.floor((index - 1) / 3)
		local card = frame(bedFrame, "Bed" .. index, UDim2.new(column / 3, 4, 0, line * 100 + 3), UDim2.new(1 / 3, -9, 0, 94), Color3.fromRGB(231, 221, 237))
		label(card, "Number", "BED " .. index, UDim2.fromOffset(8, 3), UDim2.new(1, -16, 0, 15), 8, muted)
		local name = label(card, "Crop", "Empty bed", UDim2.fromOffset(8, 21), UDim2.new(1, -16, 0, 22), 11)
		fitted(name, 8, 11)
		local progress = frame(card, "ProgressTrack", UDim2.fromOffset(8, 48), UDim2.new(1, -16, 0, 5), cream)
		local fill = frame(progress, "Fill", UDim2.new(), UDim2.fromScale(0, 1), mint)
		local use = button(card, "Use", "Plant", UDim2.fromOffset(6, 62), UDim2.new(1, -12, 0, 25), mint)
		beds[index] = { Name = name, Fill = fill, Use = use }
	end
	local seedHeading = row(pages.Farm, "SeedHeading", 28, cream)
	label(seedHeading, "Title", "SEEDS IN YOUR POCKET", UDim2.fromOffset(6, 0), UDim2.new(1, -12, 1, 0), 12).Font = Enum.Font.GothamBold
	local seedChoices = {}
	for _, id in FarmData.CropOrder do
		local crop = FarmData.Crops[id]
		local item = button(pages.Farm, id, crop.DisplayName, UDim2.new(), UDim2.new(1, 0, 0, 37), mint)
		seedChoices[id] = item
	end
	local researchLink = button(pages.Farm, "Greenhouse", "GREENHOUSE  /  Growth upgrades", UDim2.new(), UDim2.new(1, 0, 0, 40), purple)
	researchLink.Activated:Connect(function() open("Lab") end)

	local seedCards = {}
	for _, id in FarmData.CropOrder do
		local crop = FarmData.Crops[id]
		if not crop.Event then
			local card = row(pages.Seeds, id, 128)
			local tint = Color3.fromRGB(unpack(crop.Color)); outline(card, tint)
			preview(card, "Crop", id, UDim2.fromOffset(0, 5), UDim2.new(0.24, 0, 0, 110))
			label(card, "Name", crop.DisplayName, UDim2.new(0.25, 0, 0, 8), UDim2.new(0.75, -12, 0, 24), 17).Font = Enum.Font.GothamBold
			label(card, "Details", string.format("%ds growth  /  $%s base harvest", crop.GrowSeconds, UI.Number(crop.SellValue)), UDim2.new(0.25, 0, 0, 36), UDim2.new(0.75, -12, 0, 30), 11, muted)
			local owned = label(card, "Owned", "Seeds owned: 0", UDim2.new(0.25, 0, 0, 69), UDim2.new(0.75, -12, 0, 17), 10, muted)
			local buy = button(card, "Buy", "Buy seed  $" .. crop.SeedPrice, UDim2.new(0.25, 0, 0, 91), UDim2.new(0.75, -12, 0, 29), mint)
			seedCards[id] = { Buy = buy, Owned = owned }
		end
	end

	local toolCards = {}
	for _, id in FarmData.ToolOrder do
		local tool = FarmData.Tools[id]
		local card = row(pages.Tools, id, 135)
		local tile = frame(card, "ToolBadge", UDim2.fromOffset(8, 12), UDim2.new(0.22, -10, 0, 107), cyan)
		preview(tile, "Tool", id, UDim2.new(), UDim2.fromScale(1, 1))
		label(card, "Name", tool.DisplayName, UDim2.new(0.24, 0, 0, 9), UDim2.new(0.76, -12, 0, 22), 17).Font = Enum.Font.GothamBold
		label(card, "Description", tool.Description, UDim2.new(0.24, 0, 0, 37), UDim2.new(0.76, -12, 0, 48), 11, muted)
		local buy = button(card, "Buy", "Buy  $" .. tool.Price, UDim2.new(0.24, 0, 0, 96), UDim2.new(0.76, -12, 0, 30), cyan)
		toolCards[id] = buy
	end

	local eggCards = {}
	for _, id in AlienData.EggOrder do
		local egg = AlienData.Eggs[id]; local tint = Color3.fromRGB(unpack(egg.Color))
		local card = row(pages.Eggs, id, 150); outline(card, tint)
		preview(card, "Egg", id, UDim2.fromOffset(1, 7), UDim2.new(0.24, 0, 0, 125), tint)
		label(card, "Name", egg.DisplayName, UDim2.new(0.25, 0, 0, 8), UDim2.new(0.75, -12, 0, 24), 18).Font = Enum.Font.GothamBold
		local odds = {}
		for _, entry in egg.Pool do table.insert(odds, AlienData.Aliens[entry.AlienId].DisplayName .. " " .. entry.Weight .. "%") end
		label(card, "Odds", table.concat(odds, "  /  "), UDim2.new(0.25, 0, 0, 37), UDim2.new(0.75, -12, 0, 51), 10, muted)
		label(card, "Hint", "Each species has a unique farming passive.", UDim2.new(0.25, 0, 0, 89), UDim2.new(0.75, -12, 0, 17), 9, muted)
		eggCards[id] = button(card, "Buy", "Hatch  $" .. egg.Price, UDim2.new(0.25, 0, 0, 112), UDim2.new(0.75, -12, 0, 30), pink)
	end

	local helpersHeading = row(pages.Collection, "Equipped", 46, purple)
	local equippedLabel = label(helpersHeading, "EquippedNames", "0 / 3 helpers equipped", UDim2.fromOffset(12, 5), UDim2.new(1, -24, 0, 36), 12)
	local collectionCards = {}
	for _, id in AlienData.AlienOrder do
		local alien = AlienData.Aliens[id]
		local card = row(pages.Collection, id, 166)
		local icon = preview(card, "Alien", id, UDim2.fromOffset(0, 4), UDim2.new(0.25, 0, 0, 150))
		local name = label(card, "Name", "???", UDim2.new(0.26, 0, 0, 8), UDim2.new(0.74, -12, 0, 23), 18)
		name.Font = Enum.Font.GothamBold
		local detail = label(card, "Detail", "Hatch to discover", UDim2.new(0.26, 0, 0, 33), UDim2.new(0.74, -12, 0, 17), 10, muted)
		local passive = label(card, "Passive", "A secret farming talent awaits.", UDim2.new(0.26, 0, 0, 56), UDim2.new(0.74, -12, 0, 59), 11)
		local equip = button(card, "Equip", "Hatch to discover", UDim2.new(0.26, 0, 0, 124), UDim2.new(0.74, -12, 0, 32), purple)
		collectionCards[id] = { Icon = icon, Name = name, Detail = detail, Passive = passive, Equip = equip, Alien = alien }
	end
	local release = button(pages.Collection, "Release", "Release a spare alien", UDim2.new(), UDim2.new(1, 0, 0, 39), pink)
	local releaseHint = row(pages.Collection, "ReleaseHint", 35, cream)
	label(releaseHint, "Hint", "Release needs two clicks. No refund; your last alien is protected. Discoveries stay in your journal.", UDim2.fromOffset(6, 0), UDim2.new(1, -12, 1, 0), 10, muted)

	local event = row(pages.Event, "EventBrief", 275, paper); outline(event, purple)
	preview(event, "Crop", FarmData.Event.CropId, UDim2.fromOffset(4, 7), UDim2.new(0.29, 0, 0, 152))
	label(event, "Title", FarmData.Event.Title, UDim2.new(0.31, 0, 0, 14), UDim2.new(0.69, -12, 0, 49), 20).Font = Enum.Font.GothamBlack
	label(event, "Story", "The plaza researcher has found a signal inside a strange new plant. Help grow a sample!", UDim2.new(0.31, 0, 0, 70), UDim2.new(0.69, -12, 0, 69), 12, muted)
	local eventInfo = label(event, "Progress", "Visit the researcher to begin.", UDim2.fromOffset(13, 158), UDim2.new(1, -26, 0, 32), 14)
	label(event, "Rewards", string.format("REWARDS  /  $%s + %d %s seeds", UI.Number(FarmData.Event.CashReward), FarmData.Event.SeedRewardCount, FarmData.Crops[FarmData.Event.SeedRewardId].DisplayName), UDim2.fromOffset(13, 193), UDim2.new(1, -26, 0, 33), 11, muted)
	local eventAction = button(event, "Claim", "Accept mission at the plaza", UDim2.fromOffset(13, 232), UDim2.new(1, -26, 0, 32), gold)
	local eventGuide = row(pages.Event, "EventGuide", 111, cream)
	label(eventGuide, "Guide", "1  Speak to the researcher for special seeds.\n2  Plant them in your own garden.\n3  Pick 3 ripe Nebula Sprouts.\n4  Return to the researcher for your reward.", UDim2.fromOffset(8, 3), UDim2.new(1, -16, 1, -6), 12, muted)
	local eventSeeds = button(pages.Event, "EventSeeds", "Select quest seeds", UDim2.new(), UDim2.new(1, 0, 0, 39), purple)
	seedChoices[FarmData.Event.CropId] = eventSeeds

	local research = row(pages.Lab, "Research", 229, paper); outline(research, purple)
	label(research, "Title", "A HAPPIER GREENHOUSE", UDim2.fromOffset(14, 11), UDim2.new(1, -28, 0, 29), 18).Font = Enum.Font.GothamBlack
	local upgradeInfo = label(research, "Info", "Loading...", UDim2.fromOffset(14, 48), UDim2.new(1, -28, 0, 65), 14)
	label(research, "Description", "Grow crops faster with each greenhouse level. Level 1 unlocks Botanical eggs; level 2 unlocks Cosmic eggs.", UDim2.fromOffset(14, 121), UDim2.new(1, -28, 0, 53), 12, muted)
	local upgrade = button(research, "Upgrade", "Loading...", UDim2.fromOffset(14, 184), UDim2.new(1, -28, 0, 34), purple)

	local market = row(pages.Sell, "Market", 160, paper)
	label(market, "Title", "TODAY'S HARVEST", UDim2.fromOffset(14, 11), UDim2.new(1, -28, 0, 29), 18).Font = Enum.Font.GothamBlack
	local saleInfo = label(market, "Info", "Your basket is empty.", UDim2.fromOffset(14, 49), UDim2.new(1, -28, 0, 51), 14)
	local sellHarvest = button(market, "SellBasket", "Sell harvest", UDim2.fromOffset(14, 111), UDim2.new(1, -28, 0, 36), gold)
	local basketCards = {}
	for _, id in FarmData.CropOrder do
		local crop = FarmData.Crops[id]
		local card = row(pages.Sell, id, 47, cream)
		basketCards[id] = label(card, "Count", crop.DisplayName .. "  /  0", UDim2.fromOffset(10, 1), UDim2.new(1, -20, 1, -2), 12, muted)
	end
	gui.Parent = playerGui
	return { Gui = gui, Cash = cash, Harvest = harvest, Helpers = helpers, Level = level, Save = save, Status = status,
		Sell = sellHarvest, Upgrade = upgrade, UpgradeInfo = upgradeInfo, SaleInfo = saleInfo, Basket = basketCards,
		Eggs = eggCards, SeedShop = seedCards, Tools = toolCards, SeedChoices = seedChoices, Actions = actions,
		Beds = beds, Selected = selected, Collection = collectionCards, EquippedLabel = equippedLabel,
		Release = release, ReleaseConfirmed = false, EventAction = eventAction, EventInfo = eventInfo,
		MenuShade = shade, Pages = pages, Open = open }
end

function UI.Refresh(view: any, state: any, pending: boolean)
	if not state then
		for _, item in view.Eggs do UI.SetButtonEnabled(item, false) end
		for _, card in view.SeedShop do UI.SetButtonEnabled(card.Buy, false) end
		for _, item in view.Tools do UI.SetButtonEnabled(item, false) end
		for _, item in view.SeedChoices do UI.SetButtonEnabled(item, false) end
		for _, item in view.Actions do UI.SetButtonEnabled(item, false) end
		for _, card in view.Beds do UI.SetButtonEnabled(card.Use, false) end
		for _, card in view.Collection do UI.SetButtonEnabled(card.Equip, false) end
		UI.SetButtonEnabled(view.Sell, false); UI.SetButtonEnabled(view.Upgrade, false)
		UI.SetButtonEnabled(view.Release, false); UI.SetButtonEnabled(view.EventAction, false)
		return
	end
	view.Cash.Text = "$" .. UI.Number(state.Cash)
	view.Harvest.Text = UI.Number(state.HarvestCount) .. " crops  /  $" .. UI.Number(state.SellValue)
	view.Level.Text = "GREENHOUSE " .. state.LabLevel .. "  /  PLANT, GROW, DISCOVER"
	view.Helpers.Text = string.format("%d / 3 helpers  /  +%.0f%% growth", #state.Equipped, state.GrowthBonus * 100)
	view.Save.Text = if string.find(state.SaveStatus, "Session mode", 1, true) then "Session mode  /  this visit only" else state.SaveStatus
	view.SaleInfo.Text = if state.HarvestCount > 0 then string.format("%s crops in your basket\nMarket offer: $%s", UI.Number(state.HarvestCount), UI.Number(state.SellValue)) else "Your basket is empty. Pick a ripe crop first!"
	view.Sell.Text = if pending then "Working..." else "Sell basket  $" .. UI.Number(state.SellValue)
	UI.SetButtonEnabled(view.Sell, not pending and state.SellValue > 0)
	for id, item in view.Basket do item.Text = FarmData.Crops[id].DisplayName .. "  /  " .. (state.Harvest[id] or 0) end
	local selectedCrop = FarmData.Crops[state.SelectedSeed]
	view.Selected.Text = "Selected: " .. (if selectedCrop then selectedCrop.DisplayName else "choose a seed") .. "  /  " .. (state.Seeds[state.SelectedSeed] or 0) .. " left"
	for action, item in view.Actions do
		item.Text = (if state.SelectedAction == action then "> " else "") .. string.upper(action)
		UI.SetButtonEnabled(item, not pending)
	end
	for id, item in view.SeedChoices do
		local count = state.Seeds[id] or 0
		item.Text = (if state.SelectedSeed == id then "SELECTED  /  " else "Select  /  ") .. FarmData.Crops[id].DisplayName .. "  (" .. count .. ")"
		UI.SetButtonEnabled(item, not pending and count > 0)
	end
	for id, card in view.SeedShop do
		local crop = FarmData.Crops[id]
		card.Owned.Text = "In your pocket: " .. (state.Seeds[id] or 0)
		card.Buy.Text = if pending then "Working..." elseif state.Cash < crop.SeedPrice then "Need $" .. crop.SeedPrice else "Buy 1 seed  $" .. crop.SeedPrice
		UI.SetButtonEnabled(card.Buy, not pending and state.Cash >= crop.SeedPrice)
	end
	for id, item in view.Tools do
		local owned = state.Tools[id] == true
		item.Text = if owned then "OWNED  /  ready in your garden" elseif pending then "Working..." else "Buy  $" .. FarmData.Tools[id].Price
		UI.SetButtonEnabled(item, not owned and not pending and state.Cash >= FarmData.Tools[id].Price)
	end
	for index, card in view.Beds do
		local bed = state.Beds[index]
		if bed and bed.CropId then
			local progress = math.clamp(bed.Progress, 0, 1)
			card.Name.Text = FarmData.Crops[bed.CropId].DisplayName
			card.Fill.Size = UDim2.fromScale(progress, 1)
			card.Use.Text = if progress >= 1 then "PICK!" elseif state.SelectedAction == "Water" and not bed.Watered then "Water"
				else string.format("%.0f%% grown", progress * 100)
			card.Fill.BackgroundColor3 = if bed.Mutation and bed.Mutation ~= "Normal" then purple else mint
			UI.SetButtonEnabled(card.Use, not pending and (progress >= 1 or (state.SelectedAction == "Water" and not bed.Watered)))
		else
			card.Name.Text = "Empty bed"; card.Fill.Size = UDim2.fromScale(0, 1); card.Use.Text = "Plant"
			UI.SetButtonEnabled(card.Use, not pending and state.SelectedAction == "Plant" and (state.Seeds[state.SelectedSeed] or 0) > 0)
		end
	end
	local owned: { [string]: number } = {}; local equipped = {}; local discovered = {}
	for _, id in state.OwnedAliens do owned[id] = (owned[id] or 0) + 1 end
	for _, id in state.Equipped do equipped[id] = true end
	for _, id in state.Discovered do discovered[id] = true end
	local names = {}; for _, id in state.Equipped do table.insert(names, AlienData.Aliens[id].DisplayName) end
	view.EquippedLabel.Text = #state.Equipped .. " / 3 EQUIPPED  /  " .. (if #names > 0 then table.concat(names, ", ") else "Choose a helper below")
	for id, card in view.Collection do
		local found = discovered[id] == true
		card.Icon.ImageColor3 = if found then Color3.new(1, 1, 1) else Color3.fromRGB(80, 66, 109)
		card.Name.Text = if found then card.Alien.DisplayName else "???"
		card.Detail.Text = if found then card.Alien.Rarity .. "  /  " .. (owned[id] or 0) .. " owned" else "Hatch an egg to discover"
		card.Passive.Text = if found then card.Alien.PassiveName .. "\n" .. card.Alien.PassiveDescription else "A secret farming talent awaits."
		card.Equip.Text = if equipped[id] then "EQUIPPED  /  Remove" elseif not owned[id] then "Hatch this alien first"
			elseif #state.Equipped >= 3 then "Remove a helper first" else "Equip farming helper"
		UI.SetButtonEnabled(card.Equip, not pending and owned[id] ~= nil and (equipped[id] or #state.Equipped < 3))
	end
	local weakest = AlienData.Aliens[state.WeakestAlienId]
	view.Release.Text = if view.ReleaseConfirmed then "Confirm: release one " .. weakest.DisplayName .. "?"
		elseif state.AlienCount <= 1 then "Your last alien is protected" else "Release one " .. weakest.DisplayName .. "  /  make room"
	UI.SetButtonEnabled(view.Release, not pending and state.AlienCount > 1)
	for id, item in view.Eggs do
		local egg = AlienData.Eggs[id]; local unlocked = state.LabLevel >= egg.RequiredLevel
		item.Text = if not unlocked then "Greenhouse " .. egg.RequiredLevel .. " required" elseif pending then "Working..."
			elseif state.AlienCount >= AlienData.MaxAliens then "Alien nursery is full"
			elseif state.HatchCooldownRemaining > 0 then "Next egg in " .. math.ceil(state.HatchCooldownRemaining) .. "s"
			elseif state.Cash < egg.Price then "Need $" .. egg.Price else "Hatch  $" .. egg.Price
		UI.SetButtonEnabled(item, unlocked and not pending and state.HatchCooldownRemaining <= 0 and state.Cash >= egg.Price and state.AlienCount < AlienData.MaxAliens)
	end
	local price = AlienData.UpgradePrices[state.LabLevel + 1]
	view.Upgrade.Text = if not price then "GREENHOUSE COMPLETE" elseif pending then "Working..." else "Level " .. (state.LabLevel + 1) .. "  /  $" .. price
	view.UpgradeInfo.Text = string.format("GREENHOUSE LEVEL %d / %d\nTotal crop growth boost: +%.0f%%", state.LabLevel, #AlienData.UpgradePrices, state.GrowthBonus * 100)
	UI.SetButtonEnabled(view.Upgrade, not pending and price ~= nil and state.Cash >= (price or math.huge))
	local event = FarmData.Event
	view.EventInfo.Text = if state.EventActive then string.format("Nebula Sprouts picked: %d / %d", state.EventProgress, event.Required)
		else "Missions completed: " .. state.EventCompletions .. "  /  new mission available"
	view.EventAction.Text = if pending then "Working..." elseif not state.EventActive then "Accept mission at the plaza"
		elseif state.EventProgress >= event.Required then "Claim your reward at the plaza" else "Grow the mission crops first"
	UI.SetButtonEnabled(view.EventAction, not pending and (not state.EventActive or state.EventProgress >= event.Required))
end

function UI.CancelHatch(view: any)
	if view.Opening then view.Opening:Destroy(); view.Opening = nil end
end

function UI.BeginHatch(view: any, eggId: string)
	UI.CancelHatch(view)
	local egg = AlienData.Eggs[eggId]; if not egg then return end
	local overlay = frame(view.Gui, "OpeningEgg", UDim2.new(), UDim2.fromScale(1, 1), ink)
	overlay.BackgroundTransparency = 0.2; overlay.Active = true; overlay.ZIndex = 20; view.Opening = overlay
	local icon = preview(overlay, "Egg", eggId, UDim2.fromScale(0.5, 0.44), UDim2.fromOffset(240, 240), Color3.fromRGB(unpack(egg.Color)))
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	local scale = Instance.new("UIScale"); scale.Parent = icon
	TweenService:Create(scale, TweenInfo.new(0.17, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.1 }):Play()
	local caption = label(overlay, "Caption", "Someone new is about to sprout...", UDim2.fromScale(0.05, 0.73), UDim2.fromScale(0.9, 0.08), 22, cream)
	caption.TextXAlignment = Enum.TextXAlignment.Center
end

function UI.Reveal(view: any, id: string)
	UI.CancelHatch(view)
	local alien = AlienData.Aliens[id]; if not alien then return end
	if view.Reveal then view.Reveal:Destroy() end
	view.MenuShade.Visible = false
	local overlay = frame(view.Gui, "HatchReveal", UDim2.new(), UDim2.fromScale(1, 1), ink)
	overlay.BackgroundTransparency = 0.15; overlay.Active = true; overlay.ZIndex = 20; view.Reveal = overlay
	local card = frame(overlay, "WelcomeCard", UDim2.fromScale(0.5, 0.46), UDim2.fromScale(0.88, 0.82), cream)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	local limit = Instance.new("UISizeConstraint"); limit.MaxSize = Vector2.new(390, 460); limit.Parent = card
	local tint = Color3.fromRGB(unpack(alien.BodyColor)); outline(card, tint, 0.15)
	local scale = Instance.new("UIScale"); scale.Scale = 0.65; scale.Parent = card
	TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local header = label(card, "Welcome", "A NEW GARDEN FRIEND!", UDim2.fromScale(0.05, 0.04), UDim2.fromScale(0.9, 0.07), 18)
	header.TextXAlignment = Enum.TextXAlignment.Center; header.Font = Enum.Font.GothamBlack
	preview(card, "Alien", id, UDim2.fromScale(0, 0.12), UDim2.fromScale(1, 0.45))
	local name = label(card, "Name", alien.DisplayName, UDim2.fromScale(0.05, 0.57), UDim2.fromScale(0.9, 0.07), 28)
	name.TextXAlignment = Enum.TextXAlignment.Center; name.Font = Enum.Font.GothamBlack
	local talent = label(card, "Talent", alien.Rarity .. "  /  " .. alien.PassiveName, UDim2.fromScale(0.05, 0.66), UDim2.fromScale(0.9, 0.05), 13, muted)
	talent.TextXAlignment = Enum.TextXAlignment.Center
	local description = label(card, "Description", alien.PassiveDescription, UDim2.fromScale(0.07, 0.73), UDim2.fromScale(0.86, 0.08), 12)
	description.TextXAlignment = Enum.TextXAlignment.Center
	local done = button(card, "Continue", "CHOOSE YOUR HELPERS", UDim2.fromScale(0.06, 0.87), UDim2.fromScale(0.88, 0.09), purple)
	done.Activated:Connect(function()
		overlay:Destroy(); if view.Reveal == overlay then view.Reveal = nil end
		view.Open("Collection")
	end)
	-- Local confetti celebrates the server-approved result without touching rewards.
	for i = 1, 20 do
		local chip = frame(overlay, "Confetti", UDim2.fromScale((i * 0.137) % 1, -0.05), UDim2.fromOffset(7, 11), if i % 2 == 0 then tint else gold)
		chip.Rotation = i * 19
		TweenService:Create(chip, TweenInfo.new(1.1 + (i % 5) * 0.14), { Position = UDim2.fromScale((i * 0.179) % 1, 1.08), Rotation = i * 43, BackgroundTransparency = 1 }):Play()
	end
end

return UI
