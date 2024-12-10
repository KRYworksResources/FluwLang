local executor = require("./executor")
local input = [[
    var v = 1;
    for (var i = 1; i < 5; i = i+1) {
        v = i;
    };
    return v;
]]
local targetresult = 5
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
