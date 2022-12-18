local coroutine_1 = coroutine.create(
    function()
        print("Hello from coroutine 1")
        coroutine.yield()
    end
)

local coroutine_2 = coroutine.create(
    function()
        print("Hello from coroutine 2")
        coroutine.yield()
    end
)

while true do
    coroutine.resume(coroutine_1)
    coroutine.resume(coroutine_2)
    print("\r" .. "Time: " .. os.clock())
end