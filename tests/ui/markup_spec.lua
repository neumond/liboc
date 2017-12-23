require("busted.runner")()
local utils = require("utils")
local mod = require("ui.markup")
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
    describe("markupToGpuCommands", function()
        local f = mod.markupToGpuCommands

        it("works in simple cases", function()
            local singleAWord = {
                {
                    {"setForeground", 0xFFFFFF},
                    {"setBackground", 0x000000},
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
    end)
end)
