require("busted.runner")()
local mod = require("ui.offScreen")
local testFuncs = require("lib.gpu.consTests")
local gatherMod = require("lib.gpu.gather")
local expectedResults = require("lib.gpu.gpuResult_auto")
local renderTest = require("lib.renderTest")
local C = renderTest.shortColors


local function makeGpuTests(createGpuFunc)
    describe("consistency with real GPU", function()
        local gpu = createGpuFunc()
        for testName, realResult in pairs(expectedResults) do
            it(testName, function()
                local testFunc = testFuncs[testName]
                local result = {gatherMod.getGpuResult(gpu, testFunc)}
                assert.are_same(realResult, result)
            end)
        end
    end)
    it("reproduces correctly", function()
        local gpu = createGpuFunc()
        local width, height = 10, 5
        gpu.setResolution(width, height)
        gpu.setForeground(C.Y)
        gpu.setBackground(C.P)
        gpu.fill(1, 1, 10, 5, ".")
        gpu.setForeground(C.W)
        gpu.setBackground(C.G)
        gpu.set(4, 4, "abcd")
        gpu.set(4, 5, "ネエ")


        local targetGpu = renderTest.createGPU(width, height, renderTest.colorBox)
        gpu.reproduce(targetGpu)
        assert.are_same({
            "..........",
            "..........",
            "..........",
            "...abcd...",
            "...ネエ..."
        }, targetGpu.getTextResult(true))
        assert.are_same({
            "YYYYYYYYYY",
            "YYYYYYYYYY",
            "YYYYYYYYYY",
            "YYYWWWWYYY",
            "YYYWWWWYYY"
        }, targetGpu.getColorResult(true))
        assert.are_same({
            "PPPPPPPPPP",
            "PPPPPPPPPP",
            "PPPPPPPPPP",
            "PPPGGGGPPP",
            "PPPGGGGPPP"
        }, targetGpu.getBackgroundResult(true))
    end)
end


describe("off-screen buffers", function()
    describe("NaiveBuffer", function()
        makeGpuTests(function()
            return mod.NaiveBuffer():getGpuInterface()
        end)
    end)
end)
