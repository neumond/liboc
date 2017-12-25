local makeClass = require("utils").makeClass


local Stack = makeClass(function(self)
    self.s = {}
    self.ptr = 0
end)


function Stack:push(value)
    self.ptr = self.ptr + 1
    self.s[self.ptr] = value
end

function Stack:pop()
    local value = self.s[self.ptr]
    self.s[self.ptr] = nil
    self.ptr = self.ptr - 1
    return value
end

function Stack:tip(n)
    if n == nil then n = 1 end
    return self.s[self.ptr - (n - 1)]
end

function Stack:transformTip(f)
    self.s[self.ptr] = f(self.s[self.ptr])
end

function Stack:iterFromBottom()
    local i = 0
    return function()
        i = i + 1
        if i > self.ptr then return end
        return i, self.s[i]
    end
end

function Stack:iterFromTop()
    local i = self.ptr + 1
    return function()
        i = i - 1
        if i < 1 then return end
        return i, self.s[i]
    end
end


-- Module


return {
    Stack=Stack
}
