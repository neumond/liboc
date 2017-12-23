local function craftPlanning()
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


local function errtest()
    local function func()
        assert(false, "lol")
    end

    local success, err = pcall(func)
    if not success then
        print("Error occured")
        print(err)
    end
end


local function variableHiding()
    local function f(a)
        print(a)
        for i=1,3 do
            local a=5
            print(a)
        end
        print(a)
    end

    f(3)
end


local function variadic()
    local function inner(...)
        print(...)
    end
    local function x(...)
        inner("lol", ...)
    end

    x(1)
    x(nil, 2)
    x(2, 3, 4)
    inner(3, "c", 8)
end


local function keycodes()
    local event = require("event")
    for i=1,10 do
        local evt, adr, char, code, player = event.pull("key_down")
        print(evt, adr, char, code, player)
    end
end


local function returnFromDoBlock()
    local b
    do
        b = function(x)
            return x + 2
        end
    end
    print(b(2))
end


local function coros()
    local function f()
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


local function multiParams()
    local function a()
        return 2, 3
    end

    local function b(x, y)
        print(x, y)
    end

    b(a())
end


local fakeGpu = {
    getResolution=function()
        return 160, 50
    end,
    fill=function(x, y, w, h, char)
        -- print("FILL", x, y, w, h, char)
    end,
    set=function(x, y, s)
        -- print("SET", x, y, s)
    end,
    getForeground=function()
        return 0xFFFFFF
    end,
    setForeground=function(v)
        -- print("COLOR", v)
        return 0xFFFFFF
    end,
    getBackground=function()
        return 0x000000
    end,
    setBackground=function(v)
        -- print("BACKGROUND", v)
        return 0x000000
    end,
    copy=function(x, y, w, h, tx, ty)
        return true
    end
}


local function getLipsum()
    local lipsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras feugiat mattis augue condimentum finibus. Quisque vestibulum justo ut nisl interdum suscipit. Sed sed nunc vitae orci scelerisque viverra at ultricies metus. Nullam quam mauris, consectetur eu nunc sed, posuere ullamcorper quam. Phasellus eu turpis sed ipsum suscipit egestas viverra id odio. Duis hendrerit facilisis finibus. Maecenas consequat quis lorem ut mattis. Proin ultrices lectus ut felis tincidunt, eu porta quam mattis. Cras sagittis erat consectetur condimentum rhoncus. Curabitur convallis convallis mauris sed convallis. Curabitur a quam ac nisl sodales bibendum. Nunc ut sem eleifend leo viverra blandit vitae ac augue. Etiam faucibus ligula ac sem tempus ultrices. Donec suscipit ullamcorper nibh eu aliquam."

    local lipsumTable = {}
    for w in lipsum:gmatch("%S+") do
        table.insert(lipsumTable, w)
    end
    return lipsumTable
end


local function lipsumIter()
    local lipsum = getLipsum()
    local lipsumPtr = 0
    return function()
        lipsumPtr = lipsumPtr + 1
        return lipsum[lipsumPtr]
    end
end


local function mu1(m)
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


local function mu2(m)
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


local function mu3(m)
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


local function mu4(m)
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


local function mu5(m)
    local lipsumNext = lipsumIter()
    local out = {}
    for i=1,2 do
        table.insert(out, lipsumNext())
    end
    table.insert(out, m.Span(lipsumNext()):class("h"))
    for i=1,2 do
        table.insert(out, lipsumNext())
    end
    do
        local span = {}
        for i=1,3 do
            table.insert(span, lipsumNext())
        end
        table.insert(out, m.Span(table.unpack(span)):class("h"))
    end
    for i=1,11 do
        table.insert(out, lipsumNext())
    end
    do
        local span = {}
        for i=1,15 do
            table.insert(span, lipsumNext())
        end
        table.insert(out, m.Span(table.unpack(span)):class("h"))
    end
    for w in lipsumNext do
        table.insert(out, w)
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


