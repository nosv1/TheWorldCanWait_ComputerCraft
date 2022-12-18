-- Computercraft
-- branch_miner

local pretty = require "cc.pretty"

local t_args = {...}

-- SUPPORT --

local function flag_handling() end
local function table_to_string() end
local function transmit() end

-- CHECKS --

local function is_block_type(name, type)
    local block_types = {
        ["ground"] = {
            "minecraft:andesite",
            "create:andesite_cobblestone",
            "minecraft:cobblestone",
            "forbidden_arcanus:darkstone",
            "minecraft:diorite",
            "create:diorite_cobblestone",
            "minecraft:dirt",
            "create:dolomite",
            "minecraft:granite",
            "create:granite_cobblestone",
            "minecraft:grass",
            "minecraft:gravel",
            "darkerdepths:grimestone",
            "minecraft:sand",
            "minecraft:stone",
        },
    }
    
    for _, block in pairs(block_types[type]) do
        if block == name then
            return true
        end
    end
    
    return false
end

local function is_ore(name, tags)
    return (
        tags["forge:ores"] or
        name == "buddycards:luminis_ore"
    )
end

-- MATH --

local function round(num, places)
    local mult = 10^(places or 0)
    return math.floor(num * mult + 0.5) / mult
end

-- VECTOR MATH --

local function vector_addition(v1, v2)
    v1.x = v1.x + v2.x
    v1.y = v1.y + v2.y
    v1.z = v1.z + v2.z
    return v1
end

local function vector_subtraction(v1, v2)
    return {
        x = v1.x - v2.x,
        y = v1.y - v2.y,
        z = v1.z - v2.z,
    }
end

local function vector_scalar_multiplication(v, s)
    return {
        x = v.x * s,
        y = v.y * s,
        z = v.z * s,
    }
end

local function vector_dot_product(v1, v2)
    return v1.x * v2.x + v1.y * v2.y + v1.z * v2.z
end

local function vector_cross_product(v1, v2)
    return {
        x = v1.y * v2.z - v1.z * v2.y,
        y = v1.z * v2.x - v1.x * v2.z,
        z = v1.x * v2.y - v1.y * v2.x,
    }
end

local function vector_magnitude(v)
    return math.sqrt(
        math.pow(v.x, 2) + math.pow(v.y, 2) + math.pow(v.z, 2)
    )
end

local function vector_normalized(v)
    local magnitude = vector_magnitude(v)
    return {
        x = v.x / magnitude,
        y = v.y / magnitude,
        z = v.z / magnitude
    }
end

local function vector_distance(v1, v2)
    return vector_magnitude(
        vector_subtraction(v1, v2)
    )
end

local function vector_equal(v1, v2, ignore_component)
    ignore_component = ignore_component or nil
    for component, value in pairs(v1) do
        if component ~= ignore_component then
            if v1[component] ~= v2[component] then
                return false
            end
        end
    end
    return true
end

local function vector_yaw_rotation(v, angle)
    angle = angle * math.pi / 180
    return {
        x = math.cos(angle) * v.x - math.sin(angle) * v.z,
        y = v.y,
        z = math.sin(angle) * v.x + math.cos(angle) * v.z
    }
end

local function vector_round(v, places)
    places = places or 0
    return {
        x = round(v.x, places),
        y = round(v.y, places),
        z = round(v.z, places)
    }
end

local function vector_to_string(v)
    return "<" .. v.x .. ", " .. v.y .. ", " .. v.z .. ">"
end

local function vector_parse(v)
    -- v as "x,y,z"
    local i = 1
    local component = ""
    local count = 1
    local vector = {}
    while i <= #v do
        if v:sub(i, i) == "," then
            vector[count] = tonumber(component)
            component = ""
            count = count + 1
        else
            component = component .. v:sub(i, i)
        end
        i = i + 1
    end
    vector[count] = tonumber(component)
    return {
        x = vector[1],
        y = vector[2],
        z = vector[3]
    }
end

-- DIRECTIONS --

local function has_fuel() end

