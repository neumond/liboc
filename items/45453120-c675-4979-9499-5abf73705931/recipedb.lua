function recipe1x1(item)
    return {
        nil, nil, nil,
        nil, item, nil,
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


local ITEMS = {
    ["iron_ingot"]={
        name="Iron ingot"
    },
    ["gold_ingot"]={
        name="Gold ingot"
    },
    ["redstone"]={
        name="Redstone"
    },
    ["sugarcane"]={
        name="Sugarcane"
    },
    ["paper"]={
        name="Paper",
        recipe=recipe3x1("sugarcane", "sugarcane", "sugarcane")
    },
    ["iron_nugget"]={
        name="Iron nugget",
        recipe=recipe1x1("iron_ingot")
    },
    ["gold_nugget"]={
        name="Gold nugget",
        recipe=recipe1x1("gold_ingot")
    },
    ["transistor"]={
        name="Transistor",
        recipe={
            "iron_nugget", "iron_nugget", "iron_nugget",
            "gold_nugget", "paper", "gold_nugget",
            nil, "redstone", nil
        }
    },
    ["chip1"]={
        name="Chip I",
        recipe={
            "iron_nugget", "iron_nugget", "iron_nugget",
            "redstone", "transistor", "redstone",
            "iron_nugget", "iron_nugget", "iron_nugget"
        }
    }
}

return ITEMS
