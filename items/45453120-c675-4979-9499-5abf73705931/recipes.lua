local menulib = require("menulib")
local Menu = menulib.Menu
local ITEMS = require("recipedb")


function runMenu(choiceNames, choiceFuncs, title)
    while true do
        local ch = menulib.choice(choiceNames, title, true)
        if ch == nil then break end
        choiceFuncs[ch](title .. "\n" .. choiceNames[ch], ch)
    end
end


function runInfo(title, text)
    menulib.info(title .. "\n\n" .. text)
end


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


local cat = {}


function cat.basic_elements(title)
    local choice = Menu.new(true)
        :addText(title)
        :addSelectable("transistor")
        :addSelectable("chip1")
        :addSelectable("chip2")
        :addSelectable("chip3")
        :run()
end


function main()
    local choice = Menu.new(false)
        :addText("Recipe assembler")
        :addSeparator()
        :addText("Some text")
        :addSelectable("Basic elements", cat.basic_elements)
        :addSelectable("Cards", nil)
        :addSelectable("Cases", nil)
        :addSelectable("Devices", nil)
        :addSeparator()
        :run()
    menulib.clearScreen()
    print(choice)
end


main()
-- print(formatRecipe("transistor"))
-- menulib.info("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
