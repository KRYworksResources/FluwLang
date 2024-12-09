local executor = require("./executor")
local input = [[
    var a = 3 + 4 * 5;
    var b = (3 + 4) * 5;
    var d = a + b;
]]
local targetresults = {
    23,
    35,
    58
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
