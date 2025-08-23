---@diagnostic disable: undefined-field
local addOnName, AUP = ...

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")
local AceComm = LibStub("AceComm-3.0")

local serializedTable
local spacing = 4
local lastUpdate = 0
local updateQueued = false

local auraImportElementPool = {}
local UIDToID = {}  -- Installed aura UIDs to ID (ID is required for WeakAuras.GetData call)
local auraUIDs = {} -- Imported aura UIDs

local allAurasUpdatedText

local function SerializeVersionsTable()
    local versionsTable = {
        --AwakeningUpdater = tonumber(C_AddOns.GetAddOnMetadata(addOnName, "Version")) -- AddOn version
    }
    for _, addon in ipairs(AUP.AddonsList) do
        -- keep the string version
        versionsTable[addon] = C_AddOns.GetAddOnMetadata(addon, "Version")
    end

    for displayName, auraData in pairs(AwakeningUpdaterSaved.WeakAuras) do
        local uid = auraData.d.uid
        local installedAuraID = uid and UIDToID[uid]
        local installedVersion = installedAuraID and WeakAuras.GetData(installedAuraID).AwakeningVersion or 0

        versionsTable[displayName] = installedVersion
    end

    versionsTable["[NsNote]"] = AUP:GetNsNote()

    local serialized = LibSerialize:Serialize(versionsTable)
    local compressed = LibDeflate:CompressDeflate(serialized, { level = 9 })
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)

    serializedTable = encoded

    if not serializedTable then
        AUP:ErrorPrint("could not serialize version table")
    end
end

local function BroadcastVersions(prefix, message, channel, sender)
    if not serializedTable then return end

    AceComm:SendCommMessage("AU_Versions", serializedTable, channel or "GUILD")
end

local function BuildAuraImportElements()
    lastUpdate = GetTime()
    updateQueued = false

    SerializeVersionsTable()

    -- Check which auras require updates
    local aurasToUpdate = {}

    for displayName, highestSeenVersion in pairs(AUP.highestSeenAuraVersionsTable) do
        repeat
            local auraData = AwakeningUpdaterSaved.WeakAuras[displayName]
            local uid = auraData and auraData.d.uid
            local importedVersion = auraData and auraData.d.AwakeningVersion or 0
            local installedAuraID = uid and UIDToID[uid]
            local installedVersion = installedAuraID and WeakAuras.GetData(installedAuraID).AwakeningVersion or 0

            if installedVersion < importedVersion then
                table.insert(
                    aurasToUpdate,
                    {
                        displayName = displayName,
                        installedVersion = installedVersion,
                        importedVersion = importedVersion,
                        highestSeenVersion = highestSeenVersion
                    }
                )
            end
        until true
    end

    table.sort(
        aurasToUpdate,
        function(auraData1, auraData2)
            local versionsBehind1 = auraData1.highestSeenVersion - auraData1.installedVersion
            local versionsBehind2 = auraData2.highestSeenVersion - auraData2.installedVersion

            if versionsBehind1 ~= versionsBehind2 then
                return versionsBehind1 > versionsBehind2
            else
                return auraData1.displayName < auraData2.displayName
            end
        end
    )

    -- Build the aura import elements
    local parent = AUP.updateWindow

    for _, element in ipairs(auraImportElementPool) do
        element:Hide()
    end

    for i, auraData in ipairs(aurasToUpdate) do
        local auraImportFrame = auraImportElementPool[i] or AUP:CreateAuraImportElement(parent)

        auraImportFrame:SetDisplayName(auraData.displayName)
        auraImportFrame:SetVersionsBehind(auraData.highestSeenVersion - auraData.installedVersion)
        auraImportFrame:SetRequiresAddOnUpdate(auraData.highestSeenVersion > auraData.importedVersion)

        auraImportFrame:Show()
        auraImportFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", spacing,
            -(i - 1) * (auraImportFrame.height + spacing) - spacing)
        auraImportFrame:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -spacing,
            -(i - 1) * (auraImportFrame.height + spacing) - spacing)

        auraImportElementPool[i] = auraImportFrame
    end

    if next(aurasToUpdate) then
        allAurasUpdatedText:Hide()
    else
        allAurasUpdatedText:Show()
    end

    BroadcastVersions()
end

local function QueueUpdate()
    if updateQueued then return end

    -- Don't update more than once per second
    -- This is mostly to prevent the update function from running when a large number of auras get added simultaneously
    local timeSinceLastUpdate = GetTime() - lastUpdate

    if timeSinceLastUpdate > 1 then
        BuildAuraImportElements()
    else
        updateQueued = true

        C_Timer.After(1 - timeSinceLastUpdate, BuildAuraImportElements)
    end
