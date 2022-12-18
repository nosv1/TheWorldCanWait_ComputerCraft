local pretty = require "cc.pretty"

local t_args = {...}

--- SUPPORT ---

local function opposite_direction(direction)
    direction = direction == "" and "forward" or direction

    if direction == "up" then
        return "down"
    elseif direction == "down" then
        return "up"
    elseif direction == "right" then
        return "left"
    elseif direction == "left" then
        return "right"
    elseif direction == "forward" then
        return "back"
    elseif direction == "back" then
        return "forward"
    end
end

local function is_block_type(name, type)
    local block_types = {
        ["ground"] = {
            "minecraft:andesite",
            "chisel:basalt/raw",
            "extcaves:brokenstone",
            "create:andesite_cobblestone",
            "minecraft:brown_mushroom",
            "minecraft:cobblestone",
            "minecraft:cobweb",
            "forbidden_arcanus:darkstone",
            "minecraft:diorite",
            "create:diorite_cobblestone",
            "create:dolomite_cobblestone",
            "minecraft:dirt",
            "create:dolomite",
            "create:gabbro",
            "create:gabbro_cobblestone",
            "darkerdepths:glowspire",
            "darkerdepths:glowspurs",
            "darkerdepths:glowshroom",
            "darkerdepths:glowshroom_block",
            "darkerdepths:glowshroom_stem",
            "minecraft:granite",
            "create:granite_cobblestone",
            "minecraft:grass",
            "minecraft:gravel",
            "darkerdepths:grimestone",
            "chisel:laboratory/checkertile",
            "chisel:laboratory/floortile",
            "chisel:laboratory/smalltile",
            "chisel:laboratory/wallpanel",
            "extcaves:lavastone",
            "darkerdepths:mossy_grimestone",
            "minecraft:oak_fence",
            "minecraft:oak_plank",
            "minecraft:polished_diorite",
            "extcaves:polished_lavastone",
            "minecraft:sand",
            "minecraft:sandstone",
            "minecraft:stone",
            "minecraft:stone_bricks",
            "biomesoplenty:toadstool",
            "chisel:tyrian/rust",
        },
        ["avoid"] = {
            "computercraft:turtle_normal",
            "create:shaft",
            "forbidden_arcanus:stella_arcanum"
        }
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
        tags["forge:ores"]
        or name == "buddycards:luminis_ore"
        or name == "minecraft:obsidian"
    )
end

----------------------------------------------------------------------------

local Mission = {}
Mission.__index = Mission
function Mission:new(o)
    o = o or {
        status = "Waiting to start",  -- Waiting to start, Running, Finished
        branch_cycles_to_dig = 1,
        branches_dug = 0,
        branch_distance = 12 * 16 / 2,
        branch_turn_direction = "left",
    }
    setmetatable(o, self)

    o:handle_flags()
    return o
end

function Mission:from_file(o)
    setmetatable(o, self)

    o.status = o.status
    o.branch_cycles_to_dig = o.branch_cycles_to_dig
    o.branches_dug = o.branches_dug
    o.branch_distance = o.branch_distance
    o.branch_turn_direction = o.branch_turn_direction
    return o
end

function Mission:handle_flags()
    for i, arg in pairs(t_args) do
        if arg == "-bc" then
            self.branch_cycles_to_dig = tonumber(t_args[i + 1])

        elseif arg == "-c" then
            -- chunks * 16 / 2, half distnace of max chunks
            -- ideally would have turtle be aware of player pos
            self.branch_distance = math.floor(tonumber(t_args[i + 1]) * 16 / 2)

        elseif arg == "-ft" then
            self.branch_turn_direction = t_args[i + 1]
        end
    end
end

local Bot = {}
Bot.__index = Bot
function Bot:new(o)
    o = o or {
        status = "Waiting to start",
        inventory = {},
        fuel = 0,
        current_branch_length = 0,  -- how far we've traveled
        current_branch_distance = 0,  -- how far we need to travel
        blocks_avoided = {},  -- [block_name: count]
    }
    setmetatable(o, self)

    o.mission = Mission:new()

    o.position = vector.new(gps.locate())
    o.vector = vector.new()
    o.home = o.position
    o.storage_location = o.position
    o.current_branch_start = o.position
    o.current_branch_vector = vector.new()

    o:set_inventory()
    o:set_fuel()
    o:to_file()
    return o
end

