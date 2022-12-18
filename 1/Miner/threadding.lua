-- Computercraft
-- threadding.lua

local function multi_threadding()
    while true do
        local ID_MAIN = os.startTimer(5)  -- main loop timer
        local ID = os.startTimer(0.05)  -- event listener timer
        local event = { os.pullEvent() }  -- event listener

        if event[1] == "char" then -- if a key was pressed
            print("Key: " .. event[2] .. " was pressed")

        elseif event[1] == "timer" and event[2] == ID then  -- was a timer event triggered and was it 'my' timer
            print("\r" .. "Time: " .. os.clock())

        elseif event[1] == "timer" and event[2] == ID_MAIN then
            break
        end
    end
end

multi_threadding()