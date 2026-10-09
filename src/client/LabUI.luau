--!strict
-- Native Roblox UI: reusable cards, 3D previews, responsive menus, and hatch celebrations.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local shared = ReplicatedStorage:WaitForChild("Shared")
local AlienData = require(shared:WaitForChild("AlienData"))
local SlimeModel = require(shared:WaitForChild("SlimeModel"))
local UI = {}
local mint = Color3.fromRGB(130, 248, 177)
local ink = Color3.fromRGB(18, 31, 44)
local cardColor = Color3.fromRGB(32, 51, 64)
local white = Color3.fromRGB(235, 249, 244)
local muted = Color3.fromRGB(156, 182, 193)

local function corners(parent: Instance, radius: number)
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, radius); corner.Parent = parent
end

local function outline(parent: Instance, tint: Color3)
	local stroke = Instance.new("UIStroke"); stroke.Color = tint; stroke.Transparency = 0.65; stroke.Parent = parent
end

local function frame(parent: Instance, name: string, at: UDim2, size: UDim2, tint: Color3): Frame
	local f = Instance.new("Frame"); f.Name = name; f.Position = at; f.Size = size; f.BackgroundColor3 = tint
	f.BorderSizePixel = 0; f.Parent = parent; corners(f, 16)
	return f
end

local function label(parent: Instance, name: string, content: string, at: UDim2, size: UDim2, fontSize: number, tint: Color3): TextLabel
	local t = Instance.new("TextLabel"); t.Name = name; t.Text = content; t.Position = at; t.Size = size
	t.BackgroundTransparency = 1; t.TextColor3 = tint; t.Font = Enum.Font.GothamMedium; t.TextSize = fontSize
	t.TextXAlignment = Enum.TextXAlignment.Left; t.TextWrapped = true; t.Parent = parent
	return t
end

local function button(parent: Instance, name: string, caption: string, at: UDim2, size: UDim2, tint: Color3?): TextButton
	local b = Instance.new("TextButton"); b.Name = name; b.Text = caption; b.Position = at; b.Size = size
	b.BackgroundColor3 = tint or mint; b.TextColor3 = ink; b.Font = Enum.Font.GothamBold
	b.TextSize = 14; b.TextWrapped = true; b.BorderSizePixel = 0; b.AutoButtonColor = true; b.Parent = parent; corners(b, 12)
	local scale = Instance.new("UIScale"); scale.Parent = b
	b.MouseEnter:Connect(function() TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1.025 }):Play() end)
	b.MouseLeave:Connect(function() TweenService:Create(scale, TweenInfo.new(0.12), { Scale = 1 }):Play() end)
	return b
end

local function preview(parent: Instance, id: string, at: UDim2, size: UDim2, eggTint: Color3?): ViewportFrame
	local v = Instance.new("ViewportFrame"); v.Name = "Preview"; v.Position = at; v.Size = size
	v.BackgroundTransparency = 1; v.Ambient = Color3.fromRGB(207, 234, 255); v.LightColor = Color3.new(1, 1, 1)
	v.LightDirection = Vector3.new(-1, -1, -2); v.Parent = parent
	local world = Instance.new("WorldModel"); world.Parent = v
	if eggTint then
		local egg = Instance.new("Part"); egg.Shape = Enum.PartType.Ball; egg.Size = Vector3.new(2.6, 3.4, 2.6)
		egg.Position = Vector3.new(0, 1.7, 0); egg.Anchored = true; egg.Color = eggTint; egg.Material = Enum.Material.SmoothPlastic; egg.Parent = world
		for _, side in { -1, 1 } do
			local spot = Instance.new("Part"); spot.Shape = Enum.PartType.Ball; spot.Size = Vector3.new(0.7, 0.9, 0.15)
			spot.Position = Vector3.new(side * 0.55, 1.5, -1.24); spot.Color = eggTint:Lerp(Color3.new(1, 1, 1), 0.6)
			spot.Anchored = true; spot.CanCollide = false; spot.Parent = world
		end
	else SlimeModel.Create(id).Parent = world end
	local camera = Instance.new("Camera"); camera.FieldOfView = 35
	camera.CFrame = CFrame.lookAt(Vector3.new(0.5, 2.6, -9), Vector3.new(0, 1.6, 0)); camera.Parent = v; v.CurrentCamera = camera
	return v
