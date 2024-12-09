local executor = require("./executor")
local input = [[
    var a = "hello";
    a = "world";
    var b = true;
    b = "different type";
]]
local targetresults = {
    "hello",
    "world",
    true,
    "different type"
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
