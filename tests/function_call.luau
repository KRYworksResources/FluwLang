local executor = require("./executor")
local input = [[
    fn a(b, c) {
        return b + c;
    };
    var one = 1;
    return a(one, 2);
]]
local targetresult = 3
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