function Bot:from_file(o)
    setmetatable(o, self)

    o.mission = Mission:from_file(o.mission)
    o.position = vector.new(
        o.position.x,
        o.position.y,
        o.position.z
    )
    o.vector = vector.new(
        o.vector.x,
        o.vector.y,
        o.vector.z
    )
    o.home = vector.new(
        o.home.x,
        o.home.y,
        o.home.z
    )
    o.storage_location = vector.new(
        o.storage_location.x,
        o.storage_location.y,
        o.storage_location.z
    )
    o.current_branch_start = vector.new(
        o.current_branch_start.x,
        o.current_branch_start.y,
        o.current_branch_start.z
    )
    o.current_branch_vector = vector.new(
        o.current_branch_vector.x,
        o.current_branch_vector.y,
        o.current_branch_vector.z
    )
    o.status = o.status
    o.inventory = o.inventory
    o.fuel = o.fuel
    o.current_branch_length = o.current_branch_length
    o.current_branch_distance = o.current_branch_distance
    o.blocks_avoided = o.blocks_avoided
    return o
end

function Bot:set_inventory()
    local selected = turtle.getSelectedSlot()
    for i = 1, 16 do
        turtle.select(i)
        local item_detail = turtle.getItemDetail()
        if item_detail then
            self.inventory[i] = item_detail
        else
            self.inventory[i] = nil
        end
    end
    turtle.select(selected)
end

function Bot:set_fuel()
    self.fuel = turtle.getFuelLevel()
end

function Bot:to_file()
    local file = io.open("/Cloud/Miner/bot.bot", "w")
    if file then
        -- write attributes to file ignoring attributes that are functions
        file:write(textutils.serialize(self, {allow_repetitions = true}))
        file:close()
    end
end

function Bot:transmit()
    local modem = peripheral.find("modem")
    local message = {
        protocol = "Miner:Sending:Bot",
        message = textutils.serialize(self, {allow_repetitions = true})
    }
    modem.transmit(rednet.MINER, os.getComputerID(), message)
end

function Bot:refuel()
    local selected = turtle.getSelectedSlot()
    turtle.select(2)  -- fuel slot
    local fuel_count = turtle.getItemCount()
    turtle.refuel(fuel_count - 1)  -- keep the slot non-empty
    self:set_fuel()
    turtle.select(selected)
end

function Bot:turn(direction, count)
    count = count or 1
    local Direction = string.gsub(direction, "^%l", string.upper)
    for i = 1, count do
        turtle["turn" .. Direction]()
    end
end

-- @tparam string|vector_table
function Bot:move(direction, distance)
    direction = direction or "forward"
    direction = direction == "" and "forward" or direction
    distance = distance or 1

    -- if direction is a vector, convert to string direction
    if type(direction) == "table" then
        direction = direction:direction()
    end

    self:refuel()

    for i = 1, distance do
        local old_position = self.position
        turtle[direction]()
        self.position = vector.new(gps.locate())
        self.velocity = self.position:sub(old_position)

        self:to_file()
        self:transmit()
    end
end

function Bot:dump_ground()
    local selected = turtle.getSelectedSlot()
    for i = 3, 16 do
        turtle.select(i)
        local item_detail = turtle.getItemDetail()

        if item_detail then
            if (
                is_block_type(item_detail.name, "ground") or
                item_detail.name == "minecraft:coal"
            ) then
                turtle.drop()
            end
        end
        
    end
    turtle.select(selected)
end

function Bot:mine_vein(direction, fill)
    -- FIXME this ignores corners
    direction = direction or ""
    direction = string.gsub(direction, "forward", "")
    fill = fill or true

    local Direction = string.gsub(direction, "^%l", string.upper)
    turtle["dig" .. Direction]()

    self:move(direction) -- entering vein
    self:inspect_position() -- recurse through vein
    self:move(opposite_direction(direction)) -- leaving vein
    if fill and turtle.getItemCount() > 1 then  -- filling
        turtle["place" .. Direction]()
    end
end

function Bot:inspect_direction(direction)
    direction = direction or ""
    direction = string.gsub(direction, "forward", "")

    local Direction = string.gsub(direction, "^%l", string.upper)
    local is_block, block = turtle["inspect" .. Direction]()
    return is_block, block
end

function Bot:inspect()
    local is_block, block = nil, nil

    for _, direction in pairs({ "forward" , "up" , "down"}) do
        is_block, block = self:inspect_direction(direction)

        if is_block then
            if (
                is_ore(block.name, block.tags) and
                not is_block_type(block.name, "avoid")
            ) then
                local mod, name = string.match(block.name, "^(.+):(.+)$")
                self.status = "Mining vein of `" .. name .. "`"
                self:mine_vein(direction)
                self:set_inventory()
            end
        end
    end
