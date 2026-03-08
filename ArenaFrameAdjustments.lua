-- Reposition arena accessories and hide casting bar to clean up arena frames because default layout is cluttered

-- Define accessory size to ensure consistent dimensions because mismatched sizes break visual alignment

local accessorySize = 40

-- Adjust arena member frame layout to relocate accessories because default placement overlaps important content

local function AdjustArenaMember(memberFrame)
    if not memberFrame then return end

    -- Hide casting bar to reduce visual noise because cast information is rarely needed on arena frames

    local castingBar = memberFrame.CastingBarFrame
    if castingBar then
        castingBar:SetAlpha(0)
    end

    -- Position crowd control remover to the right of member frame because default placement overlaps health info

    local crowdControlRemover = memberFrame.CcRemoverFrame
    if crowdControlRemover then
        crowdControlRemover:SetSize(accessorySize, accessorySize)
        crowdControlRemover:ClearAllPoints()
        crowdControlRemover:SetPoint("TOPLEFT", memberFrame, "TOPRIGHT", 2, 0)
    end

    -- Position debuff frame to the left of member frame because default placement overlaps content area

    local debuffFrame = memberFrame.DebuffFrame
    if debuffFrame then
        debuffFrame:SetSize(accessorySize, accessorySize)
        debuffFrame:ClearAllPoints()
        debuffFrame:SetPoint("TOPRIGHT", memberFrame, "TOPLEFT", -2, 0)
    end

    -- Position diminish tray to the bottom-left of member frame because it avoids overlapping other elements

    local diminishTray = memberFrame.SpellDiminishStatusTray
    if diminishTray then
        diminishTray:ClearAllPoints()
        diminishTray:SetPoint("BOTTOMRIGHT", memberFrame, "BOTTOMLEFT", -2, 0)
    end
end

-- Hook arena frame layout to apply adjustments because mixin hooks fail after frame creation

local function SetupArenaHook()
    if not CompactArenaFrame or CompactArenaFrame.cleanArenaHooked then return end
    CompactArenaFrame.cleanArenaHooked = true
    hooksecurefunc(CompactArenaFrame, "UpdateLayout", function(self)
        for _, memberFrame in ipairs(self.memberUnitFrames) do
            AdjustArenaMember(memberFrame)
        end
    end)
end

-- Apply arena hooks immediately to catch existing frames because frames may already be created at load time

SetupArenaHook()

-- Hook frame generation to apply layout on new frames because arena frames are created lazily on demand

if CompactArenaFrame_Generate then
    hooksecurefunc("CompactArenaFrame_Generate", SetupArenaHook)
end
