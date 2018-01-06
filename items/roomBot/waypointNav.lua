local WaypointNav = makeClass(RotationNav, function(self, super, robot, points)
    super(robot)
    self.currentX = 0
    self.currentY = 0
    self.currentZ = 0
    self.points = {base=true}
end)


function WaypointNav:addPoint(name)
    self.points[name] = true
end


function WaypointNav:connect(a, b)
end
