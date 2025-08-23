local _, AUP = ...

-- Element variables
local nameFrameWidth = 150
local versionFramePaddingLeft = 10
local versionFramePaddingRight = 40
local elementHeight = 32

local scrollFrame, scrollBar, scrollView, labelFrame
local labels = {} -- Label fontstrings

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

    for displayName in pairs(AUP.highestSeenAuraVersionsTable) do
        table.insert(sortedLabelTable, displayName)
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

            labels[i]:SetFont(AUP.gs.visual.font, 12, AUP.gs.visual.fontFlags)
        end

        labels[i]:SetText(string.format("|cff%s%s|r", AUP.gs.visual.colorStrings.white, displayName))
    end

    PositionAuraLabels(nil, scrollFrame:GetWidth())
end

local function CheckElementInitializer(frame, data)
    local versionFrameCount = #data.waVersionsBehindTable

    -- Create version frames
    if not frame.versionFrames then frame.versionFrames = {} end

    for i = 1, versionFrameCount do
        local subFrame = frame.versionFrames[i] or CreateFrame("Frame", nil, frame)

        subFrame:SetSize(elementHeight, elementHeight)

        frame.versionFrames[i] = subFrame
    end

    if not frame.coloredName then
        frame.coloredName = frame:CreateFontString(nil, "OVERLAY")

        frame.coloredName:SetFont(AUP.gs.visual.font, 18, AUP.gs.visual.fontFlags)
        frame.coloredName:SetPoint("LEFT", frame, "LEFT", 8, 0)
    end

    frame.coloredName:SetText(string.format("|cff%s%s|r", AUP.gs.visual.colorStrings.white, data.coloredName))

    for i, versionInfo in ipairs(data.waVersionsBehindTable) do
        local versionsBehind = versionInfo.versionsBehind
        local versionFrame = frame.versionFrames[i]

        if not versionFrame.versionsBehindText then
            versionFrame.versionsBehindText = versionFrame:CreateFontString(nil, "OVERLAY")

            versionFrame.versionsBehindText:SetFont(AUP.gs.visual.font, 18, AUP.gs.visual.fontFlags)
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

function AUP:InitializeAuraChecker()
    scrollFrame = CreateFrame("Frame", nil, AUP.waCheckWindow, "WowScrollBoxList")
    scrollFrame:SetPoint("TOPLEFT", AUP.waCheckWindow, "TOPLEFT", 4, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", AUP.waCheckWindow, "BOTTOMRIGHT", -24, 4)

    scrollBar = CreateFrame("EventFrame", nil, AUP.waCheckWindow, "MinimalScrollBar")
    scrollBar:SetPoint("TOP", scrollFrame, "TOPRIGHT", 12, 0)
    scrollBar:SetPoint("BOTTOM", scrollFrame, "BOTTOMRIGHT", 12, 16)

    local dataProvider = AUP:GetDataProvider()

    scrollView = CreateScrollBoxListLinearView()
    scrollView:SetDataProvider(dataProvider)

    ScrollUtil.InitScrollBoxListWithScrollBar(scrollFrame, scrollBar, scrollView)

    -- The first argument here can either be a frame type or frame template. We're just passing the "UIPanelButtonTemplate" template here
    scrollView:SetElementExtent(elementHeight)
    scrollView:SetElementInitializer("Frame", CheckElementInitializer)

    -- Border
    local borderColor = AUP.gs.visual.borderColor
    AUP:AddBorder(scrollFrame)
    scrollFrame:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    --register raven event
    AUP.Raven:on("DATA_UPDATED", BuildAuraLabels)
end
