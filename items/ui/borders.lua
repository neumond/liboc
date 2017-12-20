local utils = require("utils")


local BorderTypes = {
    [0]={width=0, h=" ", v=" "},
    [1]={width=1, h="─", v="│"},
    [2]={width=1, h="═", v="║"}
}


function getBorderType(borderType)
    local bt = BorderTypes[borderType]
    if bt == nil then
        bt = BorderTypes[0]
    end
    return bt
end


function getBorderWidth(borderType)
    return getBorderType(borderType).width
end


function getBorderFillChar(borderType, vertical)
    local bt = getBorderType(borderType)
    return vertical and bt.v or bt.h
end


-- BRProxy


local BRProxy = utils.makeClass(function(self, br, x, y)
    self.br = br
    self.x = x - 1
    self.y = y - 1
end)


function BRProxy:horizontal(x, y, length, borderType)
    self.br:horizontal(x + self.x, y + self.y, length, borderType)
end


function BRProxy:vertical(x, y, length, borderType)
    self.br:vertical(x + self.x, y + self.y, length, borderType)
end


function BRProxy:enterWindow(x, y)
    return BRProxy(self.br, self.x + x, self.y + y)
end


-- BorderRenderer


local BorderRenderer = utils.makeClass(function(self)
    self.rows = {}
    self.cols = {}
    self.Hjoints = {}
    self.Vjoints = {}
end)


local lineTable = "─═│║"
local cornerTable = {
    "┌┬┐ ╔╦╗ ╓╥╖ ╒╤╕",
    "├┼┤ ╠╬╣ ╟╫╢ ╞╪╡",
    "└┴┘ ╚╩╝ ╙╨╜ ╘╧╛"
}
BorderRenderer.jointTable = {
    ["│"]={
        ["─"]={left="┤", right="├"},
        ["═"]={left="╡", right="╞"}
    },
    ["║"]={
        ["─"]={left="╢", right="╟"},
        ["═"]={left="╣", right="╠"}
    },
    ["┤"]={["─"]={right="┼"}},
    ["├"]={["─"]={left="┼"}},
    ["╡"]={["═"]={right="╪"}},
    ["╞"]={["═"]={left="╪"}},
    ["╢"]={["─"]={right="╫"}},
    ["╟"]={["─"]={left="╫"}},
    ["╣"]={["═"]={right="╬"}},
    ["╠"]={["═"]={left="╬"}},

    ["─"]={
        ["│"]={up="┴", down="┬"},
        ["║"]={up="╨", down="╥"}
    },
    ["═"]={
        ["│"]={up="╧", down="╤"},
        ["║"]={up="╩", down="╦"}
    },
    ["┴"]={["│"]={down="┼"}},
    ["┬"]={["│"]={up="┼"}},
    ["╨"]={["║"]={down="╫"}},
    ["╥"]={["║"]={up="╫"}},
    ["╧"]={["│"]={down="╪"}},
    ["╤"]={["│"]={up="╪"}},
    ["╩"]={["║"]={down="╬"}},
    ["╦"]={["║"]={up="╬"}}
}


function isNumber(v)
    return type(v) == "number"
end


function nextBinTreeIndex(current, isRight)
    return current * 2 + (isRight and 1 or 0)
end


function parentBinTreeIndex(current)
    return current // 2
end


function addBorder(tree, from, to, value)
    local i = 1
    while tree[i] ~= nil do
        assert(isNumber(tree[i]))
        assert((from >= tree[i]) == (to >= tree[i]))
        i = nextBinTreeIndex(i, from >= tree[i])
    end
    tree[i] = to + 1
    i = nextBinTreeIndex(i, false)
    tree[i] = from
    i = nextBinTreeIndex(i, true)
    tree[i] = value
end


function getBorderChar(tree, position)
    local i = 1
    while tree[i] ~= nil do
        if not isNumber(tree[i]) then return tree[i] end
        i = nextBinTreeIndex(i, position >= tree[i])
    end
end


function splitBorder(tree, position, valueFunc)
    local i = 1
    local from, to
    while tree[i] ~= nil do
        if not isNumber(tree[i]) then break end
        if position >= tree[i] then
            from = tree[i]
        else
            to = tree[i] - 1
        end
        i = nextBinTreeIndex(i, position >= tree[i])
    end
    local brd = tree[i]
    if (brd == nil) or (from == nil) or (to == nil) then return end
    local value = valueFunc(brd)
    if from == to then
        tree[i] = value
    else
        tree[i] = position
        if position > from then
            tree[nextBinTreeIndex(i, false)] = brd
            i = nextBinTreeIndex(i, true)
        end
        if position < to then
            tree[i] = position + 1
            tree[nextBinTreeIndex(i, false)] = value
            tree[nextBinTreeIndex(i, true)] = brd
        else
            tree[i] = value
        end
    end
