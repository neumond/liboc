require("busted.runner")()
local utils = require("utils")
local mod = require("ui.markup")
local DEFAULT_STYLES = require("ui.selectors").DEFAULT_STYLES
local boxModule = require("ui.boxModel")
local Flow = mod.testing.Flow


local function iterArrayValues(t)
    local ptr = 0
    return function()
        ptr = ptr + 1
        if t[ptr] == nil then return end
        return table.unpack(t[ptr])
    end
end


local function accumulate(iter)
    local result = {}
    for a, b, c, d, e in iter do
        table.insert(result, {a, b, c, d, e})
    end
    return result
end


local function strReplace(line, pos, text)
    assert(pos > 0)
    local len = utils.strlen(text)
    return (
        utils.strsub(line, 1, pos - 1) ..
        text ..
        utils.strsub(line, pos + len)
    )
end


local function render(iter, screenWidth, colorBox)
    local textLines = {}
    local colorLines = {}
    local backgroundLines = {}

    local currentLine = 0
    local currentColor = "X"
    local currentBackground = "X"

    local function pickColor(color)
        local r = colorBox[color]
        if r == nil then r = "X" end
        return r

    end

    local function replace(pos, text)
        local len = utils.strlen(text)
        textLines[currentLine] = strReplace(
            textLines[currentLine], pos, text)
        colorLines[currentLine] = strReplace(
            colorLines[currentLine], pos, string.rep(currentColor, len))
        backgroundLines[currentLine] = strReplace(
            backgroundLines[currentLine], pos, string.rep(currentBackground, len))
    end

    for cmd, a, b, c in iter do
        if cmd == Flow.gpuNewLine then
            currentLine = currentLine + 1
            textLines[currentLine] = string.rep(" ", screenWidth)
            colorLines[currentLine] = string.rep(" ", screenWidth)
            backgroundLines[currentLine] = string.rep(" ", screenWidth)
        elseif cmd == Flow.gpuSet then
            replace(a, b)
        elseif cmd == Flow.gpuFill then
            replace(a, string.rep(c, b))
        elseif cmd == Flow.gpuColor then
            currentColor = pickColor(a)
        elseif cmd == Flow.gpuBackground then
            currentBackground = pickColor(a)
        end
    end

    return {text=textLines, color=colorLines, background=backgroundLines}
end


local function makeIterTestable(f)
    return function(items)
        return accumulate(f(iterArrayValues(items)))
    end
end


local function stripToken(iter, token)
    return function()
        while true do
            local cmd, a, b = iter()
            if cmd == nil then return end
            if token ~= cmd then return cmd, a, b end
        end
    end
end