local function _forward(bot)
    if turtle.forward() then
        bot.position = vector_addition(bot.position, bot.vector)
        return true, bot
    end
    return false, bot
end

local function _back(bot)
    if turtle.back() then
        bot.position = vector_subtraction(bot.position, bot.vector)
        return true, bot
    end
    return false, bot
end

local function _up(bot)
    if turtle.up() then
        bot.position.y = bot.position.y + 1
        return true, bot
    end
    return false, bot
end

local function _down(bot)
    if turtle.down() then
        bot.position.y = bot.position.y - 1
        return true, bot
    end
    return false, bot
end

local function move(bot, direction, distance)
    direction = direction or "forward"
    direction = direction == "" and "forward" or direction
    distance = distance or 1

    for i = 1, distance do 
        transmit(bot)
        bot.fuel_level = turtle.getFuelLevel()

        if not has_fuel() then
            return false, bot
        end

        local success = false

        if direction == "forward" then
            success, bot = _forward(bot)
        elseif direction == "back" then
            success, bot = _back(bot)
        elseif direction == "up" then
            success, bot = _up(bot)
        elseif direction == "down" then
            success, bot = _down(bot)
        end

        bot.trip_distance = bot.trip_distance + 1
        if not success then
            bot.trip_distance = bot.trip_distance - 1
            return success, bot, i - 1
        end
    end

    return success, bot, distance
end

local function turn_direction(bot, direction)
    -- turn towards direction (left, right)
    if direction == "left" then
        turtle.turnLeft()
        bot.vector = vector_round(vector_yaw_rotation(bot.vector, 90))

    elseif direction == "right" then
        turtle.turnRight()
        bot.vector = vector_round(vector_yaw_rotation(bot.vector, -90))
    end

    return bot
end

local function turn_vector(bot, vector)
    -- theta = acos(dot(v1, v2) / (magnitude(v1) * magnitude(v2)))
    -- where v1 and v2 are normalized
    vector = vector_normalized(vector)
    local theta = math.acos(
        vector_dot_product(vector, bot.vector) /
        (vector_magnitude(vector) * vector_magnitude(bot.vector))
    ) * 180 / math.pi  -- degrees

    if theta > 0 then
        while not vector_equal(bot.vector, vector, "y") do
            bot = turn_direction(bot, "left")
        end
    else
        while not vector_equal(bot.vector, vector, "y") do
            bot = turn_direction(bot, "right")
        end
    end

    return bot
end

local function turn_around(bot)
    for i = 1, 2 do 
        bot = turn_direction(bot, "right") 
    end
    return bot
end

local function opposite_direction(direction)
    if direction == "left" then
        return "right"
    elseif direction == "right" then
        return "left"
    elseif direction == "up" then
        return "down"
    elseif direction == "down" then
        return "up"
    elseif direction == "" then
        return "back"
    elseif direction == "back" then
        return ""
    end
end

-- HIGH LEVEL --

local function mine_vein() end
local function inspect_direction() end
local function inspect() end
local function inspect_position() end

function mine_vein(bot, direction, block_name, fill)
    -- FIXME this ignores corners
    fill = fill or true
    bot.status = "Mining " .. block_name

    local direction_title = string.gsub(direction, "^%l", string.upper)
    turtle["dig" .. direction_title]()
    if not bot.ore[block_name] then
        bot.ore[block_name] = 0
    end
    bot.ore[block_name] = bot.ore[block_name] + 1

    local _, bot = move(bot, direction) -- entering vein
    bot = inspect_position(bot)  -- recurse through vein
    _, bot = move(bot, opposite_direction(direction)) -- leaving vein
    if fill then  -- filling
        turtle["place" .. direction_title]()
    end

    return bot
end

function inspect_direction(direction)
    direction = direction or ""
    local direction_title = string.gsub(direction, "^%l", string.upper)
    local is_block, tags = turtle["inspect" .. direction_title]()
    return is_block, tags
end

