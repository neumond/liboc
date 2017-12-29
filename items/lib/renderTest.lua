local utils = require("utils")
local Buffer = require("ui.offScreen").NaiveBuffer


-- Test gpu


local PREFILL = "¶"
assert(utils.strlen(PREFILL) == 1)
assert(utils.charWidth(PREFILL) == 1)


local function createGPU(width, height, colorBox)
    local gpu = Buffer():getGpuInterface()

    -- gpu.setResolution(width, height)
    gpu.setForeground(0x888888)
    gpu.setBackground(0x888888)
    gpu.fill(1, 1, width, height, PREFILL)

    local function pickColor(color)
        local r = colorBox[color]
        if r == nil then r = PREFILL end
        assert(utils.strlen(r) == 1)
        return r
    end

    gpu.getTextResult = function(stripTail)
        local r = {}
        for y=1,height do
            local row = {}
            local x = 1
            while x <= width do
                local char, fc, bc = gpu.get(x, y)
                table.insert(row, char)
                x = x + utils.charWidth(char)
            end
            r[y] = table.concat(row, "")
        end

        if not stripTail then return r end
        local m = string.rep(PREFILL, width)
        local cutter = height
        for y=height,1,-1 do
            if r[y] == m then
                cutter = y - 1
            else
                break
            end
        end
        local rout = {}
        for y=1,cutter do table.insert(rout, r[y]) end
        return rout
    end

    gpu.getColorResult = function()
        local r = {}
        for y=1,height do
            local row = {}
            for x=1,width do
                local char, fc, bc = gpu.get(x, y)
                row[x] = pickColor(fc)
            end
            r[y] = table.concat(row, "")
        end
        return r
    end

    gpu.getBackgroundResult = function()
        local r = {}
        for y=1,height do
            local row = {}
            for x=1,width do
                local char, fc, bc = gpu.get(x, y)
                row[x] = pickColor(bc)
            end
            r[y] = table.concat(row, "")
        end
        return r
    end

    return gpu
end


-- Module


return {
    createGPU=createGPU
}
