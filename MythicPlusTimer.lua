MythicPlusTimerCMTimer = {}

-- ---------------------------------------------------------------------------------------------------------------------
function MythicPlusTimerCMTimer:Init()
    if not MythicPlusTimerDB.pos then
        MythicPlusTimerDB.pos = {}
    end

    if MythicPlusTimerDB.pos.left == nil then
        MythicPlusTimerDB.pos.left = -260;
    end
    
    if MythicPlusTimerDB.pos.top == nil then
        MythicPlusTimerDB.pos.top = 190;
    end

    if MythicPlusTimerDB.pos.relativePoint == nil then
        MythicPlusTimerDB.pos.relativePoint = "RIGHT";
    end
    
    if not MythicPlusTimerDB.bestTimes then
        MythicPlusTimerDB.bestTimes = {}
    end

    MythicPlusTimerCMTimer.isCompleted = false;
    MythicPlusTimerCMTimer.started = false;
    MythicPlusTimerCMTimer.reset = false;
    MythicPlusTimerCMTimer.frames = {};
    MythicPlusTimerCMTimer.timerStarted = false;
    
    MythicPlusTimerCMTimer.frame = CreateFrame("Frame", "CmTimer", UIParent);
    MythicPlusTimerCMTimer.frame:SetPoint(MythicPlusTimerDB.pos.relativePoint,MythicPlusTimerDB.pos.left,MythicPlusTimerDB.pos.top)
    MythicPlusTimerCMTimer.frame:EnableMouse(true)
    MythicPlusTimerCMTimer.frame:RegisterForDrag("LeftButton")
    MythicPlusTimerCMTimer.frame:SetScript("OnDragStart", MythicPlusTimerCMTimer.frame.StartMoving)
    MythicPlusTimerCMTimer.frame:SetScript("OnDragStop", MythicPlusTimerCMTimer.frame.StopMovingOrSizing)
    MythicPlusTimerCMTimer.frame:SetScript("OnMouseDown", MythicPlusTimerCMTimer.OnFrameMouseDown)
    MythicPlusTimerCMTimer.frame:SetWidth(100);
    MythicPlusTimerCMTimer.frame:SetHeight(100);
    MythicPlusTimerCMTimer.frameToggle = false


    MythicPlusTimerCMTimer.eventFrame = CreateFrame("Frame")
    MythicPlusTimerCMTimer.eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    MythicPlusTimerCMTimer.eventFrame:SetScript("OnEvent", function(self, event, timestamp, subEvent, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags)
        if subEvent ~= "UNIT_DIED" then 
            return 
        end

        local isPlayer = strfind(destGUID, "Player")
        if not isPlayer then
            return
        end

        local isFeign = UnitIsFeignDeath(destName);
        if isFeign then
            return
        end
        
        MythicPlusTimerCMTimer:OnPlayerDeath()
    end)
end

-- ---------------------------------------------------------------------------------------------------------------------
function MythicPlusTimerCMTimer:ToggleFrame()
    if MythicPlusTimerCMTimer.frameToggle then
        MythicPlusTimerCMTimer.frame:SetMovable(false)
        MythicPlusTimerCMTimer.frame:SetBackdrop(nil)
        MythicPlusTimerCMTimer.frameToggle = false

        local _, _, relativePoint, xOfs, yOfs = MythicPlusTimerCMTimer.frame:GetPoint()
        MythicPlusTimerDB.pos.relativePoint = relativePoint;
        MythicPlusTimerDB.pos.top = yOfs;
        MythicPlusTimerDB.pos.left = xOfs;

        local _, _, difficulty, _, _, _, _, _ = GetInstanceInfo();
        if difficulty ~= 8 then
            MythicPlusTimerCMTimer.frame:Hide();
        end
    else
        MythicPlusTimerCMTimer.frame:SetMovable(true)
        local backdrop = {
            bgFile = "Interface/Tooltips/UI-Tooltip-Background",
            edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
            tile = true,
            tileSize = 32,
            edgeSize = 1,
            insets = {
                left = 0,
                right = 0,
                top = 0,
                bottom = 0
            }
        }

        MythicPlusTimerCMTimer.frame:SetBackdrop(backdrop)
        MythicPlusTimerCMTimer.frameToggle = true
        MythicPlusTimerCMTimer.frame:Show();
    end
end

