require("busted.runner")()
local mod = require("ui.regionGpu")


describe("windows framework", function()
    it("has correct intersection function", function()
        local f = mod.intersection

        -- a inside b
        assert.are.same({f(2, 5, 1, 10)}, {2, 5})

        -- b inside a
        assert.are.same({f(1, 10, 2, 5)}, {2, 5})

        -- a equals b
        assert.are.same({f(1, 10, 1, 10)}, {1, 10})

        -- a is a left edge of b
        assert.are.same({f(1, 3, 1, 10)}, {1, 3})

        -- a starts before b
        assert.are.same({f(1, 8, 5, 10)}, {5, 8})

        -- a has size 1
        assert.are.same({f(3, 3, 1, 10)}, {3, 3})

        -- outside
        assert.is_nil(f(1, 3, 5, 10))
    end)
    describe("RegionGpu", function()
        it("has correctly working method fill", function()
            local parentGpu = mock({
                fill = function(x, y, w, h, fillchar)
                end
            })
            local r = mod.RegionGpu(parentGpu, 10, 10, 3, 3, 0, 0)

            -- top left corner

            r.fill(1, 1, 1, 1, " ")
            assert.spy(parentGpu.fill).was_called_with(10, 10, 1, 1, " ")
            mock.clear(parentGpu)

            r.fill(1, 1, 5, 2, " ")
            assert.spy(parentGpu.fill).was_called_with(10, 10, 3, 2, " ")
            mock.clear(parentGpu)

            r.fill(1, 1, 8, 8, "x")
            assert.spy(parentGpu.fill).was_called_with(10, 10, 3, 3, "x")
            mock.clear(parentGpu)

            -- bottom right corner

            r.fill(3, 3, 1, 1, " ")
            assert.spy(parentGpu.fill).was_called_with(12, 12, 1, 1, " ")
            mock.clear(parentGpu)

            r.fill(4, 4, 1, 1, " ")
            assert.spy(parentGpu.fill).was_not_called()
            mock.clear(parentGpu)

            r.fill(3, 3, 5, 5, " ")
            assert.spy(parentGpu.fill).was_called_with(12, 12, 1, 1, " ")
            mock.clear(parentGpu)

            -- inside

            r.fill(-10, -10, 100, 100, "K")
            assert.spy(parentGpu.fill).was_called_with(10, 10, 3, 3, "K")
            mock.clear(parentGpu)
        end)
        it("has correctly working method set", function()
            local parentGpu = mock({
                set = function(x, y, text)
                end
            })
            local r = mod.RegionGpu(parentGpu, 10, 10, 3, 3, 0, 0)

            -- top left corner

            r.set(1, 1, "texttext")
            assert.spy(parentGpu.set).was_called_with(10, 10, "tex")
            mock.clear(parentGpu)

            -- bottom right corner

            r.set(3, 3, "lorem")
            assert.spy(parentGpu.set).was_called_with(12, 12, "l")
            mock.clear(parentGpu)

            -- inside

            r.set(-3, 2, "pad4_X_pad4")
            assert.spy(parentGpu.set).was_called_with(10, 11, "_X_")
            mock.clear(parentGpu)
        end)
        it("has correctly working method copy", function()
            local parentGpu = mock({
                copy = function(x, y, w, h, tx, ty)
                end
            })
            local r = mod.RegionGpu(parentGpu, 10, 10, 3, 3, 0, 0)

            r.copy(2, 2, 2, 2, -1, -1)
            assert.spy(parentGpu.copy).was_called_with(11, 11, 2, 2, -1, -1)
            mock.clear(parentGpu)

            r.copy(1, 1, 3, 3, -1, -1)
            assert.spy(parentGpu.copy).was_called_with(11, 11, 2, 2, -1, -1)
            mock.clear(parentGpu)

            r.copy(1, 1, 2, 2, 1, 1)
            assert.spy(parentGpu.copy).was_called_with(10, 10, 2, 2, 1, 1)
            mock.clear(parentGpu)

            r.copy(1, 1, 3, 3, 1, 1)
            assert.spy(parentGpu.copy).was_called_with(10, 10, 2, 2, 1, 1)
            mock.clear(parentGpu)

            r.copy(0, 0, 4, 4, 1, 1)
            assert.spy(parentGpu.copy).was_called_with(10, 10, 2, 2, 1, 1)
            mock.clear(parentGpu)

            r.copy(3, 3, 1, 1, -2, -2)
            assert.spy(parentGpu.copy).was_called_with(12, 12, 1, 1, -2, -2)
            mock.clear(parentGpu)

            r.copy(3, 3, 1, 1, -3, -3)
            assert.spy(parentGpu.copy).was_not_called()
            mock.clear(parentGpu)
        end)
    end)
end)
