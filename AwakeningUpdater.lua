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

SLASH_AwakeningUPDATER1, SLASH_AwakeningUPDATER2, SLASH_AwakeningUPDATER3 = "/au", "/art",
    "/Awakeningupdater"
function SlashCmdList.AwakeningUPDATER()
    AUP.window:SetShown(not AUP.window:IsShown())
end
