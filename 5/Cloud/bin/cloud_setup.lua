rednet.CLOUD = 65532
shell.run("cp /disk/Cloud /Cloud")
shell.run("mkdir /Cloud/" .. os.getComputerLabel())
shell.run("/Cloud/bin/cloud_client_updater.lua")
shell.run("/Cloud/bin/cloud_client.lua")
print()
print("Cloud is set up")
print("Remember to add to PC's startup:")
print('    - shell.run("Cloud/bin/startup.lua")')