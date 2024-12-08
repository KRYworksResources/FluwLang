local executor = require("./executor")
local input = [[
    def a = -1 + 2;
    def b = 10 * -1;
    def c = a - b;
    def d = -(8);
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