local function createUI(gpu)
    local m = require("ui.markup")
    local root = require("ui.windows").FrameRoot(gpu)

    local text, styles = mu5(m)

    local mfs = {}
    for i=1,16 do
        table.insert(mfs, root:Markup(text, {}, styles))
    end
    for i=9,16 do
        mfs[i]:setMinimalContentWidth(30)
    end

    local h1 = root:HSplit()
    h1:setBorderType(1)
    for i=1,8 do
        h1.children:append(mfs[i])
    end

    local h2 = root:HSplit()
    h2:setBorderType(1)
    for i=9,16 do
        h2.children:append(mfs[i])
    end

    local c = root:VSplit()
    c:setBorderType(2)
    c.children:append(h1)
    c.children:append(h2)

    root:assignRoot(c)

    return root, mfs
end


local function tokenizeMarkup(gpu)
    local m = require("ui.markup")
    local text, styles = mu5(m)
    local commands = m.markupToGpuCommands(text, {}, styles, 50)
    -- m.execGpuCommands(gpu, commands)
    -- m.testing.tokenDebug(text)
    for i, line in ipairs(commands) do
        print('==============')
        for j, cmd in ipairs(line) do
            print(table.unpack(cmd))
        end
    end
end


local function waitForKey()
    local event = require("event")
    repeat
        local _, _, _, key = event.pull("key_down")
        -- 200 up
        -- 208 down
        -- 203 left
        -- 205 right
    until key == 28
end


local function scrollingHandler(root, sm)
    local event = require("event")
    repeat
        local _, _, _, key = event.pull("key_down")
        local sx, sy = 0, 0
        repeat
            if key == 200 then
                sy = sy - 1
            elseif key == 208 then
                sy = sy + 1
            elseif key == 203 then
                sx = sx - 1
            elseif key == 205 then
                sx = sx + 1
            end
            local _, _, _, key = event.pull(0, "key_down")
        until key == nil
        if (sx ~= 0) or (sy ~= 0) then
            sm:relativeScroll(sx, sy)
        end
        -- root:update()
        -- 200 up
        -- 208 down
        -- 203 left
        -- 205 right
    until key == 28
end


local function runUsingRealGpu(f)
    local gpu = require("component").gpu
    local oldForeground = gpu.getForeground()
    local oldBackground = gpu.getBackground()
    gpu.setBackground(0x202020)
    gpu.fill(1, 1, 200, 100, " ")

    f(gpu)

    gpu.setForeground(oldForeground)
    gpu.setBackground(oldBackground)
end


local function runUsingFakeGpu(f)
    f(fakeGpu)
end


local function renderingUI()
    local function renderFrames(gpu)
        local root, mfs = createUI(gpu)
        for i=1,8 do
            mfs[i]:scrollTo(1, i)
        end
        for i=9,16 do
            mfs[i]:scrollTo(i - 8, 1)
        end
        root:update()
        return root, mfs[9]
    end

    local function outsideOC()
        local root, sm = renderFrames(fakeGpu)
        sm:relativeScroll(1, 0)
        root:update()
    end

    local function execGpu()
        runUsingRealGpu(function(gpu)
            local root, sm = renderFrames(gpu)
            -- waitForKey()
            scrollingHandler(root, sm)
        end)
    end

    outsideOC()
    -- execGpu()
end


local function scrollingInCentralFrame()
    runUsingRealGpu(function(gpu)
        local root = require("ui.windows").FrameRoot(gpu)
        local text, styles = mu5(require("ui.markup"))

        local mfs = {}
        do
            for i=1,9 do
                table.insert(mfs, root:Markup(text, {}, styles))
            end
            for _, mf in ipairs(mfs) do
                mf:setMinimalContentWidth(70)
            end

            local c = root:VSplit()
            c:setBorderType(2)
            for row=1,3 do
                local h = root:HSplit()
                h:setBorderType(1)
                for col=1,3 do
                    h.children:append(mfs[col * 3 - 3 + row])
                end
                c.children:append(h)
            end

            root:assignRoot(c)
        end

        root:update()
        scrollingHandler(root, mfs[5])
    end)
end


