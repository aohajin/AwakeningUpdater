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

    local title = AUP.window:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", AUP.window, "TOP", 0, -10)
    title:SetText("觉醒团本WA合集更新器")

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
            AUP.checkWindow:Hide()
        end
    )

    local borderColor = AUP.gs.visual.borderColor
    AUP:AddBorder(updateButton)
    updateButton:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Check button
    local checkButton = CreateFrame("Frame", nil, AUP.window)

    checkButton:SetPoint("TOPRIGHT", buttonFrame, "TOPRIGHT", -4, -4)
    checkButton:SetPoint("BOTTOMLEFT", buttonFrame, "BOTTOM", 2, 0)
    checkButton:EnableMouse(true)

    checkButton.highlight = checkButton:CreateTexture(nil, "HIGHLIGHT")
    checkButton.highlight:SetColorTexture(1, 1, 1, 0.05)
    checkButton.highlight:SetAllPoints()

    checkButton.text = checkButton:CreateFontString(nil, "OVERLAY")
    checkButton.text:SetFont(AUP.gs.visual.font, 17, AUP.gs.visual.fontFlags)
    checkButton.text:SetPoint("CENTER", checkButton, "CENTER")
    checkButton.text:SetText(string.format("|cff%s检查|r", AUP.gs.visual.colorStrings.white))

    checkButton:SetScript(
        "OnMouseDown",
        function()
            AUP.updateWindow:Hide()
            AUP.checkWindow:Show()
        end
    )

    AUP:AddBorder(checkButton)
    checkButton:SetBorderColor(borderColor.r, borderColor.g, borderColor.b)

    -- Sub windows
    AUP.updateWindow = CreateFrame("Frame", nil, AUP.window)
    AUP.updateWindow:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT")
    AUP.updateWindow:SetPoint("BOTTOMRIGHT", AUP.window, "BOTTOMRIGHT")

    AUP.checkWindow = CreateFrame("Frame", nil, AUP.window)
    AUP.checkWindow:SetPoint("TOPLEFT", buttonFrame, "BOTTOMLEFT")
    AUP.checkWindow:SetPoint("BOTTOMRIGHT", AUP.window, "BOTTOMRIGHT")

    AUP.checkWindow:Hide()

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
