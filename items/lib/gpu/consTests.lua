local M = {}


-- Consistency test functions


function M.fillWide(gpu)
    gpu.fill(1, 1, 3, 3, "シ")
    return 6, 3
end


function M.fillUnaligned(gpu)
    gpu.fill(1, 1, 3, 3, "シ")
    gpu.fill(2, 1, 2, 3, "ネ")
    return 6, 3
end


function M.setWide(gpu)
    gpu.set(1, 1, "abc")
    gpu.set(1, 1, "シ")
    return 4, 1
end


function M.setWideUnaligned(gpu)
    gpu.set(1, 1, "シシシシ")
    gpu.set(1, 2, "シシシシ")

    gpu.set(2, 1, "abcdef")
    gpu.set(2, 2, "ネエミ")
    return 8, 2
end


function M.copyWideUnaligned(gpu)
    for y=1,4 do
        gpu.set(2, y, "カタカナ")
    end
    gpu.copy(2, 1, 4, 1, -1, 0)
    gpu.copy(2, 2, 8, 1, -1, 0)
    gpu.copy(2, 3, 4, 1, 1, 0)
    gpu.copy(2, 4, 8, 1, 1, 0)
    return 10, 4
end


function M.copyBackwardThenSet(gpu)
    gpu.set(2, 1, "シ")
    gpu.copy(2, 1, 1, 1, -1, 0)
    gpu.set(3, 1, "カ")
    return 5, 1
end


function M.copyForwardThenSet(gpu)
    gpu.set(1, 1, "シ")
    gpu.copy(1, 1, 1, 1, 1, 0)
    gpu.set(3, 1, "abc")
    return 5, 1
end


-- TODO: uneven resolutions/changing resolutions and wide chars


return M
