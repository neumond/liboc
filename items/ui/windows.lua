local utils = require("utils")


function intersection(a1, a2, b1, b2)
    if (b1 > a2) or (b2 < a1) then return end
    return math.max(a1, b1), math.min(a2, b2)
end


function intersectionWH(a, aw, b, bw)
    local j, k = intersection(a, a + aw - 1, b, b + bw - 1)
    if j == nil then return end
    return j, k - j + 1
end


-- RegionGpu


function RegionGpu(gpu, winX, winY, winWidth, winHeight, scrollX, scrollY)
    return {
        set = function(x, y, text)
            x = x - scrollX
            y = y - scrollY
            local w = utils.strlen(text)
            local ox, ow = intersectionWH(1, winWidth, x, w)
            if ox == nil then return end
            local oy, _ = intersectionWH(1, winHeight, y, 1)
            if oy == nil then return end
            if w ~= ow then
                local textX = 1 + ox - x
                text = utils.strsub(text, textX, textX + ow - 1)
            end
            gpu.set(ox + winX - 1, oy + winY - 1, text)
        end,
        fill = function(x, y, w, h, fillchar)
            x = x - scrollX
            y = y - scrollY
            local ox, ow = intersectionWH(1, winWidth, x, w)
            if ox == nil then return end
            local oy, oh = intersectionWH(1, winHeight, y, h)
            if oy == nil then return end
            gpu.fill(ox + winX - 1, oy + winY - 1, ow, oh, fillchar)
        end,
        setForeground = function(color)
            return gpu.setForeground(color)
        end,
        setBackground = function(color)
            return gpu.setBackground(color)
        end
    }
end


-- Surface
-- Represents constrained part of screen capable of outputting Elements
-- Can scroll over its contents


local Surface = utils.makeClass(function(self, markup, minWidth, initialWidth)
    self.markup = markup
end)


function Surface:changeWidth()
end


function Surface:render()
end


--


local VSplitter = utils.makeClass(function(self)
end)


local HSplitter = utils.makeClass(function(self)
end)


-- Module


return {
    RegionGpu=RegionGpu,
    testing={
        intersection=intersection
    }
}
