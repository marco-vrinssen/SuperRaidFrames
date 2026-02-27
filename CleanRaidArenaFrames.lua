-- Apply gradient depth overlay on raid healthbars and clean arena frame accessories

-- Define vertical gradient colors for healthbar depth effect

local GRADIENT_ALPHA = 0.25
local TOP_COLOR = CreateColor(0, 0, 0, GRADIENT_ALPHA)
local BOTTOM_COLOR = CreateColor(0, 0, 0, 0)

-- Add gradient texture to unit frame healthbars to create visual depth

local function ApplyHealthBarGradient(frame)
    if not frame or not frame.healthBar then return end
    local healthBar = frame.healthBar
    if healthBar.cleanGradient then return end
    local gradient = healthBar:CreateTexture(nil, "ARTWORK", nil, 7)
    gradient:SetAllPoints(healthBar)
    gradient:SetColorTexture(1, 1, 1, 1)
    gradient:SetGradient("VERTICAL", BOTTOM_COLOR, TOP_COLOR)
    healthBar.cleanGradient = gradient
end

-- Hook frame setup to apply gradient to all raid and arena frames

hooksecurefunc("DefaultCompactUnitFrameSetup", ApplyHealthBarGradient)
hooksecurefunc("DefaultCompactMiniFrameSetup", ApplyHealthBarGradient)

local ACCESSORY_SIZE = 40

-- Reposition arena accessories and hide casting bar for cleaner appearance

local function AdjustArenaMember(memberFrame)
    if not memberFrame then return end

    -- Hide casting bar by setting alpha to transparent

    local castingBar = memberFrame.CastingBarFrame
    if castingBar then
        castingBar:SetAlpha(0)
    end

    -- Position CC remover to the right of member frame

    local ccRemover = memberFrame.CcRemoverFrame
    if ccRemover then
        ccRemover:SetSize(ACCESSORY_SIZE, ACCESSORY_SIZE)
        ccRemover:ClearAllPoints()
        ccRemover:SetPoint("TOPLEFT", memberFrame, "TOPRIGHT", 2, 0)
    end

    -- Position debuff frame to the left of member frame

    local debuffFrame = memberFrame.DebuffFrame
    if debuffFrame then
        debuffFrame:SetSize(ACCESSORY_SIZE, ACCESSORY_SIZE)
        debuffFrame:ClearAllPoints()
        debuffFrame:SetPoint("TOPRIGHT", memberFrame, "TOPLEFT", -2, 0)
    end

    -- Position diminish tray to the bottom-left of member frame

    local diminishTray = memberFrame.SpellDiminishStatusTray
    if diminishTray then
        diminishTray:ClearAllPoints()
        diminishTray:SetPoint("BOTTOMRIGHT", memberFrame, "BOTTOMLEFT", -2, 0)
    end
end

-- Hook arena frame instance directly because mixin hooks fail after frame creation

local function SetupArenaHook()
    if not CompactArenaFrame or CompactArenaFrame.cleanArenaHooked then return end
    CompactArenaFrame.cleanArenaHooked = true
    hooksecurefunc(CompactArenaFrame, "UpdateLayout", function(self)
        for _, memberFrame in ipairs(self.memberUnitFrames) do
            AdjustArenaMember(memberFrame)
        end
    end)
end

-- Apply arena hooks immediately and on frame generation

SetupArenaHook()

if CompactArenaFrame_Generate then
    hooksecurefunc("CompactArenaFrame_Generate", SetupArenaHook)
end