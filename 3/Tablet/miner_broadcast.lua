local pretty = require "cc.pretty"

local modem = peripheral.find("modem")
modem.open(rednet.CHANNEL_REPEAT)

while true do
    local event, modem_side, sender_channel, reply_channel, message, sender_distance = os.pullEvent("modem_message")

    print("Received message from " .. sender_channel .. ":")
    local bot = textutils.unserialize(message.message)
    pretty.pretty_print(bot.position)
    pretty.pretty_print(bot.ore)
    local f = io.open("Tablet/bot.json", "w")
    f:write(message.message)
    f:close()
end
