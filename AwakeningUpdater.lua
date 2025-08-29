local _, AUP = ...
_G["AUP"] = AUP

--local LDB = LibStub("LibDataBroker-1.1")
--local LDBIcon = LibStub("LibDBIcon-1.0")
local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript(
    "OnEvent",
    function(_, event, ...)
        if event == "PLAYER_LOGIN" then
            if not AwakeningUpdaterSaved then AwakeningUpdaterSaved = {} end
            if not AwakeningUpdaterSaved.settings then AwakeningUpdaterSaved.settings = {} end
            if not AwakeningUpdaterSaved.settings.frames then AwakeningUpdaterSaved.settings.frames = {} end

            AUP:InitializeWeakAurasImporter()
            AUP:InitializeInterface()

            AUP:InitializeCheckerDataProvider()
            AUP:InitializeAuraUpdater()

            AUP:InitializeAuraChecker()
            AUP:InitializeAddonChecker()
            AUP:InitializeNoteChecker()

            AUP:RebuildAllCheckElements()
        end
    end
)

-- ====== 创建“AddOns”里的面板 ======
local panel = CreateFrame("Frame")
panel.name = ADDON_NAME
panel:Hide()

-- 标题
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 16, -16)
title:SetText(ADDON_NAME)

-- 说明文字
local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
desc:SetJustifyH("LEFT")
desc:SetWidth(560) -- 控制换行宽度
desc:SetText("输入 |cffffd200/au|r，|cffffd200/art|r，|cffffd200/awakeningupdater|r，或点击下方按钮打开主界面。")

-- “打开主界面”按钮
local btn = CreateFrame("Button", "$parentOpenBtn", panel, "UIPanelButtonTemplate")
btn:SetSize(180, 24)
btn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -12)
btn:SetText("打开主界面")
btn:SetScript("OnClick", function()
    AUP.window:SetShown(not AUP.window:IsShown())
end)

-- 注册到 ESC→Options→AddOns
local categoryID
if Settings and Settings.RegisterAddOnCategory then
    -- 先创建一个“画布布局”category，再注册到 AddOns
    local category, _layout_ = Settings.RegisterCanvasLayoutCategory(panel, ADDON_NAME)

    categoryID = category.ID
    Settings.RegisterAddOnCategory(category)
else
    InterfaceOptions_AddCategory(panel) -- 旧版
end


SLASH_AwakeningUPDATER1, SLASH_AwakeningUPDATER2, SLASH_AwakeningUPDATER3 = "/au", "/art",
    "/awakeningupdater"
function SlashCmdList.AwakeningUPDATER(msg)
    if msg and msg:lower() == "opt" and categoryID and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(categoryID)
        return
    end

    AUP.window:SetShown(not AUP.window:IsShown())
end
