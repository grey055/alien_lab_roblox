--!strict
-- Cosmetic wandering runs on each client. Production and ownership still
-- come from the server, so moving these anchored pets never grants currency.
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local PetController = {}

function PetController.Start()
	local pets: { [Model]: { Home: Vector3, Seed: number } } = {}
	local function add(item: Instance)
		if not item:IsA("Model") then return end
		local home = item:GetAttribute("RoamHome")
		local seed = item:GetAttribute("RoamSeed")
		if typeof(home) == "Vector3" and typeof(seed) == "number" then
			pets[item] = { Home = home, Seed = seed }
		end
	end
	for _, item in CollectionService:GetTagged("AlienLabPet") do add(item) end
	CollectionService:GetInstanceAddedSignal("AlienLabPet"):Connect(add)
	CollectionService:GetInstanceRemovedSignal("AlienLabPet"):Connect(function(item: Instance)
		if item:IsA("Model") then pets[item] = nil end
	end)

	local elapsed = 0
	RunService.RenderStepped:Connect(function(delta: number)
		elapsed += delta
		if elapsed < 1 / 30 then return end -- Smooth movement with a modest update rate.
		elapsed = 0
		local camera = Workspace.CurrentCamera
		if not camera then return end
		local time = Workspace:GetServerTimeNow()
		for model, pet in pets do
			-- Skip distant farms. Every path stays safely inside its own garden.
			if model.Parent and (camera.CFrame.Position - pet.Home).Magnitude < 160 then
				local phase = time * 0.32 + pet.Seed
				local x = math.sin(phase) * 18
				local z = math.sin(phase * 0.73 + pet.Seed) * 10
				local bounce = math.abs(math.sin(time * 2.8 + pet.Seed)) * 0.24
				local position = pet.Home + Vector3.new(x, bounce, z)
				local direction = Vector3.new(math.cos(phase) * 18, 0, math.cos(phase * 0.73 + pet.Seed) * 7.3)
				if direction.Magnitude < 0.01 then direction = Vector3.new(0, 0, -1) end
				-- A slight wobble makes each hop feel soft, with a separate rhythm per pet.
				local wobble = math.sin(time * 2.8 + pet.Seed) * 0.06
				model:PivotTo(CFrame.lookAt(position, position + direction) * CFrame.Angles(0, 0, wobble))
			end
		end
	end)
end

return PetController
