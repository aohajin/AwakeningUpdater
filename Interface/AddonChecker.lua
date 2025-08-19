local _, AUP = ...

-- Element variables
local nameFrameWidth = 150
local versionFramePaddingLeft = 10
local versionFramePaddingRight = 40
local elementHeight = 32

local scrollFrame, scrollBar, scrollView, labelFrame
local labels = {} -- Label fontstrings

local function PositionAddonLabels(_, width)
    local firstVersionFrameX = nameFrameWidth + versionFramePaddingLeft
    local versionFramesTotalWidth = width - firstVersionFrameX - versionFramePaddingRight - elementHeight
    local versionFrameSpacing = versionFramesTotalWidth / (#labels)

    for i, versionFrame in ipairs(labels) do
        versionFrame:SetPoint("BOTTOM", labelFrame, "BOTTOMLEFT",
            firstVersionFrameX + i * versionFrameSpacing + 0.5 * elementHeight, 0)
    end
end

local function BuildAddonLabels()
    if not labelFrame then
        labelFrame = CreateFrame("Frame", nil, AUP.addonCheckWindow)
        labelFrame:SetPoint("BOTTOMLEFT", scrollFrame, "TOPLEFT", 0, 4)
        labelFrame:SetPoint("BOTTOMRIGHT", scrollFrame, "TOPRIGHT", 0, 4)
        labelFrame:SetHeight(24)

        labelFrame:SetScript("OnSizeChanged", PositionAddonLabels)
    end

    local sortedLabelTable = {}

    for _, displayName in ipairs(AUP.AddonsList) do
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

            labels[i]:SetFont(AUP.gs.visual.font, 15, AUP.gs.visual.fontFlags)
        end

        labels[i]:SetText(string.format("|cff%s%s|r", AUP.gs.visual.colorStrings.white, displayName))
    end

    PositionAddonLabels(nil, scrollFrame:GetWidth())
end

local function CheckElementInitializer(frame, data)
    local versionFrameCount = #data.addonTable

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

    --[[
    data.addonTable = list of below
                {
                    displayName = displayName,
                    unitVersion = unitVersion,
                }
    ]]
    for i, versionInfo in ipairs(data.addonTable) do
        local version      = versionInfo.unitVersion
        local displayName  = versionInfo.displayName

        local myVersion    = C_AddOns.GetAddOnMetadata(displayName, "Version") or "None"

        local versionFrame = frame.versionFrames[i]

        if not versionFrame.versionsText then
            versionFrame.versionsText = versionFrame:CreateFontString(nil, "OVERLAY")

            versionFrame.versionsText:SetFont(AUP.gs.visual.font, 21, AUP.gs.visual.fontFlags)
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
        -- 你自己是None，显示蓝色版本号
        -- 不同版本 显示红色版本号
        -- 相同版本 显示绿色版本号

        if version == nil then
            versionFrame.versionsBehindText:Hide()
            versionFrame.versionsBehindIcon:Show()

            versionFrame.versionsBehindIcon.tex:SetAtlas("QuestTurnin")

            AUP:AddTooltip(
                versionFrame,
                "无法获取该玩家的插件信息.|n|n可能并没有装AwakeningUpdater插件."
            )
        elseif myVersion == "None" then
            versionFrame.versionsBehindText:Show()
            versionFrame.versionsBehindIcon:Hide()

            versionFrame.versionsBehindText:SetText(string.format("|cff%s%s|r", AUP.gs.visual.colorStrings.blue, version))

            AUP:AddTooltip(
                versionFrame,
                string.format("该玩家的WA版本是%s，但你没有安装该插件.", version)
            )
        elseif version ~= myVersion then
            versionFrame.versionsBehindText:Show()
            versionFrame.versionsBehindIcon:Hide()

            versionFrame.versionsBehindText:SetText(string.format("|cff%s%d|r", AUP.gs.visual.colorStrings.red,
                version))

            AUP:AddTooltip(
                versionFrame,
                string.format("此玩家的该插件版本与你不同，你的是%s", myVersion)
            )
        else
            versionFrame.versionsBehindText:Hide()
            versionFrame.versionsBehindIcon:Show()

            versionFrame.versionsBehindIcon.tex:SetAtlas("common-icon-checkmark")

            AUP:AddTooltip(
                versionFrame,
                "该玩家的插件版本与你相同."
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
    scrollFrame = CreateFrame("Frame", nil, AUP.addonCheckWindow, "WowScrollBoxList")
    scrollFrame:SetPoint("TOPLEFT", AUP.addonCheckWindow, "TOPLEFT", 4, -32)
    scrollFrame:SetPoint("BOTTOMRIGHT", AUP.addonCheckWindow, "BOTTOMRIGHT", -24, 4)

    scrollBar = CreateFrame("EventFrame", nil, AUP.addonCheckWindow, "MinimalScrollBar")
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
    AUP.Raven:on("DATA_UPDATED", BuildAddonLabels)
end