end

local function RequestVersions(chatType)
    AceComm:SendCommMessage("AU_Request", " ", chatType or "GUILD")
end

local function ReceiveVersions(_, payload, _, sender)
    local shouldFullRebuild = false -- Whether all check elements should be rebuilt. Only happens if a new version is seen.
    local decoded = LibDeflate:DecodeForWoWAddonChannel(payload)

    if not decoded then
        AUP:ErrorPrint(string.format("could not decode version table received from %s", sender))

        return
    end

    local decompressed = LibDeflate:DecompressDeflate(decoded)

    if not decoded then
        AUP:ErrorPrint(string.format("could not decompress version table received from %s", sender))

        return
    end

    local success, versionsTable = LibSerialize:Deserialize(decompressed)

    if not success then
        AUP:ErrorPrint(string.format("could not deserialize version table received from %s", sender))

        return
    end

    for displayName, version in pairs(versionsTable) do
        if not AUP:IsAddon(displayName) then
            --     -- check addon version
            --     local myVersion = AUP.addonVersionDiffTable[displayName].myVersion or "None"

            --     if version ~= myVersion then
            --         table.insert(
            --             AUP.addonVersionDiffTable[displayName].diff,
            --             {
            --                 sender = sender,
            --                 version = version
            --             }
            --         )

            --         shouldFullRebuild = true
            --     end
            -- else
            --
            -- check wa version
            local highestSeenVersion = AUP.highestSeenAuraVersionsTable[displayName]
            if not highestSeenVersion or highestSeenVersion < version then
                AUP.highestSeenAuraVersionsTable[displayName] = version

                shouldFullRebuild = true
            end
        end
    end

    if shouldFullRebuild then
        BuildAuraImportElements()

        AUP:RebuildAllCheckElements()
    else
        AUP:UpdateCheckElementForUnit(sender, versionsTable)
    end
end

function AUP:InitializeAuraUpdater()
    AceComm:RegisterComm("AU_Request", BroadcastVersions)
    AceComm:RegisterComm("AU_Versions", ReceiveVersions)


    AUP.highestSeenAuraVersionsTable = {}
    -- AUP.addonVersionDiffTable = {}

    -- for _, addon in ipairs(AUP.AddonsList) do
    --     -- keep the string version
    --     -- first is your version
    --     AUP.addonVersionDiffTable[addon] = {
    --         myVersion = C_AddOns.GetAddOnMetadata(addon, "Version") or "None",
    --         diff = {}
    --     }
    -- end
    for displayName, auraData in pairs(AwakeningUpdaterSaved.WeakAuras) do
        auraUIDs[auraData.d.uid] = true

        print(displayName)

        AUP.highestSeenAuraVersionsTable[displayName] = auraData.d.AwakeningVersion
    end

    if WeakAuras and WeakAurasSaved and WeakAurasSaved.displays then
        for id, auraData in pairs(WeakAurasSaved.displays) do
            UIDToID[auraData.uid] = id
        end

        hooksecurefunc(
            WeakAuras,
            "Add",
            function(data)
                local uid = data.uid

                if uid and auraUIDs[uid] then
                    UIDToID[uid] = data.id

                    QueueUpdate()
                end
            end
        )

        hooksecurefunc(
            WeakAuras,
            "Rename",
            function(data, newID)
                local uid = data.uid

                if uid and auraUIDs[uid] then
                    UIDToID[uid] = newID
                end
            end
        )

        hooksecurefunc(
            WeakAuras,
            "Delete",
            function(data)
                local uid = data.uid

                if UIDToID[uid] then
                    UIDToID[uid] = nil

                    QueueUpdate()
                end
            end
        )
    end

    allAurasUpdatedText = AUP.updateWindow:CreateFontString(nil, "OVERLAY")

    allAurasUpdatedText:SetFont(AUP.gs.visual.font, 18, AUP.gs.visual.fontFlags)
    allAurasUpdatedText:SetPoint("CENTER", AUP.updateWindow, "CENTER")
    allAurasUpdatedText:SetText(string.format("|cff%s已全部最新|r", AUP.gs.visual.colorStrings.green))

    BuildAuraImportElements()
    RequestVersions()
end

local function OnEvent(_, event)
    if event == "GROUP_ROSTER_UPDATE" then
        AUP:RemoveCheckElementsForInvalidUnits()
        AUP:AddCheckElementsForNewUnits()
    elseif event == "GROUP_JOINED" then
        local chatType = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or "PARTY"

        RequestVersions(chatType)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("GROUP_JOINED")
f:SetScript("OnEvent", OnEvent)
