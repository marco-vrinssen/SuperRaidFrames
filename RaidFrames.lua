-- Resize raid frame auras, glow tracked healer buffs, limit to one debuff, enlarge dispellable CC

local BUFF_HEIGHT_RATIO           = 0.4
local DEBUFF_HEIGHT_RATIO         = 0.4
local DISPELLABLE_CC_HEIGHT_RATIO = 0.6
local GLOW_SCALE_FACTOR           = 1.4

local trackedHealerSpellIds = {
    [194384]  = true,  -- Atonement
    [156910]  = true,  -- Beacon of Faith
    [1244893] = true,  -- Beacon of Savior
    [53563]   = true,  -- Beacon of Light
    [115175]  = true,  -- Soothing Mist
    [33763]   = true,  -- Lifebloom
    [366155]  = true,  -- Reversion
    [383648]  = true,  -- Earth Shield
}

local CC_AURA_FILTER          = "HARMFUL|CROWD_CONTROL"
local DISPELLABLE_AURA_FILTER = "HARMFUL|RAID_PLAYER_DISPELLABLE"

local healerGlowPool    = {}
local defensiveGlowPool = {}

-- Create or return cached glow overlay to highlight tracked healer buffs because visual priority matters

local function AcquireHealerGlow(buffFrame)
    local glow = healerGlowPool[buffFrame]
    if glow then return glow end

    C_AddOns.LoadAddOn("Blizzard_ActionBar")

    glow = CreateFrame("Frame", nil, buffFrame, "ActionButtonSpellAlertTemplate")
    glow:SetPoint("CENTER", buffFrame, "CENTER", 0, 0)
    glow.ProcStartFlipbook:Hide()
    glow:Hide()

    healerGlowPool[buffFrame] = glow
    return glow
end

-- Play steady glow loop to indicate tracked healer buff because the start flash looks bad at small sizes

local function ShowHealerGlow(buffFrame)
    local glow = AcquireHealerGlow(buffFrame)

    if glow.ProcStartAnim:IsPlaying() then
        glow.ProcStartAnim:Stop()
    end

    glow:Show()

    if not glow.ProcLoop:IsPlaying() then
        glow.ProcLoop:Play()
    end
end

-- Stop healer glow animations to free cycles because hidden buffs should not animate

local function HideHealerGlow(buffFrame)
    local glow = healerGlowPool[buffFrame]
    if not glow then return end

    glow.ProcLoop:Stop()
    glow.ProcStartAnim:Stop()
    glow:Hide()
end

-- Create or return cached green glow overlay to highlight big defensives because they need visual distinction

local function AcquireDefensiveGlow(buffFrame)
    local glow = defensiveGlowPool[buffFrame]
    if glow then return glow end

    C_AddOns.LoadAddOn("Blizzard_ActionBar")

    glow = CreateFrame("Frame", nil, buffFrame, "ActionButtonSpellAlertTemplate")
    glow:SetPoint("CENTER", buffFrame, "CENTER", 0, 0)
    glow.ProcStartFlipbook:Hide()
    glow.ProcStartFlipbook:SetVertexColor(0, 0.8, 0, 1)
    glow.ProcLoopFlipbook:SetVertexColor(0, 0.8, 0, 1)
    glow:Hide()

    defensiveGlowPool[buffFrame] = glow
    return glow
end

-- Play green glow loop to indicate active big defensive because defensives need immediate visibility

local function ShowDefensiveGlow(buffFrame)
    local glow = AcquireDefensiveGlow(buffFrame)

    if glow.ProcStartAnim:IsPlaying() then
        glow.ProcStartAnim:Stop()
    end

    glow:Show()

    if not glow.ProcLoop:IsPlaying() then
        glow.ProcLoop:Play()
    end
end

-- Stop defensive glow animations to free cycles because hidden defensives should not animate

local function HideDefensiveGlow(buffFrame)
    local glow = defensiveGlowPool[buffFrame]
    if not glow then return end

    glow.ProcLoop:Stop()
    glow.ProcStartAnim:Stop()
    glow:Hide()
end

-- Resize aura frame and sync glow overlays to avoid visual mismatch because icons and glows must stay aligned

local function ScaleAuraFrame(auraFrame, iconSize, glowSize)
    auraFrame:SetSize(iconSize, iconSize)

    local healerGlow = healerGlowPool[auraFrame]
    if healerGlow then
        healerGlow:SetSize(glowSize, glowSize)
        healerGlow:ClearAllPoints()
        healerGlow:SetPoint("CENTER", auraFrame, "CENTER", 0, 0)
    end

    local defensiveGlow = defensiveGlowPool[auraFrame]
    if defensiveGlow then
        defensiveGlow:SetSize(glowSize, glowSize)
        defensiveGlow:ClearAllPoints()
        defensiveGlow:SetPoint("CENTER", auraFrame, "CENTER", 0, 0)
    end

    if auraFrame.cooldown then
        auraFrame.cooldown:SetDrawSwipe(false)
        auraFrame.cooldown:SetDrawEdge(false)
    end
