local executor = require("./executor")
local input = [[
    var integer := 1;
    integer = 2;
    integer = "1";
]]
return function()
    local success, _ = pcall(executor.exec, input)
    assert(not success, "Can't assign a different type than the one defined!")
end
