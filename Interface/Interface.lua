local addOnName, AUP = ...

-- Tooltip
CreateFrame("GameTooltip", "LRTooltip", UIParent, "GameTooltipTemplate")

AUP.Tooltip = _G["LRTooltip"]
AUP.Tooltip.TextLeft1:SetFont(AUP.gs.visual.font, 13)

-- Main window
local windowWidth = 600
local windowHeight = 400

function AUP:InitializeInterface()
    local screenWidth, screenHeight = GetPhysicalScreenSize()

    -- Window
    AUP.window = AUP:CreateWindow("Main", true, true, true)
    AUP.window:SetFrameStrata("HIGH")
    AUP.window:SetResizeBounds(windowWidth, windowHeight) -- Height is set based on timeine data
    AUP.window:Hide()

    local title = AUP.window.moverFrame:CreateFontString(nil, "OVERLAY")
    title:SetFont(AUP.gs.visual.font, 17, AUP.gs.visual.fontFlags)
    title:SetPoint("CENTER", AUP.window.moverFrame, "CENTER", 0, 0) -- 居中在 moverFrame 里
    title:SetText("觉醒WA同步工具")

    -- Button frame
    local buttonFrame = CreateFrame("Frame", nil, AUP.window)

    buttonFrame:SetPoint("TOPLEFT", AUP.window.moverFrame, "BOTTOMLEFT")
    buttonFrame:SetPoint("TOPRIGHT", AUP.window.moverFrame, "BOTTOMRIGHT")

    buttonFrame:SetHeight(32)

    -- Update button
    local updateButton = CreateFrame("Frame", nil, AUP.window)

    updateButton:SetPoint("TOPLEFT", buttonFrame, "TOPLEFT", 4, -4)
    updateButton:SetPoint("BOTTOMRIGHT", buttonFrame, "BOTTOM", -2, 0)
    updateButton:EnableMouse(true)

    updateButton.highlight = updateButton:CreateTexture(nil, "HIGHLIGHT")
    updateButton.highlight:SetColorTexture(1, 1, 1, 0.05)
    updateButton.highlight:SetAllPoints()

    updateButton.text = updateButton:CreateFontString(nil, "OVERLAY")
    updateButton.text:SetFont(AUP.gs.visual.font, 17, AUP.gs.visual.fontFlags)
    updateButton.text:SetPoint("CENTER", updateButton, "CENTER")
    updateButton.text:SetText(string.format("|cff%s更新|r", AUP.gs.visual.colorStrings.white))

    updateButton:SetScript(
        "OnMouseDown",
        function()
            AUP.updateWindow:Show()
            AUP.waCheckWindow:Hide()
            AUP.addonCheckWindow:Hide()
        end
    )

    local borderColor = AUP.gs.visual.borderColor
    AUP:AddBorder(updateButton)
    updateButton:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Addon Check button
    local addonCheckButton = CreateFrame("Frame", nil, AUP.window)

    addonCheckButton:SetPoint("TOP", buttonFrame, "TOP", -4, -4)
    addonCheckButton:SetPoint("BOTTOM", buttonFrame, "BOTTOM", 2, 0)
    addonCheckButton:EnableMouse(true)

    addonCheckButton.highlight = addonCheckButton:CreateTexture(nil, "HIGHLIGHT")
    addonCheckButton.highlight:SetColorTexture(1, 1, 1, 0.05)
    addonCheckButton.highlight:SetAllPoints()

    addonCheckButton.text = addonCheckButton:CreateFontString(nil, "OVERLAY")
    addonCheckButton.text:SetFont(AUP.gs.visual.font, 17, AUP.gs.visual.fontFlags)
    addonCheckButton.text:SetPoint("CENTER", addonCheckButton, "CENTER")
    addonCheckButton.text:SetText(string.format("|cff%s插件检查|r", AUP.gs.visual.colorStrings.white))

    addonCheckButton:SetScript(
        "OnMouseDown",
        function()
            AUP.updateWindow:Hide()
            AUP.waCheckWindow:Hide()
            AUP.addonCheckWindow:Show()
        end
    )

    AUP:AddBorder(addonCheckButton)
    addonCheckButton:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- WA Check button
    local waCheckButton = CreateFrame("Frame", nil, AUP.window)

    waCheckButton:SetPoint("TOPRIGHT", buttonFrame, "TOPRIGHT", -4, -4)
    waCheckButton:SetPoint("BOTTOMLEFT", buttonFrame, "BOTTOM", 2, 0)
    waCheckButton:EnableMouse(true)

    waCheckButton.highlight = waCheckButton:CreateTexture(nil, "HIGHLIGHT")
    waCheckButton.highlight:SetColorTexture(1, 1, 1, 0.05)
    waCheckButton.highlight:SetAllPoints()

    waCheckButton.text = waCheckButton:CreateFontString(nil, "OVERLAY")
    waCheckButton.text:SetFont(AUP.gs.visual.font, 17, AUP.gs.visual.fontFlags)
    waCheckButton.text:SetPoint("CENTER", waCheckButton, "CENTER")
    waCheckButton.text:SetText(string.format("|cff%sWA检查|r", AUP.gs.visual.colorStrings.white))

    waCheckButton:SetScript(
        "OnMouseDown",
        function()
            AUP.updateWindow:Hide()
            AUP.waCheckWindow:Show()
            AUP.addonCheckWindow:Hide()
        end
    )

    AUP:AddBorder(waCheckButton)
    waCheckButton:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Sub windows
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

    -- If there's no saved position/size settings for the main window yet, apply some default values
    local windowSettings = AwakeningUpdaterSaved.settings.frames["Main"]

    if not windowSettings or not windowSettings.points then
        AUP.window:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (screenWidth - windowWidth) / 2,
            -(screenHeight - windowHeight) / 2)
    end

    if not windowSettings or not windowSettings.width then
        AUP.window:SetSize(windowWidth, windowHeight)
    end
end
