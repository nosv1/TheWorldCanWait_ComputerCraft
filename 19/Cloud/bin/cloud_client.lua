local pretty = require "cc.pretty"

-- check what files we have in /User
-- check what files are in cloud
-- determine missing or outdated
-- download files

File = {
    __Name = "File",
    path = "",
    attributes = {},
}

function File:new(o)
    o = o or {}
    o.attributes = fs.attributes(o.path)
    setmetatable(o, self)
    self.__index = self
    return o
end

local function get_local_files(path)
    print("Getting local files in " .. path)

    local files = {}
    for i, file in ipairs(fs.list(path)) do
        local file_path = path .. "/" .. file

        if fs.isDir(file_path) then
            for j, recursed_file in pairs(get_local_files(file_path)) do
                table.insert(files, recursed_file)
            end
            
        else
            file = File:new{path = file_path}
            files[file.path] = file
        end
    end
    return files
end

local function get_cloud_files(path)
    print("Getting cloud files in " .. path)

    local modem = peripheral.find("modem")
    modem.open(rednet.CLOUD)

    while true do
        local event, side, sent_channel, reply_channel, message = os.pullEvent("modem_message")
        local protocol = message.protocol
        message = message.message
        if protocol == "Server:Transmitting:" .. path then
            local files = message
            return files
        end
    end
end

local function determine_missing_and_outdated(cloud_files, local_files)
    local missing_and_outdated = {}
    for i, cloud_file in pairs(cloud_files) do
        local path = string.gsub(cloud_file.path, "Users/", "")

        if local_files[path] then
            -- outdated
            if local_files[path].attributes.modified < cloud_file.attributes.modified then
                missing_and_outdated[path] = cloud_file
            end

        -- missing
        else
            missing_and_outdated[path] = cloud_file
        end
    end

    return missing_and_outdated
end

local function transmit(reply_channel, message)
    local datetime = tostring(os.date("%m-%d %H:%M:%S"))
    print("[" .. datetime .. "] " .. message.protocol)

    local modem = peripheral.find("modem")
    modem.transmit(rednet.CLOUD, reply_channel, message)
end

local function download_file(path, file_contents)
    print("Downloading " .. path)

    if fs.exists(path) then
        shell.run("rm " .. path)
        print("Removed old " .. path)
    end

    local file = io.open(path, "w")
    file:write(file_contents)
    file:close()
    print("Downloaded " .. path)
    return true
end

-- @tparam File
local function request_file(file)

    local modem = peripheral.find("modem")
    modem.open(os.getComputerID())

    while true do
        -- request server for file every iteration until we get it
        local message = {
            protocol = "Client:Requesting:" .. file.path,
            message = file
        }
        transmit(os.getComputerID(), message)

        -- wait for file
        local event, side, sent_channel, reply_channel, message = os.pullEvent("modem_message")

        if message.protocol == "Server:Sending:" .. file.path then
            -- get the server path from the protocol, then remove Users/
            local path = string.sub(message.protocol, string.len("Server:Sending:") + 1)
            path = string.gsub(path, "Users/", "")

            if message.message == "404" then  -- file wasn't on server, delete locally
                if fs.exists(path) then
                    shell.run("rm " .. path)
                    print("Removed " .. path)

                else
                    print(path .. " does not exist on server or locally")
                end

            else
                download_file(path, message.message)
            end

            break
        end
    end
    modem.close(os.getComputerID())
end

-- @tparam table[i: File]
local function request_files(files)
    for i, file in pairs(files) do
        request_file(file)
    end
end

local function main()
    local cloud_files = get_cloud_files("/Cloud/Users/" .. os.getComputerLabel())
    local cloud_bin_files = get_cloud_files("/Cloud/bin")
    local local_files = get_local_files("/Cloud/" .. os.getComputerLabel())
    local local_bin_files = get_local_files("/Cloud/" .. "bin")

    -- combine files and bin files
    for i, file in pairs(cloud_bin_files) do
        cloud_files[file.path] = file
    end
    for i, file in pairs(local_bin_files) do
        local_files[file.path] = file
    end

    local missing_and_outdated = determine_missing_and_outdated(
        cloud_files, local_files
    )
    request_files(missing_and_outdated)
end

main()