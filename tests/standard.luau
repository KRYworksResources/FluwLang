local fvm = require("../utils/fvm")
local input = [[
    print("hello test.luau!!");
    return 1;
]]
local targetresult = 1
return function()
    local vm = fvm.new() 
    vm:execute(input)
    local result = vm:getResult()
    assert(result == targetresult, "Assertion failed!")
end
