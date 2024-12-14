local executor = require("./executor")
local input = [[
    var lambda = fn(a, b) {
        return a + b;
    };
    return lambda(1, 2);
]]
local targetresult = 3
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