describe("Markup tokenizer", function()
    describe("test utils", function()
        it("strReplace", function()
            assert.are_equal("aaafffccc", strReplace("aaabbbccc", 4, "fff"))
            assert.are_equal("faabbbccc", strReplace("aaabbbccc", 1, "f"))
        end)
    end)
    describe("removeGlueAddWordLengths", function()
        local f = makeIterTestable(mod.testing.removeGlueAddWordLengths)

        local function beforeAfter()
            local i = 0
            local t = {
                {true, false},
                {false, true},
                {true, true}
            }
            return function()
                i = i + 1
                if t[i] == nil then return end
                return table.unpack(t[i])
            end
        end

        local function beforeAfterTokens(tokens, beforeIndex, afterIndex)
            local iter = beforeAfter()
            return function()
                local before, after = iter()
                if before == nil then return end
                local t = utils.copyTable(tokens)
                if not after then table.remove(t, afterIndex) end
                if not before then table.remove(t, beforeIndex) end
                return t
            end
        end

        it("calculates single word size", function()
            assert.are_same({
                {Flow.wordSize, 3},
                {Flow.string, "lol"}
            }, f({
                {Flow.string, "lol"}
            }))
        end)
        it("calculates sizes for two words", function()
            assert.are_same({
                {Flow.wordSize, 3},
                {Flow.string, "lol"},
                {Flow.wordSize, 3},
                {Flow.string, "kek"}
            }, f({
                {Flow.string, "lol"},
                {Flow.string, "kek"}
            }))
        end)
        it("calculates sizes for two words divided by block bound", function()
            assert.are_same({
                {Flow.wordSize, 3},
                {Flow.string, "lol"},
                {Flow.blockStart},
                {Flow.wordSize, 3},
                {Flow.string, "kek"},
                {Flow.blockEnd}
            }, f({
                {Flow.string, "lol"},
                {Flow.blockStart},
                {Flow.string, "kek"},
                {Flow.blockEnd}
            }))
        end)
        it("can handle multiple block bounds", function()
            assert.are_same({
                {Flow.blockStart},
                {Flow.blockStart},
                {Flow.wordSize, 1},
                {Flow.string, "a"},
                {Flow.blockEnd},
                {Flow.blockStart},
                {Flow.wordSize, 1},
                {Flow.string, "b"},
                {Flow.blockEnd},
                {Flow.blockEnd}
            }, f({
                {Flow.blockStart},
                {Flow.blockStart},
                {Flow.string, "a"},
                {Flow.blockEnd},
                {Flow.blockStart},
                {Flow.string, "b"},
                {Flow.blockEnd},
                {Flow.blockEnd}
            }))
        end)
        it("can glue two words", function()
            assert.are_same({
                {Flow.wordSize, 8},
                {Flow.string, "long"},
                {Flow.string, "word"}
            }, f({
                {Flow.string, "long"},
                {Flow.glue},
                {Flow.string, "word"}
            }))
        end)
        it("can glue several words", function()
            assert.are_same({
                {Flow.wordSize, 4},
                {Flow.string, "a"},
                {Flow.string, "b"},
                {Flow.string, "c"},
                {Flow.string, "d"}
            }, f({
                {Flow.string, "a"},
                {Flow.glue},
                {Flow.string, "b"},
                {Flow.glue},
                {Flow.string, "c"},
                {Flow.glue},
                {Flow.string, "d"}
            }))
        end)
        it("can handle multiple consequent glues", function()
            assert.are_same({
                {Flow.wordSize, 8},
                {Flow.string, "long"},
                {Flow.string, "word"}
            }, f({
                {Flow.string, "long"},
                {Flow.glue},
                {Flow.glue},
                {Flow.glue},
                {Flow.string, "word"}
            }))
        end)
        it("ignores glue near blockStart", function()
            local expected = {
                {Flow.wordSize, 4},
                {Flow.string, "long"},
                {Flow.blockStart},
                {Flow.wordSize, 4},
                {Flow.string, "word"},
                {Flow.blockEnd}
            }
            for t in beforeAfterTokens({
                {Flow.string, "long"},
                {Flow.glue},
                {Flow.blockStart},  -- breaks words
                {Flow.glue},
                {Flow.string, "word"},
                {Flow.blockEnd}
            }, 2, 4) do
                assert.are_same(expected, f(t))
            end
        end)
        it("ignores glue near blockEnd", function()
            local expected = {
                {Flow.blockStart},
                {Flow.wordSize, 4},
                {Flow.string, "long"},
                {Flow.blockEnd},
                {Flow.wordSize, 4},
                {Flow.string, "word"}
            }
            for t in beforeAfterTokens({
                {Flow.blockStart},
                {Flow.string, "long"},
                {Flow.glue},
                {Flow.blockEnd},
                {Flow.glue},
                {Flow.string, "word"}
            }, 3, 5) do
                assert.are_same(expected, f(t))
            end
        end)
        it("glues two words with other tokens in the middle", function()
            for _, flowcode in ipairs({
                {Flow.pushClass, "x"},
                {Flow.popClass}
            }) do
                local expected = {
                    {Flow.wordSize, 8},
                    {Flow.string, "long"},
                    flowcode,
                    {Flow.string, "word"}
                }
                for t in beforeAfterTokens({
                    {Flow.string, "long"},
                    {Flow.glue},
                    flowcode,
                    {Flow.glue},
                    {Flow.string, "word"}
                }, 2, 4) do
                    assert.are_same(expected, f(t))
                end
            end
        end)
    end)
    describe("classesToStyles", function()
        local mainColor = 0x808080
        local selectorTable = {
            mod.Selector({"main"}, {color=mainColor})
        }
        local f = function(tokens, dontUseHack)
            local defaultStyles = {}
            if not dontUseHack then
                defaultStyles._testingReset = true
            end
            return accumulate(mod.testing.classesToStyles(
                iterArrayValues(tokens), defaultStyles, selectorTable
            ))
        end

        it("sets default styles for empty markup", function()
            local r = f({}, true)
            assert(#r > 0)
            for _, v in ipairs(r) do
                local a, b, c = table.unpack(v)
                assert.are_equal(Flow.styleChange, a)
                -- print(a, b, c)
            end
        end)
        it("can suppress default styles using testing hack", function()
            local r = f({})
            assert(#r == 0)
        end)
        it("tranforms class tokens into style changes", function()
            assert.are_same({
                {Flow.wordSize, 1},
                {Flow.string, "a"},
                {Flow.styleChange, "color", mainColor},
                {Flow.wordSize, 1},
                {Flow.string, "b"},
                {Flow.styleChange, "color", nil}
            }, f({
                {Flow.wordSize, 1},
                {Flow.string, "a"},
                {Flow.pushClass, "main"},
                {Flow.wordSize, 1},
                {Flow.string, "b"},
                {Flow.popClass}
            }))
        end)
    end)
    describe("blockContentWidths", function()
        local selectorTable = {
            mod.Selector({"main"}, {marginLeft=3})
        }
        local function refineResult(iter)
            return function()
                local cmd, a, b = iter()
                if cmd == Flow.blockStart then
                    return Flow.blockStart, a.contentWidth
                elseif cmd == Flow.blockEnd then
                    return Flow.blockEnd, a.contentWidth
                else
                    return cmd, a, b
                end
            end
        end
        local f = function(tokens)
            return accumulate(
                refineResult(stripToken(
                    mod.testing.blockContentWidths(
                        mod.testing.classesToStyles(
                            iterArrayValues(tokens), {}, selectorTable
                        ),
                        10
                    ),
                    Flow.styleChange
                ))
            )
        end

        it("uses screen width as default", function()
            assert.are_same({
                {Flow.blockStart, 10},
                {Flow.blockEnd, 10}
            }, f({
                {Flow.blockStart},
                {Flow.blockEnd}
            }))
        end)
        it("uses narrows width on margin", function()
            assert.are_same({
                {Flow.blockStart, 7},
                {Flow.blockEnd, 10}
            }, f({
                {Flow.pushClass, "main"},
                {Flow.blockStart},
                {Flow.blockEnd},
                {Flow.popClass}
            }))
        end)
    end)
    describe("splitIntoLines", function()
        local f = function(tokens)
            return accumulate(mod.testing.splitIntoLines(
                iterArrayValues(tokens), 10
            ))
        end

        it("splits at blockStart", function()
            assert.are_same({
                {Flow.lineSize, 4, 0},
                {Flow.string, "abcd"},
                {Flow.blockStart, {contentWidth=10}},
                {Flow.lineSize, 5, 1},
                {Flow.string, "aa"},
                {Flow.space},
                {Flow.string, "bb"},
                {Flow.blockEnd, {contentWidth=10}}
            }, f({
                {Flow.wordSize, 4},
                {Flow.string, "abcd"},
                {Flow.blockStart, {contentWidth=10}},
                {Flow.wordSize, 2},
                {Flow.string, "aa"},
                {Flow.wordSize, 2},
                {Flow.string, "bb"},
                {Flow.blockEnd, {contentWidth=10}}
            }))
        end)
        it("splits long lines", function()
            assert.are_same({
                {Flow.lineSize, 9, 1},
                {Flow.string, "aaaa"},
                {Flow.space},
                {Flow.string, "bbbb"},
                {Flow.lineSize, 10, 0},
                {Flow.string, "exception…"},
                {Flow.lineSize, 4, 0},
                {Flow.string, "word"}
            }, f({
                {Flow.wordSize, 4},
                {Flow.string, "aaaa"},
                {Flow.wordSize, 4},
                {Flow.string, "bbbb"},
                {Flow.wordSize, 17},
                {Flow.string, "exceptionallylong"},
                {Flow.wordSize, 4},
                {Flow.string, "word"}
            }))
        end)
        it("changes widths for blocks", function()
            assert.are_same({
                {Flow.lineSize, 10, 0},
                {Flow.string, "exception…"},
                {Flow.blockStart, {contentWidth=3}},
                {Flow.lineSize, 3, 0},
                {Flow.string, "ex…"},
                {Flow.blockEnd, {contentWidth=10}},
                {Flow.lineSize, 10, 0},
                {Flow.string, "exception…"}
            }, f({
                {Flow.wordSize, 17},
                {Flow.string, "exceptionallylong"},
                {Flow.blockStart, {contentWidth=3}},
                {Flow.wordSize, 17},
                {Flow.string, "exceptionallylong"},
                {Flow.blockEnd, {contentWidth=10}},
                {Flow.wordSize, 17},
                {Flow.string, "exceptionallylong"}
            }))
        end)
    end)

    describe("renderToGpuLines", function()
        local screenWidth = 10
        local f = function(tokens)
            return render(
                mod.testing.renderToGpuLines(
                    iterArrayValues(tokens), screenWidth
                ),
                screenWidth,
                {
                    [0x000000]="B",
                    [0xFFFFFF]="W"
                }
            )
        end
        local makeBox = function(styles)
            local s = utils.copyTable(DEFAULT_STYLES)
            for k, v in pairs(styles) do s[k] = v end
            return boxModule.makeBox(s, screenWidth)
        end

        it("works", function()
            assert.are_same({
                "abcde     "
            }, f{
                {Flow.lineSize, 5, 0},
                {Flow.string, "abcde"}
            }.text)
        end)
        it("handles single block", function()
            assert.are_same({
                "abcde     "
            }, f{
                {Flow.blockStart, makeBox{}},
                {Flow.lineSize, 5, 0},
                {Flow.string, "abcde"},
                {Flow.blockEnd, makeBox{}}
            }.text)
        end)
        it("handles several blocks", function()
            assert.are_same({
                "abcde     ",
                "interblock",
                "hi bye    "
            }, f{
                {Flow.blockStart, makeBox{}},
                {Flow.lineSize, 5, 0},
                {Flow.string, "abcde"},
                {Flow.blockEnd, makeBox{}},
                {Flow.lineSize, 10, 0},
                {Flow.string, "interblock"},
                {Flow.blockStart, makeBox{}},
                {Flow.lineSize, 6, 0},
                {Flow.string, "hi"},
                {Flow.space},
                {Flow.string, "bye"},
                {Flow.blockEnd, makeBox{}},
            }.text)
        end)
        it("aligns text", function()
            for _, t in ipairs{
                {"left", "right",   "abcd      "},
                {"right", "left",   "      abcd"},
                {"center", "right", "   abcd   "},
            } do
                local align, badAlign, result = table.unpack(t)
                assert.are_same({result}, f{
                    {Flow.styleChange, "align", align},
                    {Flow.blockStart, makeBox{}},
                    {Flow.styleChange, "align", badAlign},  -- doesn't affect alignment of current block
                    {Flow.lineSize, 4, 0},
                    {Flow.string, "abcd"},
                    {Flow.blockEnd, makeBox{}}
                }.text)
            end
        end)
        it("fills block with paddingFill", function()
            assert.are_same({
                "abcd......"
            }, f{
                {Flow.styleChange, "paddingFill", "."},
                {Flow.blockStart, makeBox{}},
                {Flow.lineSize, 4, 0},
                {Flow.string, "abcd"},
                {Flow.blockEnd, makeBox{}}
            }.text)
        end)
        for _, t in ipairs{
            {"marginLeft", 2, {
                "  abcd...."
            }},
            {"marginRight", 2, {
                "abcd....  "
            }},
            {"marginTop", 1, {
                "          ",
                "abcd......"
            }},
            {"marginBottom", 1, {
                "abcd......",
                "          "
            }},
            {"paddingLeft", 2, {
                "..abcd...."
            }},
            {"paddingRight", 2, {
                "abcd......"
            }},
            {"paddingTop", 1, {
                "..........",
                "abcd......"
            }},
            {"paddingBottom", 1, {
                "abcd......",
                ".........."
            }},
            {"borderLeft", 1, {
                "│abcd....."
            }},
            {"borderRight", 1, {
                "abcd.....│"
            }},
            {"borderTop", 1, {
                "──────────",
                "abcd......"
            }},
            {"borderBottom", 1, {
                "abcd......",
                "──────────"
            }}
        } do
            local styleName, value, result = table.unpack(t)
            it("applies " .. styleName, function()
                assert.are_same(result, f{
                    {Flow.styleChange, "paddingFill", "."},
                    {Flow.blockStart, makeBox{[styleName]=value}},
                    {Flow.lineSize, 4, 0},
                    {Flow.string, "abcd"},
                    {Flow.blockEnd, makeBox{}}
                }.text)
            end)
        end
        it("can handle full border box", function()
            assert.are_same({
                "╓────────┐",
                "║abcd....│",
                "╙────────┘"
            }, f{
                {Flow.styleChange, "paddingFill", "."},
                {Flow.blockStart, makeBox{
                    borderTop=1,
                    borderBottom=1,
                    borderLeft=2,
                    borderRight=1
                }},
                {Flow.lineSize, 4, 0},
                {Flow.string, "abcd"},
                {Flow.blockEnd, makeBox{}}
            }.text)
        end)
    end)

    -- OLD

    describe("iterMarkupTokens #skip", function()
        local f = function(markup)
            return accumulate(mod.testing.iterMarkupTokens(markup))
        end

        it("returns no tokens for empty markups", function()
            assert.are_same({}, f(mod.Span()))
            assert.are_same({}, f(mod.Div()))
        end)
        it("handles single word markups", function()
            local singleAWord = {
                {Flow.wordSize, 1},
                {Flow.string, "a"}
            }

            assert.are_same(singleAWord, f(mod.Span("a")))
            assert.are_same(singleAWord, f(mod.Div("a")))
            assert.are_same(singleAWord, f(
                mod.Div(mod.Div(mod.Div("a")))
            ))
        end)
        it("inserts newLine between Divs", function()
            assert.are_same({
                {Flow.wordSize, 1},
                {Flow.string, "a"},
                {Flow.lineSize},
                {Flow.wordSize, 1},
                {Flow.string, "b"},
            }, f(
                mod.Div(
                    mod.Div("a"),
                    mod.Div("b")
                )
            ))
        end)
    end)
    describe("markupToGpuCommands #skip", function()
        local f = mod.markupToGpuCommands

        it("works in simple cases", function()
            local singleAWord = {
                {
                    {"setForeground", DEFAULT_STYLES.color},
                    {"setBackground", DEFAULT_STYLES.background},
                    {"set", 1, "a"},
                    {"fill", 2, 9, " "}
                }
            }

            assert.are_same(singleAWord, f(
                mod.Span("a"),
                {}, {}, 10
            ))

            assert.are_same(singleAWord, f(
                mod.Div("a"),
                {}, {}, 10
            ))

            assert.are_same(singleAWord, f(
                mod.Div(mod.Div(mod.Div(mod.Div("a")))),
                {}, {}, 10
            ))
        end)
        it("can handle hoverable inline elements #skip", function()
            local onClick = function() end
            local raw, clickables = f(
                mod.Span("a"):clickable(onClick),
                {}, {}, 10
            )
            assert.are_same({
                {
                    {"setForeground", DEFAULT_STYLES.color},
                    {"setBackground", DEFAULT_STYLES.background},
                    {"set", 1, "a"},
                    {"fill", 2, 9, " "}
                }
            }, raw)
            assert.are_same({
                [onClick]={
                    hover={
                        [1]={
                            {"setForeground", DEFAULT_STYLES.hoverColor},
                            {"setBackground", DEFAULT_STYLES.hoverBackground},
                            {"set", 1, "a"},
                        }
                    },
                    active={
                        [1]={
                            {"setForeground", DEFAULT_STYLES.activeColor},
                            {"setBackground", DEFAULT_STYLES.activeBackground},
                            {"set", 1, "a"},
                        }
                    }
                }
            }, clickables)
        end)
        it("can handle hoverable long inline elements #skip", function()
            local onClick = function() end
            local raw, clickables = f(
                mod.Span("1111", "2222", "3333", "4444"):clickable(onClick),
                {}, {}, 10
            )
            assert.are_same({
                {
                    {"setForeground", DEFAULT_STYLES.color},
                    {"setBackground", DEFAULT_STYLES.background},
                    {"set", 1, "1111 2222"},
                    {"fill", 10, 1, " "}
                },
                {
                    {"setForeground", DEFAULT_STYLES.color},
                    {"setBackground", DEFAULT_STYLES.background},
                    {"set", 1, "3333 4444"},
                    {"fill", 10, 1, " "}
                }
            }, raw)
            assert.are_same({
                [onClick]={
                    hover={
                        [1]={
                            {"setForeground", DEFAULT_STYLES.hoverColor},
                            {"setBackground", DEFAULT_STYLES.hoverBackground},
                            {"set", 1, "1111 2222"},
                        },
                        [2]={
                            {"setForeground", DEFAULT_STYLES.hoverColor},
                            {"setBackground", DEFAULT_STYLES.hoverBackground},
                            {"set", 1, "3333 4444"},
                        }
                    },
                    active={
                        [1]={
                            {"setForeground", DEFAULT_STYLES.activeColor},
                            {"setBackground", DEFAULT_STYLES.activeBackground},
                            {"set", 1, "1111 2222"},
                        },
                        [2]={
                            {"setForeground", DEFAULT_STYLES.activeColor},
                            {"setBackground", DEFAULT_STYLES.activeBackground},
                            {"set", 1, "3333 4444"},
                        }
                    }
                }
            }, clickables)
        end)
        it("can handle hoverable block elements #skip", function()
            local onClick = function() end
            local raw, clickables = f(
                mod.Span("1111", "2222", "3333", "4444"):clickable(onClick),
                {}, {}, 10
            )
            assert.are_same({
                {
                    {"setForeground", 0xFFFFFF},
                    {"setBackground", 0x000000},
                    {"set", 1, "1111 2222"},
                    {"fill", 10, 1, " "}
                },
                {
                    {"setForeground", 0xFFFFFF},
                    {"setBackground", 0x000000},
                    {"set", 1, "3333 4444"},
                    {"fill", 10, 1, " "}
                }
            }, raw)
            assert.are_same({
                [onClick]={
                    hover={
                        [1]={
                            {"setForeground", 0x0000FF},
                            {"setBackground", 0x000000},
                            {"set", 1, "1111 2222"},
                        },
                        [2]={
                            {"setForeground", 0x0000FF},
                            {"setBackground", 0x000000},
                            {"set", 1, "3333 4444"},
                        }
                    },
                    active={
                        [1]={
                            {"setForeground", 0xFF0000},
                            {"setBackground", 0x000000},
                            {"set", 1, "1111 2222"},
                        },
                        [2]={
                            {"setForeground", 0xFF0000},
                            {"setBackground", 0x000000},
                            {"set", 1, "3333 4444"},
                        }
                    }
                }
            }, clickables)
        end)
    end)
end)
