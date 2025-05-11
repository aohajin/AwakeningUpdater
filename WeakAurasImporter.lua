---@diagnostic disable: undefined-field
local _, AUP = ...

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

function AUP:InitializeWeakAurasImporter()
    if not AwakeningUpdaterSaved.WeakAuras then AwakeningUpdaterSaved.WeakAuras = {} end

    for _, auraData in ipairs(AUP.WeakAuras) do
        local displayName = auraData.displayName
        local version = auraData.version
        local importedVersion = AwakeningUpdaterSaved.WeakAuras[displayName] and
            AwakeningUpdaterSaved.WeakAuras[displayName].d and
            AwakeningUpdaterSaved.WeakAuras[displayName].d.AwakeningVersion

        if not importedVersion or importedVersion < version then
            local toDecode = auraData.data:match("!WA:2!(.+)")

            if toDecode then
                local decoded = LibDeflate:DecodeForPrint(toDecode)

                if decoded then
                    local decompressed = LibDeflate:DecompressDeflate(decoded)

                    if decompressed then
                        local success, data = LibSerialize:Deserialize(decompressed)

                        data.d.AwakeningVersion = version

                        if success then
                            AwakeningUpdaterSaved.WeakAuras[displayName] = data
                        else
                            AUP:ErrorPrint(string.format("could not deserialize aura data for [%s]", displayName))
                        end
                    else
                        AUP:ErrorPrint(string.format("could not decompress aura data for [%s]", displayName))
                    end
                else
                    AUP:ErrorPrint(string.format("could not decode aura data for [%s]", displayName))
                end
            else
                AUP:ErrorPrint(string.format("aura data for [%s] does not start with a valid prefix", displayName))
            end
        end
    end
end
