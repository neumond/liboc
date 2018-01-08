require("busted.runner")()
local mod = require("lib.dijkstra")


local function chord(graph, a, b, len)
    if graph[a] == nil then graph[a] = {} end
    if graph[b] == nil then graph[b] = {} end
    graph[a][b] = len
    graph[b][a] = len
end


describe("dijsktra", function()
    it("simple triangle", function()
        local graph = {}
        chord(graph, "a", "b", 5)
        chord(graph, "b", "c", 3)
        chord(graph, "a", "c", 9)
        assert.are_same({"a", "b", "c"}, mod.dijkstra(graph, "a", "c"))
    end)
    it("long chain", function()
        local graph = {}
        chord(graph, "a", "b", 1)
        chord(graph, "b", "c", 1)
        chord(graph, "c", "d", 1)
        chord(graph, "d", "e", 1)
        chord(graph, "e", "f", 1)
        assert.are_same({"a", "b", "c", "d", "e", "f"}, mod.dijkstra(graph, "a", "f"))
    end)
    it("target is source", function()
        local graph = {}
        chord(graph, "a", "b", 5)
        chord(graph, "b", "c", 3)
        chord(graph, "a", "c", 9)
        assert.are_same({"a"}, mod.dijkstra(graph, "a", "a"))
    end)
    it("isolated subgraph", function()
        local graph = {}
        chord(graph, "a", "b", 5)
        chord(graph, "b", "c", 3)
        chord(graph, "a", "c", 9)
        chord(graph, "K", "L", 7)
        chord(graph, "L", "M", 2)
        assert.is_nil(mod.dijkstra(graph, "a", "M"))
    end)
end)
