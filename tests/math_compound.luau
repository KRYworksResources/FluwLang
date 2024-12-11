local executor = require("./executor")
local input = [[
    var i = 1;
    i += 1;
    i -= 2;
    var t = {"n": 1};
    t.n *= 10;
    return (t.n == 10) and (i == 0);
]]
local targetresult = true
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
