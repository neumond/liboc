require("busted.runner")()
local mod = require("ui.borders")
local nextBinTreeIndex = mod.testing.nextBinTreeIndex


function printDebug(tree, lowestLen)
    local rows = {}
    if lowestLen == nil then lowestLen = 3 end
    local nbt = nextBinTreeIndex

    function lpad(s, l, c)
        local res = string.rep(c or ' ', l - #s) .. s
        return res, res ~= s
    end

    local function ensureLayer(i)
        if rows[i] ~= nil then return end
        rows[i] = {}
        for k=1,1<<(i-1) do
            rows[i][k] = "."
        end
    end

    local function traverse(i, layer, layerBase)
        if tree[i] == nil then return end
        ensureLayer(layer)
        rows[layer][i - layerBase + 1] = tree[i]
        traverse(nbt(i, false), layer + 1, nbt(layerBase, false))
        traverse(nbt(i, true), layer + 1, nbt(layerBase, false))
    end

    traverse(1, 1, 1)

    function itemLenForLayer(layer)
        return (1<<(#rows - layer)) * lowestLen
    end

    print()
    for layer, row in ipairs(rows) do
        local line = ""
        for i, item in ipairs(row) do
            local len = itemLenForLayer(layer)
            if i == 1 then
                len = len // 2
            end
            line = line .. lpad(string.format(item), len)
        end
        print(line)
    end
end


function umlDebug(tree)
    local nbt = nextBinTreeIndex

    local function traverse(i)
        if tree[i] == nil then return end
        print("p" .. i .. " : " .. tree[i])
        local left = nbt(i, false)
        local right = nbt(i, true)
        if tree[left] ~= nil then
            print("p" .. i .. " --> p" .. left)
        end
        if tree[right] ~= nil then
            print("p" .. i .. " --> p" .. right)
        end
        traverse(left)
        traverse(right)
    end

    print("@startuml")
    print("state p1")
    traverse(1)
    print("@enduml")
end


function bind(f, arg)
    return function(...)
        return f(arg, ...)
    end
end


describe("Border renderer", function()
    describe("binary tree index for border joint rendering", function()
        local parentBinTreeIndex = mod.testing.parentBinTreeIndex
        local addBorder = mod.testing.addBorder
        local getBorderChar = mod.testing.getBorderChar
        local splitBorder = mod.testing.splitBorder
        local traverseBorder = mod.testing.traverseBorder

        function hardSplitBorder(tree, position, value)
            return splitBorder(tree, position, function()
                return value
            end)
        end

        it("has correct binary tree indexing", function()
            local f = nextBinTreeIndex

            --            1
            --     2             3
            --  4     5      6      7
            -- 8 9  10 11  12 13  14 15

            assert.is_equal(2, f(1, false))
            assert.is_equal(3, f(1, true))

            assert.is_equal(4, f(2, false))
            assert.is_equal(5, f(2, true))

            assert.is_equal(6, f(3, false))
            assert.is_equal(7, f(3, true))

            assert.is_equal(10, f(5, false))
            assert.is_equal(11, f(5, true))
        end)
        it("has corrent binary tree parent indexing", function()
            local f = parentBinTreeIndex

            assert.is_equal(1, f(2))
            assert.is_equal(1, f(3))

            assert.is_equal(2, f(4))
            assert.is_equal(2, f(5))

            assert.is_equal(3, f(6))
            assert.is_equal(3, f(7))

            assert.is_equal(5, f(10))
            assert.is_equal(5, f(11))
        end)
        it("traverses tree correctly #traverse", function()
            local tree = {}
            local addBorder = bind(addBorder, tree)

            addBorder(1, 5, "x")
            addBorder(6, 8, "y")
            addBorder(10, 10, "!")
            addBorder(12, 15, "z")

            -- printDebug(tree)

            local result = {}
            for index, from, to in traverseBorder(tree) do
                table.insert(result, {tree[index], from, to})
            end
            assert.are.same({
                {"x", 1, 5},
                {"y", 6, 8},
                {"!", 10, 10},
                {"z", 12, 15}
            }, result)
        end)
        it("inserts border gaps properly", function()
            local tree = {}
            local addBorder = bind(addBorder, tree)
            local getBorderChar = bind(getBorderChar, tree)

            addBorder(1, 5, "x")
            addBorder(6, 8, "y")
            addBorder(10, 10, "!")
            addBorder(12, 15, "z")

            assert.is_nil(getBorderChar(0))
            for i=1,5 do
                assert.is_equal("x", getBorderChar(i))
            end
            for i=6,8 do
                assert.is_equal("y", getBorderChar(i))
            end
            assert.is_nil(getBorderChar(9))
            assert.is_equal("!", getBorderChar(10))
            assert.is_nil(getBorderChar(11))
            for i=12,15 do
                assert.is_equal("z", getBorderChar(i))
            end
            assert.is_nil(getBorderChar(16))
            -- printDebug(tree)
        end)
        it("splits borders in middle", function()
            local tree = {}
            local addBorder = bind(addBorder, tree)
            local getBorderChar = bind(getBorderChar, tree)
            local splitBorder = bind(hardSplitBorder, tree)

            addBorder(1, 5, "x")
            -- printDebug(tree)
            splitBorder(3, "#")
            assert.is_equal("x", getBorderChar(2))
            assert.is_equal("#", getBorderChar(3))
            assert.is_equal("x", getBorderChar(4))
            -- printDebug(tree)
        end)
        it("splits borders left edge", function()
            local tree = {}
            local addBorder = bind(addBorder, tree)
            local getBorderChar = bind(getBorderChar, tree)
            local splitBorder = bind(hardSplitBorder, tree)

            addBorder(1, 5, "x")
            -- printDebug(tree)
            splitBorder(1, "#")
            assert.is_nil(getBorderChar(0))
            assert.is_equal("#", getBorderChar(1))
            assert.is_equal("x", getBorderChar(2))
            -- printDebug(tree)
        end)
        it("splits borders right edge", function()
            local tree = {}
            local addBorder = bind(addBorder, tree)
            local getBorderChar = bind(getBorderChar, tree)
            local splitBorder = bind(hardSplitBorder, tree)

            addBorder(1, 5, "x")
            -- printDebug(tree)
            splitBorder(5, "#")
            assert.is_equal("x", getBorderChar(4))
            assert.is_equal("#", getBorderChar(5))
            assert.is_nil(getBorderChar(6))
            -- printDebug(tree)
        end)
    end)
    it("doesn't crash", function()
        local br = mod.BorderRenderer()

        br:horizontal(1, 1, 10, 2)
        br:horizontal(1, 10, 10, 2)

        br:vertical(2, 2, 8, 2)
        br:vertical(9, 2, 8, 2)

        br:applyJoints()
        br:render({fill=function() end})
    end)
    it("works in reallife case", function()
        local br = mod.BorderRenderer()
        local Y = 25
        br:setBorderType(1)
        br:vertical(32, 1, 24)
        br:vertical(95, 1, 24)
        br:vertical(127, 1, 24)
        br:horizontal(1, Y, 160.0)
        br:vertical(80, 26, 24)
        br:vertical(107, 26, 24)
        br:applyJoints()
        local s = spy.new(function(x, y, w, h, char) end)
        br:render({fill=s})

        local splitPoints = {
            {32, "┴"},
            {80, "┬"},
            {95, "┴"},
            {107, "┬"},
            {127, "┴"}
        }
        local X = 1
        for _, split in ipairs(splitPoints) do
            local split, char = table.unpack(split)
            assert.spy(s).was_called_with(X, Y, split - X, 1, "─")
            assert.spy(s).was_called_with(split, Y, 1, 1, char)
            X = split + 1
        end
    end)
    it("getBorderFillChars", function()
        assert.are_same({
            up="─",
            down="─",
            left="║",
            right="║",
            upLeft="╓",
            upRight="╖",
            downLeft="╙",
            downRight="╜"
        }, mod.getBorderFillChars(1, 2, 1, 2))

        assert.are_same({
            up=" ",
            down=" ",
            left=" ",
            right=" ",
            upLeft=" ",
            upRight=" ",
            downLeft=" ",
            downRight=" "
        }, mod.getBorderFillChars(0, 0, 0, 0))

        assert.are_same({
            up="─",
            down="═",
            left=" ",
            right=" ",
            upLeft="─",
            upRight="─",
            downLeft="═",
            downRight="═"
        }, mod.getBorderFillChars(1, 0, 2, 0))
    end)
end)
