-- Resize raid frame auras, glow tracked healer buffs, limit to one debuff, enlarge dispellable CC

local BUFF_HEIGHT_RATIO           = 0.4
local DEBUFF_HEIGHT_RATIO         = 0.4
local DISPELLABLE_CC_HEIGHT_RATIO = 0.6
local GLOW_SCALE_FACTOR           = 1.4
local AURA_GAP                    = 1
local AURA_EDGE_OFFSET            = 3
local AURA_BOTTOM_PADDING         = 2

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

-- Create or return cached glow overlay for a buff frame because overlays must persist across aura updates
local function AcquireHealerGlow(buffFrame)
    local glowFrame = healerGlowPool[buffFrame]
    if glowFrame then return glowFrame end
    C_AddOns.LoadAddOn("Blizzard_ActionBar")
    glowFrame = CreateFrame("Frame", nil, buffFrame, "ActionButtonSpellAlertTemplate")
    glowFrame:SetPoint("CENTER", buffFrame, "CENTER", 0, 0)
    glowFrame.ProcStartFlipbook:Hide()
    glowFrame:Hide()
    healerGlowPool[buffFrame] = glowFrame
    return glowFrame
end

-- Play steady glow loop on a healer buff because the start flash looks bad at small icon sizes
local function ShowHealerGlow(buffFrame)
    local glowFrame = AcquireHealerGlow(buffFrame)
    if glowFrame.ProcStartAnim:IsPlaying() then
        glowFrame.ProcStartAnim:Stop()
    end
    glowFrame:Show()
    if not glowFrame.ProcLoop:IsPlaying() then
        glowFrame.ProcLoop:Play()
    end
end

-- Stop healer glow animations and hide overlay because hidden buffs should not animate
local function HideHealerGlow(buffFrame)
    local glowFrame = healerGlowPool[buffFrame]
    if not glowFrame then return end
    glowFrame.ProcLoop:Stop()
    glowFrame.ProcStartAnim:Stop()
    glowFrame:Hide()
end

-- Create or return cached green glow overlay for a defensive buff because defensives need visual distinction
local function AcquireDefensiveGlow(buffFrame)
    local glowFrame = defensiveGlowPool[buffFrame]
    if glowFrame then return glowFrame end
    C_AddOns.LoadAddOn("Blizzard_ActionBar")
    glowFrame = CreateFrame("Frame", nil, buffFrame, "ActionButtonSpellAlertTemplate")
    glowFrame:SetPoint("CENTER", buffFrame, "CENTER", 0, 0)
    glowFrame.ProcStartFlipbook:Hide()
    glowFrame.ProcStartFlipbook:SetVertexColor(0, 0.8, 0, 1)
    glowFrame.ProcLoopFlipbook:SetVertexColor(0, 0.8, 0, 1)
    glowFrame:Hide()
    defensiveGlowPool[buffFrame] = glowFrame
    return glowFrame
end

-- Play green glow loop on a defensive buff because defensives need immediate visibility in combat
local function ShowDefensiveGlow(buffFrame)
    local glowFrame = AcquireDefensiveGlow(buffFrame)
    if glowFrame.ProcStartAnim:IsPlaying() then
        glowFrame.ProcStartAnim:Stop()
    end
    glowFrame:Show()
    if not glowFrame.ProcLoop:IsPlaying() then
        glowFrame.ProcLoop:Play()
    end
end

-- Stop defensive glow animations and hide overlay because hidden defensives should not animate
local function HideDefensiveGlow(buffFrame)
    local glowFrame = defensiveGlowPool[buffFrame]
    if not glowFrame then return end
    glowFrame.ProcLoop:Stop()
    glowFrame.ProcStartAnim:Stop()
    glowFrame:Hide()
end

-- Resize aura frame and sync glow overlays to prevent visual mismatch between icon and glow sizes
local function ResizeAuraFrameWithGlows(auraFrame, iconSize, glowSize)
    auraFrame:SetSize(iconSize, iconSize)

    local healerGlowFrame = healerGlowPool[auraFrame]
    if healerGlowFrame then
        healerGlowFrame:SetSize(glowSize, glowSize)
        healerGlowFrame:ClearAllPoints()
        healerGlowFrame:SetPoint("CENTER", auraFrame, "CENTER", 0, 0)
    end

    local defensiveGlowFrame = defensiveGlowPool[auraFrame]
    if defensiveGlowFrame then
        defensiveGlowFrame:SetSize(glowSize, glowSize)
        defensiveGlowFrame:ClearAllPoints()
        defensiveGlowFrame:SetPoint("CENTER", auraFrame, "CENTER", 0, 0)
    end

    if auraFrame.cooldown then
        auraFrame.cooldown:SetDrawSwipe(false)
        auraFrame.cooldown:SetDrawEdge(false)
    end
end

-- Check if buff matches a tracked healer spell via pcall because PvP hides spellIds behind protected access
local function IsTrackedHealerBuff(buffFrame)
    local succeeded, result = pcall(function()
        local parentFrame    = buffFrame:GetParent()
        local unitToken      = parentFrame and parentFrame.displayedUnit
        local auraInstanceId = buffFrame.auraInstanceID
        if not unitToken or not auraInstanceId then return false end
        local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID(unitToken, auraInstanceId)
        if not auraData or not auraData.spellId then return false end
        return trackedHealerSpellIds[auraData.spellId] == true
    end)
    return succeeded and result
end

