local robot = require("robot")
local os = require("os")
local computer = require("computer")
local max_chords = 100

function noDura()
  local d = robot.durability()
  return d == nil
end

function stepForward()
  local r, btype = robot.detect()
  local isAir = not r and btype == "air"
  if not isAir then
    if not robot.compare() then return false end
    robot.swing()
  end
  if noDura() then return false end
  if not robot.forward() then return false end
  if robot.compareDown() then
    robot.swingDown()
  end
  return true
end

function walkForward(amount)
  for i=1,amount do
    if not stepForward() then return i-1 end
  end
  return amount
end

function walk()
  local path = {}
  for i=1,max_chords do
    local ch = walkForward(math.random(8, 16))
    if ch == 0 then break end
    table.insert(path, ch)
    if math.random(1, 2) == 1 then
      robot.turnLeft()
      table.insert(path, "left")
    else
      robot.turnRight()
      table.insert(path, "right")
    end
  end
  return path
end

function reversePath(path)
  local r = {}
  for i, v in ipairs(path) do
    table.insert(r, 1, v)
  end
  return r
end

function attackingForward()
  while not robot.forward() do
    robot.swing()
  end
end

function hardForward()
  while not robot.forward() do
    os.sleep(3)
  end
end

function hardBack()
  while not robot.back() do
    os.sleep(3)
  end
end

function hardDown()
  while not robot.down() do
    os.sleep(3)
  end
end

function hardUp()
  while not robot.up() do
    os.sleep(3)
  end
end

function walkReversed(path)
  for i, v in ipairs(path) do
    if v == "left" then
      robot.turnRight()
    elseif v == "right" then
      robot.turnLeft()
    else
      for k=1,v do
        attackingForward()
      end
    end
  end
end

function unload()
  hardForward()
  for slot=2,16 do
    local items = robot.count(slot)
    if items > 0 then
      robot.select(slot)
      robot.dropDown(items)
    end
  end
  robot.select(1)
  hardBack()
end

function miningSession()
  hardUp()
  local path = walk()
  robot.turnAround()
  walkReversed(reversePath(path))
  robot.turnAround()
  hardDown()
end

function waitForPickAxe()
  for i=1,20 do
    if not noDura() then return true end
    os.sleep(1)
  end
  return false
end

function getPickAxe()
  hardBack()
  hardDown()
  hardDown()
  local r = waitForPickAxe()
  hardUp()
  hardUp()
  hardForward()
  return r
end

function main()
  while getPickAxe() do
    miningSession()
    unload()
  end
  computer.shutdown()
end

main()
