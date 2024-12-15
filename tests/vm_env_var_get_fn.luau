local fvm = require("../utils/fvm")
local input = [[
    var _ENV = fn() {
        return "hi";
    };
]]
local targetresult = "hi"
return function()
    local vm = fvm.new()
    vm:execute(input)
    local result = vm:pullFromEnv("_ENV")()
    assert(result == targetresult, "Assertion failed!")
end
