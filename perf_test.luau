local Fluw = require("./init")

print("luau 1e6 loop started")
local start = os.clock()
local i = 0
while i < 1000000 do
    i += 1
end
print(string.format("luau 1e6 loop ended in %.4f ms", (os.clock()-start)*1000))

print("fluw 1e6 loop started")
start = os.clock()
Fluw.executeString([[
    var i = 0;
    while (i < 1000000) {
        i += 1;
    };
]])
print(string.format("fluw 1e6 loop ended in %.4f ms", (os.clock()-start)*1000))