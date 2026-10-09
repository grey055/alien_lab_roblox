--!strict
-- Small client-only touches: floating shop displays, portal motes, and garden
-- feedback. These effects never change crops, inventory, rewards, or cash.
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FarmData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("FarmData"))
local Effects = {}

local DISTANCE = 180
local MAX_FLOATS = 50
local MAX_TRACKED = 150
local MAX_PORTALS = 6
local MAX_FEEDBACK = 12
local MOTE_COUNT = 7
local random = Random.new()
local started = false
local localFolder: Folder? = nil
local connections: { RBXScriptConnection } = {}
local entries: { [Instance]: any } = {}
local trackedCount = 0
local bursts: { any } = {}
local elapsed = 0
local frameTime = 0

local colors = {
	Plant = Color3.fromRGB(150, 230, 131),
	Water = Color3.fromRGB(135, 224, 250),
	Harvest = Color3.fromRGB(255, 217, 136),
	Quest = Color3.fromRGB(182, 171, 255),
}

local function finite(value: any): boolean
	return typeof(value) == "number" and value == value and math.abs(value) < math.huge
end

local function position(value: any): boolean
	return typeof(value) == "Vector3" and finite(value.X) and finite(value.Y) and finite(value.Z)
		and math.abs(value.X) <= 100000 and math.abs(value.Y) <= 100000 and math.abs(value.Z) <= 100000
end

local function attribute(item: Instance, name: string, fallback: number, minimum: number, maximum: number): number
	local value = item:GetAttribute(name)
	return if finite(value) then math.clamp(value, minimum, maximum) else fallback
end

local function getPivot(item: Instance): CFrame?
	if item:IsA("Model") then return item:GetPivot() end
	if item:IsA("BasePart") then return item.CFrame end
	return nil
end

local function pivot(item: Instance, at: CFrame)
	if item:IsA("Model") then item:PivotTo(at)
	elseif item:IsA("BasePart") then item.CFrame = at end
end

local function folder(): Folder
	if not localFolder or not localFolder.Parent then
		local item = Instance.new("Folder")
		item.Name = "AlienLabLocalEffects"; item.Parent = Workspace; localFolder = item
	end
	return localFolder :: Folder
end

local function mote(parent: Instance, size: Vector3, tint: Color3): Part
	local p = Instance.new("Part")
	p.Name = "LightMote"; p.Size = size; p.Shape = Enum.PartType.Block
	p.Color = tint; p.Material = Enum.Material.Neon; p.Anchored = true
	p.CanCollide = false; p.CanTouch = false; p.CanQuery = false; p.CastShadow = false
	-- A sphere mesh keeps stretched water drops tall; native ball parts use
	-- the shortest size axis, which would flatten these little silhouettes.
	local mesh = Instance.new("SpecialMesh"); mesh.MeshType = Enum.MeshType.Sphere; mesh.Parent = p
	p.Parent = parent
	return p
end

local function clearMotes(entry: any)
	if entry.MoteFolder then entry.MoteFolder:Destroy(); entry.MoteFolder = nil end
	entry.Motes = nil
end

local function forget(item: Instance, restore: boolean?)
	local entry = entries[item]
	if not entry then return end
	clearMotes(entry)
	if restore and entry.Float and item:IsDescendantOf(Workspace) then pivot(item, entry.Base) end
	entries[item] = nil; trackedCount -= 1
end

local function track(item: Instance)
	local at = getPivot(item)
	if not at then return end
	local entry = entries[item]
	if not entry then
		if trackedCount >= MAX_TRACKED then return end
		entry = { Base = at, Seed = at.Position.X * 0.019 + at.Position.Z * 0.031 }
		entries[item] = entry; trackedCount += 1
	end
	entry.Float = CollectionService:HasTag(item, "CosmicFloat")
	entry.Portal = item:IsA("Model") and CollectionService:HasTag(item, "CosmicPortal")
	entry.Amplitude = attribute(item, "FloatAmplitude", 0.4, 0, 2)
	entry.Speed = attribute(item, "FloatSpeed", 1, 0.1, 3)
	entry.Spin = attribute(item, "FloatSpin", 0.1, -0.5, 0.5)
	if not entry.Float and not entry.Portal then forget(item, true) end
