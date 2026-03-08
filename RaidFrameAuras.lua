-- Manage raid frame auras to hide extra debuffs and highlight healer buffs because default display is cluttered

-- Guard secret values to prevent taint errors because Blizzard may revoke spell visibility in future patches

local issecretvalue = issecretvalue or function() return false end

-- Define tracked healer spell identifiers to detect important buffs because these spells indicate active healing assignments

local trackedHealerSpells = {
    [33763] = true,
    [115175] = true,
    [53563] = true,
    [156910] = true,
    [1244893] = true,
}

-- Limit visible debuffs to one per frame to reduce clutter because multiple debuffs obscure health information

local function HideExtraDebuffs(frame)
    if not frame or not frame.debuffFrames then return end
    for debuffIndex = 2, #frame.debuffFrames do
        if frame.debuffFrames[debuffIndex] then
            frame.debuffFrames[debuffIndex]:Hide()
        end
    end
end

-- Hook aura updates to hide extra debuffs on every refresh because raid frames update dynamically

hooksecurefunc("CompactUnitFrame_UpdateAuras", HideExtraDebuffs)

-- Create golden border overlay on buff frame to highlight tracked healer spells because they need visual emphasis

local function CreateGlowOverlay(buffFrame)
    local glowFrame = CreateFrame("Frame", nil, buffFrame)
    glowFrame:SetAllPoints()
    glowFrame:SetFrameLevel(buffFrame:GetFrameLevel() + 10)

    -- Use tutorial drag slot atlas sized larger than buff frame to create thick golden border because default size is too thin to notice

    local glowTexture = glowFrame:CreateTexture(nil, "OVERLAY")
    glowTexture:SetAtlas("newplayertutorial-drag-slotgreen")
    glowTexture:SetDesaturated(true)
    glowTexture:SetVertexColor(1.0, 0.82, 0.0)
    glowTexture:SetPoint("TOPLEFT", buffFrame, "TOPLEFT", -1, 1)
    glowTexture:SetPoint("BOTTOMRIGHT", buffFrame, "BOTTOMRIGHT", 1, -1)
    glowTexture:SetTexCoord(0.24, 0.76, 0.24, 0.76)

    buffFrame.healerGlow = glowFrame
end

-- Evaluate buff frame aura to show or hide healer glow because each buff frame is recycled across different auras

local function EvaluateHealerGlow(buffFrame, aura)
    if not buffFrame.healerGlow then
        CreateGlowOverlay(buffFrame)
    end

    -- Hide glow when no aura data exists to prevent stale highlights because buff frames can be cleared

    if not aura then
        buffFrame.healerGlow:Hide()
        return
    end

    -- Skip secret auras to avoid taint errors because Blizzard restricts access to hidden spell data

    if issecretvalue(aura.spellId) then
        buffFrame.healerGlow:Hide()
        return
    end

    -- Show golden glow for tracked healer spells to make them visually distinct because they indicate healing assignments

    if trackedHealerSpells[aura.spellId] then
        buffFrame.healerGlow:Show()
    else
        buffFrame.healerGlow:Hide()
    end
end

-- Hook buff frame setup to evaluate healer glow on every buff update because raid frames refresh auras dynamically

hooksecurefunc("CompactUnitFrame_UtilSetBuff", EvaluateHealerGlow)