function inspect(bot)
    local directions = { "up", "down", "" }  -- up, down, forward
    local is_block, tags = nil, nil

    for _, direction in pairs(directions) do
        is_block, tags = inspect_direction(direction)

        if is_block then
            if is_ore(tags.name, tags.tags) then
                bot = mine_vein(bot, direction, tags.name)
            end
        end
    end

    return bot
end

function inspect_position(bot)
    bot.status = "Inspecting position"
    bot = inspect(bot)  -- inspect forward
    bot = turn_direction(bot, "left")  -- look left
    bot = inspect(bot)  -- inspect left
    bot = turn_around(bot)  -- look right
    bot = inspect(bot)  -- inspect right
    bot = turn_direction(bot, "left")  -- look forward
    return bot
end

local function fuel_quantity()
    local selected = turtle.getSelectedSlot()
    turtle.select(2)

    local quantity = turtle.getItemCount()

    turtle.select(selected)
    return quantity
end

function has_fuel()
    local selected = turtle.getSelectedSlot()
    turtle.select(2)

    if turtle.getFuelLevel() == 0 then
        local refueld = turtle.refuel(1)
        if not refueld then
            turtle.select(1)
            return false
        end
    end

    turtle.select(selected)
    return true
end

local function dump_blocks()
    local selected = turtle.getSelectedSlot()

    for i = 3, 16 do
        turtle.select(i)
        local item = turtle.getItemDetail()
        if item then
            if is_block_type(item.name, "ground") then
                turtle.drop()

            elseif item.name == "minecraft:coal" and fuel_quantity() == 64 then
                turtle.drop()
            end
        end
    end

    turtle.select(selected)
end

local function dig_branch(bot, branch_distance)
    branch_distance = branch_distance or bot.branch_distance

    local direction
    local is_block, tags  -- inspect_direction()
    local move_success  -- move()
    local file  -- io.open()
    local branch_success = false

    for i = 1, branch_distance do
        bot.status = "Digging branch (" .. branch_distance .. ")"
        bot = inspect_position(bot)  -- search for ore

        for _, direction in pairs({ "up", "" }) do  -- digging tunnel
            is_block, tags = inspect_direction(direction)

            if is_block_type(tags.name, "ground") then  -- if ground, break it
                turtle["dig" .. string.gsub(direction, "^%l", string.upper)]()
                dump_blocks()
            end

            if direction == "up" then
                move_success, bot = move(bot, direction)
                bot = inspect_position(bot)
                move_success, bot = move(bot, opposite_direction(direction))
            end
        end
        
        move_success, bot = move(bot)
    end

    branch_success = true
    return branch_success, bot
end

local function dig_end_branch(bot, branch_distance, direction)
    bot = turn_direction(bot, direction)
    local branch_success, bot = dig_branch(bot, branch_distance)
    bot = turn_direction(bot, direction)
    return bot
end

local function dump_to_storage(bot)
    bot.status = "Dumping to storage"
    local selected = turtle.getSelectedSlot()

    local losSP = vector_subtraction(bot.storage_location, bot.position)
    bot = turn_vector(bot, losSP)
    local distance = vector_magnitude(losSP)
    local success, bot = dig_branch(bot, distance)

    for i = 3, 16 do
        turtle.select(i)
        turtle.dropDown()
    end

    turtle.select(selected)
    return success, bot, distance
end

local function return_home(bot)
    bot.status = "Returning home"

    -- temporary
    local losHP = vector_subtraction(bot.home, bot.position)
    bot = turn_vector(bot, losHP)
    bot = move(bot, "forward", vector_magnitude(losHP))

    return bot
end

