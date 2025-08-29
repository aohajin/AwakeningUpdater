local ADDON_NAME, AUP = ...


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
--local categoryID
if Settings and Settings.RegisterAddOnCategory then
    local category = Settings.RegisterAddOnCategory(panel) -- 10.0+
    --categoryID = category.ID
else
    InterfaceOptions_AddCategory(panel) -- 旧版
end