end

function UI.Number(n: number): string
	if n >= 1e9 then return string.format("%.1fB", n / 1e9) end
	if n >= 1e6 then return string.format("%.1fM", n / 1e6) end
	if n >= 10000 then return string.format("%.1fK", n / 1000) end
	return tostring(math.floor(n))
end

function UI.SetButtonEnabled(b: TextButton, enabled: boolean)
	b.Active = enabled; b.AutoButtonColor = enabled
	b.BackgroundColor3 = if enabled then mint else Color3.fromRGB(54, 69, 80)
	b.TextColor3 = if enabled then ink else muted
end

function UI.Create(playerGui: PlayerGui)
	local gui = Instance.new("ScreenGui"); gui.Name = "AlienLabUI"; gui.ResetOnSpawn = false; gui.DisplayOrder = 10
	local hud = frame(gui, "Panel", UDim2.fromOffset(14, 12), UDim2.new(1, -28, 0, 224), ink)
	outline(hud, mint); hud.BackgroundTransparency = 0.06
	local limit = Instance.new("UISizeConstraint"); limit.MaxSize = Vector2.new(280, 224); limit.Parent = hud
	local title = label(hud, "Title", "ALIEN LAB", UDim2.fromOffset(16, 10), UDim2.new(1, -32, 0, 24), 18, white); title.Font = Enum.Font.GothamBlack
	local level = label(hud, "Level", "LAB 0  /  SLIME GARDEN", UDim2.fromOffset(16, 34), UDim2.new(1, -32, 0, 18), 10, muted)
	local cashCard = frame(hud, "CashCard", UDim2.fromOffset(10, 59), UDim2.new(1, -20, 0, 53), Color3.fromRGB(29, 66, 57))
	local coin = frame(cashCard, "CashIcon", UDim2.fromOffset(10, 9), UDim2.fromOffset(35, 35), mint)
	local dollar = label(coin, "Dollar", "$", UDim2.new(), UDim2.fromScale(1, 1), 24, ink); dollar.TextXAlignment = Enum.TextXAlignment.Center
	label(cashCard, "Caption", "CASH", UDim2.fromOffset(57, 4), UDim2.new(1, -65, 0, 16), 9, muted)
	local cash = label(cashCard, "Cash", "Loading...", UDim2.fromOffset(57, 20), UDim2.new(1, -65, 0, 27), 24, mint)
	cash.Font = Enum.Font.GothamBold
	local slimeCard = frame(hud, "SlimeCard", UDim2.fromOffset(10, 119), UDim2.new(1, -20, 0, 69), cardColor)
	preview(slimeCard, "Slimelet", UDim2.fromOffset(1, 0), UDim2.fromOffset(60, 64))
	label(slimeCard, "Caption", "SLIME", UDim2.fromOffset(64, 3), UDim2.new(1, -70, 0, 16), 9, muted)
	local slime = label(slimeCard, "Slime", "Loading...", UDim2.fromOffset(64, 18), UDim2.new(1, -70, 0, 27), 24, white)
	slime.Font = Enum.Font.GothamBold
	local production = label(slimeCard, "Production", "+0 slime / sec", UDim2.fromOffset(64, 46), UDim2.new(1, -70, 0, 19), 11, mint)
	local aliens = label(hud, "Aliens", "Garden loading...", UDim2.fromOffset(15, 194), UDim2.new(0.59, 0, 0, 18), 10, muted)
	local save = label(hud, "Saving", "Connecting...", UDim2.new(0.59, 0, 0, 194), UDim2.new(0.41, -12, 0, 18), 9, mint)
	save.TextXAlignment = Enum.TextXAlignment.Right

	local dock = frame(gui, "Dock", UDim2.new(0.5, 0, 1, -14), UDim2.new(1, -24, 0, 64), ink); dock.AnchorPoint = Vector2.new(0.5, 1)
	local dockLimit = Instance.new("UISizeConstraint"); dockLimit.MaxSize = Vector2.new(620, 64); dockLimit.Parent = dock; outline(dock, mint)
	local shop = button(dock, "EggShop", "EGGS", UDim2.fromOffset(8, 8), UDim2.new(0.25, -10, 0, 48))
	local collection = button(dock, "Collection", "SLIMES", UDim2.new(0.25, 2, 0, 8), UDim2.new(0.25, -10, 0, 48), Color3.fromRGB(143, 207, 255))
	local lab = button(dock, "Lab", "UPGRADE", UDim2.new(0.5, 2, 0, 8), UDim2.new(0.25, -10, 0, 48), Color3.fromRGB(198, 166, 255))
	local sell = button(dock, "Sell", "SELL SLIME", UDim2.new(0.75, 2, 0, 8), UDim2.new(0.25, -10, 0, 48))
	local status = label(gui, "Status", "Your free slime is already growing! Hatch, sell, and upgrade your lab.", UDim2.new(0.5, 0, 1, -94), UDim2.new(1, -28, 0, 28), 13, white)
	status.AnchorPoint = Vector2.new(0.5, 1); status.TextXAlignment = Enum.TextXAlignment.Center; status.TextStrokeTransparency = 0.65

	-- The menu has its own scrolling area so cards stay usable on smaller screens.
	local shade = frame(gui, "MenuShade", UDim2.new(), UDim2.fromScale(1, 1), Color3.new(0, 0, 0)); shade.BackgroundTransparency = 0.4; shade.Visible = false; shade.Active = true
	local modal = frame(shade, "Menu", UDim2.fromScale(0.5, 0.46), UDim2.fromScale(0.9, 0.78), ink); modal.AnchorPoint = Vector2.new(0.5, 0.5); outline(modal, mint)
	local sizeLimit = Instance.new("UISizeConstraint"); sizeLimit.MaxSize = Vector2.new(700, 470); sizeLimit.Parent = modal
	local menuTitle = label(modal, "Heading", "EGG SHOP", UDim2.fromOffset(20, 14), UDim2.new(1, -86, 0, 30), 23, white); menuTitle.Font = Enum.Font.GothamBlack
	local close = button(modal, "Close", "X", UDim2.new(1, -48, 0, 12), UDim2.fromOffset(34, 34))
	local pages = {}
	for _, name in { "Eggs", "Collection", "Lab" } do
		local scroll = Instance.new("ScrollingFrame"); scroll.Name = name; scroll.Position = UDim2.fromOffset(16, 58)
		scroll.Size = UDim2.new(1, -32, 1, -74); scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(); scroll.ScrollBarThickness = 4
		scroll.ScrollBarImageColor3 = mint; scroll.Visible = false; scroll.Parent = modal; pages[name] = scroll
	end
	local function open(name: string)
		shade.Visible = true; menuTitle.Text = ({ Eggs = "EGG SHOP", Collection = "SLIME COLLECTION", Lab = "RESEARCH LAB" })[name]
		for key, page in pages do page.Visible = key == name end
	end
	shop.Activated:Connect(function() open("Eggs") end)
	collection.Activated:Connect(function() open("Collection") end)
	lab.Activated:Connect(function() open("Lab") end)
	close.Activated:Connect(function() shade.Visible = false end)
	local eggCards = {}
	for i, id in AlienData.EggOrder do
		local egg = AlienData.Eggs[id]; local tint = Color3.fromRGB(unpack(egg.Color))
		local card = frame(pages.Eggs, id, UDim2.fromOffset(0, (i - 1) * 151), UDim2.new(1, -6, 0, 141), cardColor); outline(card, tint)
		preview(card, "Slimelet", UDim2.fromOffset(3, 7), UDim2.fromOffset(80, 96), tint)
		label(card, "Name", egg.DisplayName, UDim2.fromOffset(90, 8), UDim2.new(1, -100, 0, 26), 18, tint)
		local odds = {}; for _, entry in egg.Pool do table.insert(odds, string.format("%s %d%%", AlienData.Aliens[entry.AlienId].DisplayName, entry.Weight)) end
		local oddsLabel = label(card, "Odds", table.concat(odds, "  /  "), UDim2.fromOffset(90, 35), UDim2.new(1, -100, 0, 54), 11, muted)
		oddsLabel.TextScaled = true
		local oddsSize = Instance.new("UITextSizeConstraint"); oddsSize.MinTextSize = 9; oddsSize.MaxTextSize = 11; oddsSize.Parent = oddsLabel
		local buy = button(card, "Buy", "Hatch  $" .. egg.Price, UDim2.fromOffset(90, 97), UDim2.new(1, -102, 0, 34))
		eggCards[id] = buy
	end
	local collectionCards = {}
	local release = button(pages.Collection, "Release", "Make room: release weakest slime", UDim2.new(), UDim2.new(1, -6, 0, 38), Color3.fromRGB(255, 198, 148))
	label(pages.Collection, "ReleaseHint", "No refund. Discoveries stay unlocked. Your last slime is protected.", UDim2.fromOffset(6, 42), UDim2.new(1, -12, 0, 31), 10, muted)
	for i, id in AlienData.AlienOrder do
		local alien = AlienData.Aliens[id]
		local card = frame(pages.Collection, id, UDim2.new(((i - 1) % 3) / 3, 3, 0, 81 + math.floor((i - 1) / 3) * 173), UDim2.new(1 / 3, -9, 0, 163), cardColor)
		local icon = preview(card, id, UDim2.new(), UDim2.new(1, 0, 0, 105))
		local name = label(card, "Name", "???", UDim2.fromOffset(5, 101), UDim2.new(1, -10, 0, 22), 14, white); name.TextXAlignment = Enum.TextXAlignment.Center
		local detail = label(card, "Detail", "Undiscovered", UDim2.fromOffset(5, 125), UDim2.new(1, -10, 0, 29), 10, muted); detail.TextXAlignment = Enum.TextXAlignment.Center
		collectionCards[id] = { Icon = icon, Name = name, Detail = detail, Alien = alien }
	end
	local research = frame(pages.Lab, "Research", UDim2.new(), UDim2.new(1, -6, 0, 266), cardColor); outline(research, Color3.fromRGB(198, 166, 255))
	label(research, "Title", "SUPERCHARGE YOUR GARDEN", UDim2.fromOffset(18, 16), UDim2.new(1, -36, 0, 29), 18, mint)
	local upgradeInfo = label(research, "Info", "Loading...", UDim2.fromOffset(18, 53), UDim2.new(1, -36, 0, 88), 15, white)
	label(research, "Help", "Every level adds +25% production to every slime. Lab 1 unlocks Botanical eggs; Lab 2 unlocks Cosmic eggs.", UDim2.fromOffset(18, 141), UDim2.new(1, -36, 0, 58), 12, muted)
	local upgrade = button(research, "Upgrade", "Loading...", UDim2.fromOffset(18, 210), UDim2.new(1, -36, 0, 40))
	label(pages.Lab, "Guide", "STARTER GUIDE\n1. Slimes generate slime automatically.\n2. Sell slime for cash.\n3. Buy eggs and improve your lab.\n4. Discover every species!", UDim2.fromOffset(8, 284), UDim2.new(1, -16, 0, 130), 14, muted)
	-- Reveal overlays are temporary and explicitly dismissible by touch or mouse.
	gui.Parent = playerGui
	return { Gui = gui, Cash = cash, Slime = slime, Production = production, Aliens = aliens, Level = level,
		Save = save, Status = status, Sell = sell, Upgrade = upgrade, UpgradeInfo = upgradeInfo,
		Eggs = eggCards, Collection = collectionCards, Release = release, MenuShade = shade, ReleaseConfirmed = false }
