local executor = require("./executor")
local input = [[
    var counter = 0;
    while (true) {
        if (counter > 10) { a; }; #we reference nil value to error out
        counter += 1;
        if (counter < 5) {
            continue;
        };
        break;
    };
    return counter;
]]
local targetresult = 5
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
