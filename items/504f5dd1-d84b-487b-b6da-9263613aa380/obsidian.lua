local robot = require("robot")
local computer = require("computer")

while robot.forward() do
  robot.swingDown()
end

while robot.back() do end

computer.shutdown()