end

function UI.Refresh(view: any, state: AlienData.State?, pending: boolean)
	if not state then
		for _, b in view.Eggs do UI.SetButtonEnabled(b, false) end
		UI.SetButtonEnabled(view.Sell, false); UI.SetButtonEnabled(view.Upgrade, false); UI.SetButtonEnabled(view.Release, false); return
	end
	view.Cash.Text = "$" .. UI.Number(state.Cash); view.Slime.Text = UI.Number(state.Slime)
	view.Production.Text = string.format("Production: +%g / sec", state.ProductionRate)
	view.Level.Text = string.format("LAB %d  /  %.0f%% PRODUCTION", state.LabLevel, 100 * (1 + state.LabLevel * AlienData.BonusPerLevel))
	view.Aliens.Text = string.format("%d / %d slimes", state.AlienCount, AlienData.MaxAliens)
	view.Save.Text = if string.find(state.SaveStatus, "Session mode", 1, true) then "Session mode"
		elseif string.find(state.SaveStatus, "delayed", 1, true) then "Save retrying" else state.SaveStatus
	view.Sell.Text = if pending then "WAIT..." else "SELL $" .. UI.Number(state.Slime * AlienData.CashPerSlime)
	UI.SetButtonEnabled(view.Sell, not pending and state.Slime > 0)
	local weakestName = AlienData.Aliens[state.WeakestAlienId].DisplayName
	view.Release.Text = if view.ReleaseConfirmed then "Confirm: release one " .. weakestName .. "?"
		elseif state.AlienCount <= 1 then "Your last slime is protected" else "Make room: release one " .. weakestName
	UI.SetButtonEnabled(view.Release, not pending and state.AlienCount > 1)
	for id, b in view.Eggs do
		local egg = AlienData.Eggs[id]
		local unlocked = state.LabLevel >= egg.RequiredLevel
		b.Text = if not unlocked then "Unlock at Lab " .. egg.RequiredLevel
			elseif pending then "Working..." elseif state.AlienCount >= AlienData.MaxAliens then "Garden is full"
			elseif state.HatchCooldownRemaining > 0 then "Next egg in " .. math.ceil(state.HatchCooldownRemaining) .. "s"
			elseif state.Cash < egg.Price then "Need $" .. egg.Price else "Hatch  $" .. egg.Price
		UI.SetButtonEnabled(b, unlocked and not pending and state.HatchCooldownRemaining <= 0 and state.Cash >= egg.Price and state.AlienCount < AlienData.MaxAliens)
	end
	local price = AlienData.UpgradePrices[state.LabLevel + 1]
	view.Upgrade.Text = if not price then "FULLY UPGRADED" elseif pending then "Working..." else "Upgrade to Lab " .. (state.LabLevel + 1) .. "  /  $" .. price
	view.UpgradeInfo.Text = string.format("LAB LEVEL %d / %d\nProduction bonus: +%.0f%% / %g slime per sec\n%s", state.LabLevel, #AlienData.UpgradePrices, state.LabLevel * AlienData.BonusPerLevel * 100, state.ProductionRate, state.SaveStatus)
	UI.SetButtonEnabled(view.Upgrade, not pending and price ~= nil and state.Cash >= (price or math.huge))
	local discovered = {}; for _, id in state.Discovered do discovered[id] = true end
	for id, card in view.Collection do
		local found = discovered[id] == true
		card.Icon.ImageColor3 = if found then Color3.new(1, 1, 1) else Color3.fromRGB(35, 48, 59)
		card.Name.Text = if found then card.Alien.DisplayName else "???"
		card.Detail.Text = if found then card.Alien.Rarity .. " / +" .. card.Alien.SlimePerSecond .. " per sec" else "Hatch to discover"
	end
end

function UI.CancelHatch(view: any)
	if view.Opening then view.Opening:Destroy(); view.Opening = nil end
end

function UI.BeginHatch(view: any, eggId: string)
	UI.CancelHatch(view)
	local egg = AlienData.Eggs[eggId]; if not egg then return end
	local overlay = frame(view.Gui, "OpeningEgg", UDim2.new(), UDim2.fromScale(1, 1), ink)
	overlay.BackgroundTransparency = 0.25; overlay.Active = true; view.Opening = overlay
	local icon = preview(overlay, "Slimelet", UDim2.fromScale(0.5, 0.43), UDim2.fromOffset(250, 250), Color3.fromRGB(unpack(egg.Color)))
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	local scale = Instance.new("UIScale"); scale.Parent = icon
	TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.12 }):Play()
	label(overlay, "Caption", "HATCHING " .. string.upper(egg.DisplayName) .. "...", UDim2.fromScale(0.1, 0.72), UDim2.fromScale(0.8, 0.08), 23, mint).TextXAlignment = Enum.TextXAlignment.Center
