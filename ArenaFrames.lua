-- Reposition arena accessories and hide casting bar to clean up arena frames because default layout is cluttered

-- Define accessory size ratio to scale accessories relative to frame height because proportional sizing adapts to layout changes

local accessorySizeRatio = 0.7

-- Adjust arena member frame layout to relocate accessories because default placement overlaps important content

local function adjustArenaMember(memberFrame)
    if not memberFrame then return end

    -- Derive accessory size from frame height to scale proportionally because hardcoded sizes break when frames resize

    local frameHeight = memberFrame:GetHeight()
    if not frameHeight or frameHeight <= 0 then return end
    local accessorySize = math.floor(frameHeight * accessorySizeRatio)

    -- Hide casting bar to reduce visual noise because cast information is rarely needed on arena frames

    local castingBar = memberFrame.CastingBarFrame
    if castingBar then
        castingBar:SetAlpha(0)
    end

    -- Position crowd control remover to the right of member frame centered vertically because default placement overlaps health info

    local crowdControlRemover = memberFrame.CcRemoverFrame
    if crowdControlRemover then
        crowdControlRemover:SetSize(accessorySize, accessorySize)
        crowdControlRemover:ClearAllPoints()
        crowdControlRemover:SetPoint("LEFT", memberFrame, "RIGHT", 2, 0)
    end

    -- Position debuff frame to the left of member frame centered vertically because default placement overlaps content area

    local debuffFrame = memberFrame.DebuffFrame
    if debuffFrame then
        debuffFrame:SetSize(accessorySize, accessorySize)
        debuffFrame:ClearAllPoints()
        debuffFrame:SetPoint("RIGHT", memberFrame, "LEFT", -2, 0)
    end

    -- Resize diminish tray icons and position next to debuff frame centered vertically because the tray is a layout frame that ignores SetSize

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

local function setupArenaHook()
    if not CompactArenaFrame or CompactArenaFrame.isCleanArenaHooked then return end

    CompactArenaFrame.isCleanArenaHooked = true

    hooksecurefunc(CompactArenaFrame, "UpdateLayout", function(self)
        for _, memberFrame in ipairs(self.memberUnitFrames) do
            adjustArenaMember(memberFrame)
        end
    end)
end

-- Apply arena hooks immediately to catch existing frames because frames may already be created at load time

setupArenaHook()

-- Hook frame generation to apply layout on new frames because arena frames are created lazily on demand

if CompactArenaFrame_Generate then
    hooksecurefunc("CompactArenaFrame_Generate", setupArenaHook)
end
