local M = {}
local utils = require("utils")


function recipe1x1(item)
    return {
        nil, nil, nil,
        nil, item, nil,
        nil, nil, nil
    }
end


function recipe1x2(a, b)
    return {
        a, nil, nil,
        b, nil, nil,
        nil, nil, nil
    }
end


function recipe2x2(a, b, c, d)
    return {
        a, b, nil,
        c, d, nil,
        nil, nil, nil
    }
end


function recipe3x1(a, b, c)
    return {
        nil, nil, nil,
        a, b, c,
        nil, nil, nil
    }
end


function recipe3x2(a, b, c, d, e, f)
    return {
        nil, nil, nil,
        a, b, c,
        d, e, f
    }
end


M.items = {
    ["planks"]={
        name="Wood planks",
        ident="minecraft:planks",
        damage=0
    },
    ["cobblestone"]={
        name="Cobblestone",
        ident="minecraft:cobblestone"
    },
    ["sand"]={
        name="Sand",
        ident="minecraft:sand"
    },
    ["iron_ingot"]={
        name="Iron ingot",
        ident="minecraft:iron_ingot"
    },
    ["gold_ingot"]={
        name="Gold ingot",
        ident="minecraft:gold_ingot"
    },
    ["diamond"]={
        name="Diamond",
        ident="minecraft:diamond"
    },
    ["redstone"]={
        name="Redstone",
        ident="minecraft:redstone"
    },
    ["slime_ball"]={
        name="Slimeball",
        ident="minecraft:slime_ball"
    },
    ["ender_pearl"]={
        name="Ender pearl",
        ident="minecraft:ender_pearl"
    },
    ["ender_eye"]={
        name="Eye of Ender",
        ident="minecraft:ender_eye"
    },
    ["obsidian"]={
        name="Obsidian",
        ident="minecraft:obsidian"
    },
    ["yellow_dust"]={
        name="Glowstone dust",
        ident="minecraft:glowstone_dust"
    },
    ["clay_ball"]={
        name="Clay ball",
        ident="minecraft:clay_ball"
    },
    ["clay"]={
        name="Clay",
        recipe=recipe2x2(
            "clay_ball", "clay_ball",
            "clay_ball", "clay_ball"
        ),
        ident="minecraft:clay"
    },


    ["glass"]={
        name="Glass",
        furnace="sand",
        ident="minecraft:glass"
    },


    ["iron_nugget"]={
        name="Iron nugget",
        recipe=recipe1x1("iron_ingot"),
        output=9,
        ident="minecraft:iron_nugget"
    },
    ["gold_nugget"]={
        name="Gold nugget",
        recipe=recipe1x1("gold_ingot"),
        output=9,
        ident="minecraft:gold_nugget"
    },
    ["cutting_wire"]={
        name="Cutting wire",
        recipe=recipe3x1("stick", "iron_nugget", "stick"),
        ident="opencomputers:material",
        damage=0
    },
    ["diamond_chip"]={
        name="Diamond chip",
        recipe=recipe1x2("diamond", "cutting_wire"),
        output=6,
        ident="opencomputers:material",
        damage=29
    },


    ["stick"]={
        name="Stick",
        recipe=recipe1x2("planks", "planks"),
        output=4,
        ident="minecraft:stick"
    },
    ["clock"]={
        name="Clock",
        recipe={
            nil, "gold_ingot", nil,
            "gold_ingot", "redstone", "gold_ingot",
            nil, "gold_ingot", nil
        },
        ident="minecraft:clock"
    },
    ["redstone_torch"]={
        name="Redstone torch",
        recipe=recipe1x2("redstone", "stick"),
        ident="minecraft:redstone_torch"
    },
    ["lever"]={
        name="Lever",
        recipe=recipe1x2("stick", "cobblestone"),
        ident="minecraft:lever"
    },
    ["iron_fence"]={
        name="Iron fence",
        recipe=recipe3x2(
            "iron_ingot", "iron_ingot", "iron_ingot",
            "iron_ingot", "iron_ingot", "iron_ingot"
        ),
        output=16,
        ident="minecraft:iron_bars"
    },


    ["chest"]={
        name="Chest",
        recipe={
            "planks", "planks", "planks",
            "planks", nil, "planks",
            "planks", "planks", "planks"
        },
        ident="minecraft:chest"
    },
    ["hopper"]={
        name="Hopper",
        recipe={
            "iron_ingot", nil, "iron_ingot",
            "iron_ingot", "chest", "iron_ingot",
            nil, "iron_ingot", nil
        },
        ident="minecraft:hopper"
    },
    ["dropper"]={
        name="Dropper",
        recipe={
            "cobblestone", "cobblestone", "cobblestone",
            "cobblestone", nil, "cobblestone",
            "cobblestone", "planks", "cobblestone"
        },
        ident="minecraft:dropper"
    },
    ["piston"]={
        name="Piston",
        recipe={
            "planks", "planks", "planks",
            "cobblestone", "iron_ingot", "cobblestone",
            "cobblestone", "redstone", "cobblestone"
        },
        ident="minecraft:piston"
    },
    ["sticky_piston"]={
        name="Sticky piston",
        recipe=recipe1x2("slime_ball", "piston"),
        ident="minecraft:sticky_piston"
    },


    ["sugarcane"]={
        name="Sugarcane",
        ident="minecraft:reeds"
    },
    ["cactus"]={
        name="Cactus",
        ident="minecraft:cactus"
    },


    ["paper"]={
        name="Paper",
        recipe=recipe3x1("sugarcane", "sugarcane", "sugarcane"),
        output=3,
        ident="minecraft:paper"
    },


    ["dye_red"]={
        name="Red dye",
        ident="minecraft:dye",
        -- todo: recipe?
        damage=1
    },
    ["dye_green"]={
        name="Green dye",
        furnace="cactus",
        ident="minecraft:dye",
        damage=2
    },
    ["dye_blue"]={
        name="Lapis lazuli",
        ident="minecraft:dye",
        damage=4
    },


    -- CIRCUITS & MATERIALS


    ["raw_pcb"]={
        name="Raw circuit board",
        recipe=recipe3x1("gold_ingot", "clay", "dye_green"),
        output=8,
        ident="opencomputers:material",
        damage=2
    },
    ["pcb"]={
        name="PCB",
        furnace="raw_pcb",
        ident="opencomputers:material",
        damage=4
    },
    ["transistor"]={
        name="Transistor",
        recipe={
            "iron_nugget", "iron_nugget", "iron_nugget",
            "gold_nugget", "paper", "gold_nugget",
            nil, "redstone", nil
        },
        output=8,
        ident="opencomputers:material",
        damage=6
    },
    ["chip1"]={
        name="Chip I",
        recipe={
            "iron_nugget", "iron_nugget", "iron_nugget",
            "redstone", "transistor", "redstone",
            "iron_nugget", "iron_nugget", "iron_nugget"
        },
        output=8,
        ident="opencomputers:material",
        damage=7
    },
    ["chip2"]={
        name="Chip II",
        recipe={
            "gold_nugget", "gold_nugget", "gold_nugget",
            "redstone", "transistor", "redstone",
            "gold_nugget", "gold_nugget", "gold_nugget"
        },
        output=4,
        ident="opencomputers:material",
        damage=8
    },
    ["chip3"]={
        name="Chip III",
        recipe={
            "diamond_chip", "diamond_chip", "diamond_chip",
            "redstone", "transistor", "redstone",
            "diamond_chip", "diamond_chip", "diamond_chip"
        },
        output=2,
        ident="opencomputers:material",
        damage=9
    },
    ["alu"]={
        name="ALU",
        recipe={
            "iron_nugget", "redstone", "iron_nugget",
            "transistor", "chip1", "transistor",
            "iron_nugget", "transistor", "iron_nugget"
        },
        ident="opencomputers:material",
        damage=10
    },
    ["cu"]={
        name="Control unit",
        recipe={
            "gold_nugget", "redstone", "gold_nugget",
            "transistor", "clock", "transistor",
            "gold_nugget", "transistor", "gold_nugget"
        },
        ident="opencomputers:material",
        damage=11
    },
    ["disk"]={
        name="Disk",
        recipe={
            nil, "iron_nugget", nil,
            "iron_nugget", nil, "iron_nugget",
            nil, "iron_nugget", nil
        },
        ident="opencomputers:material",
        damage=12
    },


    ["cable"]={
        name="Cable",
        recipe={
            nil, "iron_nugget", nil,
            "iron_nugget", "redstone", "iron_nugget",
            nil, "iron_nugget", nil
        },
        output=4,
        ident="opencomputers:cable"
    },


    -- CPU


    ["cpu1"]={
        name="CPU I",
        recipe={
            "iron_nugget", "redstone", "iron_nugget",
            "chip1", "cu", "chip1",
            "iron_nugget", "alu", "iron_nugget"
        },
        ident="opencomputers:component",
        damage=0
    },
    ["cpu2"]={
        name="CPU II",
        recipe={
            "gold_nugget", "redstone", "gold_nugget",
            "chip2", "cu", "chip2",
            "gold_nugget", "alu", "gold_nugget"
        },
        ident="opencomputers:component",
        damage=1
    },
    ["cpu3"]={
        name="CPU III",
        recipe={
            "diamond_chip", "redstone", "diamond_chip",
            "chip3", "cu", "chip3",
            "diamond_chip", "alu", "diamond_chip"
        },
        ident="opencomputers:component",
        damage=2
    },


    -- RAM


    ["ram1"]={
        name="RAM I",
        recipe=recipe3x2(
            "chip1", "iron_nugget", "chip1",
            nil, "pcb", nil
        ),
        ident="opencomputers:component",
        damage=6
    },
    ["ram1_plus"]={
        name="RAM I+",
        recipe=recipe3x2(
            "chip1", "chip2", "chip1",
            nil, "pcb", nil
        ),
        ident="opencomputers:component",
        damage=7
    },
    ["ram2"]={
        name="RAM II",
        recipe=recipe3x2(
            "chip2", "iron_nugget", "chip2",
            nil, "pcb", nil
        ),
        ident="opencomputers:component",
        damage=8
    },
    ["ram2_plus"]={
        name="RAM II+",
        recipe=recipe3x2(
            "chip2", "chip3", "chip2",
            nil, "pcb", nil
        ),
        ident="opencomputers:component",
        damage=9
    },
    ["ram3"]={
        name="RAM III",
        recipe=recipe3x2(
            "chip3", "iron_nugget", "chip3",
            nil, "pcb", nil
        ),
        ident="opencomputers:component",
        damage=10
    },
    ["ram3_plus"]={
        name="RAM III+",
        recipe=recipe3x2(
            "chip3", "chip3", "chip3",
            "chip2", "pcb", "chip2"
        ),
        ident="opencomputers:component",
        damage=11
    },


    -- CARDS


    ["card_base"]={
        name="Card base",
        recipe={
            "iron_nugget", nil, nil,
            "iron_nugget", "pcb", nil,
            "iron_nugget", "gold_nugget", nil
        },
        ident="opencomputers:material",
        damage=5
    },
    ["gpu1"]={
        name="Graphic card I",
        recipe=recipe3x2(
            "chip1", "alu", "ram1",
            nil, "card_base", nil
        ),
        ident="opencomputers:card",
        damage=1
    },
    ["gpu2"]={
        name="Graphic card II",
        recipe=recipe3x2(
            "chip2", "alu", "ram2",
            nil, "card_base", nil
        ),
        ident="opencomputers:card",
        damage=2
    },
    ["gpu3"]={
        name="Graphic card III",
        recipe=recipe3x2(
            "chip3", "alu", "ram3",
            nil, "card_base", nil
        ),
        ident="opencomputers:card",
        damage=3
    },
    ["redstonecard"]={
        name="Redstone card",
        recipe=recipe2x2(
            "redstone_torch", "chip1",
            nil, "card_base"
        ),
        ident="opencomputers:card",
        damage=4
    },
    ["lancard"]={
        name="Network card",
        recipe=recipe2x2(
            "cable", "chip1",
            nil, "card_base"
        ),
        ident="opencomputers:card",
        damage=6
    },
    ["wlancard"]={
        name="Wireless card",
        recipe=recipe2x2(
            "ender_pearl", "chip2",
            nil, "card_base"
        ),
        ident="opencomputers:card",
        damage=7
    },


    -- STORAGE


    ["eeprom"]={
        name="EEPROM",
        recipe={
            "gold_nugget", "transistor", "gold_nugget",
            "chip1", "paper", "chip1",
            "gold_nugget", "redstone_torch", "gold_nugget"
        },
        ident="opencomputers:storage",
        damage=0
    },
    ["diskette"]={
        name="Floppy disk",
        recipe={
            "iron_nugget", "lever", "iron_nugget",
            "paper", "disk", "paper",
            "iron_nugget", "paper", "iron_nugget"
        },
        ident="opencomputers:storage",
        damage=1
    },
    ["hdd1"]={
        name="HDD I",
        recipe={
            "chip1", "disk", "iron_ingot",
            "pcb", "disk", "piston",
            "chip1", "disk", "iron_ingot"
        },
        ident="opencomputers:storage",
        damage=2
    },
    ["hdd2"]={
        name="HDD II",
        recipe={
            "chip2", "disk", "gold_ingot",
            "pcb", "disk", "piston",
            "chip2", "disk", "gold_ingot"
        },
        ident="opencomputers:storage",
        damage=3
    },
    ["hdd3"]={
        name="HDD III",
        recipe={
            "chip3", "disk", "diamond",
            "pcb", "disk", "piston",
            "chip3", "disk", "diamond"
        },
        ident="opencomputers:storage",
        damage=4
    },


    -- CASES, SCREENS, DEVICES


    ["case1"]={
        name="Computer case I",
        recipe={
            "iron_ingot", "chip1", "iron_ingot",
            "iron_fence", "chest", "iron_fence",
            "iron_ingot", "pcb", "iron_ingot",
        },
        ident="opencomputers:case1"
    },
    ["case2"]={
        name="Computer case II",
        recipe={
            "gold_ingot", "chip2", "gold_ingot",
            "iron_fence", "chest", "iron_fence",
            "gold_ingot", "pcb", "gold_ingot",
        },
        ident="opencomputers:case2"
    },
    ["case3"]={
        name="Computer case III",
        recipe={
            "diamond", "chip3", "diamond",
            "iron_fence", "chest", "iron_fence",
            "diamond", "pcb", "diamond",
        },
        ident="opencomputers:case3"
    },
    ["screen1"]={
        name="Screen I",
        recipe={
            "iron_ingot", "redstone", "iron_ingot",
            "redstone", "chip1", "glass",
            "iron_ingot", "redstone", "iron_ingot",
        },
        ident="opencomputers:screen1"
    },
    ["screen2"]={
        name="Screen II",
        recipe={
            "gold_ingot", "dye_red", "gold_ingot",
            "dye_green", "chip2", "glass",
            "gold_ingot", "dye_blue", "gold_ingot",
        },
        ident="opencomputers:screen2"
    },
    ["screen3"]={
        name="Screen III",
        recipe={
            "obsidian", "yellow_dust", "obsidian",
            "yellow_dust", "chip3", "glass",
            "obsidian", "yellow_dust", "obsidian",
        },
        ident="opencomputers:screen3"
    },
    ["floppy_drive"]={
        name="Floppy drive",
        recipe={
            "iron_ingot", "chip1", "iron_ingot",
            "piston", "stick", nil,
            "iron_ingot", "pcb", "iron_ingot",
        },
        ident="opencomputers:diskdrive"
    },


    -- KEYBOARD


    ["stone"]={
        name="Stone",
        furnace="cobblestone",
        ident="minecraft:stone"
    },
    ["button"]={
        name="Button",
        recipe=recipe1x1("stone"),
        ident="minecraft:stone_button"
    },
    ["buttons"]={
        name="Button group",
        recipe=recipe3x2(
            "button", "button", "button",
            "button", "button", "button"
        ),
        ident="opencomputers:material",
        damage=14
    },
    ["arrow_buttons"]={
        name="Arrow buttons",
        recipe=recipe3x2(
            nil, "button", nil,
            "button", "button", "button"
        ),
        ident="opencomputers:material",
        damage=15
    },
    ["numpad_buttons"]={
        name="Numpad keypad",
        recipe={
            "button", "button", "button",
            "button", "button", "button",
            "button", "button", "button"
        },
        ident="opencomputers:material",
        damage=16
    },
    ["keyboard"]={
        name="Keyboard",
        recipe=recipe3x2(
            "buttons", "buttons", "buttons",
            "buttons", "arrow_buttons", "numpad_buttons"
        ),
        ident="opencomputers:keyboard"
    }
}


