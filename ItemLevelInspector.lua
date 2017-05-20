local addonName, addon = ...
local E = addon:Eve()

local CACHE_TIMEOUT = 5

local GuidCache = {}
local ActiveGUID
local ScannedGUID 
local INSPECT_TIMEOUT = 1.5

local function GetUnitIDFromGUID(guid)
	local _, _, _, _, _, name = GetPlayerInfoByGUID(guid)
	if UnitExists(name) then 
		return name, name
	elseif UnitGUID('mouseover') == guid then 
		return 'mouseover', name
	elseif UnitGUID('target') == guid then
		return 'target', name
	elseif GetCVar('nameplateShowFriends') == '1' then 
		for i = 1, 30 do
			local unitID = 'nameplate' .. i
			local nameplateGUID = UnitGUID(unitID)
			if nameplateGUID then
				if nameplateGUID == guid then
					return unitID, name
				end
			else
				break
			end
		end
	else 
		local numMembers = GetNumGroupMembers()
		if numMembers > 0 then
			local unitPrefix = IsInRaid() and 'raid' or 'party'
			if unitPrefix == 'party' then numMembers = numMembers - 1 end
			for i = 1, numMembers do
				local unitID = unitPrefix .. i .. '-target'
				local targetGUID = UnitGUID(unitID)
				if targetGUID == guid then
					return unitID, name
				end
			end
		end
	end
	return nil, name
end

local function ColorGradient(perc, r1, g1, b1, r2, g2, b2)
	if perc >= 1 then
		local r, g, b = r2, g2, b2 
		return r, g, b
	elseif perc <= 0 then
		local r, g, b = r1, g1, b1
		return r, g, b
	end
	
	return r1 + (r2 - r1) * perc, g1 + (g2 - g1) * perc, b1 + (b2 - b1) * perc
end

local function ColorDiff(a, b)
	local diff = a - b
	local perc = diff / 30
	
	local r, g, b
	if perc < 0 then 
		perc = perc * -1
		r, g, b = ColorGradient(perc, 1, 1, 0, 0, 1, 0)
	else
		r, g, b = ColorGradient(perc, 1, 1, 0, 1, 0, 0)
	end
	return r, g, b
end

local ItemLevelPattern1 = ITEM_LEVEL:gsub('%%d', '(%%d+)')
local ItemLevelPattern2 = ITEM_LEVEL_ALT:gsub('([()])', '%%%1'):gsub('%%d', '(%%d+)')

local TwoHanders = {
	
	['INVTYPE_RANGED'] = true,
	['INVTYPE_RANGEDRIGHT'] = true,
	['INVTYPE_2HWEAPON'] = true,
}

local InventorySlots = {}
for i = 1, 17 do
	if i ~= 4 then 
		tinsert(InventorySlots, i)
	end
end

local function IsArtifact(itemLink)
	return itemLink:find('|cffe6cc80') 

local function IsCached(itemLink) 
	local cached = true
	local _, itemID, _, relic1, relic2, relic3 = strsplit(':', itemLink)
	if not GetDetailedItemLevelInfo(itemID) then cached = false end
	if IsArtifact(itemLink) then
		if relic1 and relic1 ~= '' and not GetDetailedItemLevelInfo(relic1) then cached = false end
		if relic2 and relic2 ~= '' and not GetDetailedItemLevelInfo(relic2) then cached = false end
		if relic3 and relic3 ~= '' and not GetDetailedItemLevelInfo(relic3) then cached = false end
	end
	return cached
end

local Sekret = '|Hilvl|h'
local function AddLine(leftText, rightText, r1, g1, b1, r2, g2, b2, dontShow)

		if not r1 then
			r1, g1, b1, r2, g2, b2 = 1, 1, 0, 1, 1, 0
		end
		leftText = Sekret .. leftText
		for i = 2, GameTooltip:NumLines() do
			local leftStr = _G['GameTooltipTextLeft' .. i]
			local text = leftStr and leftStr:IsShown() and leftStr:GetText()
			if text and text:find(Sekret) then
				
				local rightStr = _G['GameTooltipTextRight' .. i]
				leftStr:SetText(leftText)
				rightStr:SetText(rightText)
				if r1 and g1 and b1 then
					leftStr:SetTextColor(r1, g1, b1)
				end
				if r2 and g2 and b2 then
					rightStr:SetTextColor(r2, g2, b2)
				end
				return
			end
		end
		if not dontShow or GameTooltip:IsShown() then
			GameTooltip:AddDoubleLine(leftText, rightText, r1, g1, b1, r2, g2, b2)
			GameTooltip:Show()
		end
end

