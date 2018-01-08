local utils = require("utils")
local TrackingBinaryHeap = require("lib.binHeap").TrackingBinaryHeap


local function dijkstra(graph, source, target)
    -- graph is table of tables
    -- {
    --     ["node1"] = {
    --         ["node2"] = 5,
    --         ["node3"] = 8,
    --         ...
    --     },
    --     ["node2"] = ...
    -- }
    -- graph is required to have both directions of every edge

    assert(graph[source] ~= nil)
    assert(graph[target] ~= nil)

    local dist = {}
    local queue = TrackingBinaryHeap()
    local prev = {}
    for k, _ in pairs(graph) do
        dist[k] = math.huge
        queue:insert(math.huge, k)
    end
    dist[source] = 0
    queue:decrease(0, source)

    local function gatherResult()
        local node = target
        local path = {node}
        while node ~= source do
            node = prev[node]
            assert(node ~= nil)
            table.insert(path, node)
        end
        utils.reverseArray(path)
        return path
    end

    while queue:tip() ~= nil do
        local curDist, vertex = queue:pop()
        if curDist == math.huge then break end  -- no path exists
        if vertex == target then return gatherResult() end
        for neighbour, edgeLen in pairs(graph[vertex]) do
            local newDist = curDist + edgeLen
            if newDist < dist[neighbour] then
                dist[neighbour] = newDist
                prev[neighbour] = vertex
                queue:decrease(newDist, neighbour)
            end
        end
    end
end


return {
    dijkstra=dijkstra
}
