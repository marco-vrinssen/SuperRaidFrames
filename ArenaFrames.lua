-- Reposition arena accessories and hide casting bar to clean up arena frames

local ACCESSORY_HEIGHT_RATIO = 0.6

-- Rescale and reposition arena member accessories because default layout overlaps important content

local function AdjustArenaMember(memberFrame)
    if not memberFrame then return end

    local frameHeight = memberFrame:GetHeight()
    if not frameHeight or frameHeight <= 0 then return end

    local accessorySize = math.floor(frameHeight * ACCESSORY_HEIGHT_RATIO)

    local castingBar = memberFrame.CastingBarFrame
    if castingBar then
        castingBar:SetAlpha(0)
    end

    local ccRemover = memberFrame.CcRemoverFrame
    if ccRemover then
        ccRemover:SetSize(accessorySize, accessorySize)
        ccRemover:ClearAllPoints()
        ccRemover:SetPoint("LEFT", memberFrame, "RIGHT", 2, 0)
    end

    local debuffFrame = memberFrame.DebuffFrame
    if debuffFrame then
        debuffFrame:SetSize(accessorySize, accessorySize)
        debuffFrame:ClearAllPoints()
        debuffFrame:SetPoint("RIGHT", memberFrame, "LEFT", -2, 0)
    end

    local diminishTray = memberFrame.SpellDiminishStatusTray
    if diminishTray then
        for _, diminishIcon in pairs({ diminishTray:GetChildren() }) do
            diminishIcon:SetSize(accessorySize, accessorySize)
        end
        diminishTray:ClearAllPoints()
        diminishTray:SetPoint("RIGHT", debuffFrame, "LEFT", -2, 0)
    end
end

-- Hook arena frame layout to apply adjustments because mixin hooks fail after frame creation

local function SetupArenaHook()
    if not CompactArenaFrame or CompactArenaFrame.isCleanArenaHooked then return end

    CompactArenaFrame.isCleanArenaHooked = true

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

-- Enable diminish tracking CVars on entering world because they must be set per session

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function()
    SetCVar("spellDiminishPVPEnemiesEnabled", "1")
    SetCVar("spellDiminishPVPOnlyTriggerableByMe", "1")
end)
