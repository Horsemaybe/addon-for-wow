MythicPlusTimer = LibStub("AceAddon-3.0"):NewAddon("MythicPlusTimer", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0");

function MythicPlusTimer:OnInitialize()
    if MythicPlusTimerDB == nil then
        MythicPlusTimerDB = {}
    end
    
    if not MythicPlusTimerDB.config then
        MythicPlusTimerDB.config = {
            objectiveTime = true,
            deathCounter = false,
            objectiveTimeInChat = true,
        } 
    end
    
    if MythicPlusTimerDB.config.objectiveTimeInChat == nil then
        MythicPlusTimerDB.config.objectiveTimeInChat = true
    end

    if not MythicPlusTimerDB.currentRun then
        MythicPlusTimerDB.currentRun = {} 
    end

    MythicPlusTimer.L = LibStub("AceLocale-3.0"):GetLocale("MythicPlusTimer")

    local options = {
        name = "MythicPlusTimer",
        handler = MythicPlusTimerDB,
        type = "group",
        args = {
            objectivetimeschat = {
                type = "toggle",
                name = MythicPlusTimer.L["ObjectiveTimesInChat"],
                desc = MythicPlusTimer.L["ObjectiveTimesInChatDesc"],
                get = function(info,val) return MythicPlusTimerDB.config.objectiveTimeInChat  end,
                set = function(info,val)  MythicPlusTimerDB.config.objectiveTimeInChat = val end,
                width = "full"
            },
            objectivetimes = {
                type = "toggle",
                name = MythicPlusTimer.L["ObjectiveTimes"],
                desc = MythicPlusTimer.L["ObjectiveTimesDesc"],
                get = function(info,val) return MythicPlusTimerDB.config.objectiveTime  end,
                set = function(info,val)  MythicPlusTimerDB.config.objectiveTime = val end,
                width = "full"
            },
            deathcounter = {
                type = "toggle",
                name = MythicPlusTimer.L["DeathCounter"],
                desc = MythicPlusTimer.L["DeathCounterDesc"],
                get = function(info,val) return MythicPlusTimerDB.config.deathCounter  end,
                set = function(info,val)  MythicPlusTimerDB.config.deathCounter = val end,
                width = "full"
            },
            resetbesttimes = {
                type = "execute",
                name = MythicPlusTimer.L["DeleteBestTimes"],
                desc = MythicPlusTimer.L["DeleteBestTimesRecords"],
                func = function(info) MythicPlusTimerDB.bestTimes = {} end,
                width = "full"
            },
        },
    }

    LibStub("AceConfig-3.0"):RegisterOptionsTable("MythicPlusTimer", options)
    LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MythicPlusTimer", "MythicPlusTimer")
    
    
    MythicPlusTimerCMTimer:Init();
end
