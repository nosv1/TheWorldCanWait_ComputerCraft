rednet.open("right")

local current_command = "none"
while true do
    local _, msg = rednet.receive()
    if msg == "stop" then
        rednet.broadcast("stopping")
        break
    end

    if msg == "run" then
        current_command = "run"
    end

    if current_command == "run" then
        turtle.forward()
    end
end