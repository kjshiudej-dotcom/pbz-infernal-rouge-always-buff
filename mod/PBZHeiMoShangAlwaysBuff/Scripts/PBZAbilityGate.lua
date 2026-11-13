local M = {}
local tag = "Weapon.Type.HeiMoShang"
local parents = {"Weapon.Type", "Weapon"}
local path = "/PBZCombatAsset/ActorData/Players/Hun/Abilities/TangBlade/Default/GA_Hun_Tang_Buff.GA_Hun_Tang_Buff_C"
local changed = {}

local function contains(array, name)
    for i = 1, #array do
        if array[i].TagName:ToString():lower() == name:lower() then return true end
    end
    return false
end

local function matchesInstalled(container)
    return #container.GameplayTags == 1 and contains(container.GameplayTags, tag)
        and #container.ParentTags == 2 and contains(container.ParentTags, parents[1])
        and contains(container.ParentTags, parents[2])
end

local function install(ability, inherited)
    local container = ability.ActivationBlockedTags
    if contains(container.GameplayTags, tag) then
        if inherited and matchesInstalled(container) then changed[ability:GetAddress()] = ability end
        return
    end
    -- The stock ability has an empty block list. Leave altered instances alone.
    assert(#container.GameplayTags == 0 and #container.ParentTags == 0,
        "original blocked tags differ from the validated empty list")
    changed[ability:GetAddress()] = ability
    container.GameplayTags[1] = {TagName = FName(tag)}
    for i, parent in ipairs(parents) do
        container.ParentTags[i] = {TagName = FName(parent)}
    end
    assert(contains(container.GameplayTags, tag), "could not install weapon tag")
end

function M.restore()
    local conflict = false
    for address, ability in pairs(changed) do
        local restored = true
        if ability:IsValid() then
            local container = ability.ActivationBlockedTags
            if matchesInstalled(container) then
                container.GameplayTags:Empty()
                container.ParentTags:Empty()
            else
                restored = #container.GameplayTags == 0 and #container.ParentTags == 0
            end
        end
        if restored then changed[address] = nil else conflict = true end
    end
    return not conflict, conflict and "blocked tags changed after installation" or nil
end

function M.apply(player)
    assert(player and player:IsValid(), "player missing")
    local abilityClass = StaticFindObject(path)
    assert(abilityClass:IsValid(), "wipe ability not loaded")
    local defaultAbility = abilityClass:GetCDO()
    install(defaultAbility, false)
    local inherited = changed[defaultAbility:GetAddress()] ~= nil
    local instances = 0
    for _, ability in ipairs(FindAllOf("GA_Hun_Tang_Buff_C") or {}) do
        if ability:GetAddress() ~= defaultAbility:GetAddress() then
            local avatar = ability:GetAvatarActorFromActorInfo()
            if avatar:IsValid() and avatar:GetAddress() == player:GetAddress() then
                install(ability, inherited)
                instances = instances + 1
            end
        end
    end
    return instances
end

return M