local detection_map = {}
for k, v in pairs(M.items) do
    assert(v.ident ~= nil)
    if v.damage == nil then
        assert(detection_map[v.ident] == nil)
        detection_map[v.ident] = k
    else
        if detection_map[v.ident] == nil then
            detection_map[v.ident] = {}
        end
        assert(type(detection_map[v.ident]) == "table")
        assert(detection_map[v.ident][v.damage] == nil)
        detection_map[v.ident][v.damage] = k
    end
end


for k, v in pairs(M.items) do
    if v.recipe ~= nil then
        for i, item in ipairs(v.recipe) do
            assert(M.items[item] ~= nil, "Unknown item in recipe: " .. item)
        end
    end
    if v.furnace ~= nil then
        assert(M.items[v.furnace] ~= nil, "Unknown item in recipe: " .. v.furnace)
    end
end


function M.detect(slot)
    if slot == nil then return end
    local s = detection_map[slot.name]
    if s == nil then return end
    if type(s) == "string" then return s end
    return s[slot.damage]
end


function M.formatRecipe(recipe)
    local widths={}

    function getName(row, col)
        local name = recipe[row * 3 + col - 3]
        if name == nil then return "" end
        return M.items[name]["name"]
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


function M.recipeSummary(recipe)
    local r = {}
    for i=1,9 do
        local v = recipe[i]
        if v ~= nil then
            utils.stock.put(r, v, 1)
        end
    end
    return r
end


function M.recipeOutput(item_id)
    local output = M.items[item_id].output
    if output == nil then output = 1 end
    return output
end


return M
