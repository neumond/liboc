local makeClass = require("utils").makeClass


local function nextBinTreeIndex(current, isRight)
    return current * 2 + (isRight and 1 or 0)
end


local function parentBinTreeIndex(current)
    return current // 2
end


-- min-priority
local BinaryHeap = makeClass(function(self)
    self.prios = {}
    self.payloads = {}
    self.ptr = 0
end)


function BinaryHeap:tip()
    return self.prios[1], self.payloads[1]
end


function BinaryHeap:_swap(a, b)
    assert(a <= self.ptr)
    assert(b <= self.ptr)
    local t = self.prios
    t[a], t[b] = t[b], t[a]
    local t = self.payloads
    t[a], t[b] = t[b], t[a]
end


function BinaryHeap:_bubbleUp(i)
    local priority = self.prios[i]
    while i > 1 do
        local p = parentBinTreeIndex(i)
        if self.prios[p] <= priority then break end
        self:_swap(i, p)
        i = p
    end
end


function BinaryHeap:insert(priority, payload)
    local i = self.ptr + 1
    self.prios[i] = priority
    self.payloads[i] = payload
    self.ptr = i
    self:_bubbleUp(i)
end


function BinaryHeap:pop()
    if self.ptr <= 0 then return end

    local i = 1
    local resultPrio = self.prios[1]
    local resultPayload = self.payloads[1]

    self:_swap(1, self.ptr)
    self.prios[self.ptr] = nil
    self.ptr = self.ptr - 1
    local priority = self.prios[1]

    while i <= self.ptr do
        -- choosing smallest child
        local s = nextBinTreeIndex(i, false)
        if s > self.ptr then break end  -- no children at all
        if s + 1 <= self.ptr then  -- if has right child
            if self.prios[s + 1] < self.prios[s] then s = s + 1 end
        end
        if priority < self.prios[s] then break end
        self:_swap(i, s)
        i = s
    end

    return resultPrio, resultPayload
end


local TrackingBinaryHeap = makeClass(BinaryHeap, function(self, super)
    super()
    self.tracking = {}
end)


function TrackingBinaryHeap:_swap(a, b)
    TrackingBinaryHeap.__super._swap(self, a, b)
    self.tracking[self.payloads[a]] = a
    self.tracking[self.payloads[b]] = b
end


function TrackingBinaryHeap:insert(priority, payload)
    assert(self.tracking[payload] == nil, "Payload must be unique")
    self.tracking[payload] = self.ptr
    TrackingBinaryHeap.__super.insert(self, priority, payload)
end


function TrackingBinaryHeap:pop()
    local p = self.payloads[1]
    if p ~= nil then self.tracking[p] = nil end
    return TrackingBinaryHeap.__super.pop(self)
end


function TrackingBinaryHeap:decrease(payload, newPriority)
    local i = self.tracking[payload]
    assert(i ~= nil, "Payload must exist in heap")
    assert(self.prios[i] >= newPriority, "You can only decrease priority")
    self.prios[i] = newPriority
    self:_bubbleUp(i)
end


return {
    BinaryHeap=BinaryHeap,
    TrackingBinaryHeap=TrackingBinaryHeap
}
