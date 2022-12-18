-- Cloud drive

local pretty = require "cc.pretty"

--- File ---

local File = {}
File.__index = File

function File:new(o)
    o = o or {
        __NAME = "File",
        path = "",
        attributes = {},
    }
    setmetatable(o, self)

    o.attributes = fs.attributes(o.path)
    return o
end


--- Cloud ---

local Cloud = {}
Cloud.__index = Cloud

function Cloud:new(o)
    o = o or {
        __NAME = "Cloud",
        path = "/Cloud",
        users = {}, -- { ["{user}"] = /Cloud/Users/"{user}" }
        files = {},
    }
    setmetatable(o, self)

    o:read_metadata()
    o:update(o.path)
    o:write_metadata()
    return o
end

function Cloud:read_metadata()
    local metadata = io.open("/Cloud/server_bin/metadata.txt", "r")
    if metadata then
        self.files = textutils.unserialize(metadata:read("*a"))
        metadata:close()
    end
end

function Cloud:update(path)
    -- get files in path
    local ls = fs.list(path)

    -- loop through files
    for i, file_name in ipairs(ls) do
        local file_path = path .. "/" .. file_name

        -- if dir, recurse
        if fs.isDir(file_path) then

            -- if top level folder, add to roots
            if path == self.path .. "/Users" then
                self.users[file_name] = file_path
            end
            self:update(file_path)
            
        -- else insert file
        else
            local file = File:new{path = file_path}
            self.files[file.path] = file
        end
    end
end

function Cloud:remove_file(path)
    for file_path, file in pairs(self.files) do
        if file_path == path then
            self.files[file_path] = nil
            self:update(self.path)
            self:write_metadata()
            break
        end
    end
end

function Cloud:write_metadata()
    local metadata = io.open("/Cloud/server_bin/metadata.txt", "w")
    if metadata then
        table.sort(self.files)
        metadata:write(textutils.serialize(self.files))
        metadata:close()
    end
end

-- get all child files/folders of a parent directory
function Cloud:child_files(parent)
    local files = {}
    for path, file in pairs(self.files) do
        -- if '/Cloud/{user}/' in path
        if string.find(path, parent .. "/") then
            table.insert(files, file)
        end
    end
    return files
end

function Cloud:transmit(message, send_channel)
    print(message)
    send_channel = send_channel or rednet.CLOUD
    print(
        "[" .. tostring(os.date("%m-%d %H:%M:%S")) .. "] " .. message.protocol
)
    local modem = peripheral.find("modem")
    modem.transmit(send_channel, rednet.CLOUD, message)
end

-- transmit what files should be in user's folder
function Cloud:transmit_users()
    for user in pairs(self.users) do
        local message = {
            protocol = "Server:Transmitting:/Cloud/Users/" .. user,
            message = self:child_files(self.users[user])
        }
        self:transmit(message)
    end
end

-- transmit what files should be in bin
function Cloud:transmit_bin()
    local files = self:child_files("/Cloud/bin")
    local message = {
        protocol = "Server:Transmitting:/Cloud/bin",
        message = files
    }
    self:transmit(message)
end

-- shortcut for cloud_client and cloud_setup, use transmit()
function Cloud:transmit_file(file_name)
    local file = io.open("/Cloud/bin/" .. file_name .. ".lua", "r")
    if file then
        local message = {
            protocol = "Server:Sending:" .. file_name,
            message = file:read("*a")
        }
        self:transmit(message)
    end
end

function Cloud:parallel_transmit()
    print("Started parallel transmit")

    while true do
        self:transmit_users()
        self:transmit_bin()
        self:transmit_file("cloud_client")
        self:transmit_file("cloud_setup")

        sleep(5)
    end
end

-- waiting for user's to request files
function Cloud:parallel_request()
    print("Started parallel request")

    local modem = peripheral.find("modem")
    modem.open(rednet.CLOUD)

    while true do
        local event, side, sent_channel, reply_channel, message = os.pullEvent("modem_message")

        if (
            sent_channel == rednet.CLOUD and
            string.find(message.protocol, "Client:Requesting:")
        ) then
            local datetime = tostring(os.date("%m-%d %H:%M:%S"))
            local path = string.sub(message.protocol, string.len("Client:Requesting:") + 1)
            print("[" .. datetime .. "] " .. message.protocol)

            local file = io.open(path, "r")
            if file then
                message = {
                    protocol = "Server:Sending:" .. path,
                    message = file:read("*a")
                }
                self:transmit(message, reply_channel)

            -- file existed in metadata but not on disk
            else
                message = {
                    protocol = "Server:Sending:" .. path,
                    message = "404"
                }
                self:transmit(reply_channel, message)
                self:remove_file(path)
            end
        end
    end
end

function Cloud:parallel_update()
    print("Started parallel update")

    while true do
        local datetime = tostring(os.date("%m-%d %H:%M:%S"))
        print("[" .. datetime .. "] Updating and writing metadata")
        
        self:update(self.path)
        self:write_metadata()
        sleep(5)
    end
end


--- main ---

local function main()
    local cloud = Cloud:new()
    parallel.waitForAll(
        function() cloud:parallel_transmit() end,
        function() cloud:parallel_request() end,
        function() cloud:parallel_update() end
    )
end

main()
