local menulib = require("menulib")
local Menu = menulib.Menu
local db = require("recipedb")


function makeMenu(mcons)
    return function(titlePrefix)
        local choice = nil
        while true do
            choice = mcons(
                Menu.new(true, choice)
                    :addText(titlePrefix)
                    :addSeparator()
            ):run()
            if choice == nil then break end
            choice.run(titlePrefix .. "\n" .. choice.title)
        end
    end
end


Menu.addCategory = function(self, c)
    return self:addSelectable(c.title, c)
end


local item_cat_cache = {}


Menu.addItem = function(self, item_id)
    if item_cat_cache[item_id] == nil then
        local item = db.items[item_id]
        item_cat_cache[item_id] = {
            title=item.name,
            run=makeMenu(function(menu)
                if item.recipe ~= nil then
                    menu:addText("Recipe:\n")
                    menu:addText(db.formatRecipe(item.recipe))
                else
                    menu:addText("No recipe available.")
                end
                return menu
            end)
        }
    end
    return self:addCategory(item_cat_cache[item_id])
end


local cat = {
    basic_elements = {
        title="Basic elements",
        run=makeMenu(function(menu)
            return menu
                :addItem("transistor")
                :addItem("chip1")
                :addItem("chip2")
                :addItem("chip3")
        end)
    },
    cases = {
        title="Cases",
        run=makeMenu(function(menu)
            return menu
                :addSelectable("case1", nil)
        end)
    },
    cards = {
        title="Cards",
        run=makeMenu(function(menu)
            return menu
                :addItem("gpu1", nil)
                :addItem("gpu2", nil)
                :addItem("gpu3", nil)
        end)
    },
    devices = {
        title="Devices",
        run=makeMenu(function(menu)
            return menu
                :addSelectable("floppy", nil)
        end)
    }
}


function main()
    local menuFunc = makeMenu(function(menu)
        return menu
            :addCategory(cat.basic_elements)
            :addCategory(cat.cases)
            :addCategory(cat.cards)
            :addCategory(cat.devices)
    end)
    menuFunc("Recipe assembler")
    menulib.clearScreen()
end


main()
