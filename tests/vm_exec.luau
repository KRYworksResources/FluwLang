local fvm = require("../utils/fvm")
local input = [[
    return "hi";
]]
local targetresult = "hi"
return function()
    local vm = fvm.new()
    vm:execute(input)
    local result = vm:getResult()
    assert(result == targetresult, "Assertion failed!")
end
