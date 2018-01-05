require("busted.runner")()
local mod = require("roomBot.storageIndex")


describe("Storage Index module intended for tracking set of slots in inventories/chests", function()
    describe("ItemToSlotIndex", function()
        it("works in simple cases", function()
            local x = mod.testing.ItemToSlotIndex()
            -- x:refill(itemId, slotId, halfFilled)
            -- x:empty(itemId, slotId)
            -- x:findForInput(itemId)
            -- x:findForOutput(itemId)

            assert(x:findForInput("stone") == nil)
            assert(x:findForOutput("stone") == nil)

            x:refill("stone", 4, true)
            x:refill("stone", 3, false)

            assert(x:findForInput("stone") == 4)
            assert(x:findForOutput("stone") == 4)

            x:empty("stone", 4)

            assert(x:findForInput("stone") == 3)  -- still can take from full slot
            assert(x:findForOutput("stone") == nil)  -- need new empty slot for output

            x:empty("stone", 3)

            assert(x:findForInput("stone") == nil)
            assert(x:findForOutput("stone") == nil)
        end)
        it("converts half filled slots directly into full", function()
            local x = mod.testing.ItemToSlotIndex()

            x:refill("stone", 4, true)

            assert(x:findForInput("stone") == 4)
            assert(x:findForOutput("stone") == 4)

            x:refill("stone", 4, false)

            assert(x:findForInput("stone") == 4)
            assert(x:findForOutput("stone") == nil)

            x:refill("stone", 4, true)

            assert(x:findForInput("stone") == 4)
            assert(x:findForOutput("stone") == 4)
        end)
        it("successfully finds better slots", function()
            local x = mod.testing.ItemToSlotIndex()

            x:refill("stone", 18, false)
            x:refill("stone", 19, false)
            x:refill("stone", 20, true)

            assert(x:findForInput("stone") == 20)
            assert(x:findForOutput("stone") == 20)

            x:refill("stone", 19, true)

            assert(x:findForInput("stone") == 19)
            assert(x:findForOutput("stone") == 19)

            x:refill("stone", 19, false)

            assert(x:findForInput("stone") == 20)
            assert(x:findForOutput("stone") == 20)

            x:empty("stone", 20)

            assert(x:findForInput("stone") == 18)
            assert(x:findForOutput("stone") == nil)

            x:empty("stone", 18)

            assert(x:findForInput("stone") == 19)
            assert(x:findForOutput("stone") == nil)
        end)
        it("calls are idempotent", function()
            local x = mod.testing.ItemToSlotIndex()

            x:refill("stone", 4, true)
            x:refill("stone", 4, true)
            x:refill("stone", 4, true)

            assert(x:findForInput("stone") == 4)
            assert(x:findForOutput("stone") == 4)

            x:refill("stone", 4, false)
            x:refill("stone", 4, false)
            x:refill("stone", 4, false)

            assert(x:findForInput("stone") == 4)
            assert(x:findForOutput("stone") == nil)

            x:empty("stone", 4)
            x:empty("stone", 4)
            x:empty("stone", 4)

            assert(x:findForInput("stone") == nil)
            assert(x:findForOutput("stone") == nil)
        end)
    end)
    describe("EmptySlotIndex", function()
        it("works in simple cases", function()
            local x = mod.testing.EmptySlotIndex()
            -- x:fill(slotId)
            -- x:empty(slotId)
            -- x:find()

            assert(x:find() == nil)

            x:empty(19)

            assert(x:find() == 19)

            x:fill(19)

            assert(x:find() == nil)

            x:empty(19)
            x:empty(25)
            x:empty(14)
            x:empty(14)
            x:empty(14)
            x:empty(48)

            assert(x:find() == 14)

            x:fill(14)

            assert(x:find() == 19)

            x:fill(25)
            x:fill(25)
            x:fill(25)
            x:fill(19)

            assert(x:find() == 48)

            x:fill(48)

            assert(x:find() == nil)
        end)
    end)
    describe("SlotIndex", function()
        it("works in simple cases", function()
            local x = mod.testing.SlotIndex()
            -- x:registerSlot(address)
            -- x:fill(slotId, itemId, amount)
            -- x:empty(slotId)
            -- x:get(slotId)

            local slotA = x:registerSlot(nil)
            local slotB = x:registerSlot(nil)

            x:fill(slotA, "stone", 10)

            assert(x.stock["stone"] == 10)

            x:fill(slotB, "stone", 10)

            assert(x.stock["stone"] == 20)

            x:fill(slotB, "stone", 40)

            assert(x.stock["stone"] == 50)

            x:empty(slotB)

            assert(x.stock["stone"] == 10)
        end)
    end)
    describe("caught bugs in live testing", function()
        it("propeply assembles pistons", function()
            local initialItems = {}
            for i=239,247 do
                initialItems[i] = {"cobblestone", 64, 64}
            end
            for i=347,349 do
                initialItems[i] = {"redstone", 64, 64}
            end
            for i=401,410 do
                initialItems[i] = {"iron_ingot", 64, 64}
            end
            initialItems[509] = {"wood", 64, 64}
            initialItems[563] = {"wood", 64, 64}
            initialItems[564] = {"wood", 64, 64}

            local x = mod.IntegratedIndex()
            for i=1,670 do
                x:registerSlot(nil)
                if initialItems[i] ~= nil then
                    x:refill(i, table.unpack(initialItems[i]))
                else
                    x:empty(i)
                end
            end

            x:refill(509, "wood", 48, 64)
            x:refill(1, "planks", 64, 64)
            x:refill(509, "wood", 32, 64)
            x:refill(2, "planks", 64, 64)
            x:refill(509, "wood", 16, 64)
            x:refill(3, "planks", 64, 64)
            x:refill(509, "wood", 11, 64)
            x:refill(4, "planks", 20, 64)
            x:empty(4)

            local slotId = x:findInputSlot("planks")
            assert(slotId == 1)
        end)
        it("can handle stub items", function()
            local x = mod.IntegratedIndex()
            for i=1,27 do
                x:registerSlot(nil)
            end
            x:refill(1, "iron_nugget", 9, 64)
            for i=1,9 do
                x:refill(i, "__stub__", 1, 1)
            end
            local slotId = x:findOutputSlot("iron_nugget")
            -- print(require("inspect")(x.itemToSlot))
            assert.is_nil(x.itemToSlot:findForOutput("iron_nugget"))
            assert.are_equal(10, slotId)
        end)
    end)
end)
