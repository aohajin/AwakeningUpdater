local _, AUP = ...
local dataProvider
local guidToVersionsTable = {}


-- Checks a unit's new version table against their known one
-- Returns true if something changed
local function ShouldUpdate(GUID, newVersionsTable)
    local oldVersionsTable = guidToVersionsTable[GUID]

    if not oldVersionsTable then return true end
    if not newVersionsTable then return false end

    for k, v in pairs(oldVersionsTable) do
        if v ~= newVersionsTable[k] then return true end
    end

    for k, v in pairs(newVersionsTable) do
        if v ~= oldVersionsTable[k] then return true end
    end

    return false
end

function AUP:UpdateCheckElementForUnit(unit, versionsTable)
    local GUID = UnitGUID(unit)

    if not GUID then return end
    if not ShouldUpdate(GUID, versionsTable) then return end

    guidToVersionsTable[GUID] = versionsTable or {} -- Save for use in RebuildAllCheckElements()

    -- If this unit already has an element, remove it
    dataProvider:RemoveByPredicate(
        function(elementData)
            return elementData.GUID == GUID
        end
    )

    -- Create new data
    local _, class, _, _, _, name = GetPlayerInfoByGUID(GUID)

    if not (class and name) then return end

    local colorStr = RAID_CLASS_COLORS[class].colorStr
    local coloredName = string.format("|c%s%s|r", colorStr, name)

    local data = {
        GUID = GUID,
        unit = unit,
        name = name, -- Used for sorting
        coloredName = coloredName,
        waVersionsBehindTable = {},
        addonTable = {},
        noteTable = {},

        --TODO
    }

    -- Compare unit's versions against the highest ones we've seen so far
    -- Set version to -1 if no version table was provided (i.e. we have no info for this unit)
    for displayName, highestVersion in pairs(AUP.highestSeenAuraVersionsTable) do
        print(displayName, highestVersion)
        local version = versionsTable and versionsTable[displayName] or 0
        local versionsBehind = versionsTable and highestVersion - version or -1

        table.insert(
            data.waVersionsBehindTable,
            {
                displayName = displayName,
                versionsBehind = versionsBehind
            }
        )
    end

    --[[AUP.addonVersionDiffTable = map addon name of below
        {
            myVersion = C_AddOns.GetAddOnMetadata(addon, "Version") or "None",
            diff = {
                {
                    sender = sender,
                    version = version
                }
            }
        }
    ]]
    for _, displayName in ipairs(AUP.AddonsList) do
        -- no versionTable means that player dont have au addon
        local unitVersion = versionsTable and versionsTable[displayName] or nil
        table.insert(
            data.addonTable,
            {
                displayName = displayName,
                unitVersion = unitVersion,
            }
        )
    end

    for _, displayName in ipairs(AUP.NotesList) do
        -- no versionTable means that player dont have au addon
        local unitNote = versionsTable and versionsTable[displayName] or nil
        table.insert(
            data.noteTable,
            {
                displayName = displayName,
                unitNote = unitNote,
            }
        )
    end

    -- Sort the aura versions so they match the labels
    table.sort(
        data.waVersionsBehindTable,
        function(info1, info2)
            return info1.displayName < info2.displayName
        end
    )

    table.sort(
        data.addonTable,
        function(info1, info2)
            return info1.displayName < info2.displayName
        end
    )

    dataProvider:Insert(data)
end

function AUP:AddCheckElementsForNewUnits()
    for unit in AUP:IterateGroupMembers() do
        local GUID = UnitGUID(unit)

        if not guidToVersionsTable[GUID] then
            AUP:UpdateCheckElementForUnit(unit)
        end
    end
end

-- Iterates existing elements, and removes those whose units are no longer in our group
function AUP:RemoveCheckElementsForInvalidUnits()
    for i, data in dataProvider:ReverseEnumerate() do
        local unit = data.unit

        if not UnitExists(unit) then
            guidToVersionsTable[data.GUID] = nil

            dataProvider:RemoveIndex(i)
        end
    end
end

function AUP:RebuildAllCheckElements()
    for unit in AUP:IterateGroupMembers() do
        local GUID = UnitGUID(unit)
        --print(GUID)
        local versionsTable = guidToVersionsTable[GUID]

        AUP:UpdateCheckElementForUnit(unit, versionsTable)
    end

    AUP.Raven:emit("DATA_UPDATED")
end

function AUP:InitializeCheckerDataProvider()
    dataProvider = CreateDataProvider()

    dataProvider:SetSortComparator(
        function(data1, data2)
            local hasInfo1 = next(data1.waVersionsBehindTable)
            local hasInfo2 = next(data2.waVersionsBehindTable)

            local versionsBehindCount1 = 0
            local versionsBehindCount2 = 0

            for _, versionInfo in ipairs(data1.waVersionsBehindTable) do
                versionsBehindCount1 = versionsBehindCount1 + versionInfo.versionsBehind
            end

            for _, versionInfo in ipairs(data2.waVersionsBehindTable) do
                versionsBehindCount2 = versionsBehindCount2 + versionInfo.versionsBehind
            end

            if hasInfo1 ~= hasInfo2 then
                return hasInfo1
            elseif versionsBehindCount1 ~= versionsBehindCount2 then
                return versionsBehindCount1 > versionsBehindCount2
            else
                return data1.name < data2.name
            end
        end
    )
end

function AUP:GetDataProvider()
    return dataProvider
end
