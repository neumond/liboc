local event = require("event")


for i=1,10 do
    local evt, adr, char, code, player = event.pull("key_down")
    print(evt, adr, char, code, player)
end
