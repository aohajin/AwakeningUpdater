local _, AUP = ...

-- Element variables
local nameFrameWidth = 150
local versionFramePaddingLeft = 10
local versionFramePaddingRight = 40
local elementHeight = 32

local scrollFrame, scrollBar, scrollView, labelFrame
local labels = {} -- Label fontstrings

local function PositionNoteLabels(_, width)
    local firstVersionFrameX = nameFrameWidth + versionFramePaddingLeft
    local versionFramesTotalWidth = width - firstVersionFrameX - versionFramePaddingRight - elementHeight
    local versionFrameSpacing = versionFramesTotalWidth / (#labels)

    for i, versionFrame in ipairs(labels) do
        versionFrame:SetPoint("BOTTOM", labelFrame, "BOTTOMLEFT",
            firstVersionFrameX + i * versionFrameSpacing + 0.5 * elementHeight, 0)
    end
end

local function BuildNoteLabels()
    if not labelFrame then
        labelFrame = CreateFrame("Frame", nil, AUP.noteCheckWindow)
        labelFrame:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", 0, 4)
        labelFrame:SetPoint("BOTTOMRIGHT", scrollFrame, "TOPRIGHT", 0, 4)
        labelFrame:SetHeight(24)

        labelFrame:SetScript("OnSizeChanged", PositionNoteLabels)
    end

    local sortedLabelTable = {}

    for _, displayName in ipairs(AUP.NotesList) do
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

    PositionNoteLabels(nil, scrollFrame:GetWidth())
end

local function CheckElementInitializer(frame, data)
    local versionFrameCount = #data.noteTable

    -- Create version frames
    if not frame.versionFrames then frame.versionFrames = {} end

    for i = 1, versionFrameCount do
        local subFrame = frame.versionFrames[i] or CreateFrame("Frame", nil, frame)

        subFrame:SetSize(elementHeight, elementHeight)

        frame.versionFrames[i] = subFrame
    end

    if not frame.coloredName then
        frame.coloredName = frame:CreateFontString(nil, "OVERLAY")

        frame.coloredName:SetFont(AUP.gs.visual.font, 15, AUP.gs.visual.fontFlags)
        frame.coloredName:SetPoint("LEFT", frame, "LEFT", 8, 0)
    end

    frame.coloredName:SetText(string.format("|cff%s%s|r", AUP.gs.visual.colorStrings.white, data.coloredName))

    --[[
    data.noteTable = list of below
                {
                    displayName = displayName,
                    note = note,
                }
    ]]
    for i, noteInfo in ipairs(data.noteTable) do
        local unitNote     = noteInfo.unitNote
        local displayName  = noteInfo.displayName

        local myNote       = AUP:GetNsNote()

        local versionFrame = frame.versionFrames[i]

        if not versionFrame.versionsText then
            versionFrame.versionsText = versionFrame:CreateFontString(nil, "OVERLAY")

            versionFrame.versionsText:SetFont(AUP.gs.visual.font, 18, AUP.gs.visual.fontFlags)
            versionFrame.versionsText:SetPoint("CENTER", versionFrame, "CENTER")
        end

        if not versionFrame.versionsIcon then
            versionFrame.versionsIcon = CreateFrame("Frame", nil, versionFrame)
            versionFrame.versionsIcon:SetSize(24, 24)
            versionFrame.versionsIcon:SetPoint("CENTER", versionFrame, "CENTER")

            versionFrame.versionsIcon.tex = versionFrame.versionsIcon:CreateTexture(nil, "BACKGROUND")
            versionFrame.versionsIcon.tex:SetAllPoints()
        end

        -- 四种情况
        -- 未知版本 显示问号
        -- 你自己是empty，显示蓝色"note"
        -- 不同版本 显示红色版本号
        -- 相同版本 显示绿色版本号

        if unitNote == nil then
            versionFrame.versionsText:Hide()
            versionFrame.versionsIcon:Show()

            versionFrame.versionsIcon.tex:SetAtlas("QuestTurnin")

            AUP:AddTooltip(
                versionFrame,
                "无法获取该玩家的战术版信息.|n|n可能并没有装AwakeningUpdater插件."
            )
        elseif myNote == "empty" then
            versionFrame.versionsText:Show()
            versionFrame.versionsIcon:Hide()

            versionFrame.versionsText:SetText(string.format("|cff%s%s|r", AUP.gs.visual.colorStrings.blue, "NOTE"))

            AUP:AddTooltip(
                versionFrame,
                string.format("该玩家的战术板信息是%s，但你的战术板信息为空.", version)
            )
        elseif unitNote ~= myNote then
            versionFrame.versionsText:Show()
            versionFrame.versionsIcon:Hide()

            versionFrame.versionsText:SetText(string.format("|cff%s%s|r", AUP.gs.visual.colorStrings.red,
                "NOTE"))

            AUP:AddTooltip(
                versionFrame,
                string.format("此玩家的战术板信息与你不同，你的是%s，他的是%s", myNote, unitNote)
            )
        else
            versionFrame.versionsText:Hide()
            versionFrame.versionsIcon:Show()

            versionFrame.versionsIcon.tex:SetAtlas("common-icon-checkmark")

            AUP:AddTooltip(
                versionFrame,
                string.format("此玩家的战术板信息与你相同，是%s", myNote)
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

function AUP:InitializeNoteChecker()
    scrollFrame = CreateFrame("Frame", nil, AUP.noteCheckWindow, "WowScrollBoxList")
    scrollFrame:SetPoint("TOPLEFT", AUP.noteCheckWindow, "TOPLEFT", 4, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", AUP.noteCheckWindow, "BOTTOMRIGHT", -24, 4)

    scrollBar = CreateFrame("EventFrame", nil, AUP.noteCheckWindow, "MinimalScrollBar")
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
    AUP.Raven:on("DATA_UPDATED", BuildNoteLabels)
end