end


function makeStack()
    local s = {}
    local ptr = 0

    function s.push(value)
        ptr = ptr + 1
        s[ptr] = value
    end

    function s.pop()
        local value = s[ptr]
        s[ptr] = nil
        ptr = ptr - 1
        return value
    end

    function s.tip(n)
        if n == nil then n = 1 end
        return s[ptr - (n - 1)]
    end

    function s.transformTip(f)
        s[ptr] = f(s[ptr])
    end

    return s
end


function traverseBorder(tree)
    -- top of this stack = state of current index
    local indexStack = makeStack()
    indexStack.push(1)
    local index = nil

    -- every node of the tree is a point on coordinate axis
    -- -----o------o-o---o--------o----------o-o-o---
    --                 from  x    to
    --               current position
    -- going over a point (goUp) switches latest "to" point into "from"
    local toStack = makeStack()
    toStack.push(math.huge)
    local fromStack = makeStack()
    fromStack.push(-math.huge)

    function digDown(dir)
        indexStack.push(1)
        index = nextBinTreeIndex(index, dir)
        if not dir then
            toStack.push(fromStack.pop())
        end
        fromStack.push(tree[index])
    end

    function goUp()
        if index == 1 then return true end
        indexStack.pop()
        indexStack.transformTip(function(v) return v + 1 end)
        fromStack.pop()
        if indexStack.tip() == 2 then
            fromStack.push(toStack.pop())
        end
        index = parentBinTreeIndex(index)
        return false
    end

    function goNext()
        if index == nil then
            index = 1
            fromStack.push(tree[index])
            return false
        end
        if not isNumber(tree[index]) then
            return goUp()
        end
        local state = indexStack.tip()
        if state == 1 then
            digDown(false)
        elseif state == 2 then
            digDown(true)
        else
            return goUp()
        end
        return false
    end

    return function()
        repeat
            if goNext() then return nil end
        until (tree[index] ~= nil) and (not isNumber(tree[index]))
        return index, fromStack.tip(2), toStack.tip() - 1
    end
end


function BorderRenderer:horizontal(x, y, length, borderType)
    if getBorderWidth(borderType) <= 0 then return end
    if self.rows[y] == nil then
        self.rows[y] = {}
    end
    local char = getBorderFillChar(borderType, false)
    addBorder(self.rows[y], x, x + length - 1, char)
    table.insert(self.Hjoints, {x - 1, y, char, "right"})
    table.insert(self.Hjoints, {x + length, y, char, "left"})
end


function BorderRenderer:vertical(x, y, length, borderType)
    if getBorderWidth(borderType) <= 0 then return end
    if self.cols[x] == nil then
        self.cols[x] = {}
    end
    local char = getBorderFillChar(borderType, true)
    addBorder(self.cols[x], y, y + length - 1, char)
    table.insert(self.Vjoints, {x, y - 1, char, "down"})
    table.insert(self.Vjoints, {x, y + length, char, "up"})
end


function BorderRenderer:applyJoints()
    function charFunc(jointChar, side)
        return function(borderChar)
            local r = self.jointTable[borderChar]
            if r == nil then return end
            r = r[jointChar]
            if r == nil then return end
            return r[side]
        end
    end

    for _, joint in ipairs(self.Vjoints) do
        x, y, jointChar, side = table.unpack(joint)
        if self.rows[y] ~= nil then
            splitBorder(self.rows[y], x, charFunc(jointChar, side))
        end
    end
    for _, joint in ipairs(self.Hjoints) do
        x, y, jointChar, side = table.unpack(joint)
        if self.cols[x] ~= nil then
            splitBorder(self.cols[x], y, charFunc(jointChar, side))
        end
    end
end


function BorderRenderer:render(gpu)
    for rowIndex, row in pairs(self.rows) do
        for index, from, to in traverseBorder(row) do
            gpu.fill(from, rowIndex, to - from + 1, 1, row[index])
        end
    end
    for colIndex, col in pairs(self.cols) do
        for index, from, to in traverseBorder(col) do
            gpu.fill(colIndex, from, 1, to - from + 1, col[index])
        end
    end
end


function BorderRenderer:enterWindow(x, y)
    return BRProxy(self, x, y)
end


-- Module


return {
    getBorderWidth=getBorderWidth,
    getBorderFillChar=getBorderFillChar,
    BorderRenderer=BorderRenderer,
    testing={
        nextBinTreeIndex=nextBinTreeIndex,
        parentBinTreeIndex=parentBinTreeIndex,
        addBorder=addBorder,
        getBorderChar=getBorderChar,
        splitBorder=splitBorder,
        traverseBorder=traverseBorder
    }
}