local function veryLongLipsum()
    local m = require("ui.markup")
    local lipsum = {
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec at tortor metus. Nam vel pellentesque orci. Morbi eu eros diam. Morbi malesuada magna et lectus lacinia elementum. Quisque suscipit, leo scelerisque interdum eleifend, ligula sem dignissim nisi, eu volutpat sem mauris id est. Morbi venenatis molestie ligula, in vestibulum tellus eleifend vitae. Donec arcu metus, gravida eget massa et, egestas mattis nunc. Nulla at posuere magna, et viverra ipsum. Nullam eleifend urna urna, in iaculis est fermentum ac. Aliquam erat volutpat. Sed maximus augue et odio vulputate imperdiet. Aliquam dignissim varius malesuada. Sed iaculis nisl et nisi imperdiet, nec suscipit nunc cursus. Proin finibus auctor lacus.",
        "Vivamus pulvinar ullamcorper scelerisque. Nunc egestas est est, in euismod ligula posuere scelerisque. Vivamus in suscipit elit, ac cursus felis. Donec sem dui, molestie finibus pellentesque nec, pulvinar ac purus. Maecenas augue enim, ultricies id gravida a, sodales faucibus nunc. Maecenas fermentum porttitor felis, vel mollis ligula blandit vitae. Maecenas aliquet felis et velit condimentum, in bibendum mauris iaculis. Cras ex ligula, pretium eget velit at, sodales eleifend enim. Donec commodo blandit urna, a gravida mi maximus id. Vestibulum sed tortor vehicula, faucibus sapien in, sodales turpis. Quisque diam dui, eleifend eget ullamcorper a, consectetur sed urna.",
        "Etiam nisi velit, consectetur vitae lacus eu, eleifend elementum libero. Nunc efficitur mi sed neque molestie sodales. Vivamus ac magna eros. Vestibulum eu vulputate neque. Praesent eu turpis vel orci dictum dignissim sed a nisi. Nulla ante augue, lobortis nec pretium a, pretium vel ex. Fusce vehicula ac orci ac feugiat. Sed molestie ex elit, ac semper dolor imperdiet eget. Phasellus nec vestibulum turpis. Fusce accumsan leo at fermentum eleifend. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Nunc dolor est, viverra ac auctor a, tincidunt et leo. Duis eleifend, nisi sit amet ullamcorper molestie, risus ligula gravida lectus, dictum consequat velit elit sit amet libero. Nunc nec odio eu eros gravida tempor. Mauris vel tortor ut velit tincidunt congue a fringilla urna. Aliquam laoreet felis id neque lobortis, nec consequat justo euismod.",
        "Fusce vestibulum tellus enim. In vel mauris neque. Vivamus sodales iaculis nunc in volutpat. In hac habitasse platea dictumst. Nullam sit amet diam ac nunc ullamcorper imperdiet. Vivamus vel sem nec orci efficitur euismod ac nec nisl. Morbi tristique velit eget libero hendrerit varius. Praesent at diam pulvinar lorem lobortis feugiat commodo id leo. Vestibulum interdum ligula id dictum porttitor. Sed ut ante volutpat, fringilla libero eu, dignissim nisi. Donec fermentum lorem mauris. Morbi vitae dignissim nulla. Ut vel bibendum neque, et ultrices enim. Integer id rutrum ex. Aliquam aliquam accumsan tortor a blandit.",
        "Nullam cursus vitae velit non imperdiet. Cras commodo vel felis condimentum dignissim. Cras sagittis ipsum aliquet ipsum condimentum maximus. Nulla mattis erat eu purus condimentum molestie. Mauris orci lacus, mattis vitae turpis vitae, blandit hendrerit lacus. Nulla facilisi. Pellentesque placerat neque non urna egestas, ac sodales risus accumsan. Curabitur arcu velit, eleifend a arcu ut, ultrices sagittis eros. Morbi in erat a velit faucibus dictum ac sit amet justo. Maecenas sollicitudin eros vel blandit accumsan. Ut eleifend neque et ligula pharetra fringilla.",
        "Mauris quis nulla sed felis convallis suscipit eu sit amet orci. Nam nec mi justo. Vestibulum id dignissim velit, eget bibendum magna. Nullam sed diam ullamcorper, venenatis libero et, faucibus risus. Duis ac ligula sed felis vulputate finibus vel sit amet dui. Cras placerat finibus nunc non sagittis. Pellentesque id metus eu arcu finibus feugiat sed nec nisl.",
        "Cras a consectetur lorem. Vestibulum id lacus mattis, tristique nibh ut, scelerisque justo. Nullam vulputate fermentum sem et consequat. Vestibulum quis neque non erat bibendum tempus. Pellentesque sollicitudin condimentum nisi, eu imperdiet turpis cursus et. Nulla et commodo dolor. Aenean molestie eros sed mauris placerat sagittis.",
        "Vivamus ut ullamcorper ex. Integer aliquet sem ac bibendum sollicitudin. Praesent vitae fringilla lectus, ac placerat ipsum. Aliquam cursus lectus id lacus euismod, in suscipit quam placerat. Suspendisse fermentum, nunc eu vestibulum tincidunt, dui velit sollicitudin justo, eget posuere enim eros sed tellus. Phasellus magna velit, tristique nec tempor eu, luctus ac mauris. Maecenas fermentum feugiat ante id gravida. Quisque luctus nulla eget massa molestie iaculis. Nullam placerat posuere elit, in condimentum purus vehicula eu. Donec luctus interdum lectus, a accumsan libero dictum ac. Sed gravida at mauris id finibus.",
        "Etiam iaculis rutrum eros et faucibus. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Nullam ornare ullamcorper odio nec pellentesque. Nunc eros purus, interdum nec dignissim ut, cursus sed velit. Sed ultrices, nisi vel volutpat consequat, enim erat laoreet mi, molestie aliquet felis tortor vitae velit. Nunc vulputate, augue in tempor ornare, leo metus mollis felis, a fermentum nibh velit eu lectus. Suspendisse mattis auctor elementum. Praesent hendrerit, diam at commodo egestas, lorem est ullamcorper sapien, sed imperdiet massa leo eget nisi. Pellentesque efficitur, neque nec ultrices mattis, erat eros viverra massa, quis ultricies dolor orci at nisi. Morbi pellentesque sed turpis ac consequat. Vestibulum fermentum turpis posuere lorem tincidunt, eu aliquet sapien tincidunt. Sed a sapien vehicula, laoreet purus non, euismod leo. Vivamus in rhoncus neque.",
        "Suspendisse eget placerat nulla. Pellentesque mi nisl, euismod vitae orci ac, volutpat pharetra magna. Aliquam ut fringilla tellus. Nunc et lorem ac risus viverra tempor. Ut massa sem, rhoncus vel enim sed, dictum efficitur arcu. Nulla facilisi. Duis in lorem ut tellus iaculis condimentum. Nulla facilisi."
    }
    local divs = {}
    for i=1,3 do
        for _, line in ipairs(lipsum) do
            local words = {}
            for word in line:gmatch("%S+") do
                table.insert(words, word)
            end
            if #divs > 0 then
                table.insert(divs, m.Div("* * *"):class("hr"))
            end
            table.insert(divs, m.Div(table.unpack(words)))
        end
    end
    local text = m.Div(table.unpack(divs))
    return text, {
        m.Selector({"hr"}, {align="center"})
    }
