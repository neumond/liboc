local function enumGrid(width, height, step)
    local x = 0
    local y = 1
    return function()
        x = x + 1
        if x > width then
            x = 1
            y = y + 1
        end
        if y > height then return end
        if y % 2 == 1 then
            return (x - 1) * step, (y - 1) * step
        else
            return (width - x) * step, (y - 1) * step
        end
    end
end


local function enumPerimeter(width, height)
    width = width - 1
    height = height - 1

    local phase = 0
    local x = 0
    local max = 0

    if width == 0 and height == 0 then
        return function()
            phase = phase + 1
            if phase > 1 then return end
            return 0, 0
        end
    end

    return function()
        x = x + 1
        if x >= max then
            x = 0
            repeat
                phase = phase + 1
                if phase % 2 == 1 then
                    max = width
                else
                    max = height
                end
            until max > 0 or phase > 4
        end
        if phase == 1 then
            return x, 0
        elseif phase == 2 then
            return width, x
        elseif phase == 3 then
            return width - x, height
        elseif phase == 4 then
            return 0, height - x
        end
    end
end


return {
    enumGrid=enumGrid,
    enumPerimeter=enumPerimeter
}
