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
local dusk = Color3.fromRGB(91, 66, 139)

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
	return stroke
end

local function gradient(parent: Instance, top: Color3, bottom: Color3)
	local wash = Instance.new("UIGradient")
	wash.Rotation = 90; wash.Color = ColorSequence.new(top, bottom); wash.Parent = parent
	return wash
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
	outline(item, ink, 0.8)
	gradient(item, Color3.new(1, 1, 1), Color3.fromRGB(232, 225, 244))
	local scale = Instance.new("UIScale"); scale.Parent = item
	item.MouseEnter:Connect(function()
		if item.Active then TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.025 }):Play() end
	end)
	item.MouseLeave:Connect(function() TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play() end)
	item.MouseButton1Down:Connect(function()
		if item.Active then TweenService:Create(scale, TweenInfo.new(0.06), { Scale = 0.965 }):Play() end
	end)
	item.MouseButton1Up:Connect(function() TweenService:Create(scale, TweenInfo.new(0.1), { Scale = 1 }):Play() end)
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
	local card = frame(parent, name, UDim2.new(), UDim2.new(1, 0, 0, height), tint or paper)
	outline(card, purple, 0.7)
	gradient(card, Color3.new(1, 1, 1), Color3.fromRGB(246, 239, 248))
	return card
end

local function chip(parent: Instance, caption: string, at: UDim2, size: UDim2, tint: Color3): TextLabel
	local badge = label(parent, "Badge", caption, at, size, 9, ink)
	badge.BackgroundTransparency = 0; badge.BackgroundColor3 = tint; badge.Font = Enum.Font.GothamBold
	badge.TextXAlignment = Enum.TextXAlignment.Center; corners(badge, 7)
	fitted(badge, 7, 9)
	return badge
end

-- Small illustrations are built from rounded UI shapes, so every icon is sharp
-- at different screen sizes and works without uploaded image assets.
local function icon(parent: Instance, name: string, at: UDim2, size: UDim2, tint: Color3): Frame
	local canvas = frame(parent, "Illustration", at, size, tint); canvas.BackgroundTransparency = 1
	local function shape(key: string, x: number, y: number, w: number, h: number, color: Color3, rotation: number?): Frame
		local mark = frame(canvas, key, UDim2.fromScale(x, y), UDim2.fromScale(w, h), color)
		mark.Rotation = rotation or 0
		return mark
	end
	if name == "Coins" then
		shape("CoinShadow", 0.08, 0.19, 0.84, 0.76, Color3.fromRGB(216, 153, 65))
		shape("Coin", 0.08, 0.08, 0.84, 0.76, gold)
		outline(shape("Inset", 0.2, 0.2, 0.6, 0.52, gold), Color3.fromRGB(201, 135, 50), 0.3)
		local dollar = label(canvas, "Stamp", "$", UDim2.fromScale(0.25, 0.13), UDim2.fromScale(0.5, 0.61), 20, Color3.fromRGB(173, 116, 45))
		dollar.Font = Enum.Font.GothamBlack; dollar.TextXAlignment = Enum.TextXAlignment.Center; fitted(dollar, 12, 20)
		shape("Shine", 0.26, 0.17, 0.2, 0.05, paper, -25)
	elseif name == "Basket" then
		local handle = shape("Handle", 0.23, 0.08, 0.54, 0.69, gold); handle.BackgroundTransparency = 1
		outline(handle, Color3.fromRGB(157, 111, 73), 0).Thickness = 2.5
		shape("Harvest", 0.25, 0.24, 0.3, 0.32, pink); shape("Harvest", 0.5, 0.25, 0.25, 0.29, mint)
		shape("Basket", 0.13, 0.45, 0.75, 0.43, Color3.fromRGB(188, 137, 85))
		shape("Rim", 0.08, 0.44, 0.84, 0.12, gold)
		for i = 1, 3 do shape("Weave", 0.21, 0.58 + i * 0.06, 0.59, 0.03, gold) end
	elseif name == "Farm" or name == "Seeds" then
		if name == "Farm" then shape("Soil", 0.1, 0.69, 0.8, 0.2, Color3.fromRGB(159, 117, 89)) end
		shape("Stem", 0.45, 0.37, 0.1, 0.41, Color3.fromRGB(88, 155, 93))
		shape("Leaf", 0.14, 0.24, 0.43, 0.22, mint, 35)
		shape("Leaf", 0.45, 0.17, 0.43, 0.24, Color3.fromRGB(114, 191, 102), -40)
	elseif name == "Tools" then
		shape("Can", 0.12, 0.36, 0.56, 0.45, cyan)
		local handle = shape("Handle", 0.05, 0.2, 0.39, 0.45, cyan); handle.BackgroundTransparency = 1
		outline(handle, cyan, 0).Thickness = 2
		shape("Spout", 0.58, 0.43, 0.38, 0.12, cyan, -35)
		shape("Drop", 0.83, 0.61, 0.1, 0.19, paper, -10)
	elseif name == "Eggs" then
		shape("Egg", 0.18, 0.05, 0.64, 0.88, pink)
		shape("Spot", 0.28, 0.34, 0.15, 0.19, cream); shape("Spot", 0.56, 0.58, 0.15, 0.18, cream)
		shape("Shine", 0.3, 0.19, 0.18, 0.05, paper, -35)
	elseif name == "Collection" then
		shape("Antenna", 0.23, 0.06, 0.08, 0.23, purple, -25); shape("Antenna", 0.69, 0.06, 0.08, 0.23, purple, 25)
		shape("Head", 0.09, 0.21, 0.82, 0.68, mint)
		shape("Eye", 0.26, 0.4, 0.12, 0.21, ink); shape("Eye", 0.62, 0.4, 0.12, 0.21, ink)
		shape("Smile", 0.43, 0.67, 0.14, 0.06, ink)
	else
		shape("Star", 0.34, 0.09, 0.32, 0.8, gold)
		shape("Star", 0.1, 0.34, 0.8, 0.32, gold)
		shape("Star", 0.28, 0.27, 0.44, 0.45, gold, 45)
		shape("Spark", 0.43, 0.31, 0.15, 0.23, cream)
	end
	return canvas
