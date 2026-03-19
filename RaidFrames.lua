-- Manage raid frame auras by increasing buff sizes, highlighting tracked
-- healer buffs with a golden glow border, limiting debuffs to the first
-- one only (enlarged when it is a dispellable CC), and removing cooldown
-- swipe/edge clutter


------------------------------------------------------------------------
-- Configuration
------------------------------------------------------------------------

local AURA_SIZE_RATIO      = 0.4  -- buff icon size as a fraction of the raid frame height
local DEBUFF_SIZE_RATIO    = 0.4  -- default debuff icon size ratio (same as buffs)
local DEBUFF_CC_SIZE_RATIO = 0.7  -- enlarged debuff icon when it is a dispellable CC
local GLOW_SIZE_RATIO      = 1.4  -- glow frame extends to 140% of the aura icon size

local trackedHealerSpellIds = {
    [194384]  = true,  -- Atonement        (Discipline Priest)
    [156910]  = true,  -- Beacon of Faith  (Holy Paladin)
    [1244893] = true,  -- Beacon of Savior (Holy Paladin)
    [53563]   = true,  -- Beacon of Light  (Holy Paladin)
    [115175]  = true,  -- Soothing Mist    (Mistweaver Monk)
    [33763]   = true,  -- Lifebloom        (Restoration Druid)
    [366155]  = true,  -- Reversion        (Evoker)
    [383648]  = true,  -- Earth Shield     (Restoration Shaman)
}

-- Filter strings for the 12.0.1 aura filter API.
-- IsAuraFilteredOutByInstanceID returns true when the aura does NOT match
-- the filter (i.e. is excluded). We check with "not" to confirm a match.

local CC_FILTER          = "HARMFUL|CROWD_CONTROL"
local DISPELLABLE_FILTER = "HARMFUL|RAID_PLAYER_DISPELLABLE"


------------------------------------------------------------------------
-- Glow frame pool
------------------------------------------------------------------------

-- Pool keyed by buff frame reference.
local glowPool = {}


-- Return a cached glow overlay or create one on first use.
-- Uses Blizzard ActionButtonSpellAlertTemplate for the golden glow effect.

local function AcquireGlow(buffFrame)
    local glow = glowPool[buffFrame]
    if glow then return glow end

    C_AddOns.LoadAddOn("Blizzard_ActionBar")

    glow = CreateFrame("Frame", nil, buffFrame, "ActionButtonSpellAlertTemplate")
    glow:SetPoint("CENTER", buffFrame, "CENTER", 0, 0)
    glow.ProcStartFlipbook:Hide()
    glow:Hide()

    glowPool[buffFrame] = glow
    return glow
end


-- Show the steady glow loop, skipping the start flash which looks bad
-- at small icon sizes.

local function ShowGlow(buffFrame)
    local glow = AcquireGlow(buffFrame)

    if glow.ProcStartAnim:IsPlaying() then
        glow.ProcStartAnim:Stop()
    end

    glow:Show()

    if not glow.ProcLoop:IsPlaying() then
        glow.ProcLoop:Play()
    end
end


-- Hide the glow and stop all animations to avoid wasting cycles.

local function HideGlow(buffFrame)
    local glow = glowPool[buffFrame]
    if not glow then return end

    glow.ProcLoop:Stop()
    glow.ProcStartAnim:Stop()
    glow:Hide()
end


------------------------------------------------------------------------
-- Frame styling
------------------------------------------------------------------------

-- Apply icon size, optional glow resize, and cooldown cleanup to a
-- single aura frame.

local function StyleAuraFrame(auraFrame, auraSize, glowSize)
    auraFrame:SetSize(auraSize, auraSize)

    local glow = glowPool[auraFrame]
    if glow then
        glow:SetSize(glowSize, glowSize)
        glow:ClearAllPoints()
        glow:SetPoint("CENTER", auraFrame, "CENTER", 0, 0)
    end

    if auraFrame.cooldown then
        auraFrame.cooldown:SetDrawSwipe(false)
        auraFrame.cooldown:SetDrawEdge(false)
    end
end


------------------------------------------------------------------------
-- Aura helpers
------------------------------------------------------------------------

-- Check whether a buff frame carries a tracked healer spell. Aura fields
-- on other players' units can be "secret" (12.0.0+), which causes any
-- attempt to use them as table keys to throw "table index is secret".
-- Even re-querying through C_UnitAuras.GetAuraDataByAuraInstanceID still
-- returns secret values in some cases. We wrap the entire lookup in pcall
-- so a secret spellId is caught and treated as "not tracked".

