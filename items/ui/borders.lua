local utils = require("utils")


local BorderTypes = {
    [0]={width=0, h=" ", v=" "}
}
local jointTable = {}
local edges = {}

do
    local hLines = "─═"
    local vLines = "│║"
    for i=1,2 do
        BorderTypes[i] = {
            width=1,
            h=utils.strsub(hLines, i, i),
            v=utils.strsub(vLines, i, i)
        }
    end

    local function enst(t, k)
        if t[k] == nil then
            t[k] = {}
        end
    end

    local function rowcolIdx(row, col)
        return row * 3 - 3 + col
    end

    local function cdist(row, col)
        return math.abs(2 - row) + math.abs(2 - col)
    end

    local function registerJoints(hChar, vChar, corners)
        local function attack(targetChar, row, col, maxCDist, byChar, side)
            if (row < 1) or (row > 3) then return end
            if (col < 1) or (col > 3) then return end
            if cdist(row, col) > maxCDist then return end
            local idx = rowcolIdx(row, col)
            local becomesChar = utils.strsub(corners, idx, idx)

            enst(jointTable, targetChar)
            enst(jointTable[targetChar], byChar)
            jointTable[targetChar][byChar][side] = becomesChar
        end

        attack(vChar, 2, 3, 100, hChar, "left")
        attack(vChar, 2, 1, 100, hChar, "right")
        attack(hChar, 3, 2, 100, vChar, "up")
        attack(hChar, 1, 2, 100, vChar, "down")
        for row=1,3 do
            for col=1,3 do
                local target = rowcolIdx(row, col)
                local mc = cdist(row, col)
                local targetChar = utils.strsub(corners, target, target)
                attack(targetChar, row, col + 1, mc, hChar, "left")
                attack(targetChar, row, col - 1, mc, hChar, "right")
                attack(targetChar, row + 1, col, mc, vChar, "up")
                attack(targetChar, row - 1, col, mc, vChar, "down")
            end
        end

        edges[hChar .. vChar] = {
            utils.strsub(corners, 1, 1),
            utils.strsub(corners, 3, 3),
            utils.strsub(corners, 7, 7),
            utils.strsub(corners, 9, 9)
        }
    end
    registerJoints("─", "│", "┌┬┐├┼┤└┴┘")
    registerJoints("═", "│", "╒╤╕╞╪╡╘╧╛")
    registerJoints("─", "║", "╓╥╖╟╫╢╙╨╜")
    registerJoints("═", "║", "╔╦╗╠╬╣╚╩╝")
    -- print(require("inspect")(jointTable))

    edges["─ "] = {"─", "─", "─", "─"}
    edges["═ "] = {"═", "═", "═", "═"}
    edges[" │"] = {"│", "│", "│", "│"}
    edges[" ║"] = {"║", "║", "║", "║"}
    edges["  "] = {" ", " ", " ", " "}
end


-- border types


local function getBorderType(borderType)
    local bt = BorderTypes[borderType]
    if bt == nil then
        bt = BorderTypes[0]
    end
    return bt
end


local function getBorderWidth(borderType)
    return getBorderType(borderType).width
end


local function getBorderFillChars(up, right, down, left)
    up = getBorderType(up)
    right = getBorderType(right)
    down = getBorderType(down)
    left = getBorderType(left)
    return {
        up = up.h,
        down = down.h,
        left = left.v,
        right = right.v,
        upLeft = edges[up.h .. left.v][1],
        upRight = edges[up.h .. right.v][2],
        downLeft = edges[down.h .. left.v][3],
        downRight = edges[down.h .. right.v][4]
    }
end


-- BRProxy
-- TODO: need?


local BRProxy = utils.makeClass(function(self, br, x, y)
    self.br = br
    self.x = x - 1
    self.y = y - 1
end)


function BRProxy:setBorderType(borderType)
    self.br:setBorderType(borderType)
end


function BRProxy:horizontal(x, y, length)
    self.br:horizontal(x + self.x, y + self.y, length)
end


function BRProxy:vertical(x, y, length)
    self.br:vertical(x + self.x, y + self.y, length)
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
    self:setBorderType(0)
end)


local function isNumber(v)
    return type(v) == "number"
end


local function nextBinTreeIndex(current, isRight)
    return current * 2 + (isRight and 1 or 0)
end


local function parentBinTreeIndex(current)
    return current // 2
end


local function addBorder(tree, from, to, value)
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


local function getBorderChar(tree, position)
    local i = 1
    while tree[i] ~= nil do
        if not isNumber(tree[i]) then return tree[i] end
        i = nextBinTreeIndex(i, position >= tree[i])
    end
end


local function splitBorder(tree, position, valueFunc)
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


local function makeStack()
    -- TODO: replace with Stack from lib
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


local function traverseBorder(tree)
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

    local function digDown(dir)
        indexStack.push(1)
        index = nextBinTreeIndex(index, dir)
        if not dir then
            toStack.push(fromStack.pop())
        end
        fromStack.push(tree[index])
    end

    local function goUp()
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

    local function goNext()
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


function BorderRenderer:setBorderType(borderType)
    local bt = getBorderType(borderType)
    self.borderWidth = bt.width
    self.HBorderChar = bt.h
    self.VBorderChar = bt.v
end


function BorderRenderer:horizontal(x, y, length)
    if self.borderWidth <= 0 then return end
    if self.rows[y] == nil then
        self.rows[y] = {}
    end
    local char = self.HBorderChar
    addBorder(self.rows[y], x, x + length - 1, char)
    table.insert(self.Hjoints, {x - 1, y, char, "right"})
    table.insert(self.Hjoints, {x + length, y, char, "left"})
end


function BorderRenderer:vertical(x, y, length)
    if self.borderWidth <= 0 then return end
    if self.cols[x] == nil then
        self.cols[x] = {}
    end
    local char = self.VBorderChar
    addBorder(self.cols[x], y, y + length - 1, char)
    table.insert(self.Vjoints, {x, y - 1, char, "down"})
    table.insert(self.Vjoints, {x, y + length, char, "up"})
end


function BorderRenderer:applyJoints()
    local function charFunc(jointChar, side)
        return function(borderChar)
            local r = jointTable[borderChar]
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
    getBorderFillChars=getBorderFillChars,
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
