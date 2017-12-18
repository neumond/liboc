require("busted.runner")()
local mod = require("roomBot.crafterBot")


describe("crafterBot", function()
    describe("complex craft planning", function()
        it("can assemble workbench out of 4 planks", function()
            local success, clog = mod.testing.planCrafting({
                ["planks"]=4
            }, "workbench", 1)
            assert.is_true(success)
        end)
        it("can't assemble workbench out of 3 planks", function()
            local success, clog = mod.testing.planCrafting({
                ["planks"]=3
            }, "workbench", 1)
            assert.is_false(success)
        end)

        it("can assemble workbench out of 1 wood", function()
            local success, clog = mod.testing.planCrafting({
                ["wood"]=1
            }, "workbench", 1)
            assert.is_true(success)
        end)

        it("can assemble 2 workbenches out of 1 wood and 4 planks", function()
            local success, clog = mod.testing.planCrafting({
                ["wood"]=1,
                ["planks"]=4
            }, "workbench", 2)
            assert.is_true(success)
        end)
        it("can't assemble 2 workbenches out of 1 wood and 3 planks", function()
            local success, clog = mod.testing.planCrafting({
                ["wood"]=1,
                ["planks"]=3
            }, "workbench", 2)
            assert.is_false(success)
        end)
    end)
end)
