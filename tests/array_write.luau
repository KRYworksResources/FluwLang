local executor = require("./executor")
local input = [[
    var a = [];
    a[1] = "v";
    return a[1] != null;
]]
local targetresult = true
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
