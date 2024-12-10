local executor = require("./executor")
local input = [[
    return 1;
]]
local targetresult = 1
return function()
    local result = executor.run(input)
    assert(result == targetresult)
end
