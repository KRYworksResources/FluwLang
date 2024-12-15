local executor = require("./executor")
local input = [[
    # we dont parse this
    var a = true; # or this
    return a;
]]
local targetresult = true
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end