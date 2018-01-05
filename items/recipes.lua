local Menu = require("lib.simpleMenu").Menu
local db = require("recipedb")
local term = require("term")
local event = require("event")


function waitForKey()
    repeat
        local _, _, _, key = event.pull("key_down")
    until key == 28
end


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
    {title="Misc", children={
        "keyboard",
        "floppy_drive",
        "diskette",
        "eeprom",
        "cable",
        "adapter",
        "assembler",
        "disassembler",
        "printer",
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


local function runItem(itemId, titlePrefix)
    runMenuWrap(function(menu)
        menu:addText(db.getItemName(itemId))
        menu:addSeparator()
        if db.getRecipe(itemId) ~= nil then
            menu:addSelectable("Assemble", true)
            menu:addText("Recipe:\n")
            menu:addText(db.formatRecipe(db.getRecipe(itemId)))
        else
            menu:addText("No recipe available.")
        end
    end, function(choice)
        if choice ~= true then return end
        term.clear()
        print(itemId)
        waitForKey()
    end, titlePrefix)
end


local function runMenu(description, titlePrefix)
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
            runItem(choice, titlePrefixInner)
        else
            runMenu(choice, titlePrefixInner)
        end
    end, titlePrefix)
end


runMenu(MenuStructure)
term.clear()
