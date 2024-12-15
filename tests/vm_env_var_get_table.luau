local executor = require("./executor")
local fvm = require("../utils/fvm")
local input = [[
    var _ENV = {
        "hi": "hi"
    };
]]
local targetresult = {
    hi = "hi"
}
return function()
    local vm = fvm.new()
    vm:execute(input)
    local result = vm:pullFromEnv("_ENV")
    assert(executor.compare_tables(result, targetresult), "Assertion failed!")
end
