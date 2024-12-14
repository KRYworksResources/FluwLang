local executor = require("./executor")
local input = [[
    var t = {
        "f": fn(a, b) {
            return a + b;
        }
    };
    var one = 1;
    return t.f(one, 2);
]]
local targetresult = 3
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
