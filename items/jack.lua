local robot = require("robot")
local JackBot = require("roomBot.jackBot").JackBot


JackBot(robot, {
    width=5,
    height=2,
    step=6
}):farmSession()