end

function Bot:inspect_position()
    self:inspect()
    self:turn("left")
    self:inspect()
    self:turn("right", 2)
    self:inspect()
    self:turn("left")
end

function Bot:go_around(name)
    -- assuming desire is to go around one block in front of bot
    turtle.digUp()
    self:move("up")
    for i = 1, 2 do
        turtle.dig()
        self:move()
    end
    turtle.digDown()
    self:move("down")
end

function Bot:dig_branch(distance)
    self.current_branch_distance = distance or self.mission.branch_distance

    -- only set new branch start if we completed one
    if self.current_branch_start == vector.new() then
        self.current_branch_start = self.position
    end

    while self.current_branch_length < self.current_branch_distance do
        self.status = "Digging branch"
        self:inspect_position()  -- look for ore

        for _, direction in pairs({ "up", ""}) do  -- dig tunnel
            local is_block, block = self:inspect_direction(direction)

            if is_block_type(block.name, "ground") then
                turtle["dig" .. string.gsub(direction, "^%l", string.upper)]()
                self:dump_ground()

            elseif direction == "" and is_block_type(block.name, "avoid") then
                self:go_around(block.name)
            end

            if direction == "up" then
                -- check if bot didn't stop in 'up' direction
                if self.position.y == self.home.y then
                    self:move(direction)
                    self:inspect_position()
                end
                self:move(opposite_direction(direction))
            end
        end
        
        self:move()
        self.current_branch_vector = self.velocity
        self.current_branch_length = self.position:sub(self.current_branch_start):length2D()
        self:to_file()  -- have to write to file to store current_branch_vector
    end

    self.current_branch_start = vector.new()
    self.current_branch_length = 0
end

function Bot:storage_dump()
    local selected = turtle.getSelectedSlot()
    local distance = self.storage_location:sub(self.position):length2D()
    self:dig_branch(distance)

    for i = 3, 16 do
        turtle.select(i)
        turtle.dropDown()
    end
    self:set_inventory()

    turtle.select(selected)
    return distance
end

function Bot:return_home()
    -- temporary
    self:turn("left", 2)
    local distance = self.home:sub(self.position):length()
    self:move("forward", distance)
end

function Bot:resume()
    self.mission.status = "Running"

    while self.mission.branches_dug < self.mission.branch_cycles_to_dig * 2 do
        
        -- dig main branch
        self:dig_branch()
        self.mission.branches_dug = self.mission.branches_dug + 1

        -- switch branch turn every 3 branches
        if (
            self.mission.branches_dug > 1 and
            (self.mission.branches_dug - 1) % 2 == 0
        ) then
            self.mission.branch_turn_direction = opposite_direction(
                self.mission.branch_turn_direction
            )
        end

        self:turn(self.mission.branch_turn_direction)
        -- dig end of branch if at the 'top'
        if self.mission.branches_dug % 2 ~= 0 then
            self:dig_branch(3)
            self:turn(self.mission.branch_turn_direction)

        else
            -- dump storage
            self.status = "Dumping storage"
            local distance = self:storage_dump()

            -- if we have more branches to dig, go to next branch start
            if self.mission.branches_dug < self.mission.branch_cycles_to_dig * 2 then
                self:dig_branch(distance)
                self:turn(self.mission.branch_turn_direction)
            end
        end
    end

    print("All Branch cycles completed")
    self.mission.status = "Completed"
    self.status = "Completed"
    self:transmit()
    self:to_file()
end

local function main(t_args)
    turtle.select(1)

    if t_args[1] == "resume" then
        print("Attempting to resume mission")

        local bot_file = io.open("/Cloud/Miner/bot.bot", "r")
        if bot_file then
            local unserialized_file = textutils.unserialize(bot_file:read("*a"))
            bot_file:close()

            if unserialized_file then
                local bot = Bot:from_file(unserialized_file)
            
                if (
                    vector.new(gps.locate()) == bot.position and
                    bot.mission.status == "Running"
                ) then
                    print("Resuming mission")
                    bot:resume()
                    return

                else
                    print("Canceling resume")
                    return
                end
            end
        end
    end

    print("Starting mission")
    local bot = Bot:new()
    bot:resume()

end

main(t_args)