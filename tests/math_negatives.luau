local executor = require("./executor")
local input = [[
    var a = -1 + 2;
    var b = 10 * -1;
    var c = a - b;
    var d = -(8);
]]
local targetresults = {
    1,
    -10,
    11,
    -8
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