end

local function previewTile(parent: Instance, at: UDim2, size: UDim2, tint: Color3): Frame
	local tile = frame(parent, "DisplayTile", at, size, tint:Lerp(paper, 0.65))
	outline(tile, tint, 0.25); gradient(tile, Color3.new(1, 1, 1), Color3.fromRGB(228, 219, 246))
	local base = frame(tile, "Pedestal", UDim2.fromScale(0.17, 0.82), UDim2.fromScale(0.66, 0.09), tint)
	base.BackgroundTransparency = 0.38
	return tile
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
	local hudShadow = frame(gui, "JournalShadow", UDim2.fromOffset(12, 17), UDim2.new(1, -24, 0, 224), ink)
	hudShadow.BackgroundTransparency = 0.55
	local shadowLimit = Instance.new("UISizeConstraint"); shadowLimit.MaxSize = Vector2.new(255, 224); shadowLimit.Parent = hudShadow
	local hud = frame(gui, "FieldJournal", UDim2.fromOffset(12, 12), UDim2.new(1, -24, 0, 224), cream)
	local hudLimit = Instance.new("UISizeConstraint"); hudLimit.MaxSize = Vector2.new(255, 224); hudLimit.Parent = hud
	outline(hud, paper, 0.15); gradient(hud, Color3.new(1, 1, 1), Color3.fromRGB(248, 233, 237))
	local header = frame(hud, "Masthead", UDim2.new(), UDim2.new(1, 0, 0, 59), dusk)
	gradient(header, Color3.fromRGB(223, 204, 255), Color3.fromRGB(129, 108, 170))
	local title = label(header, "Title", "ALIEN GARDENS", UDim2.fromOffset(13, 8), UDim2.new(1, -68, 0, 25), 17, cream)
	title.Font = Enum.Font.GothamBlack; fitted(title, 12, 17)
	local level = label(header, "Level", "A LITTLE FARM AMONG THE STARS", UDim2.fromOffset(13, 35), UDim2.new(1, -63, 0, 16), 8, Color3.fromRGB(235, 224, 255))
	preview(header, "Alien", AlienData.StarterAlienId, UDim2.new(1, -58, 0, -1), UDim2.fromOffset(60, 60))
	local cashRow = frame(hud, "Coins", UDim2.fromOffset(9, 67), UDim2.new(1, -18, 0, 48), Color3.fromRGB(225, 244, 210))
	outline(cashRow, mint, 0.35); icon(cashRow, "Coins", UDim2.fromOffset(5, 3), UDim2.fromOffset(43, 43), gold)
	label(cashRow, "Caption", "COINS", UDim2.fromOffset(55, 4), UDim2.new(1, -65, 0, 12), 8, muted)
	local cash = label(cashRow, "Value", "Loading...", UDim2.fromOffset(54, 15), UDim2.new(1, -64, 0, 29), 23, Color3.fromRGB(62, 116, 67))
	cash.Font = Enum.Font.GothamBlack
	local cashScale = Instance.new("UIScale"); cashScale.Parent = cash
	local cashDelta = label(cashRow, "Change", "", UDim2.new(1, -70, 0, 3), UDim2.fromOffset(60, 14), 10)
	cashDelta.TextXAlignment = Enum.TextXAlignment.Right
	local harvestRow = frame(hud, "HarvestBasket", UDim2.fromOffset(9, 122), UDim2.new(1, -18, 0, 46), Color3.fromRGB(255, 228, 179))
	outline(harvestRow, gold, 0.2); icon(harvestRow, "Basket", UDim2.fromOffset(4, 5), UDim2.fromOffset(36, 36), gold)
	label(harvestRow, "Caption", "HARVEST BASKET", UDim2.fromOffset(43, 4), UDim2.new(1, -105, 0, 12), 8, muted)
	local harvest = label(harvestRow, "Value", "0 crops", UDim2.fromOffset(43, 17), UDim2.new(1, -105, 0, 24), 13)
	fitted(harvest, 9, 13)
	local sell = button(harvestRow, "Sell", "SELL", UDim2.new(1, -60, 0, 7), UDim2.fromOffset(52, 31), cream)
	icon(hud, "Collection", UDim2.fromOffset(10, 181), UDim2.fromOffset(28, 28), mint)
	local helpers = label(hud, "Helpers", "Helpers waking up...", UDim2.fromOffset(45, 174), UDim2.new(1, -55, 0, 28), 10)
	local save = label(hud, "Saving", "Connecting...", UDim2.fromOffset(45, 203), UDim2.new(1, -55, 0, 12), 8, muted)

	local dockShadow = frame(gui, "DockShadow", UDim2.new(0.5, 0, 1, -7), UDim2.new(1, -20, 0, 75), ink)
	dockShadow.AnchorPoint = Vector2.new(0.5, 1); dockShadow.BackgroundTransparency = 0.5
	local dockShadowLimit = Instance.new("UISizeConstraint"); dockShadowLimit.MaxSize = Vector2.new(650, 75); dockShadowLimit.Parent = dockShadow
	local dock = frame(gui, "GardenDock", UDim2.new(0.5, 0, 1, -12), UDim2.new(1, -20, 0, 75), cream)
	dock.AnchorPoint = Vector2.new(0.5, 1); outline(dock, paper, 0.1)
	gradient(dock, Color3.new(1, 1, 1), Color3.fromRGB(244, 227, 245))
	local dockLimit = Instance.new("UISizeConstraint"); dockLimit.MaxSize = Vector2.new(650, 75); dockLimit.Parent = dock
	local nav, navStrokes = {}, {}
	for i, entry in { { "Farm", "FARM", mint }, { "Seeds", "SEEDS", mint }, { "Tools", "TOOLS", cyan },
		{ "Eggs", "EGGS", pink }, { "Collection", "ALIENS", purple }, { "Event", "QUEST", gold } } do
		local key = entry[1] :: string
		local item = button(dock, key, entry[2] :: string, UDim2.new((i - 1) / 6, 7, 0, 8), UDim2.new(1 / 6, -10, 0, 59), paper)
		item.TextYAlignment = Enum.TextYAlignment.Bottom
		local inset = Instance.new("UIPadding"); inset.PaddingBottom = UDim.new(0, 5); inset.Parent = item
		icon(item, key, UDim2.new(0.5, -15, 0, 3), UDim2.fromOffset(30, 30), entry[3] :: Color3)
		item:SetAttribute("NavColor", entry[3]); navStrokes[key] = item:FindFirstChildOfClass("UIStroke")
		fitted(item, 8, 11); nav[key] = item
	end
	local status = label(gui, "Status", "FIRST SEED  /  Walk to an empty garden bed and press E.", UDim2.new(0.5, 0, 1, -96), UDim2.new(1, -30, 0, 38), 12, cream)
	status.AnchorPoint = Vector2.new(0.5, 1); status.TextXAlignment = Enum.TextXAlignment.Center
	status.ZIndex = 11 -- Purchase errors stay readable while a shop is open.
	status.BackgroundTransparency = 0.12; status.BackgroundColor3 = dusk; corners(status, 13); outline(status, purple, 0.4)
	local statusScale = Instance.new("UIScale"); statusScale.Parent = status
	local statusPadding = Instance.new("UIPadding"); statusPadding.PaddingLeft = UDim.new(0, 12); statusPadding.PaddingRight = UDim.new(0, 12); statusPadding.Parent = status
	local statusLimit = Instance.new("UISizeConstraint"); statusLimit.MaxSize = Vector2.new(620, 38); statusLimit.Parent = status

	local shade = frame(gui, "MenuShade", UDim2.new(), UDim2.fromScale(1, 1), ink)
	shade.BackgroundTransparency = 0.38; shade.Visible = false; shade.Active = true; shade.ZIndex = 10
	local modalShadow = frame(shade, "JournalShadow", UDim2.new(0.5, 0, 0.46, 7), UDim2.fromScale(0.93, 0.83), Color3.fromRGB(32, 23, 57))
	modalShadow.AnchorPoint = Vector2.new(0.5, 0.5); modalShadow.BackgroundTransparency = 0.4
	local modalShadowLimit = Instance.new("UISizeConstraint"); modalShadowLimit.MaxSize = Vector2.new(700, 570); modalShadowLimit.Parent = modalShadow
	local modal = frame(shade, "Journal", UDim2.fromScale(0.5, 0.46), UDim2.fromScale(0.93, 0.83), cream)
	modal.AnchorPoint = Vector2.new(0.5, 0.5); outline(modal, paper, 0.1)
	local modalLimit = Instance.new("UISizeConstraint"); modalLimit.MaxSize = Vector2.new(700, 570); modalLimit.Parent = modal
	local modalScale = Instance.new("UIScale"); modalScale.Parent = modal
	local menuHeader = frame(modal, "PageHeader", UDim2.new(), UDim2.new(1, 0, 0, 86), dusk)
	gradient(menuHeader, Color3.fromRGB(243, 222, 255), Color3.fromRGB(126, 105, 164))
	local menuTitle = label(menuHeader, "Title", "YOUR FARM", UDim2.fromOffset(18, 12), UDim2.new(1, -80, 0, 28), 22, cream)
	menuTitle.Font = Enum.Font.GothamBlack
	fitted(menuTitle, 14, 22)
	local menuSubtitle = label(menuHeader, "Subtitle", "A garden with a little help from the stars.", UDim2.fromOffset(18, 44), UDim2.new(1, -36, 0, 29), 11, Color3.fromRGB(232, 218, 250))
	local close = button(menuHeader, "Close", "X", UDim2.new(1, -49, 0, 12), UDim2.fromOffset(34, 34), cream)
	local pages: { [string]: ScrollingFrame } = {}
	for _, key in { "Farm", "Seeds", "Tools", "Eggs", "Collection", "Event", "Lab", "Sell" } do
		local page = Instance.new("ScrollingFrame")
		page.Name = key; page.Position = UDim2.fromOffset(12, 95); page.Size = UDim2.new(1, -24, 1, -108)
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
		local wasOpen = shade.Visible
		shade.Visible = true; menuTitle.Text = headings[key][1]; menuSubtitle.Text = headings[key][2]
		for name, page in pages do page.Visible = name == key end
		local selectedNav = if key == "Lab" or key == "Sell" then "Farm" else key
		for name, item in nav do
			local active = name == selectedNav
			item.BackgroundColor3 = if active then item:GetAttribute("NavColor") :: Color3 else paper
			navStrokes[name].Transparency = if active then 0.1 else 0.8
			navStrokes[name].Thickness = if active then 2 else 1.5
		end
		if not wasOpen then
			modalScale.Scale = 0.94
			TweenService:Create(modalScale, TweenInfo.new(0.23, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end
	end
	local function closeMenu()
		shade.Visible = false
		for name, item in nav do item.BackgroundColor3 = paper; navStrokes[name].Transparency = 0.8; navStrokes[name].Thickness = 1.5 end
	end
	for key, item in nav do item.Activated:Connect(function() open(key) end) end
	close.Activated:Connect(closeMenu)
	sell.Activated:Connect(function() open("Sell") end)

	for _, entry in {
		{ "Seeds", "GROW SOMETHING WONDERFUL", "Pick a seed. Find a bed. Start a little cosmic harvest.", mint },
		{ "Tools", "YOUR GARDEN, SUPERCHARGED", "Buy once. Enjoy the upgrade for every future crop.", cyan },
		{ "Eggs", "SMALL FRIENDS. BIG TALENTS.", "Discover helpful species and choose your dream farming team.", pink },
	} do
		local banner = row(pages[entry[1] :: string], "WelcomeBanner", 78, entry[4] :: Color3)
		icon(banner, entry[1] :: string, UDim2.fromOffset(12, 15), UDim2.fromOffset(44, 44), entry[4] :: Color3)
		local heading = label(banner, "Heading", entry[2] :: string, UDim2.fromOffset(69, 9), UDim2.new(1, -83, 0, 26), 14)
		heading.Font = Enum.Font.GothamBlack; fitted(heading, 10, 14)
		label(banner, "Description", entry[3] :: string, UDim2.fromOffset(69, 36), UDim2.new(1, -83, 0, 30), 10, ink)
	end

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
			local card = row(pages.Seeds, id, 151)
			local tint = Color3.fromRGB(unpack(crop.Color)); outline(card, tint)
			local tile = previewTile(card, UDim2.fromOffset(8, 8), UDim2.new(0.25, -12, 0, 134), tint)
			preview(tile, "Crop", id, UDim2.new(), UDim2.fromScale(1, 0.94))
			label(card, "Name", crop.DisplayName, UDim2.new(0.27, 0, 0, 9), UDim2.new(0.73, -12, 0, 24), 17).Font = Enum.Font.GothamBlack
			chip(card, string.upper(crop.Category) .. " SEED", UDim2.new(0.27, 0, 0, 37), UDim2.fromOffset(94, 17), tint:Lerp(paper, 0.6))
			label(card, "Details", string.format("Grows in %ds  /  harvest from $%s", crop.GrowSeconds, UI.Number(crop.SellValue)), UDim2.new(0.27, 0, 0, 59), UDim2.new(0.73, -12, 0, 23), 11, muted)
			local owned = label(card, "Owned", "Seeds owned: 0", UDim2.new(0.27, 0, 0, 86), UDim2.new(0.73, -12, 0, 17), 10, muted)
			local buy = button(card, "Buy", "Buy seed  $" .. crop.SeedPrice, UDim2.new(0.27, 0, 0, 111), UDim2.new(0.73, -12, 0, 32), mint)
			seedCards[id] = { Buy = buy, Owned = owned }
		end
	end

	-- Build the journal off-screen in small batches before showing it.
	task.wait()
	local toolCards = {}
	for _, id in FarmData.ToolOrder do
		local tool = FarmData.Tools[id]
		local card = row(pages.Tools, id, 151)
		local tile = previewTile(card, UDim2.fromOffset(8, 8), UDim2.new(0.25, -12, 0, 134), Color3.fromRGB(unpack(tool.Color)))
		preview(tile, "Tool", id, UDim2.new(), UDim2.fromScale(1, 0.94))
		label(card, "Name", tool.DisplayName, UDim2.new(0.27, 0, 0, 9), UDim2.new(0.73, -12, 0, 25), 16).Font = Enum.Font.GothamBlack
		chip(card, "PERMANENT TOOL", UDim2.new(0.27, 0, 0, 39), UDim2.fromOffset(100, 17), cyan:Lerp(paper, 0.4))
		label(card, "Description", tool.Description, UDim2.new(0.27, 0, 0, 60), UDim2.new(0.73, -12, 0, 42), 11, muted)
		local buy = button(card, "Buy", "Buy  $" .. tool.Price, UDim2.new(0.27, 0, 0, 112), UDim2.new(0.73, -12, 0, 31), cyan)
		toolCards[id] = buy
	end

	local eggCards = {}
	for _, id in AlienData.EggOrder do
		local egg = AlienData.Eggs[id]; local tint = Color3.fromRGB(unpack(egg.Color))
		local card = row(pages.Eggs, id, 174); outline(card, tint)
		local tile = previewTile(card, UDim2.fromOffset(8, 8), UDim2.new(0.25, -12, 0, 157), tint)
		preview(tile, "Egg", id, UDim2.new(), UDim2.fromScale(1, 0.94), tint)
		label(card, "Name", egg.DisplayName, UDim2.new(0.27, 0, 0, 8), UDim2.new(0.73, -12, 0, 25), 18).Font = Enum.Font.GothamBlack
		chip(card, "ALIEN HELPERS", UDim2.new(0.27, 0, 0, 40), UDim2.fromOffset(92, 17), tint:Lerp(paper, 0.5))
		local odds = {}
		for _, entry in egg.Pool do table.insert(odds, AlienData.Aliens[entry.AlienId].DisplayName .. " " .. entry.Weight .. "%") end
		label(card, "Odds", table.concat(odds, "  /  "), UDim2.new(0.27, 0, 0, 64), UDim2.new(0.73, -12, 0, 42), 10, muted)
		label(card, "Hint", "One new friend. One unique talent.", UDim2.new(0.27, 0, 0, 109), UDim2.new(0.73, -12, 0, 17), 9, muted)
		eggCards[id] = button(card, "Buy", "Hatch  $" .. egg.Price, UDim2.new(0.27, 0, 0, 134), UDim2.new(0.73, -12, 0, 32), pink)
	end

	local helpersHeading = row(pages.Collection, "Equipped", 46, purple)
	local equippedLabel = label(helpersHeading, "EquippedNames", "0 / 3 helpers equipped", UDim2.fromOffset(12, 5), UDim2.new(1, -24, 0, 36), 12)
	local collectionCards = {}
	for i, id in AlienData.AlienOrder do
		local alien = AlienData.Aliens[id]
		local card = row(pages.Collection, id, 184)
		local tile = previewTile(card, UDim2.fromOffset(8, 8), UDim2.new(0.25, -12, 0, 168), Color3.fromRGB(unpack(alien.BodyColor)))
		local icon = preview(tile, "Alien", id, UDim2.new(), UDim2.fromScale(1, 0.96))
		local name = label(card, "Name", "???", UDim2.new(0.26, 0, 0, 8), UDim2.new(0.74, -12, 0, 23), 18)
		name.Font = Enum.Font.GothamBlack
		local detail = chip(card, "Hatch to discover", UDim2.new(0.26, 0, 0, 38), UDim2.new(0.74, -12, 0, 20), purple:Lerp(paper, 0.55))
		local passive = label(card, "Passive", "A secret farming talent awaits.", UDim2.new(0.26, 0, 0, 69), UDim2.new(0.74, -12, 0, 61), 11)
		local equip = button(card, "Equip", "Hatch to discover", UDim2.new(0.26, 0, 0, 143), UDim2.new(0.74, -12, 0, 32), purple)
		collectionCards[id] = { Icon = icon, Name = name, Detail = detail, Passive = passive, Equip = equip, Alien = alien }
		if i % 3 == 0 then task.wait() end
	end
	local release = button(pages.Collection, "Release", "Release a spare alien", UDim2.new(), UDim2.new(1, 0, 0, 39), pink)
	local releaseHint = row(pages.Collection, "ReleaseHint", 35, cream)
	label(releaseHint, "Hint", "Release needs two clicks. No refund; your last alien is protected. Discoveries stay in your journal.", UDim2.fromOffset(6, 0), UDim2.new(1, -12, 1, 0), 10, muted)

	local event = row(pages.Event, "EventBrief", 309, paper); outline(event, purple)
	local eventTile = previewTile(event, UDim2.fromOffset(9, 9), UDim2.new(0.29, -17, 0, 153), cyan)
	preview(eventTile, "Crop", FarmData.Event.CropId, UDim2.new(), UDim2.fromScale(1, 0.95))
	chip(event, "PLAZA RESEARCH QUEST", UDim2.new(0.31, 0, 0, 10), UDim2.new(0.69, -12, 0, 20), purple:Lerp(paper, 0.35))
	label(event, "Title", FarmData.Event.Title, UDim2.new(0.31, 0, 0, 36), UDim2.new(0.69, -12, 0, 47), 19).Font = Enum.Font.GothamBlack
	label(event, "Story", "A comet left a secret signal inside this plant. The plaza researcher needs your help to grow a sample!", UDim2.new(0.31, 0, 0, 91), UDim2.new(0.69, -12, 0, 67), 11, muted)
	local eventInfo = label(event, "Progress", "Visit the researcher to begin.", UDim2.fromOffset(13, 170), UDim2.new(1, -26, 0, 24), 13)
	local eventTrack = frame(event, "ProgressTrack", UDim2.fromOffset(13, 202), UDim2.new(1, -26, 0, 9), Color3.fromRGB(226, 218, 237))
	local eventFill = frame(eventTrack, "ProgressFill", UDim2.new(), UDim2.fromScale(0, 1), purple)
	chip(event, string.format("REWARD  /  $%s + %d %s seeds", UI.Number(FarmData.Event.CashReward), FarmData.Event.SeedRewardCount, FarmData.Crops[FarmData.Event.SeedRewardId].DisplayName), UDim2.fromOffset(13, 221), UDim2.new(1, -26, 0, 33), gold:Lerp(paper, 0.35))
	local eventAction = button(event, "Claim", "Accept mission at the plaza", UDim2.fromOffset(13, 266), UDim2.new(1, -26, 0, 34), gold)
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
		CashScale = cashScale, CashDelta = cashDelta, StatusScale = statusScale,
		Sell = sellHarvest, Upgrade = upgrade, UpgradeInfo = upgradeInfo, SaleInfo = saleInfo, Basket = basketCards,
		Eggs = eggCards, SeedShop = seedCards, Tools = toolCards, SeedChoices = seedChoices, Actions = actions,
		Beds = beds, Selected = selected, Collection = collectionCards, EquippedLabel = equippedLabel,
		Release = release, ReleaseConfirmed = false, EventAction = eventAction, EventInfo = eventInfo, EventFill = eventFill,
		MenuShade = shade, Pages = pages, Open = open, Close = closeMenu }
end

function UI.SetStatus(view: any, message: string, success: boolean?)
	view.Status.Text = message; view.LastStatusAt = os.clock()
	view.Status.BackgroundColor3 = if success == true then Color3.fromRGB(72, 118, 84)
		elseif success == false then Color3.fromRGB(137, 72, 98) else dusk
	view.StatusScale.Scale = 1
	TweenService:Create(view.StatusScale, TweenInfo.new(0.12, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), { Scale = 1.025 }):Play()
end

local function nextStep(state: any): string
	if state.EventActive and state.EventProgress >= FarmData.Event.Required then return "QUEST READY  /  Return to the plaza researcher for your reward." end
	local growing, thirsty = false, false
	for _, bed in state.Beds do
		if bed.CropId then
			if bed.Progress >= 1 then return "HARVEST TIME  /  Walk to your ripe crop and press E to pick it." end
			growing = true; if not bed.Watered then thirsty = true end
		end
	end
	if state.HarvestCount > 0 then return "MARKET TIME  /  Sell your basket, then plant something new." end
	if thirsty then return "A LITTLE WATER  /  Choose FARM > WATER, then press E at a growing crop." end
	if growing then return "GROWING NICELY  /  Visit the shops or meet the researcher while your crops grow." end
	if (state.Seeds[state.SelectedSeed] or 0) > 0 then return "YOUR NEXT SEED  /  Walk to an empty garden bed and press E to plant." end
	if state.EventActive and (state.Seeds[FarmData.Event.CropId] or 0) > 0 then return "QUEST SEEDS  /  Choose your free Nebula Sprouts in QUEST, then plant them." end
	if state.Cash < 10 and not state.EventActive then return "A FREE START  /  Meet Captain Nova in the plaza for free quest seeds and rewards." end
	return "FILL YOUR POCKET  /  Visit SEEDS, buy a seed, then choose it in FARM."
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
	if view.LastCash and view.LastCash ~= state.Cash then
		local delta = state.Cash - view.LastCash
		view.CashDelta.Text = (if delta > 0 then "+$" else "-$") .. UI.Number(math.abs(delta))
		view.CashDelta.TextColor3 = if delta > 0 then Color3.fromRGB(55, 124, 66) else Color3.fromRGB(170, 91, 104)
		view.CashChangedAt = os.clock(); view.CashScale.Scale = 1
		TweenService:Create(view.CashScale, TweenInfo.new(0.14, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, true), { Scale = 1.06 }):Play()
	elseif os.clock() - (view.CashChangedAt or 0) > 2.5 then view.CashDelta.Text = "" end
	view.LastCash = state.Cash
	if not pending and os.clock() - (view.LastStatusAt or 0) >= 7 then
		view.Status.Text = nextStep(state); view.Status.BackgroundColor3 = dusk
	end
	view.Harvest.Text = UI.Number(state.HarvestCount) .. " crops  /  $" .. UI.Number(state.SellValue)
	view.Level.Text = "GREENHOUSE " .. state.LabLevel .. "  /  YOUR COSMIC FARM"
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
	view.EventFill.Size = UDim2.fromScale(if state.EventActive then math.clamp(state.EventProgress / event.Required, 0, 1) else 0, 1)
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
	for i = 1, 3 do
		local halo = frame(overlay, "HatchHalo", UDim2.fromScale(0.5, 0.44), UDim2.fromOffset(160 + i * 45, 160 + i * 45), purple)
		halo.AnchorPoint = Vector2.new(0.5, 0.5); halo.BackgroundTransparency = 1; corners(halo, 1000)
		outline(halo, Color3.fromRGB(unpack(egg.Color)), 0.3 + i * 0.16)
	end
	local icon = preview(overlay, "Egg", eggId, UDim2.fromScale(0.5, 0.44), UDim2.fromOffset(240, 240), Color3.fromRGB(unpack(egg.Color)))
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	local scale = Instance.new("UIScale"); scale.Parent = icon
	TweenService:Create(scale, TweenInfo.new(0.17, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.1 }):Play()
	local caption = label(overlay, "Caption", "Someone new is about to sprout...", UDim2.fromScale(0.05, 0.73), UDim2.fromScale(0.9, 0.08), 22, cream)
	caption.TextXAlignment = Enum.TextXAlignment.Center
	fitted(caption, 12, 22)
end

function UI.Reveal(view: any, id: string)
	UI.CancelHatch(view)
	local alien = AlienData.Aliens[id]; if not alien then return end
	if view.Reveal then view.Reveal:Destroy() end
	view.Close()
	local overlay = frame(view.Gui, "HatchReveal", UDim2.new(), UDim2.fromScale(1, 1), ink)
	overlay.BackgroundTransparency = 0.15; overlay.Active = true; overlay.ZIndex = 20; view.Reveal = overlay
	local card = frame(overlay, "WelcomeCard", UDim2.fromScale(0.5, 0.46), UDim2.fromScale(0.88, 0.82), cream)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	local limit = Instance.new("UISizeConstraint"); limit.MaxSize = Vector2.new(390, 460); limit.Parent = card
	local tint = Color3.fromRGB(unpack(alien.BodyColor)); outline(card, tint, 0.15)
	gradient(card, Color3.new(1, 1, 1), Color3.fromRGB(234, 220, 248))
	local scale = Instance.new("UIScale"); scale.Scale = 0.65; scale.Parent = card
	TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local header = label(card, "Welcome", "YOU FOUND A NEW FRIEND!", UDim2.fromScale(0.05, 0.04), UDim2.fromScale(0.9, 0.07), 18)
	header.TextXAlignment = Enum.TextXAlignment.Center; header.Font = Enum.Font.GothamBlack
	fitted(header, 11, 18)
	local spotlight = frame(card, "PortraitGlow", UDim2.fromScale(0.13, 0.16), UDim2.fromScale(0.74, 0.37), tint:Lerp(paper, 0.6))
	corners(spotlight, 1000); outline(spotlight, tint, 0.5)
	icon(card, "Event", UDim2.fromScale(0.09, 0.2), UDim2.fromOffset(20, 20), gold)
	icon(card, "Event", UDim2.fromScale(0.82, 0.37), UDim2.fromOffset(14, 14), gold)
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
