--!strict
-- A small art kit for the cosmic garden. Every object uses ordinary Roblox
-- parts, so beginners can inspect the built world while Play is running.
local Decor = {}
local lavender = Color3.fromRGB(119, 129, 199)
local purple = Color3.fromRGB(84, 66, 147)
local cyan = Color3.fromRGB(75, 225, 255)
local pink = Color3.fromRGB(235, 118, 226)
local cream = Color3.fromRGB(255, 229, 178)
local wood = Color3.fromRGB(165, 108, 69)

function Decor.Part(parent: Instance, name: string, size: Vector3, at: CFrame, tint: Color3, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.CFrame = at; p.Color = tint
	p.Anchored = true; p.Material = Enum.Material.SmoothPlastic
	p.CanCollide = false; p.CanTouch = false
	-- A sphere mesh preserves stretched oval shapes. Native Ball parts render
	-- as round spheres, which would shrink mushroom roofs and soft leaves.
	local requestedShape = shape or Enum.PartType.Block
	p.Shape = if requestedShape == Enum.PartType.Ball then Enum.PartType.Block else requestedShape
	if requestedShape == Enum.PartType.Ball then
		local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = p
	end
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

function Decor.Ball(parent: Instance, name: string, size: Vector3, at: CFrame, tint: Color3): Part
	local p = Decor.Part(parent, name, size, at, tint, Enum.PartType.Ball)
	p.CanCollide = false
	return p
end

function Decor.Disk(parent: Instance, name: string, diameter: number, height: number, at: CFrame, tint: Color3): Part
	local floor = Decor.Part(parent, name, Vector3.new(height, diameter, diameter), at * CFrame.Angles(0, 0, math.pi / 2), tint, Enum.PartType.Cylinder)
	floor.CanCollide = true
	return floor
end

local function floating(item: Instance, amplitude: number, speed: number, spin: number)
	-- LabWorld registers these with CollectionService after building the scene.
	item:SetAttribute("CosmicFloat", true)
	item:SetAttribute("FloatAmplitude", amplitude); item:SetAttribute("FloatSpeed", speed); item:SetAttribute("FloatSpin", spin)
end

local function glow(p: Part, tint: Color3, range: number)
	p.Material = Enum.Material.Neon
	local light = Instance.new("PointLight")
	light.Color = tint; light.Brightness = 0.65; light.Range = range; light.Shadows = false; light.Parent = p
end

function Decor.Board(parent: Instance, name: string, at: CFrame, size: Vector3, title: string, subtitle: string, tint: Color3): Part
	local board = Decor.Part(parent, name, size, at, wood)
	local trim = Decor.Part(parent, "BoardInset", size - Vector3.new(0.35, 0.3, 0), at * CFrame.new(0, 0, -size.Z * 0.52), Color3.fromRGB(117, 75, 61))
	trim.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignFace"; gui.Face = Enum.NormalId.Front; gui.PixelsPerStud = 32
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud; gui.LightInfluence = 0.1; gui.Parent = trim
	local heading = Instance.new("TextLabel")
	heading.Name = "Title"; heading.BackgroundTransparency = 1; heading.Size = UDim2.fromScale(0.94, 0.62)
	heading.Position = UDim2.fromScale(0.03, 0.05); heading.Font = Enum.Font.FredokaOne
	heading.Text = title; heading.TextScaled = true; heading.TextColor3 = tint; heading.TextStrokeTransparency = 0.85; heading.Parent = gui
	local detail = Instance.new("TextLabel")
	detail.Name = "Subtitle"; detail.BackgroundTransparency = 1; detail.Position = UDim2.fromScale(0.06, 0.67)
	detail.Size = UDim2.fromScale(0.88, 0.24); detail.Font = Enum.Font.GothamMedium
	detail.Text = subtitle; detail.TextScaled = true; detail.TextColor3 = cream; detail.Parent = gui
	return board
end

function Decor.Lantern(parent: Instance, at: CFrame)
	Decor.Part(parent, "LanternPost", Vector3.new(0.65, 3.6, 0.65), at * CFrame.new(0, 1.8, 0), wood)
	Decor.Part(parent, "LanternFrame", Vector3.new(1.35, 0.3, 1.35), at * CFrame.new(0, 3.65, 0), wood)
	local lamp = Decor.Part(parent, "WarmLantern", Vector3.new(0.9, 1, 0.9), at * CFrame.new(0, 4.25, 0), Color3.fromRGB(255, 218, 119))
	glow(lamp, lamp.Color, 13)
	Decor.Part(parent, "LanternRoof", Vector3.new(1.45, 0.3, 1.45), at * CFrame.new(0, 4.9, 0), wood)
end

function Decor.Crystal(parent: Instance, at: CFrame, height: number, tint: Color3)
	for i = 1, 3 do
		local angle = i * 2.2
		local length = height * (if i == 1 then 1 else 0.55)
		local p = Decor.Part(parent, "CosmicCrystal", Vector3.new(length * 0.32, length, length * 0.32),
			at * CFrame.new(math.cos(angle) * height * 0.2, length * 0.5, math.sin(angle) * height * 0.2) * CFrame.Angles(0.13, angle, 0.16), tint)
		p.Material = Enum.Material.Neon; p.CanCollide = false
		local cap = Instance.new("WedgePart")
		cap.Name = "CrystalPoint"; cap.Size = Vector3.new(length * 0.32, length * 0.35, length * 0.32)
		cap.CFrame = p.CFrame * CFrame.new(0, length * 0.63, 0); cap.Color = tint
		cap.Material = Enum.Material.Neon; cap.Anchored = true; cap.CanCollide = false; cap.Parent = parent
	end
end

function Decor.Mushroom(parent: Instance, at: CFrame, scale: number, tint: Color3)
	Decor.Part(parent, "MushroomStem", Vector3.new(scale * 0.7, scale * 2.7, scale * 0.7), at * CFrame.new(0, scale * 1.35, 0), cream)
	local cap = Decor.Ball(parent, "MushroomCap", Vector3.new(scale * 3, scale * 1.25, scale * 3), at * CFrame.new(0, scale * 3, 0), tint)
	for i = 1, 5 do
		local angle = i * math.pi * 2 / 5
		Decor.Ball(parent, "MushroomSpot", Vector3.new(scale * 0.5, scale * 0.16, scale * 0.5),
			at * CFrame.new(math.cos(angle) * scale * 0.75, scale * 3.55, math.sin(angle) * scale * 0.75), cream)
	end
	if scale > 2 then
		local light = Instance.new("PointLight"); light.Color = tint; light.Range = 15; light.Brightness = 0.25; light.Parent = cap
	end
end

function Decor.Plant(parent: Instance, at: CFrame, scale: number, tint: Color3)
	for i = 1, 4 do
		local angle = i * math.pi / 2
		Decor.Ball(parent, "WildLeaf", Vector3.new(scale * 0.7, scale * 2.5, scale * 0.36),
			at * CFrame.new(math.cos(angle) * scale * 0.5, scale, math.sin(angle) * scale * 0.5) * CFrame.Angles(0, angle, -0.5), tint)
	end
end

local function ring(parent: Instance, at: CFrame, radius: number, tint: Color3, segments: number?)
	local count = segments or 24
	for i = 1, count do
		local angle = i * math.pi * 2 / count
		local p = Decor.Part(parent, "OrbitalRing", Vector3.new(0.25, 0.3, radius * math.pi * 2 / count + 0.12),
			at * CFrame.Angles(0, angle, 0) * CFrame.new(radius, 0, 0), tint)
		p.Material = Enum.Material.Neon; p.CanCollide = false
	end
end

local function shop(parent: Instance, kind: string, at: CFrame, tint: Color3, subtitle: string): Part
	local booth = Instance.new("Model"); booth.Name = kind .. "Shop"; booth.Parent = parent
	Decor.Disk(booth, "ShopDeck", 19, 0.5, at * CFrame.new(0, 0.25, 0), Color3.fromRGB(224, 192, 150))
	Decor.Part(booth, "BackWall", Vector3.new(15, 8, 1), at * CFrame.new(0, 4, 4.5), cream)
	-- Recessed windows, rounded eaves, and a striped cloth awning give each
	-- booth a recognizable storefront instead of a lone counter and roof.
	for _, side in { -1, 1 } do
		Decor.Part(booth, "WindowFrame", Vector3.new(3.7, 4.1, 0.25), at * CFrame.new(side * 4.6, 4.8, 3.83), wood)
		local pane = Decor.Part(booth, "ShopWindow", Vector3.new(3.15, 3.5, 0.15), at * CFrame.new(side * 4.6, 4.8, 3.65), cyan:Lerp(cream, 0.25))
		pane.Material = Enum.Material.Glass; pane.Transparency = 0.25
		Decor.Part(booth, "WindowMullion", Vector3.new(0.2, 3.55, 0.2), at * CFrame.new(side * 4.6, 4.8, 3.48), wood)
		Decor.Part(booth, "WindowSill", Vector3.new(4, 0.4, 1.15), at * CFrame.new(side * 4.6, 2.7, 3.6), wood)
	end
	for i = -3, 3 do
		local stripe = if i % 2 == 0 then cream else tint:Lerp(Color3.new(1, 1, 1), 0.15)
		local canopy = Decor.Part(booth, "StripedAwning", Vector3.new(2.05, 0.22, 4.3), at * CFrame.new(i * 2.04, 6.6, -5.6) * CFrame.Angles(0.13, 0, 0), stripe)
		canopy.Material = Enum.Material.Fabric
		Decor.Ball(booth, "AwningScallop", Vector3.new(2, 0.75, 0.24), at * CFrame.new(i * 2.04, 6, -7.76), stripe)
	end
	for _, side in { -1, 1 } do
		Decor.Part(booth, "Pillar", Vector3.new(1.2, 10, 1.2), at * CFrame.new(side * 7, 5, -3.5), wood)
	end
	local counter = Decor.Part(booth, "ShopCounter", Vector3.new(14, 3.1, 4), at * CFrame.new(0, 1.8, -3.5), wood)
	Decor.Part(booth, "CounterTop", Vector3.new(14.6, 0.4, 4.6), at * CFrame.new(0, 3.55, -3.5), Color3.fromRGB(245, 207, 154))
	for i = -2, 2 do
		Decor.Part(booth, "CounterPlank", Vector3.new(0.11, 2.7, 0.1), at * CFrame.new(i * 2.45, 1.8, -5.55), Color3.fromRGB(121, 75, 49))
	end
	Decor.Ball(booth, "MushroomRoof", Vector3.new(22, 7, 20), at * CFrame.new(0, 10.5, 0), tint)
	for i = 1, 7 do
		local angle = i * math.pi * 2 / 7
		Decor.Ball(booth, "RoofSpot", Vector3.new(2.6, 0.3, 2.2), at * CFrame.new(math.cos(angle) * 6.5, 13.45, math.sin(angle) * 5.5), cream)
	end
	local title = ({ Seeds = "SEED SHOP", Tools = "TOOL SHOP", Eggs = "EGG SHOP", Sell = "HARVEST MARKET" })[kind]
	Decor.Board(booth, "ShopSign", at * CFrame.new(0, 8.8, -8.8), Vector3.new(14, 3.2, 0.5), title, subtitle, Color3.new(1, 1, 1))
	Decor.Part(booth, "SignHanger", Vector3.new(0.2, 2.3, 0.2), at * CFrame.new(0, 12.25, -10.15), wood)
	local icon = Instance.new("Model"); icon.Name = "HangingShopIcon"; icon.Parent = booth
	local badge = Decor.Ball(icon, "IconBadge", Vector3.new(2.4, 2.4, 0.35), at * CFrame.new(0, 11, -10.15), cream)
	icon.PrimaryPart = badge
	if kind == "Eggs" then
		Decor.Ball(icon, "EggSymbol", Vector3.new(1.05, 1.5, 0.25), at * CFrame.new(0, 11, -10.4), tint)
	elseif kind == "Seeds" then
		for _, side in { -1, 1 } do
			Decor.Ball(icon, "LeafSymbol", Vector3.new(0.45, 1.12, 0.2), at * CFrame.new(side * 0.27, 11.25, -10.4) * CFrame.Angles(0, 0, -side * 0.6), Color3.fromRGB(76, 172, 94))
		end
		Decor.Part(icon, "LeafStalk", Vector3.new(0.15, 0.9, 0.18), at * CFrame.new(0, 10.68, -10.4), Color3.fromRGB(76, 172, 94))
	elseif kind == "Tools" then
		Decor.Part(icon, "CanSymbol", Vector3.new(1.1, 0.9, 0.22), at * CFrame.new(-0.15, 10.95, -10.4), tint)
		Decor.Part(icon, "SpoutSymbol", Vector3.new(0.75, 0.18, 0.2), at * CFrame.new(0.6, 11.1, -10.4) * CFrame.Angles(0, 0, 0.5), tint)
	else
		Decor.Ball(icon, "FruitSymbol", Vector3.new(1.3, 1.3, 0.3), at * CFrame.new(0, 10.95, -10.4), Color3.fromRGB(243, 139, 47))
		Decor.Ball(icon, "FruitLeaf", Vector3.new(0.5, 0.3, 0.15), at * CFrame.new(0.25, 11.6, -10.4), Color3.fromRGB(73, 168, 103))
	end
	floating(icon, 0.11, 1.3, 0)
	Decor.Lantern(booth, at * CFrame.new(-8, 0.5, -7))
	Decor.Lantern(booth, at * CFrame.new(8, 0.5, -7))
	-- Display merchandise makes the shops readable even before opening a menu.
	for i = -1, 1 do
		local offset = at * CFrame.new(i * 4, 4.6, -3.5)
		if kind == "Seeds" then
			Decor.Part(booth, "SeedPacket", Vector3.new(2.2, 2.4, 0.6), offset, tint:Lerp(cream, 0.4))
			Decor.Plant(booth, offset * CFrame.new(0, -0.8, -0.5), 0.4, Color3.fromRGB(97, 180, 104))
		elseif kind == "Eggs" then
			Decor.Ball(booth, "DisplayEgg", Vector3.new(2, 2.6, 2), offset, (if i == -1 then Color3.fromRGB(158, 243, 121) elseif i == 0 then cyan else pink))
		elseif kind == "Tools" then
			Decor.Part(booth, "WateringCan", Vector3.new(1.7, 1.3, 1.4), offset, cyan)
			Decor.Part(booth, "CanSpout", Vector3.new(1.1, 0.4, 0.4), offset * CFrame.new(1.1, 0.25, 0) * CFrame.Angles(0, 0, 0.35), cyan)
		else
			Decor.Part(booth, "HarvestCrate", Vector3.new(2.5, 1.1, 2), offset, wood)
			Decor.Ball(booth, "HarvestFruit", Vector3.new(1.5, 1.5, 1.5), offset * CFrame.new(0, 0.75, 0), Color3.fromRGB(255, 174, 72))
		end
	end
	return counter
end

local function portal(parent: Instance)
	local model = Instance.new("Model"); model.Name = "StarlightPortal"; model.Parent = parent
	local center = CFrame.new(0, 23, -47)
	Decor.Part(model, "PortalPlinth", Vector3.new(32, 1.4, 10), CFrame.new(0, 6.8, -47), Color3.fromRGB(74, 85, 130)).Material = Enum.Material.Slate
	for i = 1, 20 do
		local angle = i * math.pi * 2 / 20
		local position = Vector3.new(math.sin(angle) * 12.6, math.cos(angle) * 15.4, 0)
		local stone = Decor.Part(model, "PortalArchStone", Vector3.new(4.6, 3.2, 4), center * CFrame.new(position) * CFrame.Angles(0, 0, -angle),
			if i % 2 == 0 then Color3.fromRGB(96, 106, 162) else Color3.fromRGB(75, 84, 139))
		stone.Material = Enum.Material.Slate
		local rune = Decor.Part(model, "LuminousRune", Vector3.new(1.8, 0.4, 0.25), stone.CFrame * CFrame.new(0, 0, 2.15), cyan)
		rune.Material = Enum.Material.Neon
	end
	local heart = Decor.Ball(model, "PortalHeart", Vector3.new(23, 28, 0.18), center * CFrame.new(0, 0, 0.25), Color3.fromRGB(42, 145, 231))
	heart.Material = Enum.Material.Neon; heart.Transparency = 0.62; model.PrimaryPart = heart
	-- Two continuous spiral arms read as a vortex instead of radial spokes.
	for arm = 0, 1 do
		for segment = 0, 15 do
			local function point(index: number): Vector3
				local radius = 1 + index * 0.47
				local angle = index * 0.44 + arm * math.pi
				return center:PointToWorldSpace(Vector3.new(math.sin(angle) * radius, math.cos(angle) * radius * 1.16, 0.5))
			end
			local from, toward = point(segment), point(segment + 1)
			local middle = (from + toward) * 0.5
			local stroke = Decor.Part(model, "PortalSpiral", Vector3.new(0.23, 0.23, (toward - from).Magnitude + 0.08),
				CFrame.lookAt(middle, toward), if arm == 0 then cyan else Color3.fromRGB(189, 220, 255))
			stroke.Material = Enum.Material.Neon; stroke.Transparency = 0.12
		end
	end
	local core = Decor.Ball(model, "PortalCore", Vector3.new(1.65, 1.65, 0.25), center * CFrame.new(0, 0, 0.62), Color3.fromRGB(210, 249, 255))
	core.Material = Enum.Material.Neon
	for _, side in { -1, 1 } do
		Decor.Crystal(model, CFrame.new(side * 19, 6, -47), 7.5, if side < 0 then cyan else pink)
		Decor.Plant(model, CFrame.new(side * 22, 6, -44), 2.2, Color3.fromRGB(63, 168, 165))
	end
	Decor.Board(model, "PortalName", CFrame.new(0, 8.2, -42.6) * CFrame.Angles(0, math.pi, 0), Vector3.new(16, 2, 0.35), "STARLIGHT GATE", "Where the stars meet your garden", cream)
	model:SetAttribute("CosmicPortal", true)
end

function Decor.Hub(parent: Instance): { [string]: BasePart }
	local ground = 6
	-- The broad upper island completely covers the default checkerboard around
	-- the playable area. Cliff chunks and mist turn its edge into a floating world.
	local island = Decor.Disk(parent, "FloatingGardenIsland", 282, 7, CFrame.new(0, ground - 3.5, 0), lavender)
	island.Material = Enum.Material.Grass
	for i = 1, 22 do
		local angle = i * math.pi * 2 / 22
		local at = Vector3.new(math.sin(angle) * 129, -7, math.cos(angle) * 129)
		local cliff = Decor.Part(parent, "FloatingCliff", Vector3.new(23, 24 + (i % 3) * 6, 25), CFrame.new(at) * CFrame.Angles(0.12, angle, 0.12), purple:Lerp(lavender, (i % 4) * 0.08))
		cliff.Material = Enum.Material.Slate
		cliff.CanCollide = false
		-- The lower wedges pull inward, creating a tapered floating-rock
		-- silhouette instead of a straight cylindrical wall beneath the garden.
		local lower = Instance.new("CornerWedgePart")
		lower.Name = "TaperedCliff"; lower.Size = Vector3.new(25, 31, 25)
		lower.CFrame = CFrame.new(math.sin(angle) * 114, -23, math.cos(angle) * 114) * CFrame.Angles(0, angle + math.pi / 4, 0)
		lower.Color = Color3.fromRGB(69, 64, 120):Lerp(purple, (i % 3) * 0.13)
		lower.Material = Enum.Material.Slate; lower.Anchored = true; lower.CanCollide = false; lower.CanTouch = false; lower.Parent = parent
	end
	Decor.Disk(parent, "PlazaRim", 65, 0.6, CFrame.new(0, ground + 0.3, 0), Color3.fromRGB(111, 114, 176))
	Decor.Disk(parent, "CentralPlaza", 59, 0.2, CFrame.new(0, ground + 0.7, 0), Color3.fromRGB(227, 207, 190))
	for i = 0, 5 do
		local angle = i * math.pi / 3
		local at = CFrame.new(0, ground, 0) * CFrame.Angles(0, angle, 0)
		Decor.Part(parent, "GardenPath", Vector3.new(10, 0.25, 91), at * CFrame.new(0, 0.2, 53), Color3.fromRGB(233, 195, 149)).CanCollide = true
		for z = 35, 62, 9 do
			Decor.Ball(parent, "PathStone", Vector3.new(4, 0.35, 2.5), at * CFrame.new((z % 2 - 0.5) * 3, 0.42, z), Color3.fromRGB(199, 176, 169))
		end
		Decor.Lantern(parent, at * CFrame.new(7, 0.35, 49))
	end
	local stations: { [string]: BasePart } = {}
	local settings = {
		{ Kind = "Seeds", At = Vector3.new(-34, ground, -28), Tint = Color3.fromRGB(178, 104, 230), Sub = "Plant something extraordinary" },
		{ Kind = "Tools", At = Vector3.new(34, ground, -28), Tint = Color3.fromRGB(75, 178, 228), Sub = "A little help for your garden" },
		{ Kind = "Eggs", At = Vector3.new(-34, ground, 28), Tint = Color3.fromRGB(237, 110, 179), Sub = "Meet your next garden helper" },
		{ Kind = "Sell", At = Vector3.new(34, ground, 28), Tint = Color3.fromRGB(245, 176, 69), Sub = "Fresh harvests, happy wallets" },
	}
	for _, setting in settings do
		local toward = -setting.At * Vector3.new(1, 0, 1)
		local yaw = math.atan2(-toward.X, -toward.Z)
		stations[setting.Kind] = shop(parent, setting.Kind, CFrame.new(setting.At) * CFrame.Angles(0, yaw, 0), setting.Tint, setting.Sub)
	end
	portal(parent)
	-- The planet shrine and quest captain are the unmistakable center of town.
	Decor.Disk(parent, "EventShrine", 20, 0.8, CFrame.new(0, ground + 1.05, 0), purple)
	Decor.Disk(parent, "ShrineStep", 16, 0.4, CFrame.new(0, ground + 1.65, 0), Color3.fromRGB(179, 170, 226))
	local planetModel = Instance.new("Model"); planetModel.Name = "OrbitingComet"; planetModel.Parent = parent
	local planet = Decor.Ball(planetModel, "QuestPlanet", Vector3.new(7, 7, 7), CFrame.new(0, ground + 7, 1), Color3.fromRGB(68, 173, 247))
	planet.Material = Enum.Material.Glass; planet.Transparency = 0.12
	planetModel.PrimaryPart = planet
	ring(planetModel, CFrame.new(0, ground + 7, 1) * CFrame.Angles(0.3, 0, 0.4), 5.3, cyan)
	floating(planetModel, 0.35, 0.8, 0.12)
	for i = 1, 4 do
		local angle = i * math.pi / 2
		Decor.Part(parent, "ShrinePillar", Vector3.new(1.2, 3, 1.2), CFrame.new(math.sin(angle) * 8, ground + 3, math.cos(angle) * 8), purple)
		local orb = Decor.Ball(parent, "ShrineLight", Vector3.new(1.8, 1.8, 1.8), CFrame.new(math.sin(angle) * 8, ground + 5, math.cos(angle) * 8), cyan)
		glow(orb, cyan, 13)
	end
	-- Small distant islands, plants, mushrooms, and crystals frame the village.
	for i = 1, 18 do
		local angle = i * math.pi * 2 / 18
		local at = CFrame.new(math.sin(angle) * 127, ground, math.cos(angle) * 127)
		Decor.Mushroom(parent, at, 2.1 + (i % 3) * 0.6, if i % 2 == 0 then pink else Color3.fromRGB(180, 149, 246))
		Decor.Crystal(parent, at * CFrame.new(5, 0, 3), 3 + i % 4, if i % 2 == 0 then cyan else pink)
		Decor.Plant(parent, at * CFrame.new(-5, 0, -2), 1.7, Color3.fromRGB(91, 186, 177))
		Decor.Ball(parent, "RimShrub", Vector3.new(5.5, 2.1, 4.2), at * CFrame.new(-4, 0.8, -4), Color3.fromRGB(72, 146, 174))
		Decor.Ball(parent, "RimShrub", Vector3.new(3.2, 1.4, 3), at * CFrame.new(-7, 0.65, -2), Color3.fromRGB(90, 178, 156))
		Decor.Plant(parent, at * CFrame.new(1.5, 0, -5), 0.85, Color3.fromRGB(125, 209, 176))
	end
	for i = 1, 8 do
		local angle = i * math.pi / 4
		local at = CFrame.new(math.sin(angle) * 194, 23 + (i % 3) * 10, math.cos(angle) * 194)
		Decor.Disk(parent, "DistantIsland", 24 + i % 3 * 5, 5, at, lavender)
		local rock = Decor.Part(parent, "DistantIslandRock", Vector3.new(20, 19, 20), at * CFrame.new(0, -10, 0) * CFrame.Angles(0.2, angle, 0.1), purple)
		rock.Material = Enum.Material.Slate
		Decor.Mushroom(parent, at * CFrame.new(0, 2.5, 0), 2.5, pink)
		ring(parent, at * CFrame.new(0, -7, 0), 18, cyan, 16)
	end
	return stations
end

function Decor.Farm(parent: Instance, at: CFrame)
	Decor.Part(parent, "GardenFoundation", Vector3.new(61, 1, 48), at * CFrame.new(0, -0.35, 0), Color3.fromRGB(108, 97, 159)).CanCollide = true
	local floor = Decor.Part(parent, "GardenFloor", Vector3.new(59, 0.4, 46), at * CFrame.new(0, 0.35, 0), Color3.fromRGB(130, 148, 190))
	floor.Material = Enum.Material.Grass; floor.CanCollide = true
	Decor.Part(parent, "CenterWalk", Vector3.new(3.4, 0.15, 41), at * CFrame.new(0, 0.63, 0), Color3.fromRGB(240, 205, 155)).CanCollide = true
	Decor.Part(parent, "GardenEntrance", Vector3.new(57, 0.15, 6), at * CFrame.new(0, 0.64, -18), Color3.fromRGB(231, 191, 145)).CanCollide = true
	for _, side in { -1, 1 } do
		local post = Decor.Part(parent, "GardenGatePost", Vector3.new(1.1, 7.4, 1.1), at * CFrame.new(side * 5.8, 4.3, -23), wood)
		post.Material = Enum.Material.Wood
		Decor.Part(parent, "GatePostBand", Vector3.new(1.3, 0.35, 1.3), at * CFrame.new(side * 5.8, 2.1, -23), cream)
		Decor.Plant(parent, at * CFrame.new(side * 6.8, 0.6, -21.7), 0.75, Color3.fromRGB(104, 191, 133))
	end
	Decor.Part(parent, "GateLintel", Vector3.new(12.8, 0.7, 1.5), at * CFrame.new(0, 8.1, -23), wood).Material = Enum.Material.Wood
	for _, side in { -1, 1 } do
		Decor.Ball(parent, "GateLeafCrest", Vector3.new(0.65, 1.55, 0.3), at * CFrame.new(side * 0.45, 9, -23.25) * CFrame.Angles(0, 0, -side * 0.6), Color3.fromRGB(104, 211, 140))
	end
	local crest = Decor.Ball(parent, "GateStar", Vector3.new(0.55, 0.55, 0.3), at * CFrame.new(0, 8.55, -23.4), cream)
	crest.Material = Enum.Material.Neon
	for _, x in { -29, 29 } do
		for _, z in { -23, -9, 7, 23 } do Decor.Lantern(parent, at * CFrame.new(x, 0.6, z)) end
		for y = 1.9, 3.1, 1.2 do Decor.Part(parent, "FenceRail", Vector3.new(0.4, 0.45, 46), at * CFrame.new(x, y, 0), wood) end
	end
	for _, z in { -23, 23 } do
		for _, x in { -21, -7, 7, 21 } do
			if z > 0 then Decor.Part(parent, "FencePost", Vector3.new(0.7, 3.2, 0.7), at * CFrame.new(x, 2.1, z), wood) end
		end
		for y = 1.9, 3.1, 1.2 do
			if z > 0 then Decor.Part(parent, "FenceRail", Vector3.new(58, 0.45, 0.4), at * CFrame.new(0, y, z), wood)
			else
				for _, side in { -1, 1 } do Decor.Part(parent, "EntranceRail", Vector3.new(23, 0.45, 0.4), at * CFrame.new(side * 17, y, z), wood) end
			end
		end
	end
	for _, side in { -1, 1 } do
		Decor.Plant(parent, at * CFrame.new(side * 27, 0.6, 19), 1.4, Color3.fromRGB(102, 202, 167))
		Decor.Crystal(parent, at * CFrame.new(side * 26, 0.6, -12), 2.4, if side < 0 then cyan else pink)
	end
end

function Decor.Lighting()
	local Lighting = game:GetService("Lighting")
	-- Warm late-afternoon highlights sit against cool blue shadows. A light
	-- haze keeps distant islands soft while preserving crisp crop and shop colors.
	Lighting.ClockTime = 16.2; Lighting.Brightness = 2.6
	Lighting.Ambient = Color3.fromRGB(85, 86, 139); Lighting.OutdoorAmbient = Color3.fromRGB(125, 142, 181)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 218, 167); Lighting.EnvironmentDiffuseScale = 0.8
	Lighting.EnvironmentSpecularScale = 0.95; Lighting.ExposureCompensation = -0.04
	Lighting.FogColor = Color3.fromRGB(147, 159, 213); Lighting.FogStart = 220; Lighting.FogEnd = 600
	local atmosphere = Lighting:FindFirstChild("GardenAtmosphere") or Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then atmosphere = Instance.new("Atmosphere"); atmosphere.Name = "GardenAtmosphere"; atmosphere.Parent = Lighting end
	if atmosphere:IsA("Atmosphere") then
		atmosphere.Density = 0.18; atmosphere.Offset = 0.05; atmosphere.Color = Color3.fromRGB(180, 186, 229)
		atmosphere.Decay = Color3.fromRGB(96, 115, 172); atmosphere.Glare = 0.12; atmosphere.Haze = 0.8
	end
	local bloom = Lighting:FindFirstChild("GardenBloom")
	if not bloom then bloom = Instance.new("BloomEffect"); bloom.Name = "GardenBloom"; bloom.Parent = Lighting end
	if bloom:IsA("BloomEffect") then bloom.Intensity = 0.16; bloom.Size = 20; bloom.Threshold = 1.6 end
	local grade = Lighting:FindFirstChild("GardenColorGrade")
	if not grade then grade = Instance.new("ColorCorrectionEffect"); grade.Name = "GardenColorGrade"; grade.Parent = Lighting end
	if grade:IsA("ColorCorrectionEffect") then
		grade.Contrast = 0.1; grade.Saturation = 0.13; grade.Brightness = 0; grade.TintColor = Color3.fromRGB(255, 249, 241)
	end
end

return Decor
