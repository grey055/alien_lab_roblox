--!strict
-- Walking and blinking are visual only. The server owns each companion and
-- applies its farming passive; moving a model never gives the client money.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PetController = {}
local started = false

type Limb = { Model: Model, Rest: CFrame, Side: number, IsArm: boolean }
type Pet = {
	Home: Vector3,
	Seed: number,
	Extent: Vector3,
	Yaw: number,
	Limbs: { Limb },
	BlinkParts: { BasePart },
	Blinking: boolean,
}

function PetController.Start()
	if started then return end
	started = true
	local pets: { [Model]: Pet } = {}
	local function add(item: Instance)
		if not item:IsA("Model") then return end
		local home = item:GetAttribute("RoamHome")
		local seed = item:GetAttribute("RoamSeed")
		if typeof(home) ~= "Vector3" or typeof(seed) ~= "number" then return end
		local extent = item:GetAttribute("RoamExtent")
		local yaw = item:GetAttribute("RoamYaw")
		local radius = if typeof(extent) == "Vector3" then extent else Vector3.new(18, 0, 10)
		local limbs: { Limb } = {}
		local blinkParts: { BasePart } = {}
		local origin = item:GetPivot()
		for _, child in item:GetChildren() do
			if child:IsA("Model") and (child.Name == "LeftArm" or child.Name == "RightArm" or child.Name == "LeftLeg" or child.Name == "RightLeg") then
				table.insert(limbs, {
					Model = child,
					Rest = origin:ToObjectSpace(child:GetPivot()),
					Side = if string.sub(child.Name, 1, 4) == "Left" then -1 else 1,
					IsArm = string.find(child.Name, "Arm") ~= nil,
				})
			elseif child:IsA("BasePart") and (string.sub(child.Name, 1, 6) == "Eyelid" or string.sub(child.Name, 1, 5) == "Blink") then
				table.insert(blinkParts, child)
			end
		end
		pets[item] = {
			Home = home, Seed = seed,
			Extent = Vector3.new(math.clamp(math.abs(radius.X), 0, 50), 0, math.clamp(math.abs(radius.Z), 0, 50)),
			Yaw = if typeof(yaw) == "number" then yaw else 0,
			Limbs = limbs, BlinkParts = blinkParts, Blinking = false,
		}
	end
	for _, item in CollectionService:GetTagged("AlienLabPet") do add(item) end
	CollectionService:GetInstanceAddedSignal("AlienLabPet"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("AlienLabPet"):Connect(function(item: Instance)
		if item:IsA("Model") then pets[item] = nil end
	end)

	local elapsed = 0
	RunService.RenderStepped:Connect(function(delta: number)
		elapsed += delta
		if elapsed < 1 / 30 then return end
		elapsed = 0
		local camera = Workspace.CurrentCamera
		if not camera then return end
		local time = Workspace:GetServerTimeNow()
		for model, pet in pets do
			if not model.Parent then
				pets[model] = nil
			elseif (camera.CFrame.Position - pet.Home).Magnitude < 180 then
				-- RoamHome and RoamExtent keep pets on their own garden walkway.
				-- RoamYaw turns that walkway with farms facing the central plaza.
				local phase = time * 0.19 + pet.Seed
				local localOffset = Vector3.new(math.sin(phase) * pet.Extent.X, 0, math.sin(phase * 0.73 + pet.Seed) * pet.Extent.Z)
				local localDirection = Vector3.new(math.cos(phase) * pet.Extent.X, 0, math.cos(phase * 0.73 + pet.Seed) * pet.Extent.Z * 0.73)
				local gardenRotation = CFrame.Angles(0, pet.Yaw, 0)
				local walk = math.sin(time * 5.4 + pet.Seed)
				local bounce = 0.09 + math.abs(walk) * 0.10
				local position = pet.Home + gardenRotation:VectorToWorldSpace(localOffset) + Vector3.new(0, bounce, 0)
				local direction = gardenRotation:VectorToWorldSpace(localDirection)
				if direction.Magnitude < 0.01 then direction = gardenRotation.LookVector end
				local pose = CFrame.lookAt(position, position + direction) * CFrame.Angles(0, 0, walk * 0.025)
				model:PivotTo(pose)
				for _, limb in pet.Limbs do
					-- Opposite feet and hands swing together around their own pivots.
					local swing = walk * limb.Side * (if limb.IsArm then -0.18 else 0.21)
					limb.Model:PivotTo(pose * limb.Rest * CFrame.Angles(swing, 0, 0))
				end
				local blinking = (time + pet.Seed * 1.41) % 4.6 < 0.13
				if blinking ~= pet.Blinking then
					pet.Blinking = blinking
					for _, lid in pet.BlinkParts do lid.Transparency = if blinking then 0 else 1 end
				end
			end
		end
	end)
end

return PetController