function flag_handling(args)
    local chunks
    local first_turn_direction
    local storage
    local branch_cycles_to_dig

    for i, arg in ipairs(args) do
        if arg == "-c" then  -- chunks (int 0, 16)
            chunks = args[i+1] + 0
            if chunks < 0 or chunks > 16 then
                chunks = nil
            end

        elseif arg == "-ft" then  -- first turn (string left, right)
            first_turn_direction = args[i+1]
            if first_turn_direction ~= "left" and first_turn_direction ~= "right" then
                first_turn_direction = nil
            end

        elseif arg == "-s" then  -- storage location (vector x,y,z)
            storage = vector_parse(args[i+1])

        elseif arg == "-bc" then  -- branch cycles to dig (int)
            branch_cycles_to_dig = args[i+1] + 0
            if branch_cycles_to_dig < 0 then
                branch_cycles_to_dig = nil
            end
        end
    end

    return chunks, first_turn_direction, storage, branch_cycles_to_dig
end

function transmit(bot)
    local bot_string = textutils.serialize(bot)
    local out_file = io.open("Miner/bot.txt", "a")
    out_file:write("\n" .. bot_string .. "\n")
    out_file:close()

    peripheral.find("modem", rednet.open)
    rednet.broadcast(bot_string, "Miner")
end

-- BOT CONSTRUCTOR --

local function bot_constructor(
    position, vector_, storage, chunks, first_turn_direction, branch_cycles_to_dig
)
    storage = storage or vector.new(gps.locate())
    chunks = chunks or 12
    first_turn_direction = first_turn_direction or "left"
    branch_cycles_to_dig = branch_cycles_to_dig or 1
    return {
        ["name"] = "#" .. os.getComputerID() .. " " .. os.getComputerLabel(),
        ["status"] = "Being built",
        ["trip_distance"] = 0,
        ["fuel_level"] = turtle.getFuelLevel(),
        ["ore"] = {},
        ["position"] = position,
        ["vector"] = {
            ["x"] = vector_.x,
            ["y"] = vector_.y,
            ["z"] = vector_.z
        },
        ["storage_location"] = storage,
        ["home"] = {
            ["x"] = position.x,
            ["y"] = position.y,
            ["z"] = position.z
        },
        ["branch_vector"] = {
            ["x"] = vector_.x,
            ["y"] = vector_.y,
            ["z"] = vector_.z
        },
        ["branch_distance"] = round((chunks * 16) / 2),
        ["branches_dug"] = 0,
        ["branch_turn_direction"] = first_turn_direction,
        ["branch_cycles_to_dig"] = branch_cycles_to_dig,
    }
end

-- MAIN --

local function main(t_args)
    local chunks, first_turn_direction, storage, branch_cycles_to_dig = flag_handling(t_args)
    local bot = bot_constructor(
        vector.new(gps.locate()),  -- position
        { x=0, y=0, z=1 },  -- vector
        storage,  -- storage
        chunks,  -- chunks
        first_turn_direction,  -- first_turn
        branch_cycles_to_dig  -- branch_cycles_to_dig
    )
    turtle.select(1)

    print("Branch cycles: " .. bot.branch_cycles_to_dig)
    print("Branch distance: " .. bot.branch_distance)
    print("First turn: " .. bot.branch_turn_direction)
    print("Storage: " .. tostring(bot.storage_location))

    local branch_success  -- dig_banch()
    local dump_success, distance  -- dump_to_storage()

    -- main loop
    while (
        not bot.branch_cycles_to_dig or 
        bot.branches_dug < bot.branch_cycles_to_dig * 2
    ) do

        -- dig branches, there and back
        for i = 1, 2 do
            -- dig branch
            branch_success, bot = dig_branch(bot)
            if branch_success then
                bot.branches_dug = bot.branches_dug + 1
            end

            -- switch branch turn ever 3 branches
            if bot.branches_dug % 3 == 0 then
                bot.branch_turn_direction = opposite_direction(bot.branch_turn_direction)
            end

            -- dig top end of branch
            if i == 1 then
                bot = dig_end_branch(bot, 3, bot.branch_turn_direction)
            end
        end
        
        -- dump to storage
        dump_success, bot, distance = dump_to_storage(bot)

        -- go to next branch location, some digging may be required
        branch_success, bot = dig_branch(bot, distance)
        bot = turn_direction(bot, bot.branch_turn_direction)
    end

    return_home(bot)
    return
end

main(t_args)