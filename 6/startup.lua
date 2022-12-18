shell.run("bg gps host 485 65 -502")
shell.run("bg repeat")

shell.run("Cloud/server_bin/startup.lua")

term.clear()
local title_str = "Hello friend..."
for i = 1, #title_str do
    term.setCursorPos(i, 1)
    term.write("-")
    term.setCursorPos(i,2)
    term.write(title_str:sub(i, i))
    term.setCursorPos(i,3)
    term.write("-")
    sleep(0.1)
end    
print()
