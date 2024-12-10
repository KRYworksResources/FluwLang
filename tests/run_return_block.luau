local executor = require("./executor")
local input = [[
    var i = 1;
    while (true) {
        i = i + 1;
        if (i > 5) {
            return i;
        };
    };
]]
local targetresult = 6
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
