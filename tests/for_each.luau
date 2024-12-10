local executor = require("./executor")
local input = [[
    foreach (k, v in ["test"]) {
        return v;
    };
]]
local targetresult = "test"
return function()
    local result = executor.run(input)
    assert(result == targetresult, "Assertion failed!")
end
