local executor = require("./executor")
local input = [[
    var a = [
        [
            1
        ]
    ];
    var b = a[1][1];
    return b;
]]
local targetresult = 1
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
