local size=10

function dig()
  if robot.detect() then
    robot.swing()
  end
  if robot.detectDown() then
    robot.swingDown()
  end
  robot.forward()
end

for x=1,size do
  for y=1,size do
    dig()
  end
  if x % 2 == 1 then
    robot.turnLeft()
    dig()
    robot.turnLeft()
  else
    robot.turnRight()
    dig()
    robot.turnRight()
  end
end