require("busted.runner")()
local mod = require("ui.frames")
local createGPU = require("lib.renderTest").createGPU
local markup = require("ui.markup")


describe("Frames", function()
    it("simplest scenario #skip", function()
        local gpu = createGPU(5, 5, {[0xFFFFFF]=".", [0x000000]="#"})
        local root = mod.FrameRoot(gpu)
        local mf = root:Markup(markup.Div("lol"), {}, {})
        root:assignRoot(mf)
        root:update()
    end)
end)
