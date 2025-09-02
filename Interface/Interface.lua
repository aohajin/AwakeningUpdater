local addOnName, AUP = ...

-- Tooltip
CreateFrame("GameTooltip", "AuTooltip", UIParent, "GameTooltipTemplate")

AUP.Tooltip = _G["AuTooltip"]
AUP.Tooltip.TextLeft1:SetFont(AUP.gs.visual.font, 13)

local windowWidth, windowHeight = 720, 480

function AUP:InitializeInterface()
    local screenWidth, screenHeight = GetPhysicalScreenSize()

    -- 主窗口
    AUP.window = AUP:CreateWindow("覺 醒 Raid Tools", true, true, true)
    AUP.window:SetFrameStrata("HIGH")
    AUP.window:SetResizeBounds(windowWidth, windowHeight)
    AUP.window:Hide()


    -- 按钮框架
    local buttonFrame = CreateFrame("Frame", nil, AUP.window)
    buttonFrame:SetPoint("TOPLEFT", AUP.window.TitleBg, "BOTTOMLEFT")
    buttonFrame:SetPoint("TOPRIGHT", AUP.window.TitleBg, "BOTTOMRIGHT")
    buttonFrame:SetHeight(45)

    -- 子面板
    AUP.updateWindow = CreateFrame("Frame", nil, AUP.window)
    AUP.updateWindow:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT")
    AUP.updateWindow:SetPoint("BOTTOMRIGHT", AUP.window, "BOTTOMRIGHT")

    AUP.waCheckWindow = CreateFrame("Frame", nil, AUP.window)
    AUP.waCheckWindow:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT")
    AUP.waCheckWindow:SetPoint("BOTTOMRIGHT", AUP.window, "BOTTOMRIGHT")
    AUP.waCheckWindow:Hide()

    AUP.addonCheckWindow = CreateFrame("Frame", nil, AUP.window)
    AUP.addonCheckWindow:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT")
    AUP.addonCheckWindow:SetPoint("BOTTOMRIGHT", AUP.window, "BOTTOMRIGHT")
    AUP.addonCheckWindow:Hide()

    AUP.noteCheckWindow = CreateFrame("Frame", nil, AUP.window)
    AUP.noteCheckWindow:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT")
    AUP.noteCheckWindow:SetPoint("BOTTOMRIGHT", AUP.window, "BOTTOMRIGHT")
    AUP.noteCheckWindow:Hide()

    -- 面板配置
    local panelDefinitions = {
        { label = "WA更新", panel = AUP.updateWindow, color = AUP.gs.visual.colorStrings.white },
        { label = "WA检查", panel = AUP.waCheckWindow, color = AUP.gs.visual.colorStrings.white },
        { label = "插件检查", panel = AUP.addonCheckWindow, color = AUP.gs.visual.colorStrings.white },
        { label = "战术板检查", panel = AUP.noteCheckWindow, color = AUP.gs.visual.colorStrings.white },
    }

    -- 自动生成按钮组
    AUP:CreateButtonPanelGroup(buttonFrame, panelDefinitions, 8, 4)

    -- 初始位置
    local windowSettings = AwakeningUpdaterSaved.settings.frames["Main"]
    if not windowSettings or not windowSettings.points then
        AUP.window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (screenWidth - windowWidth) / 2,
            -(screenHeight - windowHeight) / 2)
    end
    if not windowSettings or not windowSettings.width then
        AUP.window:SetSize(windowWidth, windowHeight)
    end

    -- 初始化完延迟布局一帧，确保尺寸有效
    C_Timer.After(0, function()
        if AUP.buttonFrame and AUP.buttonGroup then
            AUP:Layout_Horizontal_Equal(AUP.buttonFrame, AUP.buttonGroup, 8, 4)
        end
    end)
    -- 窗口大小变化时，自动重布局
    AUP.window:SetScript("OnSizeChanged", function(self, width, height)
        if AUP.buttonFrame and AUP.buttonGroup then
            AUP:Layout_Horizontal_Equal(AUP.buttonFrame, AUP.buttonGroup, 8, 4)
        end
    end)
end

-- 水平平分布局
function AUP:Layout_Horizontal_Equal(frame, children, padding, spacing)
    local count = #children
    if count == 0 then return end

    padding = padding or 0
    spacing = spacing or 0

    local totalSpacing = spacing * (count - 1)
    local availableWidth = frame:GetWidth() - padding * 2 - totalSpacing
    local buttonWidth = availableWidth / count
    local buttonHeight = frame:GetHeight() - padding * 2

    local currentX = padding

    for i, child in ipairs(children) do
        child:ClearAllPoints()
        child:SetPoint("TOPLEFT", frame, "TOPLEFT", currentX, -padding)
        child:SetSize(buttonWidth, buttonHeight)
        currentX = currentX + buttonWidth + spacing
    end
end

-- 面板切换+按钮高亮
function AUP:BindPanelSwitch(button, targetPanel, panelsToHide, buttonGroup)
    button:SetScript("OnMouseDown", function()
        for _, panel in ipairs(panelsToHide) do panel:Hide() end
        targetPanel:Show()

        for _, btn in ipairs(buttonGroup) do
            if btn == button then
                btn:SetBorderColor(1, 0.8, 0.1) -- 选中金黄
                btn.highlight:SetColorTexture(1, 0.8, 0.1, 0.08)
            else
                local borderColor = AUP.gs.visual.borderColor
                btn:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)
                btn.highlight:SetColorTexture(1, 1, 1, 0.05)
            end
        end
    end)
end

-- 自动生成按钮+事件+布局
function AUP:CreateButtonPanelGroup(parentFrame, panelDefs, padding, spacing)
    local borderColor = AUP.gs.visual.borderColor
    local buttons = {}

    for _, def in ipairs(panelDefs) do
        local button = CreateFrame("Frame", nil, parentFrame:GetParent())
        button:EnableMouse(true)

        button.highlight = button:CreateTexture(nil, "HIGHLIGHT")
        button.highlight:SetColorTexture(1, 1, 1, 0.05)
        button.highlight:SetAllPoints()

        button.text = button:CreateFontString(nil, "OVERLAY")
        button.text:SetFont(AUP.gs.visual.font, 15, AUP.gs.visual.fontFlags)
        button.text:SetPoint("CENTER", button, "CENTER")
        button.text:SetText(string.format("|cff%s%s|r", def.color, def.label))

        AUP:AddBorder(button)
        button:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

        table.insert(buttons, button)
    end

    -- 绑定事件
    for i, def in ipairs(panelDefs) do
        local button = buttons[i]
        local panelsToHide = {}
        for j, otherDef in ipairs(panelDefs) do
            if otherDef.panel ~= def.panel then table.insert(panelsToHide, otherDef.panel) end
        end
        AUP:BindPanelSwitch(button, def.panel, panelsToHide, buttons)
    end

    -- 自动布局
    AUP:Layout_Horizontal_Equal(parentFrame, buttons, padding, spacing)

    -- 默认第一个按钮高亮
    buttons[1]:GetScript("OnMouseDown")()

    -- 保存下来用于后续动态布局
    AUP.buttonFrame = parentFrame
    AUP.buttonGroup = buttons
end
