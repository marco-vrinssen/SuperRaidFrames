-- Apply gradient overlay on raid and arena healthbars to create visual depth because flat bars lack distinction

-- Define gradient opacity and colors to control healthbar depth effect because consistent values prevent visual inconsistency

local gradientAlpha = 0.25
local topColor = CreateColor(0, 0, 0, gradientAlpha)
local bottomColor = CreateColor(0, 0, 0, 0)

-- Add gradient texture to healthbar to simulate lighting depth because flat color bars look two-dimensional

local function applyHealthBarGradient(unitFrame)
    if not unitFrame or not unitFrame.healthBar then return end

    local healthBar = unitFrame.healthBar
    if healthBar.cleanGradient then return end

    local gradientTexture = healthBar:CreateTexture(nil, "ARTWORK", nil, 7)
    gradientTexture:SetAllPoints(healthBar)
    gradientTexture:SetColorTexture(1, 1, 1, 1)
    gradientTexture:SetGradient("VERTICAL", bottomColor, topColor)

    healthBar.cleanGradient = gradientTexture
end

-- Hook frame setup functions to apply gradient on creation because raid and arena frames are generated dynamically

hooksecurefunc("DefaultCompactUnitFrameSetup", applyHealthBarGradient)
hooksecurefunc("DefaultCompactMiniFrameSetup", applyHealthBarGradient)
