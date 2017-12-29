require("busted.runner")()
local mod = require("ui.offScreen")
local testFuncs = require("lib.gpu.consTests")
local gatherMod = require("lib.gpu.gather")
local expectedResults = require("lib.gpu.gpuResult_auto")


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
end


describe("off-screen buffers", function()
    describe("NaiveBuffer", function()
        makeGpuTests(function()
            return mod.NaiveBuffer():getGpuInterface()
        end)
    end)
end)