local function IsTrackedHealerBuff(buffFrame)
    local ok, result = pcall(function()
        local parent = buffFrame:GetParent()
        local unit   = parent and parent.displayedUnit
        local auraId = buffFrame.auraInstanceID
        if not unit or not auraId then return false end

        local data = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraId)
        if not data or not data.spellId then return false end

        return trackedHealerSpellIds[data.spellId] == true
    end)

    return ok and result
end


-- Check whether the first debuff is a crowd control effect that the
-- current player can dispel, using the 12.0.1 aura filter API.

local function IsDispellableCC(unitFrame, debuffFrame)
    local unit   = unitFrame and unitFrame.displayedUnit
    local auraId = debuffFrame and debuffFrame.auraInstanceID
    if not unit or not auraId then return false end

    local isCC = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraId, CC_FILTER)
    if not isCC then return false end

    local isDispellable = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraId, DISPELLABLE_FILTER)
    return isDispellable
end


------------------------------------------------------------------------
-- Hooks
------------------------------------------------------------------------

-- Hook into CompactUnitFrame_UtilSetBuff to immediately tag and glow buff
-- frames that carry a tracked healer spell. Applying the glow here instead
-- of in the UpdateAuras hook removes the ~500ms delay because UtilSetBuff
-- fires the instant Blizzard assigns aura data to the frame.

hooksecurefunc("CompactUnitFrame_UtilSetBuff", function(buffFrame, aura)
    if not buffFrame or not aura then return end

    local isTracked = IsTrackedHealerBuff(buffFrame)
    buffFrame.isTrackedHealerAura = isTracked

    if isTracked then
        ShowGlow(buffFrame)
    else
        HideGlow(buffFrame)
    end
end)


-- Hook into CompactUnitFrame_UtilSetDebuff to store the parent unit frame
-- reference so we can resolve the unit token for filter checks later.

hooksecurefunc("CompactUnitFrame_UtilSetDebuff", function(unitFrame, debuffFrame, aura)
    if not debuffFrame or not aura then return end

    debuffFrame.parentUnitFrame = unitFrame
end)


-- Main post-hook on CompactUnitFrame_UpdateAuras. Handles sizing for all
-- aura frames and debuff visibility. Glow state for buffs is already
-- resolved in the UtilSetBuff hook above, so this pass only needs to
-- handle sizing, cleanup for hidden frames, and debuff logic.

hooksecurefunc("CompactUnitFrame_UpdateAuras", function(unitFrame)
    if not unitFrame then return end

    local frameHeight = unitFrame:GetHeight()
    if not frameHeight or frameHeight <= 0 then return end

    local buffSize = math.floor(frameHeight * AURA_SIZE_RATIO)
    local glowSize = math.floor(buffSize   * GLOW_SIZE_RATIO)

    -- Buffs: resize all visible buffs and clean up glows on hidden frames.
    -- Glow show/hide is already handled in the UtilSetBuff hook, but we
    -- still need to hide glows on frames that Blizzard hid after the buff
    -- iteration (e.g. when a buff expires and the frame is recycled).

    if unitFrame.buffFrames then
        for i = 1, #unitFrame.buffFrames do
            local buffFrame = unitFrame.buffFrames[i]
            if not buffFrame then break end

            if buffFrame:IsShown() then
                StyleAuraFrame(buffFrame, buffSize, glowSize)
            else
                HideGlow(buffFrame)
            end
        end
    end

    -- Debuffs: show only the first debuff, hide all others.
    -- If the first debuff is a CC that the player can dispel, enlarge it
    -- to the CC size ratio so it stands out during combat.

    if unitFrame.debuffFrames then
        local first = unitFrame.debuffFrames[1]
        if first and first:IsShown() then
            local isCC       = IsDispellableCC(unitFrame, first)
            local ratio      = isCC and DEBUFF_CC_SIZE_RATIO or DEBUFF_SIZE_RATIO
            local debuffSize = math.floor(frameHeight * ratio)
            StyleAuraFrame(first, debuffSize, math.floor(debuffSize * GLOW_SIZE_RATIO))
        end

        for i = 2, #unitFrame.debuffFrames do
            local debuffFrame = unitFrame.debuffFrames[i]
            if debuffFrame then
                debuffFrame:Hide()
            end
        end
    end
end)
