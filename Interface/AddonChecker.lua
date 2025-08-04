local _, AUP = ...

-- Element variables
local nameFrameWidth = 150
local versionFramePaddingLeft = 10
local versionFramePaddingRight = 40
local elementHeight = 32

local scrollFrame, scrollBar, dataProvider, scrollView, labelFrame
local labels = {} -- Label fontstrings
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

local function PositionAuraLabels(_, width)
    local firstVersionFrameX = nameFrameWidth + versionFramePaddingLeft
    local versionFramesTotalWidth = width - firstVersionFrameX - versionFramePaddingRight - elementHeight
    local versionFrameSpacing = versionFramesTotalWidth / (#labels)

    for i, versionFrame in ipairs(labels) do
        versionFrame:SetPoint("BOTTOM", labelFrame, "BOTTOMLEFT",
            firstVersionFrameX + i * versionFrameSpacing + 0.5 * elementHeight, 0)
    end
end

local function BuildAuraLabels()
    if not labelFrame then
        labelFrame = CreateFrame("Frame", nil, AUP.waCheckWindow)
        labelFrame:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", 0, 4)
        labelFrame:SetPoint("BOTTOMRIGHT", scrollFrame, "TOPRIGHT", 0, 4)
        labelFrame:SetHeight(24)

        labelFrame:SetScript("OnSizeChanged", PositionAuraLabels)
    end

    local sortedLabelTable = {}

    for displayName in pairs(AUP.highestSeenVersionsTable) do
        if not AUP:IsAddon(displayName) then
            -- This is a WeakAura, not an add-on
            table.insert(sortedLabelTable, displayName)
        end
    end

    -- Sort the labels (addon version is always first)
    table.sort(
        sortedLabelTable,
        function(dispalyName1, displayName2)
            return dispalyName1 < displayName2
        end
    )

    for i, displayName in ipairs(sortedLabelTable) do
        if not labels[i] then
            labels[i] = labelFrame:CreateFontString(nil, "OVERLAY")

            labels[i]:SetFont(AUP.gs.visual.font, 15, AUP.gs.visual.fontFlags)
        end

        labels[i]:SetText(string.format("|cff%s%s|r", AUP.gs.visual.colorStrings.white, displayName))
    end

    PositionAuraLabels(nil, scrollFrame:GetWidth())
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
        versionsBehindTable = {},
    }

    -- Compare unit's versions against the highest ones we've seen so far
    -- Set version to -1 if no version table was provided (i.e. we have no info for this unit)
    for displayName, highestVersion in pairs(AUP.highestSeenVersionsTable) do
        repeat
            if AUP:IsAddon(displayName) then break end -- This is an add-on, not a WeakAura

            local version = versionsTable and versionsTable[displayName] or 0
            local versionsBehind = versionsTable and highestVersion - version or -1

            table.insert(
                data.versionsBehindTable,
                {
                    displayName = displayName,
                    versionsBehind = versionsBehind
                }
            )
        until true
    end

    -- Sort the aura versions so they match the labels
    table.sort(
        data.versionsBehindTable,
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
        print(GUID)
        local versionsTable = guidToVersionsTable[GUID]

        AUP:UpdateCheckElementForUnit(unit, versionsTable)
    end

    BuildAuraLabels()
end

local function CheckElementInitializer(frame, data)
    local versionFrameCount = #data.versionsBehindTable

    -- Create version frames
    if not frame.versionFrames then frame.versionFrames = {} end

    for i = 1, versionFrameCount do
        local subFrame = frame.versionFrames[i] or CreateFrame("Frame", nil, frame)

        subFrame:SetSize(elementHeight, elementHeight)

        frame.versionFrames[i] = subFrame
    end

    if not frame.coloredName then
        frame.coloredName = frame:CreateFontString(nil, "OVERLAY")

        frame.coloredName:SetFont(AUP.gs.visual.font, 21, AUP.gs.visual.fontFlags)
        frame.coloredName:SetPoint("LEFT", frame, "LEFT", 8, 0)
    end

    frame.coloredName:SetText(string.format("|cff%s%s|r", AUP.gs.visual.colorStrings.white, data.coloredName))

    for i, versionInfo in ipairs(data.versionsBehindTable) do
        local versionsBehind = versionInfo.versionsBehind
        local versionFrame = frame.versionFrames[i]

        if not versionFrame.versionsBehindText then
            versionFrame.versionsBehindText = versionFrame:CreateFontString(nil, "OVERLAY")

            versionFrame.versionsBehindText:SetFont(AUP.gs.visual.font, 21, AUP.gs.visual.fontFlags)
            versionFrame.versionsBehindText:SetPoint("CENTER", versionFrame, "CENTER")
        end

        if not versionFrame.versionsBehindIcon then
            versionFrame.versionsBehindIcon = CreateFrame("Frame", nil, versionFrame)
            versionFrame.versionsBehindIcon:SetSize(24, 24)
            versionFrame.versionsBehindIcon:SetPoint("CENTER", versionFrame, "CENTER")

            versionFrame.versionsBehindIcon.tex = versionFrame.versionsBehindIcon:CreateTexture(nil, "BACKGROUND")
            versionFrame.versionsBehindIcon.tex:SetAllPoints()
        end

        if versionsBehind == 0 then
            versionFrame.versionsBehindText:Hide()
            versionFrame.versionsBehindIcon:Show()

            versionFrame.versionsBehindIcon.tex:SetAtlas("common-icon-checkmark")

            AUP:AddTooltip(
                versionFrame,
                "该玩家的WA都是最新的."
            )
        elseif versionsBehind == -1 then
            versionFrame.versionsBehindText:Hide()
            versionFrame.versionsBehindIcon:Show()

            versionFrame.versionsBehindIcon.tex:SetAtlas("QuestTurnin")

            AUP:AddTooltip(
                versionFrame,
                "无法获取该玩家的WA信息.|n|n可能并没有装AwakeningUpdater插件."
            )
        else
            versionFrame.versionsBehindText:Show()
            versionFrame.versionsBehindIcon:Hide()

            versionFrame.versionsBehindText:SetText(string.format("|cff%s%d|r", AUP.gs.visual.colorStrings.red,
                versionsBehind))

            AUP:AddTooltip(
                versionFrame,
                string.format("此玩家的WA落后%d个版本.", versionsBehind)
            )
        end
    end

    if not frame.PositionVersionFrames then
        function frame.PositionVersionFrames(_, width)
            local firstVersionFrameX = nameFrameWidth + versionFramePaddingLeft
            local versionFramesTotalWidth = width - firstVersionFrameX - versionFramePaddingRight - elementHeight
            local versionFrameSpacing = versionFramesTotalWidth / (#frame.versionFrames)

            for i, versionFrame in ipairs(frame.versionFrames) do
                versionFrame:SetPoint("LEFT", frame, "LEFT", firstVersionFrameX + i * versionFrameSpacing, 0)
            end
        end
    end

    frame.PositionVersionFrames(nil, frame:GetWidth())

    frame:SetScript("OnSizechanged", frame.PositionVersionFrames)
end

function AUP:InitializeAddonChecker()
    scrollFrame = CreateFrame("Frame", nil, AUP.addonCheckWindow, "WowScrollBoxList")
    scrollFrame:SetPoint("TOPLEFT", AUP.addonCheckWindow, "TOPLEFT", 4, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", AUP.addonCheckWindow, "BOTTOMRIGHT", -24, 4)

    scrollBar = CreateFrame("EventFrame", nil, AUP.addonCheckWindow, "MinimalScrollBar")
    scrollBar:SetPoint("TOP", scrollFrame, "TOPRIGHT", 12, 0)
    scrollBar:SetPoint("BOTTOM", scrollFrame, "BOTTOMRIGHT", 12, 16)

    dataProvider = CreateDataProvider()
    scrollView = CreateScrollBoxListLinearView()
    scrollView:SetDataProvider(dataProvider)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollFrame, scrollBar, scrollView)

    -- The first argument here can either be a frame type or frame template. We're just passing the "UIPanelButtonTemplate" template here
    scrollView:SetElementExtent(elementHeight)
    scrollView:SetElementInitializer("Frame", CheckElementInitializer)

    dataProvider:SetSortComparator(
        function(data1, data2)
            local hasInfo1 = next(data1.versionsBehindTable)
            local hasInfo2 = next(data2.versionsBehindTable)

            local versionsBehindCount1 = 0
            local versionsBehindCount2 = 0

            for _, versionInfo in ipairs(data1.versionsBehindTable) do
                versionsBehindCount1 = versionsBehindCount1 + versionInfo.versionsBehind
            end

            for _, versionInfo in ipairs(data2.versionsBehindTable) do
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

    -- Border
    local borderColor = AUP.gs.visual.borderColor
    AUP:AddBorder(scrollFrame)
    scrollFrame:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    AUP:RebuildAllCheckElements()
end
