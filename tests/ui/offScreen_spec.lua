require("busted.runner")()
local mod = require("ui.offScreen")
local rtMod = require("lib.renderTest")


local function makeGpuTests(createGpuFunc)
    describe("consistency with real GPU", function()
        local ref = require("gpuResult_auto")
        local gpu = createGpuFunc()
        for testName, realResult in pairs(ref) do
            it(testName, function()
                local testFunc = rtMod.consistency.testFuncs[testName]
                local result = {rtMod.consistency.getGpuResult(gpu, testFunc)}
                assert.are_same(realResult, result)
            end)
        end
    end)
end


describe("off-screen buffers", function()
    describe("NaiveBuffer", function()
        makeGpuTests(function()
            return mod.NaiveBuffer():getGpuInterface()
        end)
    end)
end)