local SlotCache = {}
local ItemCache = {} 
local TestTips = {}
for i, slot in pairs(InventorySlots) do
	local tip = CreateFrame('GameTooltip', 'AverageItemLevelTooltip' .. slot, nil, 'GameTooltipTemplate')
	tip:SetOwner(WorldFrame, 'ANCHOR_NONE')
	TestTips[slot] = tip
	tip.slot = slot
	tip:SetScript('OnTooltipSetItem', function(self)
		local slot = self.slot
		local _, itemLink = self:GetItem()
		local tipName = self:GetName()
		if slot == 16 and (_ == '' or not _) and self.itemLink then 
			itemLink = self.itemLink
		end
				for i = 2, self:NumLines() do
					local str = _G[tipName .. 'TextLeft' .. i]
					local text = str and str:GetText()
					if text then
						local ilevel = text:match(ItemLevelPattern1)
						if not ilevel then
							ilevel = text:match(ItemLevelPattern2)
						end
						if ilevel then
							SlotCache[slot] = ilevel
							ItemCache[slot] = itemLink
						end
					end
				end
		
		local finished = true
		local totalItemLevel = 0
		
		for slot, ilevel in pairs(SlotCache) do
			if not ilevel then
				finished = false
				break
			else
				if slot ~= 16 and slot ~= 17 then
					totalItemLevel = totalItemLevel + ilevel
				end
			end
		end
		
		if finished then
			local weaponLevel = 0
			if SlotCache[16] and SlotCache[17] then 
				if IsArtifact(ItemCache[16]) or IsArtifact(ItemCache[17]) then -- 
					local ilevelMain = SlotCache[16]
					local ilevelOff = SlotCache[17]
					if ilevelMain > ilevelOff then
						totalItemLevel = totalItemLevel + (ilevelMain * 2)
						weaponLevel = ilevelMain
					else
						totalItemLevel = totalItemLevel + (ilevelOff * 2)
						weaponLevel = ilevelOff
					end
				else
					local ilevelMain = SlotCache[16]
					local ilevelOff = SlotCache[17]
					totalItemLevel = totalItemLevel + ilevelMain + ilevelOff
					if ilevelMain > ilevelOff then
						weaponLevel = ilevelMain
					else
						weaponLevel = ilevelOff
					end
				end
			elseif SlotCache[16] then 
				local _, _, _, weaponType = GetItemInfoInstant(ItemCache[16])
				local ilevelMain = SlotCache[16]
				weaponLevel = ilevelMain
				if TwoHanders[weaponType] then 
					totalItemLevel = totalItemLevel + (ilevelMain * 2)
				else
					totalItemLevel = totalItemLevel + ilevelMain
				end
			elseif SlotCache[17] then 
				local ilevelOff = SlotCache[17]
				totalItemLevel = totalItemLevel + ilevelOff
				weaponLevel = ilevelOff
			end
			
			
			local averageItemLevel = totalItemLevel / 16
			
			local guid = ScannedGUID
			if not GuidCache[guid] then GuidCache[guid] = {} end

			GuidCache[guid].ilevel = averageItemLevel
			GuidCache[guid].weaponLevel = weaponLevel
			GuidCache[guid].timestamp = GetTime()
			
			E('ITEM_SCAN_COMPLETE', guid, GuidCache[guid])
		end
	end)
end

local function GetTooltipGUID()
	
		local _, unitID = GameTooltip:GetUnit()
		local guid = unitID and UnitGUID(unitID)
		if UnitIsPlayer(unitID) and CanInspect(unitID) then
			return guid
		end
	
end

local f = CreateFrame('frame', nil, GameTooltip)
local ShouldInspect = false
local LastInspect = 0
local FailTimeout = 1
f:SetScript('OnUpdate', function(self, elapsed)
	local _, unitID = GameTooltip:GetUnit()
	local guid = unitID and UnitGUID(unitID)
	if not guid or (InspectFrame and InspectFrame:IsVisible()) then return end
	local timeSince = GetTime() - LastInspect
	if ShouldInspect and (ActiveGUID == guid or (timeSince >= INSPECT_TIMEOUT)) then
		ShouldInspect = false
		
		if ActiveGUID ~= guid then 
			local cache = GuidCache[guid]
			if cache and GetTime() - cache.timestamp <= CACHE_TIMEOUT then 
				print('Still cached')
			elseif CanInspect(unitID) then
				NotifyInspect(unitID)
			end
		end
	elseif ShouldInspect and (timeSince < INSPECT_TIMEOUT) then 
		if unitID and UnitIsPlayer(unitID) and CanInspect(unitID) and not GuidCache[ guid ]then
			AddLine('Pending', format('%.1fs', INSPECT_TIMEOUT - (GetTime() - LastInspect)), 0.6, 0.6, 0.6, 0.6, 0.6, 0.6)
		end
	else
		if ActiveGUID then
			if guid == ActiveGUID then
				if timeSince <= FailTimeout then
					AddLine('Scanning', format('%d%%', timeSince / FailTimeout * 100), 0.6, 0.6, 0.6, 0.6, 0.6, 0.6)
				else
					AddLine('Scanning', 'Failed', 0.6, 0.6, 0.6, 0.6, 0.6, 0.6)
					ActiveGUID = nil
				end
			else
				ActiveGUID = nil
				
				if timeSince > FailTimeout and CanInspect(unitID) then
					NotifyInspect(unitID) 
				end
			end
		end
	end
end)

hooksecurefunc('NotifyInspect', function(unitID)
	print('NotifyInspect!', unitID, UnitGUID(unitID), (select(6, GetPlayerInfoByGUID(UnitGUID(unitID)))))
	if not GuidCache[UnitGUID(unitID)] then
		ActiveGUID = UnitGUID(unitID)
	end
	LastInspect = GetTime()
end)

hooksecurefunc('ClearInspectPlayer', function()
	ActiveGUID = nil
end)

local function DoInspect()
	ShouldInspect = true
end

