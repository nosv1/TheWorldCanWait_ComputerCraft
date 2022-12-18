-- get cloud_client.lua from cloud_server

local function download_file(file_name)
    print("Downloading " .. file_name .. ".lua")

    local modem = peripheral.find("modem")
    modem.open(rednet.CLOUD)

    while true do 
        local event, side, sent_channel, reply_channel, message = os.pullEvent("modem_message")

        if message.protocol == "Server:Sending:" .. file_name then
            print("Downloaded " .. file_name)

            local path = "/Cloud/bin/" .. file_name .. ".lua"
            shell.run("rm " .. path)
            print("Removed old " .. path)

            local file = io.open(path, "w")
            file:write(message.message)
            file:close()
            print("Updated " .. path)

            return true
        end
    end
end

local function main()
    parallel.waitForAll(
        function() return download_file("cloud_client") end,
        function() return download_file("cloud_setup") end
    )
end

main()