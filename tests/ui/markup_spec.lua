require("busted.runner")()
local utils = require("utils")
local mod = require("ui.markup")
local DEFAULT_STYLES = require("ui.selectors").testing.DEFAULT_STYLES
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


local function makeIterTestable(f)
    return function(items)
        return accumulate(f(iterArrayValues(items)))
    end
end


describe("Markup tokenizer", function()
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
        it("calculates sizes for two words divided by blockBound", function()
            assert.are_same({
                {Flow.wordSize, 3},
                {Flow.string, "lol"},
                {Flow.blockBound},
                {Flow.wordSize, 3},
                {Flow.string, "kek"},
            }, f({
                {Flow.string, "lol"},
                {Flow.blockBound},
                {Flow.string, "kek"}
            }))
        end)
        it("can handle multiple blockBounds", function()
            assert.are_same({
                {Flow.blockBound},
                {Flow.blockBound},
                {Flow.wordSize, 1},
                {Flow.string, "a"},
                {Flow.blockBound},
                {Flow.blockBound},
                {Flow.wordSize, 1},
                {Flow.string, "b"},
                {Flow.blockBound},
                {Flow.blockBound}
            }, f({
                {Flow.blockBound},
                {Flow.blockBound},
                {Flow.string, "a"},
                {Flow.blockBound},
                {Flow.blockBound},
                {Flow.string, "b"},
                {Flow.blockBound},
                {Flow.blockBound}
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
        it("ignores glue near blockBound", function()
            local expected = {
                {Flow.wordSize, 4},
                {Flow.string, "long"},
                {Flow.blockBound},
                {Flow.wordSize, 4},
                {Flow.string, "word"}
            }
            for t in beforeAfterTokens({
                {Flow.string, "long"},
                {Flow.glue},
                {Flow.blockBound},  -- breaks words
                {Flow.glue},
                {Flow.string, "word"}
            }, 2, 4) do
                assert.are_same(expected, f(t))
            end
        end)
        it("glues two words with other tokens in the middle", function()
            for _, flowcode in ipairs({
                {Flow.pushClass, "x"},
                {Flow.popClass},
                {Flow.startControl},
                {Flow.endControl}
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
    describe("squashBlockBounds", function()
        local f = makeIterTestable(mod.testing.squashBlockBounds)

        it("leaves tokens without blockBounds unchanged", function()
            local t = {
                {Flow.wordSize, 8},
                {Flow.string, "long"},
                {Flow.string, "word"}
            }
            assert.are_same(t, f(t))
        end)
        it("squashes consequent blockBounds into one", function()
            local function makeTokens(nBounds)
                local t = {
                    {Flow.wordSize, 3},
                    {Flow.string, "top"},
                    {Flow.wordSize, 3},
                    {Flow.string, "kek"}
                }
                for i=1,nBounds do
                    table.insert(t, 3, {Flow.blockBound})
                end
                return t
            end
            assert.are_same(makeTokens(1), f(makeTokens(1)))
            assert.are_same(makeTokens(1), f(makeTokens(3)))
            assert.are_same(makeTokens(1), f(makeTokens(5)))
        end)
    end)
    describe("iterMarkupTokens", function()
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
        it("inserts blockBound between Divs", function()
            assert.are_same({
                {Flow.wordSize, 1},
                {Flow.string, "a"},
                {Flow.blockBound},
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
    describe("splitIntoLines", function()
        local f = function(tokens)
            return accumulate(mod.testing.splitIntoLines(
                iterArrayValues(tokens), 10
            ))
        end

        it("handles blocks as lines", function()
            assert.are_same({
                {Flow.lineSize, 4, 0},
                {Flow.string, "abcd"},
                {Flow.blockBound},
                {Flow.lineSize, 5, 1},
                {Flow.string, "aa"},
                {Flow.space},
                {Flow.string, "bb"}
            }, f({
                {Flow.wordSize, 4},
                {Flow.string, "abcd"},
                {Flow.blockBound},
                {Flow.wordSize, 2},
                {Flow.string, "aa"},
                {Flow.wordSize, 2},
                {Flow.string, "bb"}
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
    end)
    describe("markupToGpuCommands", function()
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