end

local function untag(item: Instance)
	local entry = entries[item]
	if not entry then return end
	local floated = entry.Float
	entry.Float = CollectionService:HasTag(item, "CosmicFloat")
	entry.Portal = item:IsA("Model") and CollectionService:HasTag(item, "CosmicPortal")
	if floated and not entry.Float and item:IsDescendantOf(Workspace) then pivot(item, entry.Base) end
	if not entry.Portal then clearMotes(entry) end
	if not entry.Float and not entry.Portal then forget(item) end
end

local function portalMotes(item: Model, entry: any)
	if entry.MoteFolder and entry.MoteFolder.Parent then return end
	local container = Instance.new("Folder"); container.Name = "PortalMotes"; container.Parent = folder()
	entry.MoteFolder = container; entry.Motes = {}
	local box, size = item:GetBoundingBox()
	entry.PortalOffset = entry.Base:ToObjectSpace(box)
	entry.PortalRadius = math.clamp(math.min(size.X, size.Y) * 0.32, 3, 8)
	for i = 1, MOTE_COUNT do
		local p = mote(container, Vector3.new(0.16, 0.16, 0.16), if i % 2 == 0 then colors.Water else colors.Quest)
		p.Transparency = 0.15; table.insert(entry.Motes, p)
	end
end

local function disposeBurst(index: number)
	local burst = bursts[index]
	if burst then burst.Folder:Destroy(); table.remove(bursts, index) end
end

local function render(delta: number)
	-- A single connection drives all effects. Thirty updates per second are
	-- enough for this gentle scenery, with fixed caps for busy multiplayer hubs.
	frameTime += math.clamp(delta, 0, 0.2)
	if frameTime < 1 / 30 then return end
	local step = frameTime; frameTime = 0; elapsed += step
	local camera = Workspace.CurrentCamera
	local cameraAt = if camera then camera.CFrame.Position else nil
	local floatCount, portalCount = 0, 0
	for item, entry in entries do
		if not item:IsDescendantOf(Workspace) then forget(item)
		elseif cameraAt and (entry.Base.Position - cameraAt).Magnitude <= DISTANCE then
			if entry.Float and floatCount < MAX_FLOATS then
				floatCount += 1
				local bob = math.sin(elapsed * entry.Speed + entry.Seed) * entry.Amplitude
				pivot(item, entry.Base * CFrame.new(0, bob, 0) * CFrame.Angles(0, elapsed * entry.Spin, 0))
			end
			if entry.Portal and portalCount < MAX_PORTALS then
				portalCount += 1; portalMotes(item :: Model, entry)
				local center = (getPivot(item) :: CFrame) * entry.PortalOffset
				for i, p in entry.Motes do
					local angle = elapsed * 0.3 + i * math.pi * 2 / MOTE_COUNT
					local radius = entry.PortalRadius + math.sin(elapsed + i) * 0.16
					p.CFrame = center * CFrame.new(math.cos(angle) * radius, math.sin(angle) * radius, -0.1)
					p.Transparency = 0.25 + (math.sin(elapsed * 1.3 + i) + 1) * 0.2
				end
			elseif entry.Motes then clearMotes(entry) end
		elseif entry.Motes then clearMotes(entry) end
	end
	for index = #bursts, 1, -1 do
		local burst = bursts[index]; burst.Age += step
		if burst.Age >= burst.Duration or not burst.Folder.Parent then disposeBurst(index)
		else
			local age = burst.Age; local fade = math.clamp((age - 0.2) / (burst.Duration - 0.2), 0, 1)
			for _, fragment in burst.Parts do
				local at = burst.Position + fragment.Offset + fragment.Velocity * age + Vector3.new(0, -2.5 * age * age, 0)
				fragment.Part.CFrame = CFrame.new(at) * CFrame.Angles(age * fragment.Spin, 0, age * fragment.Spin)
				fragment.Part.Transparency = fade
			end
			burst.Anchor.Position = burst.Position + Vector3.new(0, 1.2 + age * 1.4, 0)
			burst.Text.TextTransparency = fade; burst.Text.TextStrokeTransparency = 0.65 + fade * 0.35
		end
	end
