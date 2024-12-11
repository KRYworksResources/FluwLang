local executor = require("./executor")
local input = [[
    var i = 1;
    i += 1;
    i -= 2;
    return i == 0;
]]
local targetresult = true
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
