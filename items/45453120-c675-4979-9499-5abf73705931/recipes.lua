local menulib = require("menulib")
local Menu = menulib.Menu
local ITEMS = require("recipedb")


function formatRecipe(item)
    local widths={}
    local recipe=ITEMS[item]["recipe"]

    function getName(row, col)
        local name = recipe[row * 3 + col - 3]
        if name == nil then return "" end
        return ITEMS[name]["name"]
    end

    for col=1,3 do
        local w=5
        for row=1,3 do
            local sl = string.len(getName(row, col))
            if sl > w then w = sl end
        end
        widths[col] = w
    end

    local rows={}
    for row=1,3 do
        local r={}
        for col=1,3 do
            r[col] = getName(row, col)
            local spaces = widths[col] - string.len(r[col])
            local spaces_left = math.floor(spaces / 2)
            local spaces_right = spaces - spaces_left
            r[col] = string.rep(" ", spaces_left) .. r[col] .. string.rep(" ", spaces_right)
        end
        rows[row] = table.concat(r, " | ")
    end
    return table.concat(rows, "\n")
end


function makeMenu(mcons)
    return function(titlePrefix)
        while true do
            local choice = mcons(
                Menu.new(true)
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


Menu.addItem = function(self, item_id)
    local item = ITEMS[item_id]
    local item_cat = {
        title=item.name,
        run=makeMenu(function(menu)
            if item.recipe ~= nil then
                menu:addText("Recipe:\n")
                menu:addText(formatRecipe(item_id))
            else
                menu:addText("No recipe available.")
            end
            return menu
        end)
    }
    return self:addCategory(item_cat)
end


local cat = {
    basic_elements = {
        title="Basic elements",
        run=makeMenu(function(menu)
            return menu
                :addItem("transistor")
                :addItem("chip1")
                :addSelectable("chip2", nil)
                :addSelectable("chip3", nil)
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
                :addSelectable("gpu", nil)
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
-- print(formatRecipe("transistor"))
-- menulib.info("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