end

function Effects.Start()
	if started then return end
	started = true
	for _, tag in { "CosmicFloat", "CosmicPortal" } do
		for _, item in CollectionService:GetTagged(tag) do track(item) end
		table.insert(connections, CollectionService:GetInstanceAddedSignal(tag):Connect(track))
		table.insert(connections, CollectionService:GetInstanceRemovedSignal(tag):Connect(untag))
	end
	table.insert(connections, RunService.RenderStepped:Connect(render))
	table.insert(connections, script.Destroying:Connect(function()
		for _, connection in connections do connection:Disconnect() end
		table.clear(connections)
		for item in entries do forget(item, true) end
		for index = #bursts, 1, -1 do disposeBurst(index) end
		if localFolder then localFolder:Destroy(); localFolder = nil end
		started = false
	end))
end

function Effects.Feedback(payload: any): boolean
	if typeof(payload) ~= "table" or typeof(payload.Kind) ~= "string" or not colors[payload.Kind] or not position(payload.Position) then return false end
	local camera = Workspace.CurrentCamera
	if not camera or (camera.CFrame.Position - payload.Position).Magnitude > DISTANCE then return false end
	if not started then Effects.Start() end
	local kind = payload.Kind
	local crop = if typeof(payload.CropId) == "string" then FarmData.Crops[payload.CropId] else nil
	local tint = colors[kind]
	if payload.Mutation == "Golden" then tint = colors.Harvest
	elseif payload.Mutation == "Cosmic" then tint = colors.Quest end
	local caption = ({ Plant = "Planted!", Water = "Watered!", Harvest = "Harvest picked!", Quest = "Comet reward claimed!" })[kind]
	if crop and kind == "Plant" then caption = crop.DisplayName .. " planted!"
	elseif crop and kind == "Harvest" then caption = crop.DisplayName .. " picked!" end
	if finite(payload.Value) and payload.Value > 0 then
		local value = math.min(1e9, math.floor(payload.Value))
		if kind == "Harvest" then caption = "Basket +$" .. value
		elseif kind == "Quest" then caption = "Comet reward +$" .. value end
	end
	while #bursts >= MAX_FEEDBACK do disposeBurst(1) end
	local container = Instance.new("Folder"); container.Name = "GardenFeedback"; container.Parent = folder()
	local anchor = mote(container, Vector3.new(0.1, 0.1, 0.1), tint)
	anchor.Name = "CaptionAnchor"; anchor.Transparency = 1; anchor.Position = payload.Position
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FeedbackCaption"; billboard.Adornee = anchor; billboard.Size = UDim2.fromOffset(230, 32)
	billboard.AlwaysOnTop = true; billboard.MaxDistance = 90; billboard.Parent = anchor
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1); text.BackgroundTransparency = 1; text.Font = Enum.Font.GothamBold
	text.TextSize = 15; text.Text = caption; text.TextColor3 = tint; text.TextStrokeColor3 = Color3.fromRGB(62, 47, 95)
	text.TextStrokeTransparency = 0.65; text.Parent = billboard
	local burst = { Folder = container, Position = payload.Position, Anchor = anchor, Text = text,
		Age = 0, Duration = if kind == "Quest" then 1.65 else 1.25, Parts = {} }
	for i = 1, if kind == "Quest" then 10 else 7 do
		local angle = i * math.pi * 2 / 7
		local size = if kind == "Water" then Vector3.new(0.12, 0.3, 0.12) else Vector3.new(0.16, 0.24, 0.16)
		local p = mote(container, size, tint)
		local offset = Vector3.new(math.cos(angle) * 0.25, 0.3, math.sin(angle) * 0.25)
		p.Position = payload.Position + offset
		table.insert(burst.Parts, { Part = p, Offset = offset,
			Velocity = Vector3.new(math.cos(angle) * random:NextNumber(0.7, 1.8), random:NextNumber(2, 3.5), math.sin(angle) * random:NextNumber(0.7, 1.8)),
			Spin = random:NextNumber(-2, 2) })
	end
	table.insert(bursts, burst)
	Debris:AddItem(container, burst.Duration + 1)
	return true
end

return Effects
