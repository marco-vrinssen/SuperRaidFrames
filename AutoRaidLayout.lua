-- Auto-switch Edit Mode layout based on raid group size

local LARGE_RAID_SIZE_THRESHOLD = 16
local SMALL_GROUP_LAYOUT_INDEX  = 1
local LARGE_RAID_LAYOUT_INDEX   = 2

local activeLayoutIndex  = nil
local pendingLayoutIndex = nil

local function ApplyEditModeLayout(targetLayoutIndex)
    if targetLayoutIndex == activeLayoutIndex then return end
    local layouts = C_EditMode.GetLayouts()
    if not layouts or not layouts.layouts or not layouts.layouts[targetLayoutIndex] then return end
    if InCombatLockdown() then
        pendingLayoutIndex = targetLayoutIndex
        return
    end
    EditModeManagerFrame:SelectLayout(targetLayoutIndex)
    activeLayoutIndex  = targetLayoutIndex
    pendingLayoutIndex = nil
end

local function EvaluateRaidSizeAndSwitchLayout()
    if IsInRaid() and GetNumGroupMembers() >= LARGE_RAID_SIZE_THRESHOLD then
        ApplyEditModeLayout(LARGE_RAID_LAYOUT_INDEX)
    else
        ApplyEditModeLayout(SMALL_GROUP_LAYOUT_INDEX)
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if pendingLayoutIndex then
            ApplyEditModeLayout(pendingLayoutIndex)
        end
        return
    end
    if not activeLayoutIndex then
        local layouts = C_EditMode.GetLayouts()
        activeLayoutIndex = layouts and layouts.activeLayout
    end
    EvaluateRaidSizeAndSwitchLayout()
end)
