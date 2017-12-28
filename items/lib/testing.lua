local M = {}


function M.iterArrayValues(t)
    local ptr = 0
    return function()
        ptr = ptr + 1
        if t[ptr] == nil then return end
        return table.unpack(t[ptr])
    end
end


local function wrapTupleIter(iter)
    return function()
        local v = {iter()}
        if #v == 0 then return end
        return v
    end
end


function M.accumulate(iter)
    local result = {}
    for item in wrapTupleIter(iter) do
        table.insert(result, item)
    end
    return result
end


function M.makeIterTestable(f)
    return function(items)
        return M.accumulate(f(M.iterArrayValues(items)))
    end
end


return M
