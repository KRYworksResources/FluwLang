local executor = require("./executor")
local input = [[
    var a = {};
    a.k = "v";
    return a.k != null;
]]
local targetresult = true
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
