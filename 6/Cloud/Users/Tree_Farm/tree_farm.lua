-- tree_farm.lua
local pretty = require "cc.pretty"


local tArgs = { ... }

local function setCursorPos()
    local x, y = term.getCursorPos()
    term.setCursorPos(1, y)
end

local function travel_time(RPM, distance)
    return (1 / RPM) * 24 * distance
end

local function build_deployer(name, rpm, distance, output_side)
    return {
        ["RPM"] = rpm,
        ["distance"] = distance,
        ["travel_time"] = travel_time(rpm, distance),
        ["output_side"] = output_side
    }
end

local function main(tArgs)

    term.clear()
    term.setCursorPos(1, 1)

    local rpm = 4
    local deployers = {
        ["dead_wood"] = build_deployer("dead_wood", rpm, 13, "back"),
        ["oak"] = build_deployer("oak", rpm, 19, "right")
    }

    print("Deployers:")
    pretty.pretty_print(deployers)

    -- disable all redstone output
    print("Disabling all redstone output...")
    for _, side in pairs(redstone.getSides()) do
        redstone.setOutput(side, false)
    end

    -- sleep for max travel time in deployers
    local max_travel_time = 0
    for _, deployer in pairs(deployers) do
        if deployer.travel_time > max_travel_time then
            max_travel_time = deployer.travel_time
        end
    end
    for i = max_travel_time, 1, -1 do
        term.clearLine()
        setCursorPos()
        term.write('Retracting all sides for ' .. i .. ' seconds...')
        sleep(1)
    end

    print("\nStarting deployer loop...")
    while true do
        for name, deployer in pairs(deployers) do

            for i = 1, 2 do
                redstone.setOutput(deployer.output_side, i == 1)

                local direction = i == 1 and "extending" or "retracting"

                for j = deployer.travel_time, 1, -1 do
                    term.clearLine()
                    setCursorPos()
                    term.write(direction .. " " .. name .. " for " .. j .. " seconds...")
                    sleep(1)
                end
            end
        end
    end

end

main(tArgs)
