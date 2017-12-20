function craftPlanning()
    c = require("crafting")
    local success, second = c.craft({
        ["iron_ingot"]=3,
        ["pcb"]=2,
        ["gold_ingot"]=1,
        ["redstone"]=7,
        ["sugarcane"]=6,
        ["iron_nugget"]=8,
        ["gpu1"]=10
    }, "gpu1", 1)

    if success then
        print("Success")
        print("Craftlog:")
        for i, v in ipairs(second) do
            print(v.item, v.times)
        end
    else
        print("Failure")
        print("NeedStock:")
        for k, v in pairs(second) do
            print(k, v)
        end
    end
end


function errtest()
    function func()
        assert(false, "lol")
    end

    local success, err = pcall(func)
    if not success then
        print("Error occured")
        print(err)
    end
end


function variableHiding()
    function f(a)
        print(a)
        for i=1,3 do
            local a=5
            print(a)
        end
        print(a)
    end

    f(3)
end


function variadic()
    function inner(...)
        print(...)
    end
    function x(...)
        inner("lol", ...)
    end

    x(1)
    x(nil, 2)
    x(2, 3, 4)
    inner(3, "c", 8)
end


function keycodes()
    local event = require("event")
    for i=1,10 do
        local evt, adr, char, code, player = event.pull("key_down")
        print(evt, adr, char, code, player)
    end
end


function returnFromDoBlock()
    local b
    do
        function b(x)
            return x + 2
        end
    end
    print(b(2))
end


function coros()
    function f()
        for i=1,10 do
            coroutine.yield(i)
        end
    end
    local co = coroutine.create(f)
    repeat
        local _, val = coroutine.resume(co)
        print(val)
    until val == nil
end


function multiParams()
    function a()
        return 2, 3
    end

    function b(x, y)
        print(x, y)
    end

    b(a())
end


local fakeGpu = {
    getResolution=function()
        return 50, 50
    end,
    fill=function(x, y, w, h, char)
        print("FILL", x, y, w, h, char)
    end,
    set=function(x, y, s)
        print("SET", x, y, s)
    end,
    getForeground=function()
        return 0xFFFFFF
    end,
    setForeground=function(v)
        print("COLOR", v)
    end,
    getBackground=function()
        return 0x000000
    end,
    setBackground=function(v)
        print("BACKGROUND", v)
    end
}


function getLipsum()
    local lipsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras feugiat mattis augue condimentum finibus. Quisque vestibulum justo ut nisl interdum suscipit. Sed sed nunc vitae orci scelerisque viverra at ultricies metus. Nullam quam mauris, consectetur eu nunc sed, posuere ullamcorper quam. Phasellus eu turpis sed ipsum suscipit egestas viverra id odio. Duis hendrerit facilisis finibus. Maecenas consequat quis lorem ut mattis. Proin ultrices lectus ut felis tincidunt, eu porta quam mattis. Cras sagittis erat consectetur condimentum rhoncus. Curabitur convallis convallis mauris sed convallis. Curabitur a quam ac nisl sodales bibendum. Nunc ut sem eleifend leo viverra blandit vitae ac augue. Etiam faucibus ligula ac sem tempus ultrices. Donec suscipit ullamcorper nibh eu aliquam."

    local lipsumTable = {}
    for w in lipsum:gmatch("%S+") do
        table.insert(lipsumTable, w)
    end
    return lipsumTable
end


function mu1(m)
    local lipsumTable = getLipsum()
    lipsumTable[2] = m.Span(lipsumTable[2]):class("highlight")

    local text = m.Div(
        m.Div("Some", "nonbr", m.Glue, m.Span("eaking"):class("highlight"), "words"):class("quote"),
        m.Div(table.unpack(lipsumTable))
    )
    local styles = {
        m.Selector({"quote"}, {color=0x8080FF}),
        m.Selector({"highlight"}, {color=0xFF0000})
    }

    return text, styles
end


function mu2(m)
    local text = m.Div(
        "Lorem", "ipsum",
        m.Div(
            "dolor", "sit", "amet"
        ):class("right")
    ):class("left")

    local styles = {
        m.Selector({"left"}, {align="left"}),
        m.Selector({"right"}, {align="right"})
    }

    return text, styles
end


function mu3(m)
    local text = m.Div(
        m.Div(
            m.Div("Lorem", "ipsum"):class("right")
        ):class("center")
    ):class("left")

    local styles = {
        m.Selector({"left"}, {align="left"}),
        m.Selector({"center"}, {align="center"}),
        m.Selector({"right"}, {align="right"})
    }

    return text, styles
