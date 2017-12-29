local utils = require("utils")


local function forceRange(value, a, b)
    return math.min(math.max(value, a), b)
end


local function intersection(a1, a2, b1, b2)
    if (b1 > a2) or (b2 < a1) then return end
    return math.max(a1, b1), math.min(a2, b2)
end


local function intersectionWH(a, aw, b, bw)
    local j, k = intersection(a, a + aw - 1, b, b + bw - 1)
    if j == nil then return end
    return j, k - j + 1
end


-- RegionGpu


local function RegionGpu(gpu, winX, winY, winWidth, winHeight)
    local fg, bg

    local function flushColors()
        if fg ~= nil then
            gpu.setForeground(fg)
            fg = nil
        end
        if bg ~= nil then
            gpu.setBackground(bg)
            bg = nil
        end
    end

    return {
        set = function(x, y, text)
            flushColors()
            local w = utils.strlen(text)
            local ox, ow = intersectionWH(1, winWidth, x, w)
            if ox == nil then return false end
            local oy, _ = intersectionWH(1, winHeight, y, 1)
            if oy == nil then return false end
            if w ~= ow then
                local textX = 1 + ox - x
                text = utils.strsub(text, textX, textX + ow - 1)
            end
            return gpu.set(ox + winX - 1, oy + winY - 1, text)
        end,
        get = function(x, y)
            return gpu.get(x + winX - 1, y + winY - 1)
        end,
        fill = function(x, y, w, h, fillchar)
            flushColors()
            local ox, ow = intersectionWH(1, winWidth, x, w)
            if ox == nil then return false end
            local oy, oh = intersectionWH(1, winHeight, y, h)
            if oy == nil then return false end
            return gpu.fill(ox + winX - 1, oy + winY - 1, ow, oh, fillchar)
        end,
        setForeground = function(color)  -- TODO: palette colors support
            fg = color
            -- gpu.setForeground(color)
            -- NOTE: no return value here
        end,
        setBackground = function(color)
            bg = color
            -- gpu.setBackground(color)
            -- NOTE: no return value here
        end,
        getResolution = function()
            return winWidth, winHeight
        end,
        copy = function(x, y, width, height, tx, ty)
            x, width = intersectionWH(1, winWidth, x, width)
            if x == nil then return false end
            y, height = intersectionWH(1, winHeight, y, height)
            if y == nil then return false end

            _, targetWidth = intersectionWH(1, winWidth, x + tx, width)
            if targetWidth == nil then return false end
            _, targetHeight = intersectionWH(1, winHeight, y + ty, height)
            if targetHeight == nil then return false end

            correctedWidth = math.min(width, targetWidth)
            correctedHeight = math.min(height, targetHeight)

            wDiff = width - correctedWidth
            hDiff = height - correctedHeight

            if tx < 0 then x = x + wDiff end
            if ty < 0 then y = y + hDiff end
            return gpu.copy(x + winX - 1, y + winY - 1, correctedWidth, correctedHeight, tx, ty)
        end
    }
end


return {
    forceRange=forceRange,
    intersection=intersection,
    intersectionWH=intersectionWH,
    RegionGpu=RegionGpu
}
