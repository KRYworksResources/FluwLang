local fvm = require("../utils/fvm")
local input = [[
    _ENV = fn() {
        return "NAHHH";
    };
    return _ENV();
]]
local targetresult = "NAHHH"
return function()
    local vm = fvm.new()
    vm:pushToEnv("_ENV", function()
        return "HIIII"
    end, true)
    vm:execute(input)
    local result = vm:getResult()
    assert(result == targetresult, "Assertion failed!")
end
