local executor = require("./executor")
local input = [[
    const a = "hello, world!";
    a = "this should fail";
    const b = true;
    b = false;
]]
return function()
    --local results = executor.exec(input)
    local success, _ = pcall(executor.exec, input)
    assert(not success, "Consts should not be able to be redeclared without error.")
end
