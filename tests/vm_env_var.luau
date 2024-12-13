local fvm = require("../utils/fvm")
local input = [[
    return _ENV;
]]
local targetresult = "hi"
return function()
    local vm = fvm.new()
    vm:pushToEnv("_ENV", "hi")
    vm:execute(input)
    local result = vm:getResult()
    assert(result == targetresult, "Assertion failed!")
end
