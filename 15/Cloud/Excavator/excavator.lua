-- mining program that digs 1D layers of half of a circle of given radius

-- From the start, it should dig straight until it hits the edge of the circle
-- check if block left or right is within radius, dig it, then go back to diameter line of circle where it started

local t_args = {...}

--------------------- UTILS ---------------------

local turns = {
    left = "left",
    right = "right",
}

local function distance(a, b)
    return math.sqrt((a.x - b.x)^2 + (a.y - b.y)^2 + (a.z - b.z)^2)
end

local function is_block_type(block_name, block_type)
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
            "forbidden_arcanus:stella_arcanum"
        }
    }

    for _, block in ipairs(block_types[block_type]) do
        if block_name == block then
            return true
        end
    end

    return false
end

--------------------- MISSION ---------------------

local Mission = {}
Mission.__index = Mission
function Mission:new(o)
    o = o or {
        branch_start = vector.new(0, 0, 0),  -- set this when starting a branch
        radius = 1,
    }
    setmetatable(o, self)
    self.__index = self

    o.center = vector.new(0, 0, 0)
    o.current_turn = turns.right

    return o
end

--------------------- BOT ---------------------

local Bot = {}
Bot.__index = Bot
function Bot:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.velocity = vector.new(0, 0, 0)
    o.position = vector.new(0, 0, 0)
    o.mission = Mission:new()

    return o
end

function Bot:distance_to_center(position)
    position = position or self.position
    return position:sub(self.mission.center):length()
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

function Bot:refuel()
    local selected = turtle.getSelectedSlot()
    turtle.select(2)  -- fuel slot
    local fuel_count = turtle.getItemCount()
    turtle.refuel(fuel_count - 1)  -- keep the slot non-empty
    turtle.select(selected)
end

function Bot:dig()
    turtle.dig()
    turtle.forward()
    self.position = self.position + self.velocity
    print("Position:", self.position)

    is_block_above, block_above = turtle.inspectUp()
    if is_block_above and not is_block_type(block_above.name, "avoid") then
        turtle.digUp()
    end

    is_block_below, block_below = turtle.inspectDown()
    if is_block_below and not is_block_type(block_below.name, "avoid") then
        turtle.digDown()
    end

    self:dump_ground()
    self:refuel()
end

function Bot:dig_half()
    -- this starts on the outer edge of circle
    -- digs length of diameter, checking if next block is within circle
    self.velocity = vector.new(1, 0, 0)
    self.position = self.velocity:unm():mul(self.mission.radius + 1):round()

    while true do
        self:dig()

        local block_ahead_position = self.position + self.velocity
        if self:distance_to_center(block_ahead_position) > self.mission.radius then
            print("Distance to center:", self:distance_to_center(block_ahead_position))
            if self.mission.current_turn == turns.left then
                local left_block_position = self.position + self.velocity:rotate(90):round()
                if self:distance_to_center(left_block_position) > self.mission.radius + 1 then
                    turtle.back()
                    self.position = self.position - self.velocity
                end
                turtle.turnLeft()
                self.velocity = self.velocity:rotate(-90):round()
                self:dig()
                turtle.turnLeft()
                self.velocity = self.velocity:rotate(-90):round()
                
            else
                local right_block_position = self.position + self.velocity:rotate(-90):round()
                if self:distance_to_center(right_block_position) > self.mission.radius + 1 then
                    turtle.back()
                    self.position = self.position - self.velocity
                end
                turtle.turnRight()
                self.velocity = self.velocity:rotate(90):round()
                self:dig()
                turtle.turnRight()
                self.velocity = self.velocity:rotate(90):round()
            end
            print("Velocity:", self.velocity)

            self.mission.current_turn = (self.mission.current_turn == turns.left 
                and turns.right 
                or turns.left)
        end
        if self:distance_to_center() > self.mission.radius + 1 then
            break
        end
    end
end

--------------------- MAIN ---------------------

local function main(t_args)
    turtle.select(1)

    print("Starting mission")
    local bot = Bot:new()
    bot.mission.radius = tonumber(t_args[1])
    bot:dig_half()

end

main(t_args)