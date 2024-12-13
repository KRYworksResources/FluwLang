local executor = require("./executor")
local input = [[
    var a = [
        "value"
    ];
    var b = a[1];
    return b;
]]
local targetresult = "value"
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
