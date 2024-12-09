local executor = require("./executor")
local input = [[
    var a = "hello" + "world";
    var b = "my id is " + 5;
    var c = 5 + " gnomes";
]]
local targetresults = {
    "helloworld",
    "my id is 5",
    "5 gnomes"
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
