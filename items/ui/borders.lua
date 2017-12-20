local utils = require("utils")


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


function traverseBorder(tree)
    local indexStack = {1}  -- top of this stack = state of current index
    local stackPtr = 1
    local index = nil
    local from, to

    function digDown(dir)
        stackPtr = stackPtr + 1
        indexStack[stackPtr] = 1
        index = nextBinTreeIndex(index, dir)
        if isNumber(tree[index]) then
            if dir then
                to = tree[index]
            else
                from = tree[index]
            end
        end
    end

    function goUp()
        if index == 1 then return true end
        indexStack[stackPtr] = nil
        stackPtr = stackPtr - 1
        indexStack[stackPtr] = indexStack[stackPtr] + 1
        index = parentBinTreeIndex(index)
        return false
    end

    function goNext()
        if index == nil then
            index = 1
            to = tree[index]
            return false
        end
        if not isNumber(tree[index]) then
            return goUp()
        end
        local state = indexStack[stackPtr]
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
        return index, from, to - 1
    end
end


function BorderRenderer:horizontal(x, y, length, char)
    if self.rows[y] == nil then
        self.rows[y] = {}
    end
    addBorder(self.rows[y], x, x + length - 1, char)
    self:addJoint(x - 1, y, char, "right", false)
    self:addJoint(x + length, y, char, "left", false)
end


function BorderRenderer:vertical(x, y, length, char)
    if self.cols[x] == nil then
        self.cols[x] = {}
    end
    addBorder(self.cols[x], y, y + length - 1, char)
    self:addJoint(x, y - 1, char, "down", true)
    self:addJoint(x, y + length, char, "up", true)
end


function BorderRenderer:addJoint(x, y, char, side, vertical)
    -- TODO: inline this function?
    local t = vertical and self.Vjoints or self.Hjoints
    table.insert(t, {x, y, char, side})
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


-- Module


return {
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
