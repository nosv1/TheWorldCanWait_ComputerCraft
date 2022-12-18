args = { ... }
print(args)
print(type(args))
print(args.keys)
print(args[1])
print(args["1"])

for k, v in pairs(args) do print(tostring(k) .. tostring(v)) end


