local robot = require("robot")
local tree_height = 4
local radius = 2
local padding = 6
local trees_per_col = 2
local tree_double_cols = 1

function chopmove()
  if robot.detect() then robot.swing() end
  robot.forward()
end

function chopTree()
  chopmove()

  for z=1,tree_height do
    if robot.detectUp() then robot.swingUp() end
    robot.up()

    for ring=1,radius do
      chopmove()  -- entering ring
      robot.turnLeft()
      for r=1,ring do chopmove() end
      for rside=1,3 do
        robot.turnLeft()
        for r=1,ring*2 do chopmove() end
      end
      robot.turnLeft()
      for r=1,ring do chopmove() end
      robot.turnRight()
    end

    for ring=1,radius do robot.back() end
  end

  for z=1,tree_height do robot.down() end
  robot.back()
end

function isSapling()
  r, btype = robot.detect()
  if not r then return false end
  return btype == "passable"
end

function handleTree()
  if not isSapling() then
    chopTree()
    robot.place()
  end
end

function handleTreeEx()
  robot.turnLeft()
  robot.forward()
  robot.turnRight()
  handleTree()
  robot.turnRight()
  robot.forward()
  robot.turnLeft()
end

function padForward()
  for i=1,padding+1 do robot.forward() end
end

function handleCol()
  for cx=1,trees_per_col-1 do
    handleTreeEx()
    padForward()
  end
  handleTreeEx()
end

function handleDoubleCol()
  handleCol()
  robot.forward()
  robot.forward()
  robot.turnLeft()
  padForward()
  robot.forward()
  robot.forward()
  robot.turnLeft()
  handleCol()
  robot.forward()
  robot.forward()
end

function handleFarm()
  for dc=1,tree_double_cols-1 do
    handleDoubleCol()
    robot.turnRight()
    robot.back()
    robot.back()
    padForward()
    robot.turnRight()
  end
  handleDoubleCol()
  robot.turnLeft()
  robot.forward()
  robot.forward()
  for x=1,tree_double_cols*2-1 do padForward() end
  robot.turnLeft()
end

handleFarm()