end

function UI.Reveal(view: any, id: string)
	UI.CancelHatch(view)
	local alien = AlienData.Aliens[id]; if not alien then return end
	if view.Reveal then view.Reveal:Destroy() end
	view.MenuShade.Visible = false
	local overlay = frame(view.Gui, "HatchReveal", UDim2.new(), UDim2.fromScale(1, 1), ink)
	overlay.BackgroundTransparency = 0.18; overlay.Active = true; view.Reveal = overlay
	local card = frame(overlay, "ResultCard", UDim2.fromScale(0.5, 0.45), UDim2.new(0.9, 0, 0.8, 0), cardColor)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	local limit = Instance.new("UISizeConstraint"); limit.MaxSize = Vector2.new(360, 420); limit.Parent = card
	local tint = Color3.fromRGB(unpack(alien.BodyColor)); outline(card, tint)
	local scale = Instance.new("UIScale"); scale.Scale = 0.65; scale.Parent = card
	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	label(card, "Hatched", "YOU HATCHED!", UDim2.new(0, 12, 0.04, 0), UDim2.new(1, -24, 0.09, 0), 20, white).TextXAlignment = Enum.TextXAlignment.Center
	preview(card, id, UDim2.fromScale(0, 0.12), UDim2.fromScale(1, 0.48))
	label(card, "Name", alien.DisplayName, UDim2.fromScale(0, 0.60), UDim2.fromScale(1, 0.09), 28, tint).TextXAlignment = Enum.TextXAlignment.Center
	label(card, "Rarity", alien.Rarity .. " / +" .. alien.SlimePerSecond .. " slime per sec", UDim2.fromScale(0, 0.70), UDim2.fromScale(1, 0.07), 14, white).TextXAlignment = Enum.TextXAlignment.Center
	local done = button(card, "Continue", "MEET YOUR NEW SLIME", UDim2.new(0, 20, 0.82, 0), UDim2.new(1, -40, 0.12, 0))
	done.Activated:Connect(function() overlay:Destroy(); if view.Reveal == overlay then view.Reveal = nil end end)
	-- Confetti is local decoration; it never changes cash or the hatch result.
	for i = 1, 24 do
		local chip = frame(overlay, "Confetti", UDim2.fromScale((i * 0.137) % 1, -0.05), UDim2.fromOffset(7, 12), if i % 2 == 0 then tint else mint)
		chip.Rotation = i * 17
		TweenService:Create(chip, TweenInfo.new(1.2 + (i % 5) * 0.16), { Position = UDim2.fromScale((i * 0.179) % 1, 1.1), Rotation = i * 47, BackgroundTransparency = 1 }):Play()
	end
end

return UI
