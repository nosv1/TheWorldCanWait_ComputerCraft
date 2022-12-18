print("Running api_extenions.lua")
shell.run("/Cloud/bin/api_extensions/api_extensions.lua")

print("Running rednet.lua")
shell.run("/Cloud/bin/rednet/rednet.lua")

shell.run("bg /Cloud/server_bin/cloud_server.lua")
