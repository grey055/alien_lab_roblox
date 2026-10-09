--!strict
-- Server-only saves. Studio uses a separate store so test money cannot replace live money.
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AlienData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AlienData"))
local Persistence = {}
local sessions: { [Player]: any } = {}
local store: GlobalDataStore? = nil
local LEASE_SECONDS = 180 -- refreshed every 60 seconds; expires if a server crashes

local function integer(value: any, fallback: number, maximum: number): number
	if typeof(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return fallback end
	return math.clamp(math.floor(value), 0, maximum)
end

function Persistence.Normalize(raw: any): any
	local source = if typeof(raw) == "table" then raw else {}
	local aliens = {}
	if typeof(source.Aliens) == "table" then
		for _, id in source.Aliens do
			if #aliens >= AlienData.MaxAliens then break end
			if typeof(id) == "string" and AlienData.Aliens[id] then table.insert(aliens, id) end
		end
	end
	if #aliens == 0 then table.insert(aliens, AlienData.StarterAlienId) end
	local discovered = { [AlienData.StarterAlienId] = true }
	if typeof(source.Discovered) == "table" then
		for _, id in AlienData.AlienOrder do if source.Discovered[id] == true then discovered[id] = true end end
	end
	for _, id in aliens do discovered[id] = true end
	return { Cash = integer(source.Cash, AlienData.StartingCash, 1e12), Slime = integer(source.Slime, 0, 1e12),
		Aliens = aliens, LabLevel = integer(source.LabLevel, 0, #AlienData.UpgradePrices), Discovered = discovered }
end

local function getStore(): GlobalDataStore
	if not store then
		store = DataStoreService:GetDataStore("AlienLab_v1" .. (if RunService:IsStudio() then "_Studio" else ""))
	end
	return store :: GlobalDataStore
end

local function update(key: string, transform: (any) -> any): (boolean, any)
	for attempt = 1, 3 do
		local ok, value = pcall(function() return getStore():UpdateAsync(key, transform) end)
		if ok then return true, value end
		if attempt < 3 then task.wait(attempt) end
	end
	return false, nil
end

function Persistence.Load(player: Player): (any?, string)
	if game.GameId == 0 then return nil, "Session mode" end
	local token = HttpService:GenerateGUID(false)
	local key = "Player_" .. player.UserId
	local blocked = false
	local ok, record = update(key, function(previous: any)
		blocked = false -- UpdateAsync may run this callback again after a conflict.
		if typeof(previous) == "table" then
			if previous.Version and previous.Version ~= 1 then blocked = true; return nil end
			local lock = previous.Session
			if typeof(lock) == "table" and lock.Token ~= token and typeof(lock.Expires) == "number" and lock.Expires > os.time() then
				blocked = true
				return nil
			end
		end
		local data = Persistence.Normalize(if typeof(previous) == "table" then previous.Data else nil)
		return { Version = 1, Data = data, Session = { Token = token, Expires = os.time() + LEASE_SECONDS } }
	end)
	if blocked then return nil, "Locked" end
	if not ok or not record then
		-- A failed load MUST NOT be followed by saving defaults over a real profile.
		warn("Alien Lab: save loading unavailable for " .. player.UserId .. "; session-only play enabled.")
		return nil, "Session mode - saving unavailable"
	end
	sessions[player] = { Key = key, Token = token, Busy = false, Closing = false, Valid = true }
	return record.Data, "Autosave ready"
end

function Persistence.Save(player: Player, snapshot: any, release: boolean?): string
	local session = sessions[player]
	if not session or not snapshot then return "Session mode" end
	if release then session.Closing = true end
	if session.Busy then
		if not release then return "Saving..." end
		local deadline = os.clock() + 20
		while session.Busy and os.clock() < deadline do task.wait(0.1) end
		if session.Busy then return "Save delayed" end
	elseif session.Closing and not release then
		return "Saving..."
	end
	if not session.Valid then return "Save session expired" end
	session.Busy = true
	local payload = Persistence.Normalize(snapshot)
	local lostLock = false
	local ok, record = update(session.Key, function(previous: any)
		lostLock = false
		if typeof(previous) ~= "table" or typeof(previous.Session) ~= "table" or previous.Session.Token ~= session.Token then
			lostLock = true
			return nil
		end
		return { Version = 1, Data = payload,
			Session = if release then nil else { Token = session.Token, Expires = os.time() + LEASE_SECONDS } }
	end)
	session.Busy = false
	if lostLock then session.Valid = false end
	if release then sessions[player] = nil end
	if lostLock then return "Save session expired" end
	if not ok or not record then warn("Alien Lab: save failed for " .. player.UserId); return "Save delayed - retrying" end
	return "Saved"
end

return Persistence
