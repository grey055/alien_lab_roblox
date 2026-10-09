--!strict
-- Small reusable decorations built from Roblox parts. No downloaded models required.
local Decor = {}
local mint = Color3.fromRGB(107, 246, 174)
local navy = Color3.fromRGB(37, 61, 79)

local function block(parent: Instance, name: string, size: Vector3, at: Vector3, color: Color3, ball: boolean?): Part
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.Position = at; p.Color = color
	p.Anchored = true; p.Material = Enum.Material.SmoothPlastic
	p.Shape = if ball then Enum.PartType.Ball else Enum.PartType.Block
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function tree(parent: Instance, at: Vector3, tint: Color3)
	block(parent, "TreeTrunk", Vector3.new(1.4, 7, 1.4), at + Vector3.new(0, 3.5, 0), Color3.fromRGB(142, 104, 83))
	block(parent, "TreeCanopy", Vector3.new(8, 8, 8), at + Vector3.new(0, 9, 0), tint, true)
	block(parent, "TreeCanopy", Vector3.new(5, 5, 5), at + Vector3.new(3, 7.5, 0), tint:Lerp(mint, 0.2), true)
end

function Decor.Hub(parent: Instance)
	local island = block(parent, "GardenIsland", Vector3.new(280, 2, 210), Vector3.new(0, -1, 38), Color3.fromRGB(92, 163, 119))
	island.Material = Enum.Material.Grass
	block(parent, "MainWalkway", Vector3.new(274, 0.12, 12), Vector3.new(0, 0.08, -36), Color3.fromRGB(207, 226, 218))
	for x = -120, 120, 24 do
		local lamp = block(parent, "PathLight", Vector3.new(1, 4, 1), Vector3.new(x, 2, -44), navy)
		local head = block(parent, "LampGlow", Vector3.new(2, 1, 2), lamp.Position + Vector3.new(0, 2.5, 0), mint)
		head.Material = Enum.Material.Neon
		local light = Instance.new("PointLight"); light.Color = mint; light.Brightness = 0.5; light.Range = 12; light.Parent = head
	end
	for _, x in { -128, 128 } do
		for _, z in { -14, 35, 95 } do tree(parent, Vector3.new(x, 0, z), Color3.fromRGB(69, 173, 130)) end
	end
	local pedestal = block(parent, "WelcomeStand", Vector3.new(12, 2, 12), Vector3.new(0, 1, -57), navy)
	local mascot = block(parent, "WelcomeSlime", Vector3.new(8, 6, 7), pedestal.Position + Vector3.new(0, 4, 0), mint, true)
	for _, side in { -1, 1 } do
		block(parent, "MascotEye", Vector3.new(0.8, 1, 0.3), mascot.Position + Vector3.new(side * 1.4, 0.4, -3.3), navy, true)
	end
	local gui = Instance.new("BillboardGui"); gui.Size = UDim2.fromOffset(340, 70); gui.StudsOffset = Vector3.new(0, 6, 0); gui.MaxDistance = 160; gui.Parent = mascot
	local title = Instance.new("TextLabel"); title.Size = UDim2.fromScale(1, 1); title.BackgroundTransparency = 1
	title.Text = "ALIEN LAB\nHATCH  /  GROW  /  DISCOVER"; title.Font = Enum.Font.GothamBlack; title.TextSize = 28
	title.TextColor3 = Color3.new(1, 1, 1); title.TextStrokeTransparency = 0.5; title.Parent = gui
end

function Decor.Farm(parent: Instance, center: Vector3): Part
	local function p(name: string, size: Vector3, offset: Vector3, tint: Color3, ball: boolean?): Part
		return block(parent, name, size, center + offset, tint, ball)
	end
	for _, x in { -31, 31 } do
		local trim = p("DeckNeon", Vector3.new(0.3, 0.15, 56), Vector3.new(x, 1.04, 0), mint)
		trim.Material = Enum.Material.Neon; trim.CanCollide = false
	end
	-- The arch frames the entrance without blocking it.
	for _, side in { -1, 1 } do
		p("GateColumn", Vector3.new(1.2, 8, 1.2), Vector3.new(side * 5, 5, -11), navy)
		local light = p("GateStrip", Vector3.new(0.2, 5, 0.25), Vector3.new(side * 5, 5, -11.7), mint)
		light.Material = Enum.Material.Neon
		tree(parent, center + Vector3.new(side * 29, 1, 18), Color3.fromRGB(126, 204, 156))
		for z = -2, 14, 8 do
			local stem = p("MushroomStem", Vector3.new(0.4, 0.6, 0.4), Vector3.new(side * 22, 1.55, z), Color3.fromRGB(238, 236, 200))
			local cap = p("MushroomCap", Vector3.new(1.4, 0.65, 1.4), stem.Position - center + Vector3.new(0, 0.5, 0), Color3.fromRGB(180, 152, 253), true)
			cap.CanCollide = false
		end
	end
	p("GateBeam", Vector3.new(11, 1, 1.3), Vector3.new(0, 9.3, -11), navy)
	for z = -24, -14, 3 do
		p("PathTile", Vector3.new(6.5, 0.08, 1.7), Vector3.new(0, 1.12, z), Color3.fromRGB(232, 241, 218))
	end
	-- A mini research reactor becomes brighter at each purchased lab level.
	p("ReactorBase", Vector3.new(7, 0.8, 5), Vector3.new(0, 1.4, 27), navy)
	local reactor = p("ResearchReactor", Vector3.new(3, 3, 3), Vector3.new(0, 3.3, 27), mint, true)
	reactor.Material = Enum.Material.Neon
	local light = Instance.new("PointLight"); light.Name = "ReactorLight"; light.Color = mint; light.Brightness = 0.4; light.Range = 10; light.Parent = reactor
	for _, side in { -1, 1 } do
		p("ReactorFin", Vector3.new(0.45, 3.5, 3), Vector3.new(side * 2.5, 3, 27), Color3.fromRGB(185, 216, 231))
	end
	return reactor
end

return Decor
