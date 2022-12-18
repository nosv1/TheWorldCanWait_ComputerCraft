local pretty = require "cc.pretty"

local t_args = {...}

-- Support
local function suck_into(slot)
    while true do
        turtle.select(slot)
        if turtle.getItemCount(slot) > 0 then
            return true
        end
        turtle.suck(1)
        sleep(1)
    end
end

local function orient(direction)
    -- direction is a cardinal direction "north", "south", "east", "west"
    repeat
        is_block, block = turtle.inspect()
        if is_block and block.name == "storagedrawers:oak_half_drawers_1" then
            break
        end
        turtle.turnLeft()
    until true
    
    -- we assume we are always facing a drawer
    if block.state.facing == "east" then  -- nickel ingot drawer faces east
        if direction == "west" then
            return
        elseif direction == "south" then
            turtle.turnLeft()
        end

    elseif block.state.facing == "north" then  -- iron dust drawer faces north
        if direction == "south" then
            return
        elseif direction == "west" then
            turtle.turnRight()
        end
    end
end

-------------------------------------------------------------------------------

local function craft_nickel_compound()
    while true do
        term.clear()
        term.setCursorPos(1, 1)

        term.write("Waiting for nickel compound removal...")
        craft_slot = 16
        while turtle.getItemCount(craft_slot) > 0 do
            sleep(1)
        end

        -- get nickel
        orient("west")
        print("Sucking nickel ingot into slot 1...")
        redstone.setOutput("right", true)
        slot = 1
        suck_into(slot)
        redstone.setOutput("right", false)
        

        -- get iron dust
        orient("south")
        slots = { 2, 3, 5, 6 }
        for i, slot in ipairs(slots) do
            print("Sucking iron dust into slot " .. slot .. "...")
            suck_into(slot)
        end

        -- craft
        print("Crafting nickel compound...")
        turtle.select(craft_slot)
        turtle.craft(1)

    end
end

local function main(t_args)
    craft_nickel_compound()
end

main(t_args)