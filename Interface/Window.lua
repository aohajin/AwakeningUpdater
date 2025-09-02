local _, AUP = ...

local buttonSize = 16
local buttonMargin = 2
local moverFrameHeight = buttonSize + 2 * buttonMargin + 4


--[[
    AUP:CreateWindow(name, exitable, movable, resizable, opts)
    - name: 用于保存/恢复位置与尺寸的键；传 nil 则不保存
    - exitable: 是否显示默认关闭按钮
    - movable: 是否可拖动（仅标题栏区域）
    - resizable: 是否允许右下角拖拽改变大小
    - opts: 可选项表：
        - width, height: 初始尺寸，默认 480x320
        - title: 标题文本，默认 "Awakening Updater"
        - anchor: {point, relativeTo, relativePoint, x, y} 初始锚点，默认居中
        - withScroll: boolean，是否在 Inset 内创建一个默认滚动区域，默认 true
        - minWidth, minHeight: 允许调整的最小尺寸，默认 320x200
]]
function AUP:CreateWindow(name, exitable, movable, resizable)
    -- 使用默认外观
    local window = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")

    -- 默认尺寸与位置（实际会被 Restore 覆盖）
    window:SetSize(720, 480)
    window:SetPoint("CENTER")

    -- 标题（模板自带 TitleText）
    if window.TitleText then
        window.TitleText:SetText(name or "Awakening Updater")
        window.TitleText:SetMaxLines(1)
    end

    -- 关闭按钮（模板自带 CloseButton）
    if window.CloseButton then
        if exitable == false then
            window.CloseButton:Hide()
        else
            window.CloseButton:Show()
            window.CloseButton:SetScript("OnClick", function() window:Hide() end)
        end
    end

    ------------------------------------------------------------
    -- 按钮组 & 背板（保留原 API 语义）
    ------------------------------------------------------------
    window.buttons = {}

    -- 用于吃掉标题栏右上角空隙，防止鼠标穿透
    window.buttonBackground = CreateFrame("Button", nil, window)
    window.buttonBackground:SetFrameLevel(window:GetFrameLevel() + 2)
    window.buttonBackground:SetPoint("TOPRIGHT", window)
    window.buttonBackground:SetSize(1, moverFrameHeight) -- 实际宽度随按钮数量更新

    function window:AddButton(texture, onClick)
        local button = CreateFrame("Button", nil, window)
        button:SetSize(buttonSize, buttonSize)
        button:SetFrameLevel(window:GetFrameLevel() + 3)

        -- 布局：从 CloseButton 向左排，如果没有 CloseButton 就贴窗口右上角
        if #window.buttons == 0 then
            if window.CloseButton and window.CloseButton:IsShown() then
                button:SetPoint("RIGHT", window.CloseButton, "LEFT", -buttonMargin, 0)
            else
                button:SetPoint("TOPRIGHT", window, "TOPRIGHT", -buttonMargin, -buttonMargin)
            end
        else
            button:SetPoint("RIGHT", window.buttons[#window.buttons], "LEFT", -buttonMargin, 0)
        end

        -- 更新 buttonBackground 宽度，覆盖标题栏高度
        window.buttonBackground:SetSize((#window.buttons + 1) * (buttonSize + buttonMargin), moverFrameHeight)

        button.tex = button:CreateTexture(nil, "OVERLAY")
        button.tex:SetAllPoints(button)
        button.tex:SetTexture(texture or "Interface\\Buttons\\UI-OptionsButton")
        button.tex:SetVertexColor(0.5, 0.5, 0.5)

        button:SetScript("OnEnter", function()
            button.tex:SetVertexColor(0.85, 0.85, 0.85)
        end)
        button:SetScript("OnLeave", function()
            button.tex:SetVertexColor(0.5, 0.5, 0.5)
        end)
        button:SetScript("OnClick", onClick)

        table.insert(window.buttons, button)
        return button
    end

    ------------------------------------------------------------
    -- moverFrame
    ------------------------------------------------------------
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        AUP:SavePosition(self, name)
    end)
    window:SetClampedToScreen(true)

    ------------------------------------------------------------
    -- resizeFrame
    ------------------------------------------------------------
    if resizable then
        window:SetResizable(true)
        -- 只用新 API：最小尺寸限制（按需修改数值）
        if window.SetResizeBounds then
            window:SetResizeBounds(360, 220)
        end

        window.resizeFrame = CreateFrame("Button", nil, window)
        window.resizeFrame:SetSize(16, 16)
        window.resizeFrame:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -4, 4)
        window.resizeFrame:SetFrameLevel(window:GetFrameLevel() + 2)

        window.resizeFrame:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        window.resizeFrame:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        window.resizeFrame:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

        window.resizeFrame:SetScript("OnMouseDown", function(_, button)
            if button == "LeftButton" then
                window:StartSizing("BOTTOMRIGHT")
            end
        end)
        window.resizeFrame:SetScript("OnMouseUp", function(_, button)
            if button == "LeftButton" then
                window:StopMovingOrSizing()
                AUP:SaveSize(window, name)
            end
        end)
    else
        window.resizeFrame = nil
    end

    ------------------------------------------------------------
    -- 恢复尺寸/位置（保持你的持久化逻辑）
    ------------------------------------------------------------
    AUP:RestoreSize(window, name)
    AUP:RestorePosition(window, name)

    return window
end
