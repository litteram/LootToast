-----------------------------------------------------------------------
-- Upvalued Lua API.
-----------------------------------------------------------------------
local _G = getfenv(0)

local tonumber = _G.tonumber

-------------------------------------------------------------------------------
-- AddOn namespace.
-------------------------------------------------------------------------------
local FOLDER_NAME, private = ...

local LibStub = _G.LibStub
local LibToast = LibStub("LibToast-1.0")
local LootToasts = LibStub("AceAddon-3.0"):NewAddon(FOLDER_NAME, "AceEvent-3.0")

LibToast:Register(
    FOLDER_NAME,
    function(toast, title, text, iconTexture, qualityID, amountGained, amountOwned)
        if amountOwned == nil then
            return
        end

        local _, _, _, hex = _G.GetItemQualityColor(qualityID)
        toast:SetFormattedTitle("%s %s", title, amountGained > 1 and _G.PARENS_TEMPLATE:format(amountGained) or "")
        toast:SetFormattedText("|c%s%s|r %s", hex, text, amountOwned > 0 and _G.PARENS_TEMPLATE:format(amountOwned) or "")

        if iconTexture then
            toast:SetIconTexture(iconTexture)
        end
    end
)

-------------------------------------------------------------------------------
-- Variables.
-------------------------------------------------------------------------------
local CurrentCopperAmount

-------------------------------------------------------------------------------
-- Event handlers.
-------------------------------------------------------------------------------
function LootToasts:OnEnable()
    CurrentCopperAmount = _G.GetMoney()

    self:RegisterEvent("CHAT_MSG_CURRENCY")
    self:RegisterEvent("CHAT_MSG_LOOT")
    self:RegisterEvent("PLAYER_MONEY")
end

do
    local CURRENCY_PATTERN = (_G.CURRENCY_GAINED):gsub("%%s", "(.+)")
    local CURRENCY_MULTIPLE_PATTERN = (_G.CURRENCY_GAINED_MULTIPLE):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")

    function LootToasts:CHAT_MSG_CURRENCY(eventName, message)
        local currencyLink, amountGained = message:match(CURRENCY_MULTIPLE_PATTERN)
        if not currencyLink then
            amountGained, currencyLink = 1, message:match(CURRENCY_PATTERN)

            if not currencyLink then
                return
            end
        end

        local name, amountOwned, texturePath = C_CurrencyInfo.GetCurrencyInfo(tonumber(currencyLink:match("currency:(%d+)")))
        LibToast:Spawn(FOLDER_NAME, _G.CURRENCY, name, texturePath, 1, tonumber(amountGained), tonumber(amountOwned))
    end
end -- do-block

do
    local LOOT_ITEM_PATTERN = (_G.LOOT_ITEM_SELF):gsub("%%s", "(.+)")
    local LOOT_ITEM_PUSH_PATTERN = (_G.LOOT_ITEM_PUSHED_SELF):gsub("%%s", "(.+)")
    local LOOT_ITEM_MULTIPLE_PATTERN = (_G.LOOT_ITEM_SELF_MULTIPLE):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
    local LOOT_ITEM_PUSH_MULTIPLE_PATTERN = (_G.LOOT_ITEM_PUSHED_SELF_MULTIPLE):gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")

    function LootToasts:CHAT_MSG_LOOT(eventName, message)
        local hyperLink, amountGained = message:match(LOOT_ITEM_MULTIPLE_PATTERN)
        if not hyperLink then
            hyperLink, amountGained = message:match(LOOT_ITEM_PUSH_MULTIPLE_PATTERN)
            if not hyperLink then
                amountGained, hyperLink = 1, message:match(LOOT_ITEM_PATTERN)
                if not hyperLink then
                    amountGained, hyperLink = 1, message:match(LOOT_ITEM_PUSH_PATTERN)
                    if not hyperLink then
                        return
                    end
                end
            end
        end
        amountGained = tonumber(amountGained) or 0

        if hyperLink:find("battlepet") then
            local _, speciesID, _, breedQuality = (":"):split(hyperLink)
            local name, texturePath = _G.C_PetJournal.GetPetInfoBySpeciesID(speciesID)

            LibToast:Spawn(FOLDER_NAME, _G.TOOLTIP_BATTLE_PET, name, texturePath, breedQuality, amountGained, 0)
        else
            local name, _, quality, _, _, _, _, _, _, texturePath = _G.GetItemInfo(hyperLink)
            LibToast:Spawn(FOLDER_NAME, _G.HELPFRAME_ITEM_TITLE, name, texturePath, quality, amountGained, amountGained + tonumber(_G.GetItemCount(hyperLink)))
        end
    end
end -- do-block

function LootToasts:PLAYER_MONEY(eventName)
    local previousCopperAmount = CurrentCopperAmount
    CurrentCopperAmount = _G.GetMoney()

    local difference = CurrentCopperAmount - previousCopperAmount
    if difference > 0 then
        local goldAmount = difference >= 10000 and difference / 10000 or 0
        local silverAmount = difference >= 100 and (difference / 100) % 100 or 0
        local copperAmount = difference % 100
        local texturePath, moneyString

        if goldAmount > 0 then
            texturePath = goldAmount < 10 and [[Interface\ICONS\INV_Misc_Coin_01]] or [[Interface\ICONS\INV_Misc_Coin_02]]
            moneyString = ("%s%s%s"):format(_G.GOLD_AMOUNT_TEXTURE:format(goldAmount, 0, 0), silverAmount > 0 and (" " .. _G.SILVER_AMOUNT_TEXTURE:format(silverAmount, 0, 0)) or "", copperAmount > 0 and (" " .. _G.COPPER_AMOUNT_TEXTURE:format(copperAmount, 0, 0)) or "")
        elseif silverAmount > 0 then
            texturePath = silverAmount < 10 and [[Interface\ICONS\INV_Misc_Coin_03]] or [[Interface\ICONS\INV_Misc_Coin_04]]
            moneyString = ("%s%s"):format(_G.SILVER_AMOUNT_TEXTURE:format(silverAmount, 0, 0), copperAmount > 0 and (" " .. _G.COPPER_AMOUNT_TEXTURE:format(copperAmount, 0, 0)) or "")
        else
            texturePath = copperAmount < 10 and [[Interface\ICONS\INV_Misc_Coin_05]] or [[Interface\ICONS\INV_Misc_Coin_06]]
            moneyString = _G.COPPER_AMOUNT_TEXTURE:format(copperAmount, 0, 0)
		end

		LibToast:Spawn(FOLDER_NAME, _G.MONEY, moneyString, texturePath, 1, 0, 0)
	end
end
