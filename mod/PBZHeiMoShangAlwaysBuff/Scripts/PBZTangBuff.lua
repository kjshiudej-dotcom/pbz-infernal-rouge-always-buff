local M = {}
local path = "/PBZCombatAsset/ActorData/Players/Hun/Weapon/Tang/UpgradeData/GE_Weapon_Tang_Buff_Lv1.GE_Weapon_Tang_Buff_Lv1_C"
local own

local function blueprintLibrary(name)
    local object = StaticFindObject(name)
    assert(object:IsValid(), "effect blueprint library unavailable: " .. name)
    return object
end

local function library()
    return blueprintLibrary("/Script/GameplayAbilities.Default__AbilitySystemBlueprintLibrary")
end

function M.restore()
    if not own then return true end
    if own.asc:IsValid() then
        local effects = library()
        local before = effects:GetActiveGameplayEffectStackCount(own.handle)
        if before > 0 then
            own.asc:RemoveActiveGameplayEffect(own.handle, 1)
            if effects:GetActiveGameplayEffectStackCount(own.handle) >= before then return false end
        end
    end
    print(string.format("[PBZTangBuff] removed handle=%d\n", own.handle.Handle))
    own = nil
    return true
end

function M.maintain(player)
    local ascClass = StaticFindObject("/Script/GameplayAbilities.AbilitySystemComponent")
    local asc = player:GetComponentByClass(ascClass)
    if not asc:IsValid() or asc:GetGameplayTagCount({TagName = FName("Weapon.Type.HeiMoShang")}) < 1 then
        assert(M.restore(), "could not remove effect after weapon switch")
        return false
    end
    if own and (not own.asc:IsValid() or own.asc:GetAddress() ~= asc:GetAddress()) then
        assert(M.restore(), "could not remove effect from the previous pawn")
    end
    local effects = library()
    if own and effects:GetActiveGameplayEffectStackCount(own.handle) > 0 then return true end
    own = nil
    local effect = StaticFindObject(path)
    if not effect:IsValid() then effect = LoadAsset(path) end
    assert(effect:IsValid(), "original Tang Blade effect unavailable")
    if asc:GetGameplayEffectCount(effect, nil, false) > 0 then
        return asc:GetGameplayEffectCount(effect, nil, true) > 0
    end

    local durationValue = effect:GetCDO().DurationMagnitude.ScalableFloatMagnitude
    local originalDuration = durationValue.Value
    assert(type(originalDuration) == "number", "original effect duration is unavailable")
    local applied, handle = pcall(function()
        durationValue.Value = 86400
        return asc:BP_ApplyGameplayEffectToSelf(effect, 1, asc:MakeEffectContext())
    end)
    durationValue.Value = originalDuration
    assert(applied, handle)
    local id = handle.Handle
    assert(type(id) == "number" and id >= 0, "effect did not return an active handle")
    own = {asc = asc, handle = {Handle = id, bPassedFiltersAndWasExecuted = true}}
    assert(effects:GetActiveGameplayEffectStackCount(own.handle) == 1, "unexpected Tang Blade effect stack count")
    local duration = effects:GetActiveGameplayEffectTotalDuration(own.handle)
    assert(duration >= 86400, "could not extend the effect duration")
    print(string.format("[PBZTangBuff] applied handle=%d stacks=1 duration=%.0f\n", id, duration))
    return true
end

return M