-- ---------------------------------------------------------------------------------------------------------------------
function MythicPlusTimerCMTimer:OnComplete()
    if not MythicPlusTimerDB.bestTimes[MythicPlusTimerDB.currentRun.currentZoneID]["_complete"] or MythicPlusTimerDB.currentRun.time < MythicPlusTimerDB.bestTimes[MythicPlusTimerDB.currentRun.currentZoneID]["_complete"] then
        MythicPlusTimerDB.bestTimes[MythicPlusTimerDB.currentRun.currentZoneID]["_complete"] = MythicPlusTimerDB.currentRun.time
    end
    
    if MythicPlusTimerDB.config.objectiveTimeInChat then
        MythicPlusTimer:Print(MythicPlusTimerDB.currentRun.zoneName.." +"..MythicPlusTimerDB.currentRun.cmLevel.." "..MythicPlusTimer.L["Completed"].."! "..MythicPlusTimer.L["Time"]..": "..MythicPlusTimerCMTimer:FormatSeconds(MythicPlusTimerDB.currentRun.time).." "..MythicPlusTimer.L["BestTime"]..": "..MythicPlusTimerCMTimer:FormatSeconds(MythicPlusTimerDB.bestTimes[MythicPlusTimerDB.currentRun.currentZoneID]["_complete"]))
    end
    
    ObjectiveTrackerFrame:Show();
    MythicPlusTimerCMTimer.isCompleted = true;
    MythicPlusTimerCMTimer.frame:Hide();
    ObjectiveTrackerFrame:Show();
    MythicPlusTimerCMTimer:HideObjectivesFrames()

    MythicPlusTimerDB.currentRun = {}
end

-- ---------------------------------------------------------------------------------------------------------------------
function MythicPlusTimerCMTimer:OnStart()
    MythicPlusTimerDB.currentRun = {}
    
    MythicPlusTimerCMTimer.isCompleted = false;
    MythicPlusTimerCMTimer.started = true;
    MythicPlusTimerCMTimer.reset = false;
    
    MythicPlusTimer:StartCMTimer()
end

-- ---------------------------------------------------------------------------------------------------------------------
function MythicPlusTimerCMTimer:OnReset()
    MythicPlusTimerCMTimer.frame:Hide();
    ObjectiveTrackerFrame:Show();
    MythicPlusTimerCMTimer.isCompleted = false;
    MythicPlusTimerCMTimer.started = false;
    MythicPlusTimerCMTimer.reset = true;
    MythicPlusTimerCMTimer:HideObjectivesFrames()

    MythicPlusTimerDB.currentRun = {}
end

-- ---------------------------------------------------------------------------------------------------------------------
function MythicPlusTimerCMTimer:HideObjectivesFrames()
    if MythicPlusTimerCMTimer.frames.objectives then
        for key, _ in pairs(MythicPlusTimerCMTimer.frames.objectives) do
            MythicPlusTimerCMTimer.frames.objectives[key]:Hide()
        end
    end
end


-- ---------------------------------------------------------------------------------------------------------------------
function MythicPlusTimerCMTimer:ReStart()
    local _, _, difficulty, _, _, _, _, _ = GetInstanceInfo();
    local _, timeCM = GetWorldElapsedTime(1);
    
    if difficulty == 8 and timeCM > 0 then
        MythicPlusTimerCMTimer.started = true;
        MythicPlusTimer:StartCMTimer()
        return
    end

    MythicPlusTimerCMTimer.frame:Hide();
    ObjectiveTrackerFrame:Show();
    MythicPlusTimerCMTimer.reset = false
    MythicPlusTimerCMTimer.timerStarted = false
    MythicPlusTimerCMTimer.started = false
    MythicPlusTimerCMTimer.isCompleted = false
    MythicPlusTimerDB.currentRun = {}
    return
end

function MythicPlusTimerCMTimer:OnPlayerDeath()
    local _, _, difficulty, _, _, _, _, _ = GetInstanceInfo();
    local _, timeCM = GetWorldElapsedTime(1);

    if difficulty ~= 8 then
        return
    end
    
    if not MythicPlusTimerCMTimer.started then
        return
    end
    
    if MythicPlusTimerDB.currentRun.death == nil then
        return
    end

    MythicPlusTimerDB.currentRun.death = MythicPlusTimerDB.currentRun.death + 1
end