end


local function renderBigWallOfText()
    runUsingRealGpu(function(gpu)
        local root = require("ui.windows").FrameRoot(gpu)
        local text, styles = veryLongLipsum()
        local sm = root:Markup(text, {}, styles)
        root:assignRoot(sm)
        root:update()
        scrollingHandler(root, sm)
    end)
end


local function clickableElements()
    runUsingRealGpu(function(gpu)
        local function createMarkup()
            local m = require("ui.markup")
            local lipsumNext = lipsumIter()
            local spans = {}
            for i=1,5 do
                table.insert(spans, m.Span(lipsumNext()))
            end
            table.insert(spans, m.Span(lipsumNext()):clickable(function()
                print("LOL")
            end))
            for word in lipsumNext do
                table.insert(spans, m.Span(word))
            end
            local text = m.Div(table.unpack(spans))
            local styles = {
                -- m.Selector({"right"}, {align="right"}),
                -- m.Selector({"right", "left"}, {align="left", color=0x00FF00})
            }
            return text, {}, styles
        end

        local root = require("ui.windows").FrameRoot(gpu)
        local sm = root:Markup(createMarkup())
        root:assignRoot(sm)
        root:update()

        scrollingHandler(root, sm)
        -- waitForKey()
    end)
end


-- craftPlanning()
-- errtest()
-- variableHiding()
-- variadic()
-- keycodes()
-- returnFromDoBlock()
-- coros()
-- multiParams()
-- tokenizeMarkup()
-- renderingUI()
-- scrollingInCentralFrame()
renderBigWallOfText()
-- clickableElements()
