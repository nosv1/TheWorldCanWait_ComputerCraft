print("Running rednet.lua")
shell.run("/Cloud/bin/rednet/rednet.lua")

print("Running cloud_client_updater.lua")
shell.run("/Cloud/bin/cloud_client_updater.lua")

print("Running cloud_client.lua")
shell.run("/Cloud/bin/cloud_client.lua")

-- 

print("Running api_extenions.lua")
shell.run("/Cloud/bin/api_extensions/api_extensions.lua")

print("Running rednet.lua")
shell.run("/Cloud/bin/rednet/rednet.lua")