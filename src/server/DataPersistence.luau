--!strict
-- Server-only saves. Studio uses a separate store so test money cannot replace live money.
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Schema = require(script.Parent:WaitForChild("FarmSaveSchema"))
local Persistence = {}
local sessions: { [Player]: any } = {}
local store: GlobalDataStore? = nil
local LEASE_SECONDS = 180 -- refreshed every 60 seconds; expires if a server crashes

function Persistence.Normalize(raw: any): any
	return Schema.Normalize(raw)
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
			if typeof(previous.Data) == "table" and previous.Data.FarmVersion and previous.Data.FarmVersion ~= 1 then blocked = true; return nil end
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
