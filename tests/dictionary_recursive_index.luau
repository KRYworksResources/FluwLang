local executor = require("./executor")
local input = [[
    var a = {
        "key": "value",
        "sub": {
            "k": "v"
        }
    };
    var b = a["sub"];
    var c = b.k;
    return c == a["sub"].k;
]]
local targetresult = true
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
