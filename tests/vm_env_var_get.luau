local fvm = require("../utils/fvm")
local input = [[
    var _ENV = "hi";
]]
local targetresult = "hi"
return function()
    local vm = fvm.new()
    vm:execute(input)
    local result = vm:pullFromEnv("_ENV", "hi")
    assert(result == targetresult, "Assertion failed!")
end
