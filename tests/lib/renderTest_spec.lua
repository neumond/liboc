require("busted.runner")()
local mod = require("lib.renderTest")


describe("renderTest", function()
    it("creates prefilled planes", function()
        local gpu = mod.createGPU(3, 3, {})
        assert.are_same({
            "¶¶¶",
            "¶¶¶",
            "¶¶¶",
        }, gpu.getTextResult())
        assert.are_same({
            "¶¶¶",
            "¶¶¶",
            "¶¶¶",
        }, gpu.getColorResult())
        assert.are_same({
            "¶¶¶",
            "¶¶¶",
            "¶¶¶",
        }, gpu.getBackgroundResult())
    end)
    it("fill method", function()
        local gpu = mod.createGPU(3, 3, {
            [0] = ".",
            [1] = "#"
        })
        gpu.setForeground(1)
        gpu.setBackground(0)
        gpu.fill(2, 2, 1, 1, "A")
        assert.are_same({
            "¶¶¶",
            "¶A¶",
            "¶¶¶",
        }, gpu.getTextResult())
        assert.are_same({
            "¶¶¶",
            "¶#¶",
            "¶¶¶",
        }, gpu.getColorResult())
        assert.are_same({
            "¶¶¶",
            "¶.¶",
            "¶¶¶",
        }, gpu.getBackgroundResult())
    end)
    it("set method", function()
        local gpu = mod.createGPU(3, 3, {
            [0] = ".",
            [1] = "#"
        })
        gpu.setForeground(1)
        gpu.setBackground(0)
        gpu.set(2, 2, "Aa")
        assert.are_same({
            "¶¶¶",
            "¶Aa",
            "¶¶¶",
        }, gpu.getTextResult())
        assert.are_same({
            "¶¶¶",
            "¶##",
            "¶¶¶",
        }, gpu.getColorResult())
        assert.are_same({
            "¶¶¶",
            "¶..",
            "¶¶¶",
        }, gpu.getBackgroundResult())
    end)
    it("copy method", function()
        local gpu = mod.createGPU(3, 3, {
            [0] = ".",
            [1] = "#"
        })
        gpu.setForeground(1)
        gpu.setBackground(0)
        gpu.set(2, 2, "Aa")
        gpu.copy(2, 2, 2, 2, -1, -1)
        assert.are_same({
            "Aa¶",
            "¶¶a",
            "¶¶¶",
        }, gpu.getTextResult())
        assert.are_same({
            "##¶",
            "¶¶#",
            "¶¶¶",
        }, gpu.getColorResult())
        assert.are_same({
            "..¶",
            "¶¶.",
            "¶¶¶",
        }, gpu.getBackgroundResult())
    end)
end)
