local pretty = require "cc.pretty"

local modem = peripheral.find("modem")
modem.open(rednet.MINER)

local monitor = peripheral.find("monitor")
monitor.clear()
monitor.setTextScale(0.5)

while true do
    local event, modem_side, sender_channel, reply_channel, message, sender_distance = os.pullEvent("modem_message")

    if message.protocol == "Miner:Sending:Bot" then
        local lines = {}

        local lines = { }
        -- split message.message by new line 
        for line in string.gmatch(message.message, "[^\r\n]+") do
            table.insert(lines, line)
        end

        monitor.clear()
        monitor.setCursorPos(1, 1)
        monitor.write("Received message from " .. sender_channel .. ":")
        for i, line in ipairs(lines) do
            monitor.setCursorPos(1, i + 1)
            monitor.write(line)
        end
    end
end
