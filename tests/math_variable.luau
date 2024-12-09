local executor = require("./executor")
local input = [[
    def a = 3 + 4 * 5;
    def b = (3 + 4) * 5;
    def d = a + b;
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
