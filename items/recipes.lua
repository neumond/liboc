local Menu = require("lib.simpleMenu").Menu
local db = require("recipedb")
local term = require("term")
local event = require("event")


function waitForKey()
    repeat
        local _, _, _, key = event.pull("key_down")
    until key == 28
end


function makeMenu(mcons)
    return function(titlePrefix)
        local choice = nil
        while true do
            choice = mcons(
                Menu(true, choice)
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
    return self:addCategory{
        title=db.getItemName(item_id),
        run=makeMenu(function(menu)
            if db.getRecipe(item_id) ~= nil then
                menu:addText("Recipe:\n")
                menu:addText(db.formatRecipe(db.getRecipe(item_id)))
                menu:addCategory({
                    title="Assemble",
                    run=function()
                        term.clear()
                        print(item_id)
                        waitForKey()
                    end
                })
            else
                menu:addText("No recipe available.")
            end
            return menu
        end)
    }
end


function main(af)
    local menuFunc = makeMenu(function(menu)
        return menu
            :addCategory{
                title="Cases, screens, keyboards",
                run=makeMenu(function(menu)
                    return menu
                        :addItem("case1")
                        :addItem("case2")
                        :addItem("case3")
                        :addItem("screen1")
                        :addItem("screen2")
                        :addItem("screen3")
                        :addItem("keyboard")
                end)
            }
            :addCategory{
                title="CPUs",
                run=makeMenu(function(menu)
                    return menu
                        :addItem("cpu1")
                        :addItem("cpu2")
                        :addItem("cpu3")
                end)
            }
            :addCategory{
                title="RAM modules",
                run=makeMenu(function(menu)
                    return menu
                        :addItem("ram1")
                        :addItem("ram1_plus")
                        :addItem("ram2")
                        :addItem("ram2_plus")
                        :addItem("ram3")
                        :addItem("ram3_plus")
                end)
            }
            :addCategory{
                title="Storage",
                run=makeMenu(function(menu)
                    return menu
                        :addItem("diskette")
                        :addItem("floppy_drive")
                        :addItem("eeprom")
                        :addItem("hdd1")
                        :addItem("hdd2")
                        :addItem("hdd3")
                end)
            }
            :addCategory{
                title="Cards",
                run=makeMenu(function(menu)
                    return menu
                        :addItem("gpu1")
                        :addItem("gpu2")
                        :addItem("gpu3")
                        :addItem("lancard")
                        :addItem("cable")
                        :addItem("wlancard")
                        :addItem("redstonecard1")
                        :addItem("redstonecard2")
                        :addItem("internet_card")
                        :addItem("datacard1")
                        :addItem("datacard2")
                        :addItem("datacard3")
                end)
            }
            :addCategory{
                title="Upgrades",
                run=makeMenu(function(menu)
                    return menu
                        :addCategory{
                            title="Tier 1",
                            run=makeMenu(function(menu)
                                return menu
                                    :addItem("battery_upgrade1")
                                    :addItem("database_upgrade1")
                                    :addItem("hover_upgrade1")
                                    :addItem("inventory_upgrade")
                                    :addItem("leash_upgrade")
                                    :addItem("piston_upgrade")
                                    :addItem("sign_upgrade")
                                    :addItem("tank_upgrade")
                            end)
                        }
                        :addCategory{
                            title="Tier 2",
                            run=makeMenu(function(menu)
                                return menu
                                    :addItem("angel_upgrade")
                                    :addItem("battery_upgrade2")
                                    :addItem("crafting_upgrade")
                                    :addItem("database_upgrade2")
                                    :addItem("generator_upgrade")
                                    :addItem("inventory_controller_upgrade")
                                    :addItem("solar_upgrade")
                                    :addItem("tank_controller_upgrade")
                                    :addItem("trading_upgrade")
                            end)
                        }
                        :addCategory{
                            title="Tier 3",
                            run=makeMenu(function(menu)
                                return menu
                                    :addItem("battery_upgrade3")
                                    :addItem("chunkloader_upgrade")
                                    :addItem("database_upgrade3")
                                    :addItem("experience_upgrade")
                                    :addItem("tractor_beam_upgrade")
                            end)
                        }
                end)
            }
            :addCategory{
                title="Slots",
                run=makeMenu(function(menu)
                    return menu
                        :addItem("card_upgrade1")
                        :addItem("card_upgrade2")
                        :addItem("card_upgrade3")
                        :addItem("upgrade_container1")
                        :addItem("upgrade_container2")
                        :addItem("upgrade_container3")
                end)
            }
            :addCategory{
                title="Devices",
                run=makeMenu(function(menu)
                    return menu
                        :addItem("adapter")
                        :addItem("assembler")
                        :addItem("disassembler")
                end)
            }
            :addCategory{
                title="Printing",
                run=makeMenu(function(menu)
                    return menu
                        :addItem("printer")
                        :addItem("cartridge_full")
                end)
            }
            :addCategory{
                title="Test",
                run=makeMenu(function(menu)
                    return menu
                        :addItem("iron_nugget")
                end)
            }
    end)
    menuFunc("Recipe assembler")
    term.clear()
end


main()