end

-- Check healer buff via pcall to handle secret spellId values in PvP because direct access throws

local function IsTrackedHealerBuff(buffFrame)
    local succeeded, result = pcall(function()
        local parent = buffFrame:GetParent()
        local unit   = parent and parent.displayedUnit
        local auraId = buffFrame.auraInstanceID
        if not unit or not auraId then return false end

        local data = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraId)
        if not data or not data.spellId then return false end

        return trackedHealerSpellIds[data.spellId] == true
    end)

    return succeeded and result
end

-- Check whether debuff is a dispellable CC to decide enlargement because CC needs visual priority

local function IsDispellableCC(unitFrame, debuffFrame)
    local unit   = unitFrame and unitFrame.displayedUnit
    local auraId = debuffFrame and debuffFrame.auraInstanceID
    if not unit or not auraId then return false end

    local isCC = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraId, CC_AURA_FILTER)
    if not isCC then return false end

    return not C_UnitAuras.IsAuraFilteredOutByInstanceID(unit, auraId, DISPELLABLE_AURA_FILTER)
end

-- Tag and glow healer buffs immediately to avoid delay because UtilSetBuff fires before UpdateAuras

hooksecurefunc("CompactUnitFrame_UtilSetBuff", function(buffFrame, aura)
    if not buffFrame or not aura then return end

    local isTracked = IsTrackedHealerBuff(buffFrame)
    buffFrame.isTrackedHealerAura = isTracked

    if isTracked then
        ShowHealerGlow(buffFrame)
    else
        HideHealerGlow(buffFrame)
    end
end)

-- Store parent unit frame on debuff to resolve unit token for filter checks later

hooksecurefunc("CompactUnitFrame_UtilSetDebuff", function(unitFrame, debuffFrame, aura)
    if not debuffFrame or not aura then return end

    debuffFrame.parentUnitFrame = unitFrame
end)

-- Resize all aura frames and manage debuff visibility because Blizzard defaults need overriding

hooksecurefunc("CompactUnitFrame_UpdateAuras", function(unitFrame)
    if not unitFrame then return end

    local frameHeight = unitFrame:GetHeight()
    if not frameHeight or frameHeight <= 0 then return end

    local buffSize     = math.floor(frameHeight * BUFF_HEIGHT_RATIO)
    local glowSize     = math.floor(buffSize * GLOW_SCALE_FACTOR)
    local auraGap      = 1
    local auraOffset   = 3
    local bottomOffset = 2 + (unitFrame.powerBarUsedHeight or 0)

    -- Reposition buffs in a bottom-right grid to compensate for upscaled icon sizes because defaults overlap

    if unitFrame.buffFrames then
        local visibleIndex = 0

        for i = 1, #unitFrame.buffFrames do
            local buffFrame = unitFrame.buffFrames[i]
            if not buffFrame then break end

            if buffFrame:IsShown() then
                ScaleAuraFrame(buffFrame, buffSize, glowSize)

                local col = visibleIndex % 3
                local row = math.floor(visibleIndex / 3)

                local xOffset = -auraOffset - (col * (buffSize + auraGap))
                local yOffset = bottomOffset + (row * (buffSize + auraGap))

                buffFrame:ClearAllPoints()
                buffFrame:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", xOffset, yOffset)

                visibleIndex = visibleIndex + 1
            else
                HideHealerGlow(buffFrame)
            end
        end
    end

    -- Rescale and reposition center defensive buff to top-left because it should match other buff sizing

    if unitFrame.CenterDefensiveBuff then
        local defensiveBuff = unitFrame.CenterDefensiveBuff
        if defensiveBuff:IsShown() then
            ScaleAuraFrame(defensiveBuff, buffSize, glowSize)
            defensiveBuff:ClearAllPoints()
            defensiveBuff:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", auraOffset, -auraOffset)
            ShowDefensiveGlow(defensiveBuff)
        else
            HideDefensiveGlow(defensiveBuff)
        end
    end

    -- Reposition first debuff to bottom-left and hide extras because only one debuff should be visible

    if unitFrame.debuffFrames then
        local first = unitFrame.debuffFrames[1]
        if first and first:IsShown() then
            local isCC       = IsDispellableCC(unitFrame, first)
            local ratio      = isCC and DISPELLABLE_CC_HEIGHT_RATIO or DEBUFF_HEIGHT_RATIO
            local debuffSize = math.floor(frameHeight * ratio)
            ScaleAuraFrame(first, debuffSize, math.floor(debuffSize * GLOW_SCALE_FACTOR))

            first:ClearAllPoints()
            first:SetPoint("BOTTOMLEFT", unitFrame, "BOTTOMLEFT", auraOffset, bottomOffset)
        end

        for i = 2, #unitFrame.debuffFrames do
            local debuffFrame = unitFrame.debuffFrames[i]
            if debuffFrame then
                debuffFrame:Hide()
            end
        end
    end
end)
