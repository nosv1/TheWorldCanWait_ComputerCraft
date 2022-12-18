local mod = peripheral.wrap("right")
local f = io.open("test.lua", "r")
f = f:read("*a")
while true do
    print('Transmitting')
    mod.transmit(9, 1, f)
    print('Sleeping')
    print(os.time())
    sleep(3)
end    
