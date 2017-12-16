local M = {}


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
    ["wood"]={
        name="Oak Wood",
        ident="minecraft:log",
        damage=0,
        stack=64
    },
    ["planks"]={
        name="Oak Wood Planks",
        recipe=recipe1x1("wood"),
        output=4,
        ident="minecraft:planks",
        damage=0,
        stack=64
    },
    ["stone"]={
        name="Stone",
        furnace="cobblestone",
        ident="minecraft:stone",
        damage=0,
        stack=64
    },
    ["cobblestone"]={
        name="Cobblestone",
        ident="minecraft:cobblestone",
        damage=0,
        stack=64
    },
    ["sand"]={
        name="Sand",
        ident="minecraft:sand",
        damage=0,
        stack=64
    },
    ["iron_ore"]={
        name="Iron Ore",
        ident="minecraft:iron_ore",
        damage=0,
        stack=64
    },
    ["gold_ore"]={
        name="Gold Ore",
        ident="minecraft:gold_ore",
        damage=0,
        stack=64
    },
    ["iron_ingot"]={
        name="Iron Ingot",
        furnace="iron_ore",
        ident="minecraft:iron_ingot",
        damage=0,
        stack=64
    },
    ["gold_ingot"]={
        name="Gold Ingot",
        furnace="gold_ore",
        ident="minecraft:gold_ingot",
        damage=0,
        stack=64
    },
    ["diamond"]={
        name="Diamond",
        ident="minecraft:diamond",
        damage=0,
        stack=64
    },
    ["emerald"]={
        name="Emerald",
        ident="minecraft:emerald",
        damage=0,
        stack=64
    },
    ["redstone"]={
        name="Redstone",
        ident="minecraft:redstone",
        damage=0,
        stack=64
    },
    ["slime_ball"]={
        name="Slimeball",
        ident="minecraft:slime_ball",
        damage=0,
        stack=64
    },
    ["ender_pearl"]={
        name="Ender Pearl",
        ident="minecraft:ender_pearl",
        damage=0,
        stack=16
    },
    ["ender_eye"]={
        name="Eye of Ender",
        recipe=recipe1x2("blaze_powder", "ender_pearl"),
        ident="minecraft:ender_eye",
        damage=0,
        stack=64
    },
    ["obsidian"]={
        name="Obsidian",
        ident="minecraft:obsidian",
        damage=0,
        stack=64
    },
    ["yellow_dust"]={
        name="Glowstone Dust",
        ident="minecraft:glowstone_dust",
        damage=0,
        stack=64
    },
    ["clay_ball"]={
        name="Clay Ball",
        ident="minecraft:clay_ball",
        damage=0,
        stack=64
    },
    ["clay"]={
        name="Clay",
        recipe=recipe2x2(
            "clay_ball", "clay_ball",
            "clay_ball", "clay_ball"
        ),
        ident="minecraft:clay",
        damage=0,
        stack=64
    },
    ["lapis_block"]={
        name="Lapis Lazuli Block",
        recipe={
            "dye_blue", "dye_blue", "dye_blue",
            "dye_blue", "dye_blue", "dye_blue",
            "dye_blue", "dye_blue", "dye_blue"
        },
        ident="minecraft:lapis_block",
        damage=0,
        stack=64
    },
    ["redstone_block"]={
        name="Block of Redstone",
        recipe={
            "redstone", "redstone", "redstone",
            "redstone", "redstone", "redstone",
            "redstone", "redstone", "redstone"
        },
        ident="minecraft:redstone_block",
        damage=0,
        stack=64
    },


    ["glass"]={
        name="Glass",
        furnace="sand",
        ident="minecraft:glass",
        damage=0,
        stack=64
    },
    ["glass_pane"]={
        name="Glass Pane",
        recipe=recipe3x2(
            "glass", "glass", "glass",
            "glass", "glass", "glass"
        ),
        output=16,
        ident="minecraft:glass_pane",
        damage=0,
        stack=64
    },
    ["bottle"]={
        name="Glass Bottle",
        recipe=recipe3x2(
            "glass", nil, "glass",
            nil, "glass", nil
        ),
        output=3,
        ident="minecraft:glass_bottle",
        damage=0,
        stack=64
    },


    ["string"]={
        name="String",
        ident="minecraft:string",
        damage=0,
        stack=64
    },
    ["iron_nugget"]={
        name="Iron Nugget",
        recipe=recipe1x1("iron_ingot"),
        output=9,
        ident="minecraft:iron_nugget",
        damage=0,
        stack=64
    },
    ["gold_nugget"]={
        name="Gold Nugget",
        recipe=recipe1x1("gold_ingot"),
        output=9,
        ident="minecraft:gold_nugget",
        damage=0,
        stack=64
    },
    ["cutting_wire"]={
        name="Cutting Wire",
        recipe=recipe3x1("stick", "iron_nugget", "stick"),
        ident="opencomputers:material",
        damage=0,
        stack=64
    },
    ["diamond_chip"]={
        name="Diamond Chip",
        recipe=recipe1x2("diamond", "cutting_wire"),
        output=6,
        ident="opencomputers:material",
        damage=29,
        stack=64
    },


    ["stick"]={
        name="Stick",
        recipe=recipe1x2("planks", "planks"),
        output=4,
        ident="minecraft:stick",
        damage=0,
        stack=64
    },
    ["clock"]={
        name="Clock",
        recipe={
            nil, "gold_ingot", nil,
            "gold_ingot", "redstone", "gold_ingot",
            nil, "gold_ingot", nil
        },
        ident="minecraft:clock",
        damage=0,
        stack=64
    },
    ["redstone_torch"]={
        name="Redstone Torch",
        recipe=recipe1x2("redstone", "stick"),
        ident="minecraft:redstone_torch",
        damage=0,
        stack=64
    },
    ["lever"]={
        name="Lever",
        recipe=recipe1x2("stick", "cobblestone"),
        ident="minecraft:lever",
        damage=0,
        stack=64
    },
    ["iron_fence"]={
        name="Iron Bars",
        recipe=recipe3x2(
            "iron_ingot", "iron_ingot", "iron_ingot",
            "iron_ingot", "iron_ingot", "iron_ingot"
        ),
        output=16,
        ident="minecraft:iron_bars",
        damage=0,
        stack=64
    },
    ["bow"]={
        name="Bow",
        recipe={
            nil, "stick", "string",
            "stick", nil, "string",
            nil, "stick", "string"
        },
        ident="minecraft:bow",
        damage=0,
        stack=1
    },


    ["bucket"]={
        name="Bucket",
        recipe=recipe3x2(
            "iron_ingot", nil, "iron_ingot",
            nil, "iron_ingot", nil
        ),
        ident="minecraft:bucket",
        damage=0,
        stack=16
    },
    ["bucket_water"]={
        name="Water Bucket",
        ident="minecraft:water_bucket",
        damage=0,
        stack=1
    },
    ["bucket_lava"]={
        name="Lava Bucket",
        ident="minecraft:lava_bucket",
        damage=0,
        stack=1
    },


    ["leash"]={
        name="Lead",
        recipe={
            "string", "string", nil,
            "string", "slime_ball", nil,
            nil, nil, "string",
        },
        output=2,
        ident="minecraft:lead",
        damage=0,
        stack=64
    },


    ["workbench"]={
        name="Crafting Table",
        recipe=recipe2x2(
            "planks", "planks",
            "planks", "planks"
        ),
        ident="minecraft:crafting_table",
        damage=0,
        stack=64
    },
    ["chest"]={
        name="Chest",
        recipe={
            "planks", "planks", "planks",
            "planks", nil, "planks",
            "planks", "planks", "planks"
        },
        ident="minecraft:chest",
        damage=0,
        stack=64
    },
    ["hopper"]={
        name="Hopper",
        recipe={
            "iron_ingot", nil, "iron_ingot",
            "iron_ingot", "chest", "iron_ingot",
            nil, "iron_ingot", nil
        },
        ident="minecraft:hopper",
        damage=0,
        stack=64
    },
    ["dropper"]={
        name="Dropper",
        recipe={
            "cobblestone", "cobblestone", "cobblestone",
            "cobblestone", nil, "cobblestone",
            "cobblestone", "redstone", "cobblestone"
        },
        ident="minecraft:dropper",
        damage=0,
        stack=64
    },
    ["dispenser"]={
        name="Dispenser",
        recipe={
            "cobblestone", "cobblestone", "cobblestone",
            "cobblestone", "bow", "cobblestone",
            "cobblestone", "redstone", "cobblestone"
        },
        ident="minecraft:dispenser",
        damage=0,
        stack=64
    },
    ["piston"]={
        name="Piston",
        recipe={
            "planks", "planks", "planks",
            "cobblestone", "iron_ingot", "cobblestone",
            "cobblestone", "redstone", "cobblestone"
        },
        ident="minecraft:piston",
        damage=0,
        stack=64
    },
    ["sticky_piston"]={
        name="Sticky Piston",
        recipe=recipe1x2("slime_ball", "piston"),
        ident="minecraft:sticky_piston",
        damage=0,
        stack=64
    },
    ["cauldron"]={
        name="Cauldron",
        recipe={
            "iron_ingot", nil, "iron_ingot",
            "iron_ingot", nil, "iron_ingot",
            "iron_ingot", "iron_ingot", "iron_ingot"
        },
        ident="minecraft:cauldron",
        damage=0,
        stack=64
    },


    ["sugarcane"]={
        name="Sugar Canes",
        ident="minecraft:reeds",
        damage=0,
        stack=64
    },
    ["cactus"]={
        name="Cactus",
        ident="minecraft:cactus",
        damage=0,
        stack=64
    },


    ["blaze_rod"]={
        name="Blaze Rod",
        ident="minecraft:blaze_rod",
        damage=0,
        stack=64
    },
    ["blaze_powder"]={
        name="Blaze Powder",
        recipe=recipe1x1("blaze_rod"),
        output=2,
        ident="minecraft:blaze_powder",
        damage=0,
        stack=64
    },
    ["bone"]={
        name="Bone",
        ident="minecraft:bone",
        damage=0,
        stack=64
    },
    ["feather"]={
        name="Feather",
        ident="minecraft:feather",
        damage=0,
        stack=64
    },


    ["paper"]={
        name="Paper",
        recipe=recipe3x1("sugarcane", "sugarcane", "sugarcane"),
        output=3,
        ident="minecraft:paper",
        damage=0,
        stack=64
    },
    ["rabbit_hide"]={
        name="Rabbit Hide",
        ident="minecraft:rabbit_hide",
        damage=0,
        stack=64
    },
    ["leather"]={
        name="Leather",
        recipe=recipe2x2(
            "rabbit_hide", "rabbit_hide",
            "rabbit_hide", "rabbit_hide"
        ),
        ident="minecraft:leather",
        damage=0,
        stack=64
    },
    ["book"]={
        name="Book",
        recipe={
            nil, "paper", nil,
            nil, "paper", nil,
            "leather", "paper", nil
        },
        ident="minecraft:book",
        damage=0,
        stack=64
    },


    ["dye_black"]={
        name="Ink Sac",
        ident="minecraft:dye",
        damage=0,
        stack=64
    },
    ["dye_red"]={
        name="Rose Red",
        ident="minecraft:dye",
        damage=1,
        stack=64
    },
    ["dye_green"]={
        name="Cactus Green",
        furnace="cactus",
        ident="minecraft:dye",
        damage=2,
        stack=64
    },
    ["dye_brown"]={
        name="Cocoa Beans",
        ident="minecraft:dye",
        damage=3,
        stack=64
    },
    ["dye_blue"]={
        name="Lapis Lazuli",
        ident="minecraft:dye",
        damage=4,
        stack=64
    },
    ["dye_purple"]={
        name="Purple Dye",
        recipe=recipe1x2("dye_blue", "dye_red"),
        output=2,
        ident="minecraft:dye",
        damage=5,
        stack=64
    },
    ["dye_cyan"]={
        name="Cyan Dye",
        recipe=recipe1x2("dye_blue", "dye_green"),
        output=2,
        ident="minecraft:dye",
        damage=6,
        stack=64
    },
    ["dye_light_gray"]={
        name="Light Gray Dye",
        recipe=recipe1x2("dye_white", "dye_gray"),
        output=2,
        ident="minecraft:dye",
        damage=7,
        stack=64
    },
    ["dye_gray"]={
        name="Gray Dye",
        recipe=recipe1x2("dye_black", "dye_white"),
        output=2,
        ident="minecraft:dye",
        damage=8,
        stack=64
    },
    ["dye_pink"]={
        name="Pink Dye",
        recipe=recipe1x2("dye_red", "dye_white"),
        output=2,
        ident="minecraft:dye",
        damage=9,
        stack=64
    },
    ["dye_lime"]={
        name="Lime Dye",
        recipe=recipe1x2("dye_green", "dye_white"),
        output=2,
        ident="minecraft:dye",
        damage=10,
        stack=64
    },
    ["dye_yellow"]={
        name="Dandelion Yellow",
        ident="minecraft:dye",
        damage=11,
        stack=64
    },
    ["dye_light_blue"]={
        name="Light Blue Dye",
        recipe=recipe1x2("dye_blue", "dye_white"),
        output=2,
        ident="minecraft:dye",
        damage=12,
        stack=64
    },
    ["dye_magenta"]={
        name="Magenta Dye",
        recipe=recipe1x2("dye_purple", "dye_pink"),
        output=2,
        ident="minecraft:dye",
        damage=13,
        stack=64
    },
    ["dye_orange"]={
        name="Orange Dye",
        recipe=recipe1x2("dye_red", "dye_yellow"),
        output=2,
        ident="minecraft:dye",
        damage=14,
        stack=64
    },
    ["dye_white"]={
        name="Bone Meal",
        recipe=recipe1x1("bone"),
        output=3,
        ident="minecraft:dye",
        damage=15,
        stack=64
    },


    -- CIRCUITS & MATERIALS


    ["raw_pcb"]={
        name="Raw Circuit Board",
        recipe=recipe3x1("gold_ingot", "clay", "dye_green"),
        output=8,
        ident="opencomputers:material",
        damage=2,
        stack=64
    },
    ["pcb"]={
        name="Printed Circuit Board (PCB)",
        furnace="raw_pcb",
        ident="opencomputers:material",
        damage=4,
        stack=64
    },
    ["transistor"]={
        name="Transistor",
        recipe={
            "iron_ingot", "iron_ingot", "iron_ingot",
            "gold_nugget", "paper", "gold_nugget",
            nil, "redstone", nil
        },
        output=8,
        ident="opencomputers:material",
        damage=6,
        stack=64
    },
    ["chip1"]={
        name="Microchip (Tier 1)",
        recipe={
            "iron_nugget", "iron_nugget", "iron_nugget",
            "redstone", "transistor", "redstone",
            "iron_nugget", "iron_nugget", "iron_nugget"
        },
        output=8,
        ident="opencomputers:material",
        damage=7,
        stack=64
    },
    ["chip2"]={
        name="Microchip (Tier 2)",
        recipe={
            "gold_nugget", "gold_nugget", "gold_nugget",
            "redstone", "transistor", "redstone",
            "gold_nugget", "gold_nugget", "gold_nugget"
        },
        output=4,
        ident="opencomputers:material",
        damage=8,
        stack=64
    },
    ["chip3"]={
        name="Microchip (Tier 3)",
        recipe={
            "diamond_chip", "diamond_chip", "diamond_chip",
            "redstone", "transistor", "redstone",
            "diamond_chip", "diamond_chip", "diamond_chip"
        },
        output=2,
        ident="opencomputers:material",
        damage=9,
        stack=64
    },
    ["alu"]={
        name="Arithmetic Logic Unit (ALU)",
        recipe={
            "iron_nugget", "redstone", "iron_nugget",
            "transistor", "chip1", "transistor",
            "iron_nugget", "transistor", "iron_nugget"
        },
        ident="opencomputers:material",
        damage=10,
        stack=64
    },
    ["cu"]={
        name="Control Unit (CU)",
        recipe={
            "gold_nugget", "redstone", "gold_nugget",
            "transistor", "clock", "transistor",
            "gold_nugget", "transistor", "gold_nugget"
        },
        ident="opencomputers:material",
        damage=11,
        stack=64
    },
    ["disk"]={
        name="Disk Platter",
        recipe={
            nil, "iron_nugget", nil,
            "iron_nugget", nil, "iron_nugget",
            nil, "iron_nugget", nil
        },
        ident="opencomputers:material",
        damage=12,
        stack=64
    },
    ["analyzer"]={
        name="Analyzer",
        recipe={
            "redstone_torch", nil, nil,
            "transistor", "gold_nugget", nil,
            "pcb", "gold_nugget", nil
        },
        ident="opencomputers:tool",
        damage=0,
        stack=64
    },
    ["cable"]={
        name="Cable",
        recipe={
            nil, "iron_nugget", nil,
            "iron_nugget", "redstone", "iron_nugget",
            nil, "iron_nugget", nil
        },
        output=4,
        ident="opencomputers:cable",
        stack=64
    },
    ["oc_manual"]={
        name="OpenComputers Manual",
        recipe=recipe1x2("book", "chip1"),
        ident="opencomputers:tool",
        damage=4,
        stack=64
    },
    ["capacitor"]={
        name="Capacitor",
        recipe={
            "iron_ingot", "transistor", "iron_ingot",
            "gold_nugget", "paper", "gold_nugget",
            "iron_ingot", "pcb", "iron_ingot"
        },
        ident="opencomputers:capacitor",
        damage=0,
        stack=64
    },
    ["interweb"]={
        name="Interweb",
        recipe={
            "string", "string", "string",
            "string", "ender_pearl", "string",
            "string", "string", "string",
        },
        ident="opencomputers:material",
        damage=13,
        stack=64
    },


    -- CPU


    ["cpu1"]={
        name="Central Processing Unit (CPU) (Tier 1)",
        recipe={
            "iron_nugget", "redstone", "iron_nugget",
            "chip1", "cu", "chip1",
            "iron_nugget", "alu", "iron_nugget"
        },
        ident="opencomputers:component",
        damage=0,
        stack=64
    },
    ["cpu2"]={
        name="Central Processing Unit (CPU) (Tier 2)",
        recipe={
            "gold_nugget", "redstone", "gold_nugget",
            "chip2", "cu", "chip2",
            "gold_nugget", "alu", "gold_nugget"
        },
        ident="opencomputers:component",
        damage=1,
        stack=64
    },
    ["cpu3"]={
        name="Central Processing Unit (CPU) (Tier 3)",
        recipe={
            "diamond_chip", "redstone", "diamond_chip",
            "chip3", "cu", "chip3",
            "diamond_chip", "alu", "diamond_chip"
        },
        ident="opencomputers:component",
        damage=2,
        stack=64
    },


    -- RAM


    ["ram1"]={
        name="Memory (Tier 1)",
        recipe=recipe3x2(
            "chip1", "iron_nugget", "chip1",
            nil, "pcb", nil
        ),
        ident="opencomputers:component",
        damage=6,
        stack=64
    },
    ["ram1_plus"]={
        name="Memory (Tier 1.5)",
        recipe=recipe3x2(
            "chip1", "chip2", "chip1",
            nil, "pcb", nil
        ),
        ident="opencomputers:component",
        damage=7,
        stack=64
    },
    ["ram2"]={
        name="Memory (Tier 2)",
        recipe=recipe3x2(
            "chip2", "iron_nugget", "chip2",
            nil, "pcb", nil
        ),
        ident="opencomputers:component",
        damage=8,
        stack=64
    },
    ["ram2_plus"]={
        name="Memory (Tier 2.5)",
        recipe=recipe3x2(
            "chip2", "chip3", "chip2",
            nil, "pcb", nil
        ),
        ident="opencomputers:component",
        damage=9,
        stack=64
    },
    ["ram3"]={
        name="Memory (Tier 3)",
        recipe=recipe3x2(
            "chip3", "iron_nugget", "chip3",
            nil, "pcb", nil
        ),
        ident="opencomputers:component",
        damage=10,
        stack=64
    },
    ["ram3_plus"]={
        name="Memory (Tier 3.5)",
        recipe=recipe3x2(
            "chip3", "chip3", "chip3",
            "chip2", "pcb", "chip2"
        ),
        ident="opencomputers:component",
        damage=11,
        stack=64
    },


    -- CARDS


    ["card_base"]={
        name="Card Base",
        recipe={
            "iron_nugget", nil, nil,
            "iron_nugget", "pcb", nil,
            "iron_nugget", "gold_nugget", nil
        },
        ident="opencomputers:material",
        damage=5,
        stack=64
    },
    ["gpu1"]={
        name="Graphics Card (Tier 1)",
        recipe=recipe3x2(
            "chip1", "alu", "ram1",
            nil, "card_base", nil
        ),
        ident="opencomputers:card",
        damage=1,
        stack=64
    },
    ["gpu2"]={
        name="Graphics Card (Tier 2)",
        recipe=recipe3x2(
            "chip2", "alu", "ram2",
            nil, "card_base", nil
        ),
        ident="opencomputers:card",
        damage=2,
        stack=64
    },
    ["gpu3"]={
        name="Graphics Card (Tier 3)",
        recipe=recipe3x2(
            "chip3", "alu", "ram3",
            nil, "card_base", nil
        ),
        ident="opencomputers:card",
        damage=3,
        stack=64
    },
    ["redstonecard1"]={
        name="Redstone Card (Tier 1)",
        recipe=recipe2x2(
            "redstone_torch", "chip1",
            nil, "card_base"
        ),
        ident="opencomputers:card",
        damage=4,
        stack=64
    },
    ["redstonecard2"]={
        name="Redstone Card (Tier 2)",
        recipe=recipe3x2(
            "redstone_block", "chip2", "ender_pearl",
            nil, "card_base", nil
        ),
        ident="opencomputers:card",
        damage=5,
        stack=64
    },
    ["lancard"]={
        name="Network Card",
        recipe=recipe2x2(
            "cable", "chip1",
            nil, "card_base"
        ),
        ident="opencomputers:card",
        damage=6,
        stack=64
    },
    ["wlancard"]={
        name="Wireless Network Card",
        recipe=recipe2x2(
            "ender_pearl", "chip2",
            nil, "card_base"
        ),
        ident="opencomputers:card",
        damage=7,
        stack=64
    },
    ["internet_card"]={
        name="Internet Card",
        recipe=recipe3x2(
            "interweb", "chip2", "redstone_torch",
            nil, "card_base", "obsidian"
        ),
        ident="opencomputers:card",
        damage=8,
        stack=64
    },
    -- TODO: special recipe creates pairs of cards
    -- ["linked_card"]={
    --     name="Linked Card",
    --     recipe={
    --         "ender_eye", nil, "ender_eye",
    --         "lancard", "interweb", "lancard",
    --         "chip3", nil, "chip3"
    --     },
    --     output=2,
    --     ident="opencomputers:card",
    --     damage=9,
    --     stack=64
    -- },
    ["datacard1"]={
        name="Data Card (Tier 1)",
        recipe=recipe3x2(
            "iron_nugget", "alu", "chip2",
            nil, "card_base", nil
        ),
        ident="opencomputers:card",
        damage=10,
        stack=64
    },
    ["datacard2"]={
        name="Data Card (Tier 2)",
        recipe=recipe3x2(
            "gold_nugget", "cpu1", "chip3",
            nil, "card_base", nil
        ),
        ident="opencomputers:card",
        damage=11,
        stack=64
    },
    ["datacard3"]={
        name="Data Card (Tier 3)",
        recipe=recipe3x2(
            "diamond_chip", "cpu2", "ram3",
            nil, "card_base", nil
        ),
        ident="opencomputers:card",
        damage=12,
        stack=64
    },
    ["card_upgrade1"]={
        name="Card Container (Tier 1)",
        recipe={
            "iron_ingot", "chip1", "iron_ingot",
            "piston", "chest", nil,
            "iron_ingot", "card_base", "iron_ingot"
        },
        ident="opencomputers:upgrade",
        damage=5,
        stack=64
    },
    ["card_upgrade2"]={
        name="Card Container (Tier 2)",
        recipe={
            "iron_ingot", "chip2", "iron_ingot",
            "piston", "chest", nil,
            "iron_ingot", "card_base", "iron_ingot"
        },
        ident="opencomputers:upgrade",
        damage=6,
        stack=64
    },
    ["card_upgrade3"]={
        name="Card Container (Tier 3)",
        recipe={
            "gold_ingot", "chip2", "gold_ingot",
            "piston", "chest", nil,
            "gold_ingot", "card_base", "gold_ingot"
        },
        ident="opencomputers:upgrade",
        damage=7,
        stack=64
    },


    -- STORAGE


    ["eeprom"]={
        name="EEPROM",
        recipe={
            "gold_nugget", "transistor", "gold_nugget",
            "paper", "chip1", "paper",
            "gold_nugget", "redstone_torch", "gold_nugget"
        },
        ident="opencomputers:storage",
        damage=0,
        stack=64
    },
    ["diskette"]={
        name="Floppy Disk",
        recipe={
            "iron_nugget", "lever", "iron_nugget",
            "paper", "disk", "paper",
            "iron_nugget", "paper", "iron_nugget"
        },
        ident="opencomputers:storage",
        damage=1,
        stack=64
    },
    ["floppy_drive"]={
        name="Disk Drive",
        recipe={
            "iron_ingot", "chip1", "iron_ingot",
            "piston", "stick", nil,
            "iron_ingot", "pcb", "iron_ingot",
        },
        ident="opencomputers:diskdrive",
        damage=0,
        stack=64
    },
    ["rack_floppy_drive"]={
        name="Rack Disk Drive",
        recipe={
            "obsidian", "chip1", "obsidian",
            "iron_fence", "floppy_drive", "iron_fence",
            "obsidian", "pcb", "obsidian"
        },
        ident="opencomputers:component",
        damage=20,
        stack=64
    },
    ["hdd1"]={
        name="Hard Disk Drive (Tier 1) (1MB)",
        recipe={
            "chip1", "disk", "iron_ingot",
            "pcb", "disk", "piston",
            "chip1", "disk", "iron_ingot"
        },
        ident="opencomputers:storage",
        damage=2,
        stack=64
    },
    ["hdd2"]={
        name="Hard Disk Drive (Tier 2) (2MB)",
        recipe={
            "chip2", "disk", "gold_ingot",
            "pcb", "disk", "piston",
            "chip2", "disk", "gold_ingot"
        },
        ident="opencomputers:storage",
        damage=3,
        stack=64
    },
    ["hdd3"]={
        name="Hard Disk Drive (Tier 3) (4MB)",
        recipe={
            "chip3", "disk", "diamond",
            "pcb", "disk", "piston",
            "chip3", "disk", "diamond"
        },
        ident="opencomputers:storage",
        damage=4,
        stack=64
    },


    -- CASES, SCREENS


    ["case1"]={
        name="Computer Case (Tier 1)",
        recipe={
            "iron_ingot", "chip1", "iron_ingot",
            "iron_fence", "chest", "iron_fence",
            "iron_ingot", "pcb", "iron_ingot",
        },
        ident="opencomputers:case1",
        damage=0,
        stack=64
    },
    ["case2"]={
        name="Computer Case (Tier 2)",
        recipe={
            "gold_ingot", "chip2", "gold_ingot",
            "iron_fence", "chest", "iron_fence",
            "gold_ingot", "pcb", "gold_ingot",
        },
        ident="opencomputers:case2",
        damage=0,
        stack=64
    },
    ["case3"]={
        name="Computer Case (Tier 3)",
        recipe={
            "diamond", "chip3", "diamond",
            "iron_fence", "chest", "iron_fence",
            "diamond", "pcb", "diamond",
        },
        ident="opencomputers:case3",
        damage=0,
        stack=64
    },
    ["screen1"]={
        name="Screen (Tier 1)",
        recipe={
            "iron_ingot", "redstone", "iron_ingot",
            "redstone", "chip1", "glass",
            "iron_ingot", "redstone", "iron_ingot",
        },
        ident="opencomputers:screen1",
        damage=0,
        stack=64
    },
    ["screen2"]={
        name="Screen (Tier 2)",
        recipe={
            "gold_ingot", "dye_red", "gold_ingot",
            "dye_green", "chip2", "glass",
            "gold_ingot", "dye_blue", "gold_ingot",
        },
        ident="opencomputers:screen2",
        damage=0,
        stack=64
    },
    ["screen3"]={
        name="Screen (Tier 3)",
        recipe={
            "obsidian", "yellow_dust", "obsidian",
            "yellow_dust", "chip3", "glass",
            "obsidian", "yellow_dust", "obsidian",
        },
        ident="opencomputers:screen3",
        damage=0,
        stack=64
    },


    -- KEYBOARD


    ["button"]={
        name="Button",
        recipe=recipe1x1("stone"),
        ident="minecraft:stone_button",
        damage=0,
        stack=64
    },
    ["buttons"]={
        name="Button Group",
        recipe=recipe3x2(
            "button", "button", "button",
            "button", "button", "button"
        ),
        ident="opencomputers:material",
        damage=14,
        stack=64
    },
    ["arrow_buttons"]={
        name="Arrow Keys",
        recipe=recipe3x2(
            nil, "button", nil,
            "button", "button", "button"
        ),
        ident="opencomputers:material",
        damage=15,
        stack=64
    },
    ["numpad_buttons"]={
        name="Numeric Keypad",
        recipe={
            "button", "button", "button",
            "button", "button", "button",
            "button", "button", "button"
        },
        ident="opencomputers:material",
        damage=16,
        stack=64
    },
    ["keyboard"]={
        name="Keyboard",
        recipe=recipe3x2(
            "buttons", "buttons", "buttons",
            "buttons", "arrow_buttons", "numpad_buttons"
        ),
        ident="opencomputers:keyboard",
        damage=0,
        stack=64
    },


    -- UPGRADES


    ["angel_upgrade"]={
        name="Angel Upgrade",
        recipe={
            "iron_ingot", "ender_pearl", "iron_ingot",
            "chip1", "sticky_piston", "chip1",
            "iron_ingot", "ender_pearl", "iron_ingot"
        },
        ident="opencomputers:upgrade",
        damage=0,
        stack=64
    },
    ["battery_upgrade1"]={
        name="Battery Upgrade (Tier 1)",
        recipe={
            "iron_nugget", "gold_nugget", "iron_nugget",
            "iron_fence", "capacitor", "iron_fence",
            "iron_nugget", "gold_nugget", "iron_nugget"
        },
        ident="opencomputers:upgrade",
        damage=1,
        stack=64
    },
    ["battery_upgrade2"]={
        name="Battery Upgrade (Tier 2)",
        recipe={
            "iron_nugget", "capacitor", "iron_nugget",
            "iron_fence", "gold_nugget", "iron_fence",
            "iron_nugget", "capacitor", "iron_nugget"
        },
        ident="opencomputers:upgrade",
        damage=2,
        stack=64
    },
    ["battery_upgrade3"]={
        name="Battery Upgrade (Tier 3)",
        recipe={
            "iron_nugget", "capacitor", "iron_nugget",
            "capacitor", "diamond_chip", "capacitor",
            "iron_nugget", "capacitor", "iron_nugget"
        },
        ident="opencomputers:upgrade",
        damage=3,
        stack=64
    },
    ["chunkloader_upgrade"]={
        name="Chunkloader Upgrade",
        recipe={
            "gold_ingot", "glass", "gold_ingot",
            "chip3", "ender_eye", "chip3",
            "obsidian", "pcb", "obsidian"
        },
        ident="opencomputers:upgrade",
        damage=4,
        stack=64
    },
    ["crafting_upgrade"]={
        name="Crafting Upgrade",
        recipe={
            "iron_ingot", nil, "iron_ingot",
            "chip1", "workbench", "chip1",
            "iron_ingot", "pcb", "iron_ingot"
        },
        ident="opencomputers:upgrade",
        damage=11,
        stack=64
    },
    ["database_upgrade1"]={
        name="Database Upgrade (Tier 1)",
        recipe={
            "iron_ingot", "analyzer", "iron_ingot",
            "chip1", "hdd1", "chip1",
            "iron_ingot", "pcb", "iron_ingot"
        },
        ident="opencomputers:upgrade",
        damage=12,
        stack=64
    },
    ["database_upgrade2"]={
        name="Database Upgrade (Tier 2)",
        recipe={
            "iron_ingot", "analyzer", "iron_ingot",
            "chip2", "hdd2", "chip2",
            "iron_ingot", "pcb", "iron_ingot"
        },
        ident="opencomputers:upgrade",
        damage=13,
        stack=64
    },
    ["database_upgrade3"]={
        name="Database Upgrade (Tier 3)",
        recipe={
            "iron_ingot", "analyzer", "iron_ingot",
            "chip3", "hdd3", "chip3",
            "iron_ingot", "pcb", "iron_ingot"
        },
        ident="opencomputers:upgrade",
        damage=14,
        stack=64
    },
    ["experience_upgrade"]={
        name="Experience Upgrade",
        recipe={
            "gold_ingot", nil, "gold_ingot",
            "chip2", "emerald", "chip2",
            "gold_ingot", "pcb", "gold_ingot"
        },
        ident="opencomputers:upgrade",
        damage=15,
        stack=64
    },
    ["generator_upgrade"]={
        name="Generator Upgrade",
        recipe={
            "iron_ingot", nil, "iron_ingot",
            "chip1", "piston", "chip1",
            "iron_ingot", "pcb", "iron_ingot"
        },
        ident="opencomputers:upgrade",
        damage=16,
        stack=64
    },
    ["hover_upgrade1"]={
        name="Hover Upgrade (Tier 1)",
        recipe={
            "feather", "chip1", "feather",
            "iron_nugget", "leather", "iron_nugget",
            "feather", "pcb", "feather"
        },
        ident="opencomputers:upgrade",
        damage=27,
        stack=64
    },
    -- TODO:
    -- ["hover_upgrade2"]={
    --     name="Hover Upgrade (Tier 2)",
    --     recipe={
    --         "endstone", "chip2", "endstone",
    --         "gold_nugget", "iron_ingot", "gold_nugget",
    --         "endstone", "pcb", "endstone"
    --     },
    --     ident="opencomputers:upgrade",
    --     damage=28,
    --     stack=64
    -- },
    ["inventory_upgrade"]={
        name="Inventory Upgrade",
        recipe={
            "planks", "hopper", "planks",
            "dropper", "chest", "piston",
            "planks", "chip1", "planks"
        },
        ident="opencomputers:upgrade",
        damage=17,
        stack=64
    },
    ["inventory_controller_upgrade"]={
        name="Inventory Controller Upgrade",
        recipe={
            "gold_ingot", "analyzer", "gold_ingot",
            "dropper", "chip2", "piston",
            "gold_ingot", "pcb", "gold_ingot"
        },
        ident="opencomputers:upgrade",
        damage=18,
        stack=64
    },
    ["leash_upgrade"]={
        name="Leash Upgrade",
        recipe={
            "iron_ingot", "leash", "iron_ingot",
            "leash", "cu", "leash",
            "iron_ingot", "leash", "iron_ingot"
        },
        ident="opencomputers:upgrade",
        damage=26,
        stack=64
    },
    -- TODO:
    -- ["navigation_upgrade"]={
    --     name="Navigation Upgrade",
    --     recipe={
    --         "gold_ingot", "compass", "gold_ingot",
    --         "chip2", "filled_map", "chip2",
    --         "gold_ingot", "potion", "gold_ingot"
    --     },
    --     ident="opencomputers:upgrade",
    --     damage=19,
    --     stack=64
    -- },
    ["piston_upgrade"]={
        name="Piston Upgrade",
        recipe={
            "iron_ingot", "piston", "iron_ingot",
            "stick", "chip1", "stick",
            "iron_ingot", "pcb", "iron_ingot"
        },
        ident="opencomputers:upgrade",
        damage=20,
        stack=64
    },
    ["sign_upgrade"]={
        name="Sign I/O Upgrade",
        recipe={
            "iron_ingot", "dye_black", "iron_ingot",
            "chip1", "stick", "chip1",
            "iron_ingot", "sticky_piston", "iron_ingot"
        },
        ident="opencomputers:upgrade",
        damage=21,
        stack=64
    },
    ["solar_upgrade"]={
        name="Solar Generator Upgrade",
        recipe={
            "glass", "glass", "glass",
            "chip3", "lapis_block", "chip3",
            "iron_ingot", "pcb", "iron_ingot"
        },
        ident="opencomputers:upgrade",
        damage=22,
        stack=64
    },
    ["tank_upgrade"]={
        name="Tank Upgrade",
        recipe={
            "planks", "iron_fence", "planks",
            "dispenser", "cauldron", "piston",
            "planks", "chip1", "planks"
        },
        ident="opencomputers:upgrade",
        damage=23,
        stack=64
    },
    ["tank_controller_upgrade"]={
        name="Tank Controller Upgrade",
        recipe={
            "gold_ingot", "bottle", "gold_ingot",
            "dispenser", "chip2", "piston",
            "gold_ingot", "pcb", "gold_ingot"
        },
        ident="opencomputers:upgrade",
        damage=24,
        stack=64
    },
    ["tractor_beam_upgrade"]={
        name="Tractor Beam Upgrade",
        recipe={
            "gold_ingot", "piston", "gold_ingot",
            "iron_ingot", "capacitor", "iron_ingot",
            "gold_ingot", "chip3", "gold_ingot"
        },
        ident="opencomputers:upgrade",
        damage=25,
        stack=64
    },
    ["trading_upgrade"]={
        name="Trading Upgrade",
        recipe={
            "gold_ingot", "chest", "gold_ingot",
            "emerald", "chip2", "emerald",
            "dropper", "pcb", "piston"
        },
        ident="opencomputers:upgrade",
        damage=29,
        stack=64
    },
    ["upgrade_container1"]={
        name="Upgrade Container (Tier 1)",
        recipe={
            "iron_ingot", "chip1", "iron_ingot",
            "piston", "chest", nil,
            "iron_ingot", "pcb", "iron_ingot"
        },
        ident="opencomputers:upgrade",
        damage=8,
        stack=64
    },
    ["upgrade_container2"]={
        name="Upgrade Container (Tier 2)",
        recipe={
            "iron_ingot", "chip2", "iron_ingot",
            "piston", "chest", nil,
            "iron_ingot", "pcb", "iron_ingot"
        },
        ident="opencomputers:upgrade",
        damage=9,
        stack=64
    },
    ["upgrade_container3"]={
        name="Upgrade Container (Tier 3)",
        recipe={
            "gold_ingot", "chip2", "gold_ingot",
            "piston", "chest", nil,
            "gold_ingot", "pcb", "gold_ingot"
        },
        ident="opencomputers:upgrade",
        damage=10,
        stack=64
    },


    -- DEVICES


    ["adapter"]={
        name="Adapter",
        recipe={
            "iron_ingot", "cable", "iron_ingot",
            "cable", "chip1", "cable",
            "iron_ingot", "pcb", "iron_ingot"
        },
        ident="opencomputers:adapter",
        damage=0,
        stack=64
    },
    ["assembler"]={
        name="Electronics Assembler",
        recipe={
            "iron_ingot", "workbench", "iron_ingot",
            "piston", "chip2", "piston",
            "iron_ingot", "pcb", "iron_ingot"
        },
        ident="opencomputers:assembler",
        damage=0,
        stack=64
    },
    ["disassembler"]={
        name="Disassembler",
        recipe={
            "cu", "glass_pane", "analyzer",
            "piston", nil, "obsidian",
            "iron_ingot", "bucket_lava", "iron_ingot"
        },
        ident="opencomputers:disassembler",
        damage=0,
        stack=64
    },


    -- PRINTER


    ["printer"]={
        name="3D Printer",
        recipe={
            "iron_ingot", "hopper", "iron_ingot",
            "piston", "chip3", "piston",
            "iron_ingot", "pcb", "iron_ingot"
        },
        ident="opencomputers:printer",
        damage=0,
        stack=64
    },
    ["cartridge_empty"]={
        name="Ink Cartridge (Empty)",
        recipe={
            "iron_nugget", "dispenser", "iron_nugget",
            "transistor", "bucket", "transistor",
            "iron_nugget", "pcb", "iron_nugget"
        },
        ident="opencomputers:material",
        damage=26,
        stack=1
    },
    ["cartridge_full"]={
        name="Ink Cartridge",
        recipe=recipe3x2(
            "cartridge_empty", nil, "dye_black",
            "dye_cyan", "dye_magenta", "dye_yellow"
        ),
        ident="opencomputers:material",
        damage=27,
        stack=1
    }
}