end


function mu4(m)
    local lipsumTable = getLipsum()
    local text = m.Div(
        m.Span(table.unpack(lipsumTable)):class("left")
    ):class("right")

    local styles = {
        m.Selector({"right"}, {align="right"}),
        m.Selector({"right", "left"}, {align="left", color=0x00FF00})
    }

    return text, styles
end


function mu5(m)
    local lipsum = getLipsum()
    local out = {}
    for i=1,2 do
        table.insert(out, lipsum[i])
    end
    table.insert(out, m.Span(lipsum[3]):class("h"))
    for i=4,5 do
        table.insert(out, lipsum[i])
    end
    do
        local span = {}
        for i=6,8 do
            table.insert(span, lipsum[i])
        end
        table.insert(out, m.Span(table.unpack(span)):class("h"))
    end
    for i=9,20 do
        table.insert(out, lipsum[i])
    end
    do
        local span = {}
        for i=20,35 do
            table.insert(span, lipsum[i])
        end
        table.insert(out, m.Span(table.unpack(span)):class("h"))
    end
    for i=35,#lipsum do
        table.insert(out, lipsum[i])
    end

    local text = m.Div(
        m.Div(table.unpack(out)),
        m.Div(""):class("hr"),
        m.Div(
            "Highlighting", "here", "applied", "to", "whole", "block.",
            "You", "can", "see", "block", "paddings", "filled", "in", "red."
        ):class("h"),
        m.Div("* * *"):class("hr2")
    ):class("main")

    local styles = {
        m.Selector({"main"}, {align="right"}),
        m.Selector({"h"}, {color=0xFFFFFF, background=0xFF0000, fill="+", fillcolor=0xFFFF00}),
        m.Selector({"hr"}, {fill="─"}),
        m.Selector({"hr2"}, {align="center"})
    }

    return text, styles
end


function renderingMarkup()
    local m = require("ui.markup")
    local w = require("ui.windows")
    local BorderRenderer = require("ui.borders").BorderRenderer

    local text, styles = mu5(m)

    local result = m.markupToGpuCommands(text, styles, 50)

    function renderFrames(gpu)
        local h1 = w.HSplitFrame(1)
        h1:insert(w.MarkupFrame(text, styles))
        h1:insert(w.MarkupFrame(text, styles), nil, 2)
        h1:insert(w.MarkupFrame(text, styles))
        h1:insert(w.MarkupFrame(text, styles))

        local h2 = w.HSplitFrame(1)
        h2:insert(w.MarkupFrame(text, styles), nil, 3)
        h2:insert(w.MarkupFrame(text, styles))
        h2:insert(w.MarkupFrame(text, styles), nil, 2)

        local c = w.VSplitFrame(1)
        c:insert(h1)
        c:insert(h2)
        c:resize(gpu.getResolution())

        local br = BorderRenderer()
        c:render(gpu, br)

        gpu.setBackground(0x000000)
        gpu.setForeground(0x00FF00)
        br:applyJoints()
        br:render(gpu)
    end

    function outsideOC()
        -- for i, line in ipairs(result) do
        --     print('==============')
        --     for j, cmd in ipairs(line) do
        --         print(table.unpack(cmd))
        --     end
        -- end
        renderFrames({
            set = function(x, y, text)
                print("set", x, y, text)
            end,
            fill = function(x, y, w, h, fillchar)
                print("fill", x, y, w, h, fillchar)
            end,
            setForeground = function(color)
                print("setForeground", color)
            end,
            setBackground = function(color)
                print("setBackground", color)
            end,
            getResolution = function()
                print("getResolution")
                return 50, 50
            end
        })
    end

    function waitForKey()
        local event = require("event")
        repeat
            local _, _, _, key = event.pull("key_down")
        until key == 28
    end

    function execGpu()
        local gpu = require("component").gpu
        local w = require("ui.windows")

        local oldForeground = gpu.getForeground()
        local oldBackground = gpu.getBackground()
        gpu.setBackground(0x202020)
        gpu.fill(1, 1, 200, 100, " ")

        renderFrames(gpu)

        gpu.setForeground(oldForeground)
        gpu.setBackground(oldBackground)

        waitForKey()
    end

    -- m.testing.tokenDebug(text)
    -- outsideOC()
    execGpu()
end


-- craftPlanning()
-- errtest()
-- variableHiding()
-- variadic()
-- keycodes()
-- returnFromDoBlock()
-- coros()
-- multiParams()
renderingMarkup()
