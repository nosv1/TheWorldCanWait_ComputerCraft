local pretty = require "cc.pretty"

local modem = peripheral.find("modem")
modem.open(rednet.MINER)

local term_x, term_y = term.getSize()

local bots = {}  -- [bot_id: bot]
local bot_line_range = {nil, nil}  -- [start, end]

local function get_bot_lines(bot_id, bot)
    local lines = { }

    table.insert(lines, "ID: " .. bot_id)
    table.insert(lines, "Status:")
    table.insert(lines, "  " .. bot.mission.status)
    table.insert(lines, "  " .. bot.status)
    table.insert(lines, "Position: " .. tostring(vector.new(
        bot.position.x, bot.position.y, bot.position.z
    )))
    table.insert(lines, "Fuel: " .. bot.fuel)
    table.insert(lines, "Branches dug: " .. bot.mission.branches_dug)
    table.insert(lines, "Branches to dig: " .. bot.mission.branch_cycles_to_dig * 2)
    table.insert(lines, "Branch length: " .. bot.current_branch_length)
    table.insert(lines, "Branch distance: " .. bot.current_branch_distance)
    table.insert(lines, "Inventory:")
    table.insert(lines, "   #: item")

    for i, block in pairs(bot.inventory) do
        local mod, name = string.match(block.name, "^(.+):(.+)$")

        -- name
        -- split name by underscore, remove vowels from long words
        local name_parts = { }
        for word in string.gmatch(name, "[^_]+") do
            if #word > 5 then
                word = string.gsub(word, "[aeiou]", "")
            end
            table.insert(name_parts, word)
        end

        -- count
        -- zero fill count to 2 digits
        local count = tostring(block.count)
        count = string.rep("0", 2 - #count) .. count

        table.insert(lines, "  " .. count .. ": " .. table.concat(name_parts, " "))
    end

    return lines
end

local function write_to_screen(key)
    key = key or nil
    key = key == "up" and -1 or key == "down" and 1 or 0
    
    term.clear()
    local time = os.date("%I:%M %p")

    local header = {
        "Miner Broadcast",
        string.rep("=", term_x)
    }
    header[1] = header[1] .. string.rep(" ", term_x - #header[1] - #time) .. time
    local body = {}
    local footer = {
        string.rep("=", term_x),
        "Lines " .. table.concat(bot_line_range, " - "),
        "Press up/down to scroll"
    }

    -- header
    for i, line in ipairs(header) do
        term.setCursorPos(1, i)
        term.write(line)
    end

    -- bot lines
    for bot_id, bot in pairs(bots) do
        for i, line in ipairs(get_bot_lines(bot_id, bot)) do
            table.insert(body, line)
        end
    end

    local max_lines_for_body = term_y - #header - #footer
    if bot_line_range[1] == nil then
        bot_line_range[1] = 1
        bot_line_range[2] = math.max(max_lines_for_body)
    end

    if key ~= 0 then
        if key == -1 then
            if bot_line_range[1] > 1 then
                bot_line_range[1] = bot_line_range[1] - 1
                bot_line_range[2] = bot_line_range[2] - 1
            end
        elseif key == 1 then
            if bot_line_range[2] < #body then
                bot_line_range[1] = bot_line_range[1] + 1
                bot_line_range[2] = bot_line_range[2] + 1
            end
        end
    end

    for i, line in ipairs(body) do
        if i >= bot_line_range[1] and i <= bot_line_range[2] then
            term.setCursorPos(1, i - bot_line_range[1] + #header + 1)
            term.write(line)
        end
    end

    -- footer
    footer[2] = "Lines " .. table.concat(bot_line_range, " - ") .. " of " .. #body
    for i, line in ipairs(footer) do
        term.setCursorPos(1, term_y - #footer + i)
        term.write(line)
    end

end

local function main()

    while true do

        local event, b, c, d, e = os.pullEvent()

        if event == "modem_message" then
            local side, sent_channel, reply_channel, message = b, c, d, e

            if message.protocol == "Miner:Sending:Bot" then
                bots[reply_channel] = textutils.unserialize(message.message)
            end

            write_to_screen()

        elseif event == "key_up" then
            local key = b
            write_to_screen(keys.getName(key))
        end
    end
end

main()