-- Check if debuff is both crowd control and dispellable to decide enlarged display
local function IsDispellableCrowdControl(unitFrame, debuffFrame)
    local unitToken      = unitFrame and unitFrame.displayedUnit
    local auraInstanceId = debuffFrame and debuffFrame.auraInstanceID
    if not unitToken or not auraInstanceId then return false end
    local isCrowdControl = not C_UnitAuras.IsAuraFilteredOutByInstanceID(unitToken, auraInstanceId, CC_AURA_FILTER)
    if not isCrowdControl then return false end
    return not C_UnitAuras.IsAuraFilteredOutByInstanceID(unitToken, auraInstanceId, DISPELLABLE_AURA_FILTER)
end

-- Reposition visible buffs in a bottom-right grid because upscaled icon sizes overlap default positions
local function RepositionBuffFrames(unitFrame, buffSize, glowSize, bottomOffset)
    if not unitFrame.buffFrames then return end
    local visibleIndex = 0
    for i = 1, #unitFrame.buffFrames do
        local buffFrame = unitFrame.buffFrames[i]
        if not buffFrame then break end
        if buffFrame:IsShown() then
            ResizeAuraFrameWithGlows(buffFrame, buffSize, glowSize)
            local col = visibleIndex % 3
            local row = math.floor(visibleIndex / 3)
            local xOffset = -AURA_EDGE_OFFSET - (col * (buffSize + AURA_GAP))
            local yOffset = bottomOffset + (row * (buffSize + AURA_GAP))
            buffFrame:ClearAllPoints()
            buffFrame:SetPoint("BOTTOMRIGHT", unitFrame, "BOTTOMRIGHT", xOffset, yOffset)
            visibleIndex = visibleIndex + 1
        else
            HideHealerGlow(buffFrame)
        end
    end
end

-- Reposition center defensive buff to top-left with green glow because defensives need immediate visibility
local function UpdateDefensiveBuffDisplay(unitFrame, buffSize, glowSize)
    if not unitFrame.CenterDefensiveBuff then return end
    local defensiveBuffFrame = unitFrame.CenterDefensiveBuff
    if defensiveBuffFrame:IsShown() then
        ResizeAuraFrameWithGlows(defensiveBuffFrame, buffSize, glowSize)
        defensiveBuffFrame:ClearAllPoints()
        defensiveBuffFrame:SetPoint("TOPLEFT", unitFrame, "TOPLEFT", AURA_EDGE_OFFSET, -AURA_EDGE_OFFSET)
        ShowDefensiveGlow(defensiveBuffFrame)
    else
        HideDefensiveGlow(defensiveBuffFrame)
    end
end

-- Show primary debuff at bottom-left and hide extras because only one debuff should be visible at a time
local function UpdateDebuffFrameDisplay(unitFrame, frameHeight, bottomOffset)
    if not unitFrame.debuffFrames then return end
    local primaryDebuffFrame = unitFrame.debuffFrames[1]
    if primaryDebuffFrame and primaryDebuffFrame:IsShown() then
        local isCrowdControl = IsDispellableCrowdControl(unitFrame, primaryDebuffFrame)
        local heightRatio    = isCrowdControl and DISPELLABLE_CC_HEIGHT_RATIO or DEBUFF_HEIGHT_RATIO
        local debuffSize     = math.floor(frameHeight * heightRatio)
        ResizeAuraFrameWithGlows(primaryDebuffFrame, debuffSize, math.floor(debuffSize * GLOW_SCALE_FACTOR))
        primaryDebuffFrame:ClearAllPoints()
        primaryDebuffFrame:SetPoint("BOTTOMLEFT", unitFrame, "BOTTOMLEFT", AURA_EDGE_OFFSET, bottomOffset)
    end
    for i = 2, #unitFrame.debuffFrames do
        local debuffFrame = unitFrame.debuffFrames[i]
        if debuffFrame then
            debuffFrame:Hide()
        end
    end
end

-- Tag and glow healer buffs on assignment because UtilSetBuff fires before UpdateAuras
hooksecurefunc("CompactUnitFrame_UtilSetBuff", function(buffFrame, aura)
    if not buffFrame or not aura then return end
    local isTrackedHealer = IsTrackedHealerBuff(buffFrame)
    buffFrame.isTrackedHealerAura = isTrackedHealer
    if isTrackedHealer then
        ShowHealerGlow(buffFrame)
    else
        HideHealerGlow(buffFrame)
    end
end)

-- Store parent unit frame on debuff assignment to resolve unit token for filter checks
hooksecurefunc("CompactUnitFrame_UtilSetDebuff", function(unitFrame, debuffFrame, aura)
    if not debuffFrame or not aura then return end
    debuffFrame.parentUnitFrame = unitFrame
end)

-- Resize and reposition all aura frames after Blizzard updates because default layout needs overriding
hooksecurefunc("CompactUnitFrame_UpdateAuras", function(unitFrame)
    if not unitFrame then return end
    local frameHeight = unitFrame:GetHeight()
    if not frameHeight or frameHeight <= 0 then return end
    local buffSize     = math.floor(frameHeight * BUFF_HEIGHT_RATIO)
    local glowSize     = math.floor(buffSize * GLOW_SCALE_FACTOR)
    local bottomOffset = AURA_BOTTOM_PADDING + (unitFrame.powerBarUsedHeight or 0)
    RepositionBuffFrames(unitFrame, buffSize, glowSize, bottomOffset)
    UpdateDefensiveBuffDisplay(unitFrame, buffSize, glowSize)
    UpdateDebuffFrameDisplay(unitFrame, frameHeight, bottomOffset)
end)
