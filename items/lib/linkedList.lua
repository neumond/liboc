local makeClass = require("utils").makeClass


-- LinkedListItem


local LinkedListItem = makeClass(function(self, list, prev, next, payload)
    self.list = list
    self.prev = prev
    self.next = next
    self.payload = payload
    self.list.onChange("add", self)
    self.list.count = self.list.count + 1
end)


function LinkedListItem:remove()
    self.list.onChange("remove", self)
    if self.prev ~= nil then self.prev.next = self.next end
    if self.next ~= nil then self.next.prev = self.prev end
    self.list.count = self.list.count - 1
    if self.list.first == self then self.list.first = self.next end
    if self.list.last == self then self.list.last = self.prev end
    self.prev = nil
    self.next = nil
    self.list = nil
end


function LinkedListItem:insertBefore(payload)
    local item = LinkedListItem(self.list, self.prev, self, payload)
    if self.prev ~= nil then self.prev.next = item end
    self.prev = item
    return item
end


function LinkedListItem:insertAfter(payload)
    local item = LinkedListItem(self.list, self, self.next, payload)
    if self.next ~= nil then self.next.prev = item end
    self.next = item
    return item
end


function LinkedListItem:getPayload()
    return self.payload
end


-- LinkedList


local LinkedList = makeClass(function(self, onChange)
    self.first = nil
    self.last = nil
    self.count = 0
    self.onChange = onChange ~= nil and onChange or function() end
end)


function LinkedList:append(payload)
    if self.last == nil then
        self.last = LinkedListItem(self, nil, nil, payload)
        self.first = self.last
    else
        self.last = self.last:insertAfter(payload)
    end
    return self.last
end


function LinkedList:prepend(payload)
    if self.first == nil then
        self.first = LinkedListItem(self, nil, nil, payload)
        self.last = self.first
    else
        self.first = self.first:insertBefore(payload)
    end
    return self.first
end


function LinkedList:iter()
    local item = {next=self.first}
    return function()
        item = item.next
        return item
    end
end


LinkedList.registerMetaMethod("__len", function(self)
    return self.count
end)


-- Module


return {
    LinkedList=LinkedList
}
