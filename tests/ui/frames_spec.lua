require("busted.runner")()
local mod = require("ui.frames")
local renderTest = require("lib.renderTest")
local markup = require("ui.markup")


describe("Frames", function()
    it("simplest scenario #skip", function()
        local gpu = renderTest.createGPU(5, 5, renderTest.colorBox)
        local root = mod.FrameRoot(gpu)
        local mf = root:Markup(markup.Div("lol"), {}, {})
        root:assignRoot(mf)
        root:update()

        assert.are_same({
            "lol  ",
            "     ",
            "     ",
            "     ",
            "     "
        }, gpu.getTextResult(true))
        assert.are_same({
            "WWWWW",
            "WWWWW",
            "WWWWW",
            "WWWWW",
            "WWWWW"
        }, gpu.getColorResult(true))
        assert.are_same({
            "BBBBB",
            "BBBBB",
            "BBBBB",
            "BBBBB",
            "BBBBB"
        }, gpu.getBackgroundResult(true))
    end)
end)