-- Self checks


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
        for i=1,9 do
            local item = v.recipe[i]
            if item ~= nil then
                assert(M.items[item] ~= nil, "Unknown item in recipe: " .. item)
            end
        end
    end
    if v.furnace ~= nil then
        assert(M.items[v.furnace] ~= nil, "Unknown item in recipe: " .. v.furnace)
    end
    assert(v.name ~= nil)
    assert(type(v.name) == "string")
    assert(v.stack ~= nil)
    assert(v.stack > 0)
    assert(v.stack <= 64)
end


-- Module interface


function M.detect(slot)
    -- argument is output of inventory_controller_upgrade's getStackInSlot/getStackInInternalSlot
    -- M.detect({
    --     name="minecraft:crafting_table",
    --     damage=0,
    --     maxDamage=0,
    --     size=1,
    --     maxSize=64,
    --     label="Crafting Table",
    --     hasTag=false
    -- })
    -- ="workbench"
    if slot == nil then return end
    local s = detection_map[slot.name]
    if s == nil then return end
    if type(s) == "string" then return s end
    return s[slot.damage]
end


function M.getItemType(itemId)
    -- M.getItemType("workbench")
    -- ="craftable"
    local x = M.items[itemId]
    if x.recipe ~= nil then
        return "craftable"
    elseif x.furnace ~= nil then
        return "smeltable"
    else
        return "raw"
    end
end


function M.getItemName(itemId)
    -- M.getItemName("workbench")
    -- ="Crafting Table"
    return M.items[itemId].name
end


function M.getItemStack(itemId)
    -- M.getItemStack("workbench")
    -- =64
    return M.items[itemId].stack
end


function M.getRecipe(itemId)
    -- M.getRecipe("workbench")
    -- ={
    --     1="planks",
    --     2="planks",
    --     4="planks",
    --     5="planks",
    -- }
    return M.items[itemId].recipe
end


function M.getRecipeOutput(itemId)
    -- M.getRecipeOutput("iron_nugget")
    -- =9
    local output = M.items[item_id].output
    if output == nil then output = 1 end
    return output
end


function M.formatRecipe(recipe)
    -- print(M.formatRecipe(M.getRecipe("workbench")))
    local widths={}

    function getName(row, col)
        local item = recipe[row * 3 + col - 3]
        if item == nil then return "" end
        return M.getItemName(item)
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


return M
