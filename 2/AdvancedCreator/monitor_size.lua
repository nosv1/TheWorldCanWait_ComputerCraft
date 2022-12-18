mon = peripheral.wrap("left")

for i = 1, 100 do
    mon.setCursorPos(1, i)
    for j = 1, 100 do
        mon.write(string.format("%d", j + i - 1))
    end
end
