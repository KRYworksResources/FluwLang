local executor = require("./executor")
local input = [[
    var i = 1;
    do {
        i = 3;
    };
    return i;
]]
local targetresult = 3
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
