-- ComputerCraft
-- Miner
-- search.lua
-- Go in direction looking all around for a block

local t_args = { ... }
local file = io.open("./search_log.txt", "w")
if not file then
    print("Could not open log file")
    return
end

local function inspect(compare_to, direction)
    direction = direction or "forward"
    -- compare_to is a mod:block
    -- direction is a string: "up", "down", "foward"

    local success, block = nil, nil
    if direction == "up" then
        success, block = turtle.inspectUp()
    elseif direction == "down" then
        success, block = turtle.inspectDown()
    else
        success, block = turtle.inspect()
    end

    if not success then
        return
    end

    file:write("Detected: " .. block.name .. "\n")
    if block.name == compare_to then
        if direction == "up" then
            turtle.digUp()
        elseif direction == "down" then
            turtle.digDown()
        else
            turtle.dig()
        end
        file:write("Dug: " .. block.name .. "\n")
    end
end

local function main(args)      
    local distance = tonumber(args[1])  -- int ex. 10
    local block = args[2]  -- string ex. minecraft:dirt
    file:write("Distance: " .. distance .. "\n")
    file:write("Block: " .. block .. "\n")

    while distance > 0 do 
        -- look forward, up, down, left, right

        file:write("Looking forward...\n")
        if turtle.detect() then  -- check in front
            inspect(block)
        end

        file:write("Looking up...\n")
        if turtle.detectUp() then  -- check up
            inspect(block, "up")
        end

        file:write("Looking down...\n")
        if turtle.detectDown() then  -- check down
            inspect(block, "down")
        end

        file:write("Turning left...\n")
        turtle.turnLeft()

        file:write("Looking left...\n")
        if turtle.detect() then  -- check relative left
            inspect(block)
        end

        for i = 1, 2 do
            file:write("Turning right... x" .. i .. "\n")
            turtle.turnRight()
        end

        file:write("Looking right...\n")
        if turtle.detect() then  -- check relative right
            inspect(block)
        end

        file:write("Turning left...\n")
        turtle.turnLeft()

        file:write("Going forward - To go: " .. distance - 1 .. "\n")
        turtle.forward()
        distance = distance - 1
    end
end

main(t_args)
file:close()