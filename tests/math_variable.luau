local executor = require("./executor")
local input = [[
    def a = 3 + 4 * 5;
    def b = (3 + 4) * 5;
    def c = 2 ^ 3 ^ 2;
    def d = a + b;
    d + c;
]]
local targetresults = {
    23,
    35,
    512,
    58,
    570
}
return function()
    local results = executor.exec(input)
    assert(executor.compare_tables(results, targetresults))
end
