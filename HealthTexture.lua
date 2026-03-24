-- Apply gradient overlay on raid and arena healthbars to simulate lighting depth

local GRADIENT_OPACITY = 0.25
local GRADIENT_TOP     = CreateColor(0, 0, 0, GRADIENT_OPACITY)
local GRADIENT_BOTTOM  = CreateColor(0, 0, 0, 0)

-- Add gradient texture to healthbar to create visual depth because flat color bars look two-dimensional

local function ApplyHealthBarGradient(unitFrame)
    if not unitFrame or not unitFrame.healthBar then return end

    local healthBar = unitFrame.healthBar
    if healthBar.cleanGradient then return end

    C_Timer.After(0, function()
        if healthBar.cleanGradient then return end

        local gradient = healthBar:CreateTexture(nil, "ARTWORK", nil, 7)
        gradient:SetAllPoints(healthBar)
        gradient:SetColorTexture(1, 1, 1, 1)
        gradient:SetGradient("VERTICAL", GRADIENT_BOTTOM, GRADIENT_TOP)

        healthBar.cleanGradient = gradient
    end)
end

-- Hook frame setup functions to apply gradient on creation because frames are generated dynamically

hooksecurefunc("DefaultCompactUnitFrameSetup", ApplyHealthBarGradient)
hooksecurefunc("DefaultCompactMiniFrameSetup", ApplyHealthBarGradient)
