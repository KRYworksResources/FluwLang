local executor = require("./executor")
local input = [[
    var a = {
        "key": "value"
    };
    var b = a["key"];
    var c = a.key;
    return b == c;
]]
local targetresult = true
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
