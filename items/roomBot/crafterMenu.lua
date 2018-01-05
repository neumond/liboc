local Menu = require("lib.simpleMenu").Menu
local db = require("recipedb")
local utils = require("utils")


local MenuStructure = {title="Recipe assembler", children={
    {title="Tier 1", children={
        {title="Components", children={
            "case1",
            "screen1",
            "cpu1",
            "ram1",
            "ram1_plus",
            "hdd1"
        }},
        {title="Cards", children={
            "gpu1",
            "lancard",
            "redstonecard1",
            "datacard1"
        }},
        {title="Upgrades", children={
            "battery_upgrade1",
            "database_upgrade1",
            "hover_upgrade1",
            "inventory_upgrade",
            "leash_upgrade",
            "piston_upgrade",
            "sign_upgrade",
            "tank_upgrade"
        }},
        {title="Slots", children={
            "card_upgrade1",
            "upgrade_container1"
        }}
    }},
    {title="Tier 2", children={
        {title="Components", children={
            "case2",
            "screen2",
            "cpu2",
            "ram2",
            "ram2_plus",
            "hdd2"
        }},
        {title="Cards", children={
            "gpu2",
            "wlancard",
            "redstonecard2",
            "internet_card",
            "datacard2"
        }},
        {title="Upgrades", children={
            "angel_upgrade",
            "battery_upgrade2",
            "crafting_upgrade",
            "database_upgrade2",
            "generator_upgrade",
            "inventory_controller_upgrade",
            "solar_upgrade",
            "tank_controller_upgrade",
            "trading_upgrade"
        }},
        {title="Slots", children={
            "card_upgrade2",
            "upgrade_container2"
        }}
    }},
    {title="Tier 3", children={
        {title="Components", children={
            "case3",
            "screen3",
            "cpu3",
            "ram3",
            "ram3_plus",
            "hdd3"
        }},
        {title="Cards", children={
            "gpu3",
            "datacard3"
        }},
        {title="Upgrades", children={
            "battery_upgrade3",
            "chunkloader_upgrade",
            "database_upgrade3",
            "experience_upgrade",
            "tractor_beam_upgrade"
        }},
        {title="Slots", children={
            "card_upgrade3",
            "upgrade_container3"
        }}
    }},
    {title="Devices", children={
        "adapter",
        "assembler",
        "disassembler",
        "powerconverter",
        "charger",
        "capacitor",
        "floppy_drive",
        "printer"
    }},
    {title="Misc", children={
        "keyboard",
        "diskette",
        "eeprom",
        "cable",
        "cartridge_full"
    }},
    {title="Test", children={
        "iron_nugget"
    }}
}}


local function runMenuWrap(fillMenuFunc, handleChoiceFunc, titlePrefix)
    local choice = nil
    while true do
        local menu = Menu(true, choice)
        if titlePrefix ~= nil then
            menu:addText(titlePrefix)
        end
        fillMenuFunc(menu)
        choice = menu:run()
        if choice == nil then break end
        handleChoiceFunc(choice)
    end
end


local CrafterMenu = utils.makeClass(function(self, assembleFunc)
    self.assembleFunc = assembleFunc
    self:runMenu(MenuStructure)
end)


function CrafterMenu:runItem(itemId, titlePrefix)
    runMenuWrap(function(menu)
        menu:addText(db.getItemName(itemId))
        menu:addSeparator()
        if db.getRecipe(itemId) ~= nil then
            local ab = {}
            local function asmN(n)
                n = n - n % db.getRecipeOutput(itemId)
                if n < 1 then n = 1 end
                if n > db.getItemStack(itemId) then return end
                if ab[n] then return end
                menu:addSelectable("Assemble " .. n, n)
                ab[n] = true
            end

            x = 1
            while x <= 64 do
                asmN(x)
                x = x * 2
            end

            menu:addText("Recipe:\n")
            menu:addText(db.formatRecipe(db.getRecipe(itemId)))
        else
            menu:addText("No recipe available.")
        end
    end, function(n)
        self.assembleFunc(itemId, n)
    end, titlePrefix)
end


function CrafterMenu:runMenu(description, titlePrefix)
    local titlePrefixInner = (titlePrefix or "") .. "\n" .. description.title
    runMenuWrap(function(menu)
        menu:addText(description.title)
        menu:addSeparator()
        for i, cat in ipairs(description.children) do
            if type(cat) == "string" then
                menu:addSelectable(db.getItemName(cat), cat)
            else
                menu:addSelectable(cat.title, cat)
            end
        end
    end, function(choice)
        if type(choice) == "string" then
            self:runItem(choice, titlePrefixInner)
        else
            self:runMenu(choice, titlePrefixInner)
        end
    end, titlePrefix)
end


return {
    CrafterMenu=CrafterMenu
}
