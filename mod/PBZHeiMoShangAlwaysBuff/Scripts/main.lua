local UEHelpers = require("UEHelpers")
local scripts = assert(debug.getinfo(1, "S").source:sub(2):match("^(.*[\\/])"))
local gate = dofile(scripts .. "PBZAbilityGate.lua")
local buff = dofile(scripts .. "PBZTangBuff.lua")
local base = scripts .. "../"
local lastStatus
local lastPublish = 0
local requestId, requestMode, requestExpiry = "", "0", 0
local failedId

local function request()
    local stream = io.open(base .. "trainer-request.txt", "r")
    if stream then
        local id, mode, expiry = stream:read("*a"):match("^([%x]+) ([01]) (%d+)%s*$")
        stream:close()
        if id then requestId, requestMode, requestExpiry = id, mode, tonumber(expiry) end
    end
    return requestId, requestMode == "1" and requestExpiry >= os.time()
end

local function publish(id, status)
    local message = id .. " " .. status
    if message == lastStatus and os.time() - lastPublish < 2 then return end
    local stream = io.open(base .. "trainer-status.txt", "w")
    if not stream then return end
    stream:write(message, "\n")
    stream:close()
    if message ~= lastStatus then print("[PBZNoWipe] " .. status .. "\n") end
    lastStatus = message
    lastPublish = os.time()
end

local function refresh()
    local id, enabled = request()
    local player = enabled and UEHelpers.GetPlayer() or nil
    if not enabled or failedId == id or not player or not player:IsValid() then
        local buffOk, removed = pcall(buff.restore)
        local gateOk, restored = pcall(gate.restore)
        local status = "error"
        if buffOk and removed and gateOk and restored and failedId ~= id then
            status = enabled and "waiting" or "off"
        end
        publish(id, status)
        return
    end
    local ok, result = pcall(function()
        local instances = gate.apply(player)
        if instances == 0 then
            assert(buff.restore(), "could not remove effect while waiting for ability")
            return "waiting"
        end
        return buff.maintain(player) and "on" or "armed"
    end)
    if not ok then
        failedId = id
        pcall(buff.restore)
        pcall(gate.restore)
        publish(id, "error")
        error(result)
    end
    publish(id, result)
end

local lastError
LoopAsync(500, function()
    ExecuteInGameThread(function()
        local ok, err = pcall(refresh)
        if not ok and err ~= lastError then print("[PBZNoWipe] " .. tostring(err) .. "\n") end
        lastError = ok and nil or err
    end)
    return false
end)
